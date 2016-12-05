-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				Debouncer.
--
-- Description:
-- ------------------------------------
--		Automated testbench for 'PoC.io_Debounce'.
--		TODO
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

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.strings.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity io_Debounce_tb is
end entity;


architecture tb of io_Debounce_tb is
	constant CLOCK_FREQ			: FREQ					:= 100 MHz;

	-- simulation signals
	signal SimStop					: std_logic 		:= '0';
	signal Clock						: std_logic			:= '1';

	signal EventCounter			: natural				:= 0;

	-- unit Under Test (UUT) configuration
	constant BOUNCE_TIME		:	time					:= 50 ns;

	signal RawInput					: std_logic			:= '0';
	signal deb_out					: std_logic;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(Clock, CLOCK_FREQ);


	procGenerator : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Generator");
	begin
		wait for 5 ns;

		RawInput	<= '0';
		wait for 200 ns;

		RawInput	<= '1';
		wait for 200 ns;

		RawInput	<= '0';
		wait for 20 ns;

		RawInput	<= '1';
		wait for 20 ns;

		RawInput	<= '0';
		wait for 200 ns;

		RawInput	<= '1';
		wait for 20 ns;

		RawInput	<= '0';
		wait for 200 ns;

		RawInput	<= '1';
		wait for 100 ns;

		RawInput	<= '0';
		wait for 235 ns;

		-- shut down simulation
		RawInput	<= '0';

		-- final assertion
		simAssertion((EventCounter = 6), "Events counted=" & integer'image(EventCounter) &	" Expected=6");

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;

	process(deb_out)
	begin
		if ((deb_out'event) and (now /= 0 fs)) then
			report "deb_out=" & to_char(deb_out) & " deb_out'last_value=" & to_char(deb_out'last_value) severity note;
			EventCounter <= EventCounter + 1;
		end if;
	end process;

	UUT : entity PoC.io_Debounce
		generic map (
			CLOCK_FREQ							=> CLOCK_FREQ,
			BOUNCE_TIME							=> BOUNCE_TIME,
			BITS										=> 1,
			ADD_INPUT_SYNCHRONIZERS	=> TRUE,
			COMMON_LOCK							=> FALSE
		)
		port map (
			Clock			=> Clock,
			Reset			=> '0',
			Input(0)	=> RawInput,
			Output(0)	=> deb_out
		);
end architecture;
