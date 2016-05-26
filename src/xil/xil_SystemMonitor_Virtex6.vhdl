-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Module:				 	System Monitor wrapper for temperature supervision applications
--
-- Description:
-- ------------------------------------
--		This module wraps a Virtex-6 System Monitor primitive to report if preconfigured
--		temperature values are overrun.
--
--		Temperature curve:
--		------------------
--
--										|											 /-----\
--		Temp_ov	 on=80	|	-	-	-	-	-	-	/-------/				\
--										|						 /				|				 \
--		Temp_ov	off=60	|	-	-	-	-	-	/	-	-	-	-	|	-	-	-	-	\----\
--										|					 /					|								\
--										|					/						|							 | \
--		Temp_us	 on=35	|	-	 /---/						|							 |	\
--		Temp_us	off=30	|	-	/	-	-|-	-	-	-	-	-	|	-	-	-	-	-	-	-|-  \------\
--										|  /		 |						|							 |					 \
--		----------------|--------|------------|--------------|----------|---------
--		pwm =						|		min	 |	medium		|		max				 |	medium	|	min
--
--
-- License:
-- ============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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

LIBRARY IEEE;
USE			IEEE.STD_LOGIC_1164.all;
USE			IEEE.NUMERIC_STD.all;

LIBRARY	UniSim;
USE			UniSim.vComponents.ALL;


entity xil_SystemMonitor_Virtex6 is
	port (
		Reset								: in	STD_LOGIC;				-- Reset signal for the System Monitor control logic

		Alarm_UserTemp			: out	STD_LOGIC;				-- Temperature-sensor alarm output
		Alarm_OverTemp			: out	STD_LOGIC;				-- Over-Temperature alarm output
		Alarm								: out	STD_LOGIC;				-- OR'ed output of all the Alarms
		VP									: in	STD_LOGIC;				-- Dedicated Analog Input Pair
		VN									: in	STD_LOGIC
	);
end;


architecture xilinx of xil_SystemMonitor_Virtex6 is
	signal FLOAT_VCCAUX_ALARM		: STD_LOGIC;
	signal FLOAT_VCCINT_ALARM		: STD_LOGIC;
	signal aux_channel_p				: STD_LOGIC_VECTOR(15 downto 0);
	signal aux_channel_n				: STD_LOGIC_VECTOR(15 downto 0);

	signal SysMonitor_Alarm			: STD_LOGIC_VECTOR(2 downto 0);
	signal SysMonitor_OverTemp	: STD_LOGIC;
begin
	genAUXChannel : for i in 0 to 15 generate
		aux_channel_p(i) <= '0';
		aux_channel_n(i) <= '0';
	end generate;

	SysMonitor : SYSMON
		generic map (
			INIT_40						=> x"0000",										-- config reg 0
			INIT_41						=> x"300c",										-- config reg 1
			INIT_42						=> x"0a00",										-- config reg 2
			INIT_48						=> x"0100",										-- Sequencer channel selection
			INIT_49						=> x"0000",										-- Sequencer channel selection
			INIT_4A						=> x"0000",										-- Sequencer Average selection
			INIT_4B						=> x"0000",										-- Sequencer Average selection
			INIT_4C						=> x"0000",										-- Sequencer Bipolar selection
			INIT_4D						=> x"0000",										-- Sequencer Bipolar selection
			INIT_4E						=> x"0000",										-- Sequencer Acq time selection
			INIT_4F						=> x"0000",										-- Sequencer Acq time selection
			INIT_50						=> x"a418",										-- Temp alarm trigger
			INIT_51						=> x"5999",										-- Vccint upper alarm limit
			INIT_52						=> x"e000",										-- Vccaux upper alarm limit
			INIT_53						=> x"b363",										-- Temp alarm OT upper
			INIT_54						=> x"9c87",										-- Temp alarm reset
			INIT_55						=> x"5111",										-- Vccint lower alarm limit
			INIT_56						=> x"caaa",										-- Vccaux lower alarm limit
			INIT_57						=> x"a425",										-- Temp alarm OT reset
			SIM_DEVICE				=> "VIRTEX6",
			SIM_MONITOR_FILE	=> "SystemMonitor_sim.txt"
		)
		port map (
			-- Control and Clock
			RESET								=> Reset,
			CONVSTCLK						=> '0',
			CONVST							=> '0',
			-- DRP port
			DCLK								=> '0',
			DEN									=> '0',
			DADDR								=> "0000000",
			DWE									=> '0',
			DI									=> x"0000",
			DO									=> open,
			DRDY								=> open,
			-- External analog inputs
			VAUXN								=> aux_channel_n(15 downto 0),
			VAUXP								=> aux_channel_p(15 downto 0),
			VN									=> VN,
			VP									=> VP,
			-- Alarms
			OT									=> SysMonitor_OverTemp,
			ALM									=> SysMonitor_Alarm,
			-- Status
			CHANNEL							=> open,
			BUSY								=> open,
			EOC									=> open,
			EOS									=> open,

			JTAGBUSY						=> open,
			JTAGLOCKED					=> open,
			JTAGMODIFIED				=> open
		);

	Alarm_UserTemp	<= SysMonitor_Alarm(0);
	Alarm_OverTemp	<= SysMonitor_OverTemp;
	Alarm						<= SysMonitor_Alarm(0) or SysMonitor_OverTemp;
end;
