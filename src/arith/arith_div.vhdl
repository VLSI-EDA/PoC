-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Authors:					Thomas B. Preusser
-- 
-- Module:					Multi-cycle Non-Performing Restoring Divider
-- 
-- Description:
-- ------------------------------------
--	Implementation of a Non-Performing restoring divider with a configurable radix.
--	The multi-cycle division is controlled by 'start' / 'rdy'. A new division is
--	started by asserting 'start'. The result Q = A/D is available when 'rdy'
--  returns to '1'.
--  The generic DETECT_DIVISION_BY_ZERO enables circuitry to detect a divisor
--  of zero (0) right upon start. It is signalled by the corresponding output
--  'Z' together with an immediate 'rdy' indication. If this generic flag is
--  not enabled, the output 'Z' will never be asserted. The computation, in
--  fact, also terminates but with undefined results.
-- =============================================================================
-- Copyright 2007-2016 Technische Universität Dresden - Germany,
--										 Chair for VLSI-Design, Diagnostics and Architecture
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--		http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library IEEE;
use IEEE.std_logic_1164.all;

entity arith_div is
  generic (
    A_BITS             : positive;  		    -- Dividend Width
    D_BITS             : positive;  		    -- Divisor Width
    DETECT_DIV_BY_ZERO : boolean;  			    -- Detect Division by Zero
    RAPOW              : positive := 1;     -- Power of Compute Radix (2**RAPOW)
    PIPELINED          : boolean  := false  -- Computation Pipeline
  );
  port (
    -- Global Reset/Clock
    clk : in std_logic;
    rst : in std_logic;

    -- Ready / Start
    start : in  std_logic;
    ready : out std_logic;

    -- Arguments / Result (2's complement)
    A : in  std_logic_vector(A_BITS-1 downto 0);  -- Dividend
    D : in  std_logic_vector(D_BITS-1 downto 0);  -- Divisor
    Q : out std_logic_vector(A_BITS-1 downto 0);  -- Quotient
    R : out std_logic_vector(D_BITS-1 downto 0);  -- Remainder
    Z : out std_logic  -- Division by Zero
  );
end arith_div;


library IEEE;
use IEEE.numeric_std.all;

library PoC;
use PoC.utils.all;

architecture rtl of arith_div is

  -- Constants
  constant STEPS       : positive := (A_BITS+RAPOW-1)/RAPOW;   -- Number of Iteration Steps
  constant DEPTH       : natural  := ite(PIPELINED, STEPS, 0); -- Physical Depth
  constant TRUNK_BITS  : natural  := (STEPS-1)*RAPOW;
  constant ACTIVE_BITS : positive := D_BITS + RAPOW;

  -- Private Types
	subtype residue is unsigned(ACTIVE_BITS+TRUNK_BITS-1 downto 0);
	subtype divisor is unsigned(D_BITS-1 downto 0);
	type residue_vector is array(natural range<>) of residue;
	type divisor_vector is array(natural range<>) of divisor;

  function div_step(av : residue; dv : divisor) return residue is
    variable res : residue;
    variable win : unsigned(D_BITS-1 downto 0);
    variable dif : unsigned(D_BITS downto 0);
  begin
    win := av(av'left downto TRUNK_BITS + RAPOW);
    for i in RAPOW-1 downto 0 loop
      dif := (win & av(TRUNK_BITS+i)) - dv;
      if dif(dif'left) = '0' then
        win := dif(D_BITS-1 downto 0);
      else
        win := win(D_BITS-2 downto 0) & av(TRUNK_BITS+i);
      end if;
      res(i) := not dif(dif'left);
    end loop;
    res(res'left downto RAPOW) := win & av(TRUNK_BITS-1 downto 0);
    return res;
  end function div_step;

	-- Data Registers
  signal AR : residue_vector(0 to DEPTH) := (others => (others => '-'));
  signal DR : divisor_vector(0 to DEPTH) := (others => (others => '-'));
  signal ZR : std_logic := '-';  -- Zero Detection only in last pipeline stage

	signal exec : std_logic;

begin

  -- Control
  genPipeN : if not PIPELINED generate
    constant EXEC_BITS : positive                     := log2ceil(STEPS)+1;
    constant EXEC_IDLE : signed(EXEC_BITS-1 downto 0) := '0' & (1 to EXEC_BITS-1 => '-');
    signal CntExec     : signed(EXEC_BITS-1 downto 0) := EXEC_IDLE;
  begin
    process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          CntExec <= EXEC_IDLE;
          ZR      <= '-';
        elsif start = '1' then
          if DETECT_DIV_BY_ZERO and D = (D'range => '0') then
            CntExec <= EXEC_IDLE;
            ZR      <= '1';
          else
            CntExec <= to_signed(-STEPS, CntExec'length);
            ZR      <= '0';
          end if;
        elsif CntExec(CntExec'left) = '1' then
          CntExec <= CntExec + 1;
        end if;
      end if;
    end process;
    exec  <= CntExec(CntExec'left);
    ready <= not exec;
  end generate genPipeN;

  genPipeY : if PIPELINED generate
    signal Vld : std_logic_vector(0 to STEPS) := (others => '0');
  begin
    process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          Vld <= (others => '0');
          ZR  <= '-';
        else
          Vld <= start & Vld(0 to STEPS-1);
					if Is_X(std_logic_vector(DR(STEPS-1))) then
						ZR <= 'X';
					elsif DR(STEPS-1) = 0 then
						ZR <= '1';
					else
						ZR <= '0';
					end if;
        end if;
      end if;
    end process;
    ready <= Vld(STEPS);
  end generate genPipeY;

  -- Registers
  process(clk)
  begin
    if rising_edge(clk) then
      -- Reset
      if rst = '1' then
        AR <= (others => (others => '-'));
        DR <= (others => (others => '-'));

			-- Operation Initialization
			else

				if PIPELINED then
					for i in 0 to STEPS-1 loop
						AR(i+1) <= div_step(AR(i), DR(i));
						DR(i+1) <= DR(i);
					end loop;
				elsif exec = '1' then
					AR(0) <= div_step(AR(0), DR(0));
				end if;

				if PIPELINED or start = '1' then
          AR(0) <= residue'((residue'left downto A_BITS => '0') & unsigned(A));
          DR(0) <= divisor'(unsigned(D));
				end if;

      end if;
    end if;
  end process;

  Q   <= std_logic_vector(AR(DEPTH)(A_BITS-1 downto 0));
  R   <= std_logic_vector(AR(DEPTH)(STEPS*RAPOW+D_BITS-1 downto STEPS*RAPOW));
  Z   <= ZR;
end rtl;
