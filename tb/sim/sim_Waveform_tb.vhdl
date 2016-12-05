-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				for waveform generation and arithmetic
--
-- Description:
-- ------------------------------------
--	TODO
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
use			PoC.components.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity sim_Waveform_tb is
end entity;


architecture tb of sim_Waveform_tb is
	constant CLOCK_FREQ					: FREQ						:= 100 MHz;

	constant simTestID					: T_SIM_TEST_ID		:= simCreateTest("Test waveform generation");

	signal Clock								: std_logic;

	signal Reset_1							: std_logic;
	signal Reset_2							: std_logic;
	signal Reset_3							: std_logic;

	signal Impulse_01						: std_logic;
	signal Impulse_02						: std_logic;
	signal Impulse_03						: std_logic;

	signal Wave_01							: std_logic;
	signal Wave_02							: std_logic;
	signal Wave_03							: std_logic;
	signal Wave_04							: std_logic;
	signal Wave_05							: std_logic;
	signal Wave_06							: std_logic;

	signal Wave_11							: std_logic;

	signal Bus_01								: T_SLV_8;
	signal Bus_02								: T_SLV_8;




	constant IMPULSE_1		: T_TIMEVEC		:= simGenerateWaveform_Reset(Pause => 10 ns);
	constant WAVE_1				: T_TIMEVEC		:= (20 ns, 5 ns, 5 ns, 5 ns, 5 ns, 10 ns, 5 ns, 5 ns, 10 ns, 20 ns);
	constant BUS_1				: T_SIM_WAVEFORM_SLV_8	:= (
		(Delay => 20 ns, Value => x"00"),
		(Delay => 10 ns, Value => x"01"),
		(Delay => 10 ns, Value => x"02"),
		(Delay => 10 ns, Value => x"03")
	);

	constant BUS_2				: T_SLVV_8		:= (x"10", x"11", x"12", x"13", x"14", x"15", x"16", x"17");

begin
	-- initialize global simulation status
	simInitialize;

	-- simple clock
	simGenerateClock(simTestID, Clock, CLOCK_FREQ);

	-- simple reset waveforms
	simGenerateWaveform(simTestID, Reset_1, simGenerateWaveform_Reset(Pause => 10 ns));
	simGenerateWaveform(simTestID, Reset_2, simGenerateWaveform_Reset(ResetPulse => 10 ns));
	simGenerateWaveform(simTestID, Reset_3, simGenerateWaveform_Reset(Pause => 20 ns, ResetPulse => 30 ns));

	simGenerateWaveform(simTestID, Impulse_01, IMPULSE_1);
	simGenerateWaveform(simTestID, Impulse_02, IMPULSE_1 * 5);
	simGenerateWaveform(simTestID, Impulse_03, IMPULSE_1 * 20);

	simGenerateWaveform(simTestID, Wave_01, IMPULSE_1 & WAVE_1 * 3);
	simGenerateWaveform(simTestID, Wave_02, (IMPULSE_1 & WAVE_1 * 3) < 5 ns);
	simGenerateWaveform(simTestID, Wave_03, (IMPULSE_1 & WAVE_1 * 3) < 10 ns);
	simGenerateWaveform(simTestID, Wave_04, (IMPULSE_1 & WAVE_1 * 3) < 15 ns);
	simGenerateWaveform(simTestID, Wave_05, (IMPULSE_1 & WAVE_1 * 3) < 20 ns);
	simGenerateWaveform(simTestID, Wave_06, (IMPULSE_1 & WAVE_1 * 3) < 30 ns);

	simGenerateWaveform(simTestID, Wave_11, (IMPULSE_1 & WAVE_1 * 3) > 100 ns);

	simGenerateWaveform(simTestID, Bus_01, BUS_1 * 2);
	simGenerateWaveform(simTestID, Bus_02, to_waveform(BUS_2, 10 ns) > 40 ns);


	procChecker_2 : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Checker_2");
	begin
		simWaitUntilRisingEdge(Clock, 100);

		-- This process is finished
		simDeactivateProcess(simProcessID);
		simFinalize;
		wait;  -- forever
	end process;
end architecture;
