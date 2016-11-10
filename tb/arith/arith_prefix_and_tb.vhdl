-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Thomas B. Preusser
--									Patrick Lehmann
--
-- Testbench:				Testbench for arith_prefix_and.
--
-- Description:
-- ------------------------------------
--		Automated testbench for PoC.arith.prefix_and
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
library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library PoC;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity arith_prefix_and_tb is
end entity;


architecture tb of arith_prefix_and_tb is
	constant CLOCK_FREQ	: FREQ						:= 100 MHz;

  constant BITS				: positive				:= 8;
	constant simTestID	: T_SIM_TEST_ID		:= simCreateTest("Test setup for BITS=" & integer'image(BITS));

	signal Clock				: std_logic;

  signal x	: std_logic_vector(BITS - 1 downto 0);
  signal y	: std_logic_vector(BITS - 1 downto 0);

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock and reset
	simGenerateClock(simTestID, Clock, CLOCK_FREQ);

  -- component instantiation
  UUT : entity PoC.arith_prefix_and
    generic map (
      N => BITS
    )
    port map (
      x => x,
      y => y
    );

	procChecker : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Checker for " & integer'image(BITS) & " bits");
	begin
		x		<= (others => '0');
		wait until rising_edge(Clock);

		-- Exhaustive Testing
    for i in natural range 0 to 2**BITS - 1 loop
      x <= std_logic_vector(to_unsigned(i, BITS));
      wait until rising_edge(Clock);
      for j in 0 to BITS - 1 loop
				simAssertion((y(j) = '1') = (x(j downto 0) = (j downto 0 => '1')), "Wrong result for " & integer'image(i) & " / " & integer'image(j));
			end loop;
    end loop;

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
  end process;

end architecture;
