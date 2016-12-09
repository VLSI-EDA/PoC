-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:					Martin Zabel
--
-- Module:					Model of pipelined memory with PoC.Mem interface.
--
-- Description:
-- ------------------------------------
-- Model of pipelined memory with
-- :doc:`PoC.Mem </Interfaces/Memory>` interface.
--
-- To be used for simulation as a replacement for a real memory controller.
--
-- The interface is documented in detail :doc:`here </Interfaces/Memory>`.
--
-- Additional parameter: LATENCY = the latency of the pipelined read.
--
-- .. NOTE::
--    Synchronous reset is required after simulation startup.
--
-- License:
-- ============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany,
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
-- ============================================================================


-------------------------------------------------------------------------------
-- Naming Conventions:
-- (Based on: Keating and Bricaud: "Reuse Methodology Manual")
--
-- active low signals: "*_n"
-- clock signals: "clk", "clk_div#", "clk_#x"
-- reset signals: "rst", "rst_n"
-- generics: all UPPERCASE
-- user defined types: "*_TYPE"
-- state machine next state: "*_ns"
-- state machine current state: "*_cs"
-- output of a register: "*_r"
-- asynchronous signal: "*_a"
-- pipelined or register delay signals: "*_p#"
-- data before being registered into register with the same name: "*_nxt"
-- clock enable signals: "*_ce"
-- internal version of output port: "*_i"
-- tristate internal signal "*_z"
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mem_model is

  generic (
    A_BITS  : positive;
    D_BITS  : positive;
		LATENCY : positive := 1
  );

  port (
    clk : in std_logic;
    rst : in std_logic;

    mem_req   : in  std_logic;
    mem_write : in  std_logic;
    mem_addr  : in  unsigned(A_BITS-1 downto 0);
    mem_wdata : in  std_logic_vector(D_BITS-1 downto 0);
    mem_wmask : in  std_logic_vector(D_BITS/8-1 downto 0) := (others => '0');
    mem_rdy   : out std_logic;
    mem_rstb  : out std_logic;
    mem_rdata : out std_logic_vector(D_BITS-1 downto 0));

end entity mem_model;

architecture sim of mem_model is
	-- data types
	type RAM_T is array(natural range<>) of std_logic_vector(D_BITS-1 downto 0);
	signal ram : RAM_T(0 to 2**A_BITS-1);

	-- read pipeline
	type RDATA_T is array(natural range<>) of std_logic_vector(D_BITS-1 downto 0);
	signal rdata_p : RDATA_T(1 to LATENCY);
	signal rstb_p : std_logic_vector(1 to LATENCY) := (others => '0');

	-- FSM
	type T_FSM is (RESET, READY, UNKNOWN);
	signal fsm_cs : T_FSM := UNKNOWN; -- current state

	signal req_write : X01;
	signal req_read  : X01;

begin  -- architecture sim

	-- Command decoding, handle 'U' as 'X'
	req_write <= to_x01(mem_req and mem_write);
	req_read  <= to_x01(mem_req and not mem_write);

	-- TODO: implement some logic / FSM which introduces wait states
	process(clk)
		variable fsm_ns : T_FSM; -- next state
	begin
		if rising_edge(clk) then
			fsm_ns := fsm_cs;

			case fsm_cs is
				when READY =>
					-- check for valid command
					if is_x(req_read) or is_x(req_write) then
						report "Invalid read/write command." severity error;
						fsm_ns := UNKNOWN;
					end if;

				when RESET   => fsm_ns := READY;
				when UNKNOWN => null;
			end case;

			-- Reset override
			case to_x01(rst) is
				when '1' => fsm_cs <= RESET;
				when '0' => fsm_cs <= fsm_ns;
				when 'X' => fsm_cs <= UNKNOWN;
			end case;
		end if;
	end process;

	-- Memory and Read Pipeline
	process(clk)
	begin
		if rising_edge(clk) then
			rstb_p(1)  <= '0'; -- default

			-- access memory only when ready, ignore requests otherwise
			if fsm_cs = READY then
				if (req_write) = '1' then
					if Is_X(std_logic_vector(mem_addr)) then
						report "Invalid address during write." severity error;
						ram <= (others => (others => 'X'));
					else
						for i in 0 to D_BITS/8-1 loop
							if Is_X(mem_wmask(i)) then
								ram(to_integer(mem_addr))(i*8+7 downto i*8) <= (others => 'X');
							elsif mem_wmask(i) = '0' then
								ram(to_integer(mem_addr))(i*8+7 downto i*8) <= to_ux01(mem_wdata(i*8+7 downto i*8));
							end if;
						end loop;  -- i
					end if;
				elsif (req_write = 'X') then
					-- error is reported above
					ram        <= (others => (others => 'X'));
				end if;

				if req_read = '1' then
					rstb_p(1)  <= '1';
					if Is_X(std_logic_vector(mem_addr)) then
						report "Invalid address during read." severity error;
						rdata_p(1) <= (others => 'X');
					else
						rdata_p(1) <= ram(to_integer(mem_addr));
					end if;
				elsif req_read = 'X' then
					-- error is reported above
					rstb_p(1)  <= 'X';
					rdata_p(1) <= (others => 'X');
				end if;
			end if;

			-- read pipeline
			if LATENCY > 1 then
				rstb_p (2 to LATENCY) <= rstb_p (1 to LATENCY-1);
				rdata_p(2 to LATENCY) <= rdata_p(1 to LATENCY-1);
			end if;

			-- reset only read strobe
			case to_x01(rst) is
				when '1' =>	rstb_p <= (others => '0');
				when '0' => null;
				when 'X' => rstb_p <= (others => 'X');
			end case;
		end if;
	end process;

	-- Outputs
	with fsm_cs select mem_rdy <=
		'1' when READY,
		'X' when UNKNOWN,
		'0' when others;

	mem_rdata <= rdata_p(LATENCY);
	mem_rstb	<= rstb_p (LATENCY);

end architecture sim;
