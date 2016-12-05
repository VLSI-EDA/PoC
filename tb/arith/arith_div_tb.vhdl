-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:		Thomas B. Preusser
--
-- Testbench:	arith_div_tb
--
-- Description
-- -----------
--		Automated testbench for PoC.arith_div
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
--										 Chair of VLSI-Design, Diagnostics and Architecture
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

entity arith_div_tb is
end entity;


library IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library PoC;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.strings.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.sim_random.all;
use			PoC.simulation.all;
use			PoC.waveform.all;

architecture tb of arith_div_tb is
  constant CLOCK_FREQ : FREQ := 100 MHz;

  constant A_BITS  : positive := 13;
  constant D_BITS  : positive :=  4;
  constant MAX_POW : positive := 	3;

	-- Global Control
  signal clk : std_logic;
  signal rst : std_logic;

	-- Connectivity
	subtype tA is std_logic_vector(A_BITS-1 downto 0);
	type tA_vector is array(positive range<>) of tA;
	subtype tD is std_logic_vector(D_BITS-1 downto 0);
	type tD_vector is array(positive range<>) of tD;

  signal start : std_logic;
  signal ready : std_logic_vector(1 to 2*MAX_POW);
  signal A     : tA;
  signal D     : tD;
  signal Q     : tA_vector(1 to 2*MAX_POW);
  signal R     : tD_vector(1 to 2*MAX_POW);
  signal Z     : std_logic_vector(1 to 2*MAX_POW);

begin

	-- Initialization
	simInitialize;
	simGenerateClock(clk, CLOCK_FREQ);

  genDUTs : for i in 1 to MAX_POW generate
    DUT_SEQU : entity PoC.arith_div
      generic map (
        A_BITS             => A_BITS,
        D_BITS             => D_BITS,
        RAPOW              => i
      )
      port map (
        clk => clk,
        rst => rst,

        start => start,
        ready => ready(i),

        A => A,
        D => D,
        Q => Q(i),
        R => R(i),
        Z => Z(i)
      );

    DUT_PIPE : entity PoC.arith_div
      generic map (
        A_BITS             => A_BITS,
        D_BITS             => D_BITS,
        RAPOW              => i,
        PIPELINED          => true
      )
      port map (
        clk => clk,
        rst => rst,

        start => start,
        ready => ready(MAX_POW+i),

        A => A,
        D => D,
        Q => Q(MAX_POW+i),
        R => R(MAX_POW+i),
        Z => Z(MAX_POW+i)
      );
	end generate;

  -- Stimuli
  process
    constant PID : T_SIM_PROCESS_ID := simRegisterProcess("arith_div_tb.main");

    procedure cycle is
		begin
			wait until rising_edge(clk);
			wait for 1 ns;
		end;

    procedure test(aval, dval : in integer) is
			variable QQ : tA_vector(1 to 2*MAX_POW);
			variable RR : tD_vector(1 to 2*MAX_POW);
			variable ZZ : std_logic_vector(1 to 2*MAX_POW);

			type boolean_vector is array(positive range<>) of boolean;
			variable done : boolean_vector(1 to 2*MAX_POW);
		begin
			-- Start
			start <= '1';
			A     <= std_logic_vector(to_unsigned(aval, A'length));
			D     <= std_logic_vector(to_unsigned(dval, D'length));
			cycle;

      start <= '0';
      A     <= (others => '-');
      D     <= (others => '-');
      done  := (others => false);
      loop
				for i in done'range loop
					if ready(i) = '1' and not done(i) then
						QQ(i)   := Q(i);
						RR(i)   := R(i);
						ZZ(i)   := Z(i);
						done(i) := true;
					end if;
				end loop;
        exit when done = (done'range => true);
        cycle;
      end loop;

			for i in done'range loop
				simAssertion(((dval = 0) and (ZZ(i) = '1')) or
										 ((dval /= 0) and (ZZ(i) = '0') and
										  (to_integer(unsigned(QQ(i)))*dval + to_integer(unsigned(RR(i))) = aval)),
										 "INST="&integer'image(i)&" failed: "&integer'image(aval)&"/"&integer'image(dval)&" /= "&
								     integer'image(to_integer(unsigned(QQ(i))))&" R "&integer'image(to_integer(unsigned(RR(i)))));
			end loop;
		end;

		variable random : T_RANDOM;
  begin
		-- Reset
		rst <= '1';
		cycle;
    rst   <= '0';

    -- Boundary Conditions
    test(0, 0);
    test(0, 2**D_BITS-1);
		test(0, 1);
		test(1, 0);
		test(2, 0);
    test(2**A_BITS-1, 0);
    test(2**A_BITS-1, 2**D_BITS-1);

    -- Run Random Tests
    for i in 0 to 1023 loop
      test(random.getUniformDistributedValue(0, 2**A_BITS-1), random.getUniformDistributedValue(0, 2**D_BITS-1));
    end loop;

    simDeactivateProcess(PID);
    wait;
  end process;

end tb;
