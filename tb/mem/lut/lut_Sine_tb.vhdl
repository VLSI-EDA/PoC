-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				testbench for sine wave LUT
--
-- Description:
-- ------------------------------------
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
use			PoC.strings.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity lut_Sine_tb is
end entity;


architecture test of lut_Sine_tb is
	constant CLOCK_FREQ							: FREQ					:= 100 MHz;

	signal Clock							: std_logic						:= '1';
	signal sim_Stop						: std_logic						:= '0';

	signal lut_in							: std_logic_vector(7 downto 0)	:= (others => '0');
	signal lut_Q1_in					: std_logic_vector(7 downto 0);
	signal lut_Q1_out					: std_logic_vector(7 downto 0);
	signal lut_Q2_in					: std_logic_vector(7 downto 0);
	signal lut_Q2_out					: std_logic_vector(7 downto 0);
	signal lut_Q3_in					: std_logic_vector(7 downto 0);
	signal lut_Q3_out					: std_logic_vector(7 downto 0);
	signal lut_Q4_in					: std_logic_vector(7 downto 0);
	signal lut_Q4_out					: std_logic_vector(7 downto 0);

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(Clock, CLOCK_FREQ);


	procGenerator : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Generator");
	begin
		simWaitUntilRisingEdge(Clock, 4);

		for i in 0 to 1023 loop
			lut_in	<= to_slv(i mod 2**lut_in'length, lut_in'length);
			wait until rising_edge(Clock);
		end loop;

		simWaitUntilRisingEdge(Clock, 4);

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;

	lut_Q1_in	<= lut_in;
	lut_Q2_in	<= lut_in;
	lut_Q3_in	<= lut_in;
	lut_Q4_in	<= lut_in;

	lutQ1 : entity PoC.lut_Sine
		generic map (
			REG_OUTPUT			=> TRUE,
			MAX_AMPLITUDE		=> 127,
			POINTS					=> 256,
			OFFSET_DEG			=> 0.0,
			QUARTERS				=> 1
		)
		port map (
			Clock			=> Clock,			--
			Input			=> lut_Q1_in,		--
			Output		=> lut_Q1_out		--
		);

	lutQ2 : entity PoC.lut_Sine
		generic map (
			REG_OUTPUT			=> TRUE,
			MAX_AMPLITUDE		=> 127,
			POINTS					=> 256,
			OFFSET_DEG			=> 0.0,
			QUARTERS				=> 2
		)
		port map (
			Clock			=> Clock,			--
			Input			=> lut_Q2_in,		--
			Output		=> lut_Q2_out		--
		);

	lutQ3 : entity PoC.lut_Sine
		generic map (
			REG_OUTPUT			=> TRUE,
			MAX_AMPLITUDE		=> 127,
			POINTS					=> 256,
			OFFSET_DEG			=> 0.0,
			QUARTERS				=> 4
		)
		port map (
			Clock			=> Clock,			--
			Input			=> lut_Q3_in,		--
			Output		=> lut_Q3_out		--
		);

	lutQ4 : entity PoC.lut_Sine
		generic map (
			REG_OUTPUT			=> TRUE,
			MAX_AMPLITUDE		=> 127,
			POINTS					=> 256,
			OFFSET_DEG			=> 45.0,
			QUARTERS				=> 4
		)
		port map (
			Clock			=> Clock,			--
			Input			=> lut_Q4_in,		--
			Output		=> lut_Q4_out		--
		);
end architecture;
