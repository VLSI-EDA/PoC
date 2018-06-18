-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Testbench:				Testbench for arith_firstone
--
-- Description:
-- ------------------------------------
--		Automated testbench for PoC.arith.arith_firstone
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

library	PoC;
use			PoC.utils.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity arith_firstone_tb is
end arith_firstone_tb;


architecture tb of arith_firstone_tb is
	constant CLOCK_FREQ							: FREQ					:= 100 MHz;

  -- component generics
  constant N : positive := 8;
	constant simTestID	: T_SIM_TEST_ID			:= simCreateTest("Test setup for N=" & integer'image(N));

	signal Clock	: std_logic  := '1';

  -- component ports
  signal tin  : std_logic;
  signal rqst : std_logic_vector(N-1 downto 0);
  signal grnt : std_logic_vector(N-1 downto 0);
  signal tout : std_logic;
  signal bin  : std_logic_vector(log2ceil(N)-1 downto 0);

begin
	-- initialize global simulation status
	simInitialize(MaxSimulationRuntime => 1 ms);
	-- generate global testbench clock and reset
	simGenerateClock(simTestID, Clock, CLOCK_FREQ);
	-- Clock <= not Clock after 10 ns;

  -- component instantiation
  DUT : entity PoC.arith_firstone
    generic map (
      N => N
    )
    port map (
      tin  => tin,
      rqst => rqst,
      grnt => grnt,
      tout => tout,
      bin  => bin
    );

  procStimuli : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Checker for " & integer'image(N) & " bits");
  begin
		-- Exhaustive Testing
    for i in natural range 0 to 2**N-1 loop
      rqst <= std_logic_vector(to_unsigned(i, N));

			tin <= '0';
			wait until rising_edge(Clock);
			simAssertion(grnt = (grnt'range => '0') and tout = '0',
							 "Unexpected token output in testcase #"&integer'image(i));

			tin <= '1';
			wait until falling_edge(Clock);
      for j in 0 to N-1 loop
				simAssertion((grnt(j) = '1') = ((rqst(j) = '1') and (rqst(j-1 downto 0) = (j-1 downto 0 => '0'))),
								 "Wrong grant in testcase #"&integer'image(i));
			end loop;
    end loop;

		-- This process is finished
		simDeactivateProcess(simProcessID);
		-- Report overall result
		simFinalize;
		std.env.stop;
		wait;  -- forever
  end process;

end architecture;
