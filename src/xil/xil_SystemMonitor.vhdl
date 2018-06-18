-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	SysMon wrapper for temperature supervision applications
--
-- Description:
-- -------------------------------------
-- This module wraps a SYSMON or XADC to report if preconfigured temperature values
-- are overrun. The XADC was formerly known as "System Monitor".
--
-- .. rubric:: Temperature Curve
--
-- .. code-block:: none
--
--                    |                      /-----\
--    Temp_ov   on=80 | - - - - - - /-------/       \
--                    |            /        |        \
--    Temp_ov  off=60 | - - - - - / - - - - | - - - - \----\
--                    |          /          |              |\
--                    |         /           |              | \
--    Temp_us   on=35 | -  /---/            |              |  \
--    Temp_us  off=30 | - / - -|- - - - - - |- - - - - - - |- -\------\
--                    |  /     |            |              |           \
--    ----------------|--------|------------|--------------|-----------|--------
--    pwm =           |   min  |  medium    |   max        |   medium  |  min
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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

library	UniSim;
use			UniSim.vComponents.all;

library PoC;
use     PoC.config.all;


entity xil_SystemMonitor is
	port (
		Reset								: in	std_logic;				-- Reset signal for the System Monitor control logic

		Alarm_UserTemp			: out	std_logic;				-- Temperature-sensor alarm output
		Alarm_OverTemp			: out	std_logic;				-- Over-Temperature alarm output
		Alarm								: out	std_logic;				-- OR'ed output of all the Alarms
		VP									: in	std_logic;				-- Dedicated Analog Input Pair
		VN									: in	std_logic
	);
end entity;


architecture xilinx of xil_SystemMonitor is
	signal aux_channel_p				: std_logic_vector(15 downto 0);
	signal aux_channel_n				: std_logic_vector(15 downto 0);

