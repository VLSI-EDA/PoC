-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Authors:					Patrick Lehmann
-- 
-- Testbench:				for clock generation in testbenches.
-- 
-- Description:
-- ------------------------------------
--	TODO
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library OSVVM;
use			OSVVM.CoveragePkg.all;
use			OSVVM.TranscriptPkg.all;

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


entity sim_ClockGenerator_tb is
end entity;


architecture tb of sim_ClockGenerator_tb is
	constant CLOCK_FREQ					: FREQ						:= 100 MHz;
	constant NO_CLOCK_PHASE			: T_PHASE					:= 0 deg;

	constant simTestID					: T_SIM_TEST_ID		:= simCreateTest("Test clock generation");
	
	signal Clock								: STD_LOGIC;
	signal ClockIsActive				: STD_LOGIC		:= '1';
	
	signal Clock_01							: STD_LOGIC;
	signal Clock_02							: STD_LOGIC;
	signal Clock_03							: STD_LOGIC;
	signal Clock_04							: STD_LOGIC;
	signal Clock_05							: STD_LOGIC;
	signal Clock_06							: STD_LOGIC;
	
	signal Clock_10							: STD_LOGIC;
	signal Clock_11							: STD_LOGIC;
	signal Clock_12							: STD_LOGIC;
	signal Clock_13							: STD_LOGIC;
	signal Clock_14							: STD_LOGIC;
	signal Clock_15							: STD_LOGIC;
	signal Clock_16							: STD_LOGIC;
	signal Clock_17							: STD_LOGIC;
	signal Clock_18							: STD_LOGIC;
	signal Clock_19							: STD_LOGIC;
	
	signal Clock_21							: STD_LOGIC;
	signal Clock_22							: STD_LOGIC;
	signal Clock_23							: STD_LOGIC;
	signal Clock_24							: STD_LOGIC;
	signal Clock_25							: STD_LOGIC;
	
	signal Clock_31							: STD_LOGIC;
	signal Clock_32							: STD_LOGIC;
	signal Clock_33							: STD_LOGIC;
	signal Clock_34							: STD_LOGIC;
	signal Clock_35							: STD_LOGIC;
	
	signal Clock_40							: STD_LOGIC;
	signal Clock_41							: STD_LOGIC;
	signal Clock_42							: STD_LOGIC;
	signal Clock_43							: STD_LOGIC;
	signal Counter_Clock_40_us	: UNSIGNED(15 downto 0)		:= (others => '0');
	signal Counter_Clock_41_us	: UNSIGNED(15 downto 0)		:= (others => '0');
	signal Counter_Clock_42_us	: UNSIGNED(15 downto 0)		:= (others => '0');
	signal Counter_Clock_43_us	: UNSIGNED(15 downto 0)		:= (others => '0');
	signal Counter_41_cmp				: UNSIGNED(1 downto 0);
	signal Counter_42_cmp				: UNSIGNED(1 downto 0);
	signal Counter_43_cmp				: UNSIGNED(1 downto 0);
	signal Drift_Clock_41				: SIGNED(15 downto 0);
	signal Drift_Clock_42				: SIGNED(15 downto 0);
	signal Drift_Clock_43				: SIGNED(15 downto 0);
	
	signal Clock_50							: STD_LOGIC;
	signal Clock_51							: STD_LOGIC;
	signal Counter_Clock_50_us	: UNSIGNED(15 downto 0)		:= (others => '0');
	signal Counter_Clock_51_us	: UNSIGNED(15 downto 0)		:= (others => '0');
	signal Mean_Clock_51				: SIGNED(15 downto 0);
	signal Drift_Clock_51				: SIGNED(15 downto 0);
	signal Drift_Clock_52				: SIGNED(15 downto 0);
	signal Debug_Jitter					: REAL;
	signal Debug2								: SIGNED(15 downto 0);

	
	signal Reset_1							: STD_LOGIC;
	signal Reset_2							: STD_LOGIC;
	
