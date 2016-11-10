-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:					Martin Zabel
--
-- Testbench:				for component ddrio_in
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

library PoC;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity ddrio_in_tb is
end entity;


architecture sim of ddrio_in_tb is
	constant CLOCK_FREQ	: FREQ					:= 100 MHz;

  -- component generics
  constant BITS				: positive := 2;
  constant INIT_VALUE	: bit_vector(1 downto 0) := "10";

  -- component ports
  signal Clock				: std_logic := '1';
  signal ClockEnable	: std_logic := '0';
  signal DataIn_high	: std_logic_vector(BITS - 1 downto 0);
  signal DataIn_low		: std_logic_vector(BITS - 1 downto 0);
  signal Pad					: std_logic_vector(BITS - 1 downto 0);

	-- delay from "Clock" input to outputs of DUT
	-- must be less than CLOCK_PERIOD
	constant OUTPUT_DELAY : time :=  6 ns;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(Clock, CLOCK_FREQ);

  -- component instantiation
  DUT: entity poc.ddrio_in
    generic map (
      BITS	      => BITS,
      INIT_VALUE 	=> INIT_VALUE)
    port map (
      Clock	  		=> Clock,
      ClockEnable => ClockEnable,
      DataIn_high => DataIn_high,
      DataIn_low  => DataIn_low,
      Pad	  			=> Pad);

  -- waveform generation
  WaveGen_Proc: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Generator");
    variable ii : std_logic_vector(3 downto 0);
  begin
    -- simulate waiting for clock enable
    wait until rising_edge(Clock);
    wait until rising_edge(Clock);

    -- clock ready
    ClockEnable 	<= '1';
		for i in 0 to 15 loop
      ii := std_logic_vector(to_unsigned(i, 4));
			-- input LSB first
			Pad <= ii(1 downto 0); -- bit 0 and 1 with falling edge
			wait until falling_edge(Clock);

			Pad <= ii(3 downto 2); -- bit 2 and 3 with rising  edge
			wait until rising_edge(Clock);
		end loop;

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
  end process WaveGen_Proc;

	-- checkout output while reading from PAD
	WaveCheck_Proc: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Checker");
    variable ii : std_logic_vector(3 downto 0);
	begin
		wait for OUTPUT_DELAY;
		simAssertion((DataIn_high = to_stdlogicvector(INIT_VALUE)), "Wrong initial DataIn_high");
		simAssertion((DataIn_low  = to_stdlogicvector(INIT_VALUE)), "Wrong initial DataIn_low");

		-- wait until clock is enabled from process above
		wait until rising_edge(Clock) and ClockEnable = '1';

		for i in 0 to 15 loop
			-- precondition: simulation is at a rising_edge(Clock)
      ii := std_logic_vector(to_unsigned(i, 4));
			wait for OUTPUT_DELAY;
			simAssertion((DataIn_high = ii(3 downto 2)), "Wrong DataIn_high");
			simAssertion((DataIn_low  = ii(1 downto 0)), "Wrong DataIn_low");
			wait until rising_edge(Clock);
		end loop;

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process WaveCheck_Proc;

end architecture;