begin
	aux_channel_p <= (others => '0');
	aux_channel_n <= (others => '0');

	genVirtex6: if (DEVICE = DEVICE_VIRTEX6) generate
		signal SysMon_Alarm     : std_logic_vector(7 downto 0);
		signal SysMon_OverTemp  : std_logic;
	begin
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
				RESET							=> Reset,
				CONVSTCLK					=> '0',
				CONVST						=> '0',
				-- DRP port
				DCLK							=> '0',
				DEN								=> '0',
				DADDR							=> "0000000",
				DWE								=> '0',
				DI								=> x"0000",
				DO								=> open,
				DRDY							=> open,
				-- External analog inputs
				VAUXN							=> aux_channel_n,
				VAUXP							=> aux_channel_p,
				VN								=> VN,
				VP								=> VP,
				-- Alarms
				OT								=> SysMon_OverTemp,
				ALM								=> SysMon_Alarm,
				-- Status
				CHANNEL						=> open,
				BUSY							=> open,
				EOC								=> open,
				EOS								=> open,

				JTAGBUSY					=> open,
				JTAGLOCKED				=> open,
				JTAGMODIFIED			=> open
			);

		Alarm_UserTemp	<= SysMon_Alarm(0);
		Alarm_OverTemp	<= SysMon_OverTemp;
		Alarm						<= SysMon_Alarm(0) or SysMon_OverTemp;
	end generate;
	genSeries7: if (DEVICE_SERIES = DEVICE_SERIES_7_SERIES) generate
		signal XADC_Alarm       : std_logic_vector(7 downto 0);
	begin
		SysMonitor : XADC
			generic map (
				INIT_40							=> x"8000",					-- config reg 0
				INIT_41							=> x"8f0c",					-- config reg 1
				INIT_42							=> x"0400",					-- config reg 2
				INIT_48							=> x"0000",					-- Sequencer channel selection
				INIT_49							=> x"0000",					-- Sequencer channel selection
				INIT_4A							=> x"0000",					-- Sequencer Average selection
				INIT_4B							=> x"0000",					-- Sequencer Average selection
				INIT_4C							=> x"0000",					-- Sequencer Bipolar selection
				INIT_4D							=> x"0000",					-- Sequencer Bipolar selection
				INIT_4E							=> x"0000",					-- Sequencer Acq time selection
				INIT_4F							=> x"0000",					-- Sequencer Acq time selection
				INIT_50							=> x"9c87",					-- Temp alarm trigger
				INIT_51							=> x"57e4",					-- Vccint upper alarm limit
				INIT_52							=> x"a147",					-- Vccaux upper alarm limit
				INIT_53							=> x"b363",					-- Temp alarm OT upper
				INIT_54							=> x"99fd",					-- Temp alarm reset
				INIT_55							=> x"52c6",					-- Vccint lower alarm limit
				INIT_56							=> x"9555",					-- Vccaux lower alarm limit
				INIT_57							=> x"a93a",					-- Temp alarm OT reset
				INIT_58							=> x"5999",					-- Vbram upper alarm limit
				INIT_5C							=> x"5111",					-- Vbram lower alarm limit
				SIM_DEVICE					=> "7SERIES",
				SIM_MONITOR_FILE		=> "design.txt"
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
				VAUXN								=> aux_channel_n,
				VAUXP								=> aux_channel_p,
				VN									=> VN,
				VP									=> VP,
				-- Alarms
				OT									=> Alarm_OverTemp,
				ALM									=> XADC_Alarm,
				-- Status
				MUXADDR							=> open,
				CHANNEL							=> open,
				BUSY								=> open,
				EOC									=> open,
				EOS									=> open,

				JTAGBUSY						=> open,
				JTAGLOCKED					=> open,
				JTAGMODIFIED				=> open
		 );

		Alarm						<= XADC_Alarm(7);
		Alarm_UserTemp	<= XADC_Alarm(0);
	end generate;
	genUltraScale: if (DEVICE_SERIES = DEVICE_SERIES_ULTRASCALE) generate
		signal SysMon_Alarm  : std_logic_vector(15 downto 0);
	begin
		SysMonitor: SYSMONE1
			generic map(
				INIT_40          => X"0000", -- config reg 0
				INIT_41          => X"2190", -- config reg 1
				INIT_42          => X"1400", -- config reg 2
				INIT_43          => X"200F", -- config reg 3
				INIT_45          => X"DEDC", -- Analog Bus Register
				INIT_46          => X"0000", -- Sequencer Channel selection (Vuser0-3)
				INIT_47          => X"0000", -- Sequencer Average selection (Vuser0-3)
				INIT_48          => X"4F01", -- Sequencer channel selection
				INIT_49          => X"0000", -- Sequencer channel selection
				INIT_4A          => X"0000", -- Sequencer Average selection
				INIT_4B          => X"0000", -- Sequencer Average selection
				INIT_4C          => X"0000", -- Sequencer Bipolar selection
				INIT_4D          => X"0000", -- Sequencer Bipolar selection
				INIT_4E          => X"0000", -- Sequencer Acq time selection
				INIT_4F          => X"0000", -- Sequencer Acq time selection
				INIT_50          => X"9D9C", -- Temp alarm trigger
				INIT_51          => X"4E81", -- Vccint upper alarm limit
				INIT_52          => X"A147", -- Vccaux upper alarm limit
				INIT_53          => X"B493", -- Temp alarm OT upper
				INIT_54          => X"9B0E", -- Temp alarm reset
				INIT_55          => X"4963", -- Vccint lower alarm limit
				INIT_56          => X"9555", -- Vccaux lower alarm limit
				INIT_57          => X"AA5F", -- Temp alarm OT reset
				INIT_58          => X"4E81", -- Vccbram upper alarm limit
				INIT_5C          => X"4963", -- Vbccram lower alarm limit
				INIT_59          => X"5555", -- vccpsintlp upper alarm limit
				INIT_5D          => X"5111", -- vccpsintlp lower alarm limit
				INIT_5A          => X"9999", -- vccpsintfp upper alarm limit
				INIT_5E          => X"91EB", -- vccpsintfp lower alarm limit
				INIT_5B          => X"6AAA", -- vccpsaux upper alarm limit
				INIT_5F          => X"6666", -- vccpsaux lower alarm limit
				INIT_60          => X"9A74", -- Vuser0 upper alarm limit
				INIT_61          => X"4DA6", -- Vuser1 upper alarm limit
				INIT_62          => X"9A74", -- Vuser2 upper alarm limit
				INIT_63          => X"4D39", -- Vuser3 upper alarm limit
				INIT_68          => X"98BF", -- Vuser0 lower alarm limit
				INIT_69          => X"4BF2", -- Vuser1 lower alarm limit
				INIT_6A          => X"98BF", -- Vuser2 lower alarm limit
				INIT_6B          => X"4C5E", -- Vuser3 lower alarm limit
				SIM_MONITOR_FILE => "design.txt"
			)
			port map (
				CONVST        => '0',
				CONVSTCLK     => '0',
				
				RESET         => Reset,
				
				DCLK          => '0',
				DEN           => '0',
				DADDR         => x"00",
				DWE           => '0',
				DI            => x"0000",
				DO            => open,
				DRDY          => open,
				
				ALM           => SysMon_Alarm,
				OT            => Alarm_OverTemp,
				
				CHANNEL       => open,
				BUSY          => open,
				EOC           => open,
				EOS           => open,
				
				JTAGBUSY      => open,
				JTAGLOCKED    => open,
				JTAGMODIFIED  => open,
				
				I2C_SCLK      => '0',
				I2C_SDA       => '0',
				I2C_SCLK_TS   => open,
				I2C_SDA_TS    => open,

				MUXADDR       => open,
				VAUXP         => aux_channel_p,
				VAUXN         => aux_channel_n,
				VN            => VN,
				VP            => VP
			);

		Alarm						<= SysMon_Alarm(7);
		Alarm_UserTemp	<= SysMon_Alarm(0);
	end generate;
	genUltraScalePlus: if (DEVICE_SERIES = DEVICE_SERIES_ULTRASCALE_PLUS) generate
		signal SysMon_Alarm  : std_logic_vector(7 downto 0);
	begin
		SysMonitor: SYSMONE4
			generic map(
				COMMON_N_SOURCE   => X"FFFF", --Source for Common N Channels
				INIT_40           => X"0000", -- config reg 0
				INIT_41           => X"2190", -- config reg 1
				INIT_42           => X"1400", -- config reg 2
				INIT_43           => X"200F", -- config reg 3
				INIT_44           => X"0000", -- config reg 4
				INIT_45           => X"8EDC", -- Analog Bus Register
				INIT_46           => X"0000", -- Sequencer Channel selection (Vuser0-3)
				INIT_47           => X"0000", -- Sequencer Average selection (Vuser0-3)
				INIT_48           => X"4F01", -- Sequencer channel selection
				INIT_49           => X"0000", -- Sequencer channel selection
				INIT_4A           => X"0000", -- Sequencer Average selection
				INIT_4B           => X"0000", -- Sequencer Average selection
				INIT_4C           => X"0000", -- Sequencer Bipolar selection
				INIT_4D           => X"0000", -- Sequencer Bipolar selection
				INIT_4E           => X"0000", -- Sequencer Acq time selection
				INIT_4F           => X"0000", -- Sequencer Acq time selection
				INIT_50           => X"A098", -- Temp alarm trigger
				INIT_51           => X"4E81", -- Vccint upper alarm limit
				INIT_52           => X"A147", -- Vccaux upper alarm limit
				INIT_53           => X"B803", -- Temp alarm OT upper
				INIT_54           => X"9DFD", -- Temp alarm reset
				INIT_55           => X"4963", -- Vccint lower alarm limit
				INIT_56           => X"9555", -- Vccaux lower alarm limit
				INIT_57           => X"ADA0", -- Temp alarm OT reset
				INIT_58           => X"4E81", -- Vccbram upper alarm limit
				INIT_5C           => X"4963", -- Vbccram lower alarm limit
				INIT_59           => X"5555", -- vccpsintlp upper alarm limit
				INIT_5D           => X"5111", -- vccpsintlp lower alarm limit
				INIT_5A           => X"9999", -- vccpsintfp upper alarm limit
				INIT_5E           => X"91EB", -- vccpsintfp lower alarm limit
				INIT_5B           => X"6AAA", -- vccpsaux upper alarm limit
				INIT_5F           => X"6666", -- vccpsaux lower alarm limit
				INIT_60           => X"D62F", -- Vuser0 upper alarm limit
				INIT_61           => X"4DA6", -- Vuser1 upper alarm limit
				INIT_62           => X"9A74", -- Vuser2 upper alarm limit
				INIT_63           => X"9A74", -- Vuser3 upper alarm limit
				INIT_68           => X"D47A", -- Vuser0 lower alarm limit
				INIT_69           => X"4BF2", -- Vuser1 lower alarm limit
				INIT_6A           => X"98BF", -- Vuser2 lower alarm limit
				INIT_6B           => X"98BF", -- Vuser3 lower alarm limit
				INIT_7A           => X"0000", -- DUAL0 Register
				INIT_7B           => X"0000", -- DUAL1 Register
				INIT_7C           => X"0000", -- DUAL2 Register 
				INIT_7D           => X"0000", -- DUAL3 Register
				SIM_DEVICE        => "ZYNQ_ULTRASCALE",
				SIM_MONITOR_FILE  => "design.txt"
			)
			port map (
				RESET         => Reset,
					
				DCLK          => '0',
				DEN           => '0',
				DADDR         => x"00",
				DWE           => '0',
				DI            => x"0000",
				DO            => open,
				DRDY          => open,
					
				VAUXN         => aux_channel_n,
				VAUXP         => aux_channel_p,
				
				ALM           => SysMon_Alarm,
				OT            => Alarm_OverTemp,
				
				CONVST        => '0',
				CONVSTCLK     => '0',
				BUSY          => open,
				ADC_DATA      => open,
				CHANNEL       => open,
				EOC           => open,
				EOS           => open,
				
				JTAGBUSY      => open,
				JTAGLOCKED    => open,
				JTAGMODIFIED  => open,
				
				I2C_SCLK      => '0',
				I2C_SDA       => '0',
				I2C_SCLK_TS   => open,
				I2C_SDA_TS    => open,
				
				SMBALERT_TS   => open,

				MUXADDR       => open,
				VN            => vn,
				VP            => vp
			);

		Alarm						<= SysMon_Alarm(7);
		Alarm_UserTemp	<= SysMon_Alarm(0);
	end generate;
end architecture;