begin
	-- initialize OSVVM transcript file
	TranscriptOpen("sim_ClockGenerator_tb.csv");
	-- SetTranscriptMirror;
	
	-- initialize global simulation status
	simInitialize;
	
	-- simple clock
	simGenerateClock(Clock, CLOCK_FREQ / 2);
	ClockIsActive		<= not to_sl(simIsStopped) when rising_edge(Clock);
	
	-- generate global testbench clock
	simGenerateClock(Clock_01, CLOCK_FREQ, Phase =>   0 deg);
	simGenerateClock(Clock_02, CLOCK_FREQ, Phase =>  90 deg);
	simGenerateClock(Clock_03, CLOCK_FREQ, Phase => 180 deg);
	simGenerateClock(Clock_04, CLOCK_FREQ, Phase => 270 deg);
	simGenerateClock(Clock_05, CLOCK_FREQ, Phase => 360 deg);
	simGenerateClock(Clock_06, CLOCK_FREQ, Phase => -90 deg);
	
	simGenerateClock(Clock_10, CLOCK_FREQ, DutyCycle =>	 0 percent);
	simGenerateClock(Clock_11, CLOCK_FREQ, DutyCycle => 10 percent);
	simGenerateClock(Clock_12, CLOCK_FREQ, DutyCycle => 20 percent);
	simGenerateClock(Clock_13, CLOCK_FREQ, DutyCycle => 30 percent);
	simGenerateClock(Clock_14, CLOCK_FREQ, DutyCycle => 40 percent);
	simGenerateClock(Clock_15, CLOCK_FREQ, DutyCycle => 50 percent);
	simGenerateClock(Clock_16, CLOCK_FREQ, DutyCycle => 60 percent);
	simGenerateClock(Clock_17, CLOCK_FREQ, DutyCycle => 70 percent);
	simGenerateClock(Clock_18, CLOCK_FREQ, DutyCycle => 80 percent);
	simGenerateClock(Clock_19, CLOCK_FREQ, DutyCycle => 90 percent);
	
	simGenerateClock(Clock_21, CLOCK_FREQ, Phase =>   0 deg, DutyCycle => 25 percent);
	simGenerateClock(Clock_22, CLOCK_FREQ, Phase =>  90 deg, DutyCycle => 25 percent);
	simGenerateClock(Clock_23, CLOCK_FREQ, Phase => 180 deg, DutyCycle => 25 percent);
	simGenerateClock(Clock_24, CLOCK_FREQ, Phase => 270 deg, DutyCycle => 25 percent);
	simGenerateClock(Clock_25, CLOCK_FREQ, Phase => 360 deg, DutyCycle => 25 percent);
	
	simGenerateClock(Clock_31, CLOCK_FREQ, Phase =>   0 deg, DutyCycle => 75 percent);
	simGenerateClock(Clock_32, CLOCK_FREQ, Phase =>  90 deg, DutyCycle => 75 percent);
	simGenerateClock(Clock_33, CLOCK_FREQ, Phase => 180 deg, DutyCycle => 75 percent);
	simGenerateClock(Clock_34, CLOCK_FREQ, Phase => 270 deg, DutyCycle => 75 percent);
	simGenerateClock(Clock_35, CLOCK_FREQ, Phase => 360 deg, DutyCycle => 75 percent);

	simGenerateClock(Clock_40, CLOCK_FREQ, Wander =>	 0 permil);
	simGenerateClock(Clock_41, CLOCK_FREQ, Wander =>	 5 permil);		-- clock drift of  0.5% (  5 permil) => shift by 1 UI every 200 cycles
	simGenerateClock(Clock_42, CLOCK_FREQ, Wander =>  10 permil);		-- clock drift of  1.0% ( 10 permil) => shift by 1 UI every 100 cycles
	simGenerateClock(Clock_43, CLOCK_FREQ, Wander => -10 permil);		-- clock drift of -1.0% (-10 permil) => shift by 1 UI every 100 cycles

	Counter_Clock_40_us		<= upcounter_next(cnt => Counter_Clock_40_us) when rising_edge(Clock_40);
	Counter_Clock_41_us		<= upcounter_next(cnt => Counter_Clock_41_us) when rising_edge(Clock_41);
	Counter_Clock_42_us		<= upcounter_next(cnt => Counter_Clock_42_us) when rising_edge(Clock_42);
	Counter_Clock_43_us		<= upcounter_next(cnt => Counter_Clock_43_us) when rising_edge(Clock_43);
	Counter_41_cmp				<= comp(Counter_Clock_40_us, Counter_Clock_41_us);
	Counter_42_cmp				<= comp(Counter_Clock_40_us, Counter_Clock_42_us);
	Counter_43_cmp				<= comp(Counter_Clock_40_us, Counter_Clock_43_us);

	procDrift_41 : process
		-- constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Drift_43");
	begin
		Drift_Clock_41		<= (others => '0');
		wait until rising_edge(Clock_40);
		wait until rising_edge(Clock_41);
		while (not simIsStopped) loop
			wait until rising_edge(Clock_41);
			Drift_Clock_41		<= to_signed((Clock_40'last_event - Clock_41'last_event) / 10 ps, Drift_Clock_41'length);
		end loop;
		
		-- This process is finished
		-- simDeactivateProcess(simProcessID);
		-- simFinalize;
		wait;  -- forever
	end process;
	
	procDrift_42 : process
		-- constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Drift_43");
	begin
		Drift_Clock_42		<= (others => '0');
		wait until rising_edge(Clock_40);
		wait until rising_edge(Clock_42);
		while (not simIsStopped) loop
			wait until rising_edge(Clock_42);
			Drift_Clock_42		<= to_signed((Clock_40'last_event - Clock_42'last_event) / 10 ps, Drift_Clock_42'length);
		end loop;
		
		-- This process is finished
		-- simDeactivateProcess(simProcessID);
		-- simFinalize;
		wait;  -- forever
	end process;
	
	procDrift_43 : process
		-- constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Drift_43");
	begin
		Drift_Clock_43		<= (others => '0');
		wait until rising_edge(Clock_40);
		wait until rising_edge(Clock_43);
		while (not simIsStopped) loop
			wait until rising_edge(Clock_43);
			Drift_Clock_43		<= to_signed((Clock_40'last_event - Clock_43'last_event) / 10 ps, Drift_Clock_43'length);
		end loop;
		
		-- This process is finished
		-- simDeactivateProcess(simProcessID);
		-- simFinalize;
		wait;  -- forever
	end process;

	
	simGenerateClock(Clock_50, CLOCK_FREQ);
	simGenerateClock2(-1, Clock_51, Debug_Jitter, to_time(CLOCK_FREQ));

	Counter_Clock_50_us		<= upcounter_next(cnt => Counter_Clock_50_us) when rising_edge(Clock_50);
	Counter_Clock_51_us		<= upcounter_next(cnt => Counter_Clock_51_us) when rising_edge(Clock_51);
	
	procHistogram : process
		-- constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Histogram");
		
		variable Sum					: INTEGER;
		variable Count				: NATURAL;
		variable Rand					: INTEGER;
		variable RandPointer	: NATURAL;
		variable RandBuffer		: T_INTVEC(0 to 15);

		constant BIN_SIZE			: POSITIVE		:= 1000;
		constant BIN_SIZE_2		: REAL				:= real(BIN_SIZE) / 2.0;
		variable CovBin1			: CovPType;
	begin
		CovBin1.AddBins(GenBin(0, BIN_SIZE));

		Sum							:= 0;
		Count						:= 0;
		Debug2					<= (others => '0');
		Mean_Clock_51		<= (others => '0');
		RandPointer			:= 0;
		RandBuffer			:= (others => (BIN_SIZE / 2));

		wait until rising_edge(Clock_51);
		while (not simIsStopped) loop
			wait until rising_edge(Clock_51);
			-- subtract old random value from mean aggregator
			Sum												:= Sum - RandBuffer(RandPointer);
			-- convert new random value to integer
			Rand											:= integer(Debug_Jitter * BIN_SIZE_2 + BIN_SIZE_2);	-- scale and move into positive range
			-- store random value in buffer
			RandBuffer(RandPointer)		:= Rand;
			RandPointer								:= (RandPointer + 1) mod RandBuffer'length;
			-- log random value
			CovBin1.ICover(Rand);
			Debug2										<= to_signed(Rand, Debug2'length);
			
			Sum							:= Sum + Rand;
			Count						:= Count + 1;
			Mean_Clock_51		<= to_signed((Sum / imin(RandBuffer'length, Count + 1)), Mean_Clock_51'length);
			
		end loop;

		CovBin1.WriteBin;-- This process is finished
		-- simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;

	procDrift_51 : process
		-- constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Drift_51");
	begin
		Drift_Clock_51		<= (others => '0');
		Drift_Clock_52		<= (others => '0');
	
		wait until rising_edge(Clock_50);
		wait until rising_edge(Clock_51);
	
		while (not simIsStopped) loop
			wait until rising_edge(Clock_50);
			Drift_Clock_51		<= to_signed((Clock_50'last_event - Clock_51'last_event) / 100 fs, Drift_Clock_51'length);
			-- Drift_Clock_52		<= to_signed((Clock_51'last_event - Clock_50'last_event) / 100 fs, Drift_Clock_52'length);
		
		end loop;
	
		-- This process is finished
		-- simDeactivateProcess(simProcessID);
		-- simFinalize;
		wait;  -- forever
	end process;
	



	simGenerateWaveform(Reset_1, simGenerateWaveform_Reset(Pause => 10 ns, ResetPulse => 10 ns));

	-- procChecker_1 : process
		-- constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Checker_1");
	-- begin
	
		-- simWaitUntilRisingEdge(Clock_01, 99);
		-- simWaitUntilFallingEdge(Clock_01, 99);
	
		-- -- This process is finished
		-- simDeactivateProcess(simProcessID);
		-- simFinalize;
		-- wait;  -- forever
	-- end process;
	
	procChecker_2 : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Checker_2");
	begin
	
		simWaitUntilRisingEdge(Clock, 5000);
		simWaitUntilFallingEdge(Clock, 5000);
	
		-- This process is finished
		simDeactivateProcess(simProcessID);
		simFinalize;
		wait;  -- forever
	end process;
end architecture;
