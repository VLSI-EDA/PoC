-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:					Martin Zabel
--
-- Testbench:				for component ddrio_inout
--
-- Description:
-- ------------------------------------
-- TODO
--
-- License:
-- ============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany,
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
-- ============================================================================

library	ieee;
use			ieee.std_logic_1164.all;
use			ieee.numeric_std.all;

library poc;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity ddrio_inout_tb is
end entity;


architecture sim of ddrio_inout_tb is
  -- component generics
  constant BITS : positive := 2;

	-- component ports
	signal ClockOut				: std_logic := '1';
	signal ClockOutEnable : std_logic := '0';
	signal OutputEnable		: std_logic;
	signal DataOut_high		: std_logic_vector(BITS - 1 downto 0);
	signal DataOut_low		: std_logic_vector(BITS - 1 downto 0);
	signal ClockIn				: std_logic := '1';
	signal ClockInEnable	: std_logic := '0';
	signal DataIn_high		: std_logic_vector(BITS - 1 downto 0);
	signal DataIn_low			: std_logic_vector(BITS - 1 downto 0);
	signal Pad						: std_logic_vector(BITS - 1 downto 0);

	-- period of signal "ClockIn"
	constant CLOCK_IN_PERIOD : time := 12 ns;

	-- delay from "ClockIn" input to outputs "DataIn_*" of DUT
	-- must be less than CLOCK_PERIOD
	constant OUTPUT_IN_DELAY : time :=  6 ns;

	-- period of signal "ClockOut"
	constant CLOCK_OUT_PERIOD : time := 10 ns;

	-- delay from "ClockOut" input to output "Pad" of DUT
	-- must be less than CLOCK_OUT_PERIOD/2
	constant OUTPUT_OUT_DELAY : time :=  4 ns;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(ClockIn,		CLOCK_IN_PERIOD);
	simGenerateClock(ClockOut,	CLOCK_OUT_PERIOD);

  -- component instantiation
  DUT: entity poc.ddrio_inout
    generic map (
      BITS 						=> BITS)
    port map (
      ClockOut 				=> ClockOut,
      ClockOutEnable 	=> ClockOutEnable,
      OutputEnable 		=> OutputEnable,
      DataOut_high 		=> DataOut_high,
      DataOut_low 		=> DataOut_low,
      ClockIn					=> ClockIn,
      ClockInEnable 	=> ClockInEnable,
      DataIn_high 		=> DataIn_high,
      DataIn_low 			=> DataIn_low,
      Pad							=> Pad);


	-- waveform generation
	WaveGen_Proc: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Generator");
		variable ii : std_logic_vector(3 downto 0);
	begin
		-- disabled outputs on FPGA and other side
		OutputEnable <= '0';
		Pad					 <= (others => 'Z');

    -- simulate waiting for clock enable
		wait for 42 ns;

    -- clock out ready, synchronous to ClockIn
    wait until rising_edge(ClockOut);
    ClockOutEnable 	<= '1';

    -- clock in ready, synchronous to ClockIn
    wait until rising_edge(ClockIn);
    ClockInEnable 	<= '1';

		-- input data into FPGA
		for i in 0 to 15 loop
			-- precondition: simulation is at a rising_edge(ClockIn)
      ii := std_logic_vector(to_unsigned(i, 4));

			-- input LSB first
			Pad <= ii(1 downto 0); -- bit 0 and 1 with falling edge
			wait until falling_edge(ClockIn);

			Pad <= ii(3 downto 2); -- bit 2 and 3 with rising  edge
			wait until rising_edge(ClockIn);
		end loop;

		-- switch direction
		Pad <= (others => 'Z');
		wait for 24 ns;

		-- output data from FPGA
    wait until rising_edge(ClockOut);
    OutputEnable <= '1';
    for i in 0 to 15 loop
			-- precondition: simulation is at a rising_edge(ClockOut)
      ii := std_logic_vector(to_unsigned(i, 4));
      -- output LSB first
      DataOut_high <= ii(1 downto 0); -- bit 0 and 1 with rising  edge
      DataOut_low  <= ii(3 downto 2); -- bit 2 and 3 with falling edge
      wait until rising_edge(ClockOut);
    end loop;

    -- disable output again
    OutputEnable <= '0';
    wait until rising_edge(ClockOut);

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
  end process WaveGen_Proc;

	-- checkout output while reading from PAD
	WaveCheck_Proc: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Checker");
    variable ii : std_logic_vector(3 downto 0);
	begin
		-- wait until ClockIn is enabled from process above
		wait until rising_edge(ClockIn) and ClockInEnable = '1';

		for i in 0 to 15 loop
			-- precondition: simulation is at a rising_edge(ClockIn)
      ii := std_logic_vector(to_unsigned(i, 4));
			wait for OUTPUT_IN_DELAY;
			simAssertion((DataIn_high = ii(3 downto 2)), "Wrong DataIn_high");
			simAssertion((DataIn_low  = ii(1 downto 0)), "Wrong DataIn_low");
			wait until rising_edge(ClockIn);
		end loop;

		-- wait until output is enabled from process above
		wait until rising_edge(ClockOut) and OutputEnable = '1';

		for i in 0 to 15 loop
			-- precondition: simulation is at a rising_edge(ClockIn)
      ii := std_logic_vector(to_unsigned(i, 4));
			wait for OUTPUT_OUT_DELAY;
			simAssertion((Pad = ii(1 downto 0)), "Wrong Pad during clock high");
      wait until falling_edge(ClockOut);
			wait for OUTPUT_OUT_DELAY;
			simAssertion((Pad = ii(3 downto 2)), "Wrong Pad during clock low");
			wait until rising_edge(ClockOut);
		end loop;

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process WaveCheck_Proc;

end architecture;
