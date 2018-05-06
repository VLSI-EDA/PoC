-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	Generic Fan Controller
--
-- Description:
-- -------------------------------------
-- .. code-block:: none
--
--		This module generates a PWM signal for a 3-pin (transistor controlled) or
--		4-pin fan header. The FPGAs temperature is read from device specific system
--		monitors (normal, user temperature, over temperature).
--
--		For example the Xilinx System Monitors are configured as follows:
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

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.strings.all;
use			PoC.vectors.all;
use			PoC.physical.all;
use			PoC.components.all;
use			PoC.xil.all;


entity io_FanControl is
	generic (
		CLOCK_FREQ							: FREQ;
		ADD_INPUT_SYNCHRONIZERS	: boolean			:= TRUE;
		ENABLE_TACHO						: boolean			:= FALSE
	);
	port (
		-- Global Control
		Clock										: in	std_logic;
		Reset										: in	std_logic;

		-- Fan Control derived from internal System Health Monitor
		Fan_PWM									: out	std_logic;

    -- Decoding of Speed Sensor (Requires ENABLE_TACHO)
    Fan_Tacho      : in  std_logic := 'X';
    TachoFrequency : out std_logic_vector(15 downto 0)
  );
end entity;


architecture rtl of io_FanControl is
	-- constant TIME_STARTUP			: TIME																					:= 500 ms;		-- StartUp time
	-- Use frequencies only to make Vivado work.
	constant TIME_STARTUP_INVERSE : FREQ																					:= 2 Hz;		-- StartUp time
	constant PWM_RESOLUTION		: positive																					:= 4;					-- 4 Bit resolution => 0 to 15 steps
	constant PWM_FREQ					: FREQ																							:= 10 Hz;			--

	constant TACHO_RESOLUTION	: positive																					:= 8;

	signal PWM_PWMIn					: std_logic_vector(PWM_RESOLUTION - 1 downto 0);
	signal PWM_PWMOut					: std_logic																					:= '0';

begin
	-- System Monitor and temperature to PWM ratio calculation for Virtex6
	-- ==========================================================================================================================================================
	genXilinx : if VENDOR = VENDOR_XILINX generate
		signal OverTemperature_async	: std_logic;
		signal OverTemperature_sync		: std_logic;

		signal UserTemperature_async	: std_logic;
		signal UserTemperature_sync		: std_logic;

		signal TC_Timeout					: std_logic;
		signal StartUp						: std_logic;
	begin
		genXilinxBoard : if str_imatch(BOARD_NAME, "ML605") or str_imatch(BOARD_NAME, "KC705") or
		                    str_imatch(BOARD_NAME, "VC707") or str_imatch(BOARD_NAME, "KCU105") generate
			SystemMonitor : xil_SystemMonitor
				port map (
					Reset								=> Reset,										-- Reset signal for the System Monitor control logic

					Alarm_UserTemp			=> UserTemperature_async,		-- Temperature-sensor alarm output
					Alarm_OverTemp			=> OverTemperature_async,		-- Over-Temperature alarm output
					Alarm								=> open,										-- OR'ed output of all the Alarms
					VP									=> '0',											-- Dedicated Analog Input Pair
					VN									=> '0'
				);
		end generate;

		sync : entity PoC.sync_Bits_Xilinx
			generic map (
				BITS			=> 2
			)
			port map (
				Clock				=> Clock,
				Input(0)		=> OverTemperature_async,
				Input(1)		=> UserTemperature_async,
				Output(0)		=> OverTemperature_sync,
				Output(1)		=> UserTemperature_sync
			);

		-- timer for warm-up control
		-- ==========================================================================================================================================================
		TC : entity PoC.io_TimingCounter
			generic map (
				TIMING_TABLE				=> (0 => CLOCK_FREQ/TIME_STARTUP_INVERSE)	-- timing table
			)
			port map (
				Clock								=> Clock,				-- clock
				Enable							=> StartUp,			-- enable counter
				Load								=> '0',					-- load Timing Value from TIMING_TABLE selected by slot
				Slot								=> 0,						--
				Timeout							=> TC_Timeout		-- timing reached
			);

		StartUp	<= not TC_Timeout;

		process(StartUp, UserTemperature_sync, OverTemperature_sync)
		begin
			if		(StartUp = '1') then								PWM_PWMIn <= to_slv(2**PWM_RESOLUTION - 1, PWM_RESOLUTION);			-- 100%; start up
			elsif (OverTemperature_sync = '1') then		PWM_PWMIn <= to_slv(2**PWM_RESOLUTION - 1, PWM_RESOLUTION);			-- 100%
			elsif (UserTemperature_sync = '1') then		PWM_PWMIn <= to_slv(2**(PWM_RESOLUTION - 1), PWM_RESOLUTION);			-- 50%
			else																			PWM_PWMIn <= to_slv(4, PWM_RESOLUTION);														-- 13%
			end if;
		end process;
	end generate;

	genAltera : if VENDOR = VENDOR_ALTERA generate
--		signal OverTemperature_async	: STD_LOGIC;
		signal OverTemperature_sync		: std_logic;

--		signal UserTemperature_async	: STD_LOGIC;
		signal UserTemperature_sync		: std_logic;

		signal TC_Timeout					: std_logic;
		signal StartUp						: std_logic;
	begin
		genDE4 : if str_imatch(BOARD_NAME, "DE4") generate
			OverTemperature_sync		<= '0';
			UserTemperature_sync		<= '1';
		end generate;

		-- timer for warm-up control
		-- ==========================================================================================================================================================
		TC : entity PoC.io_TimingCounter
			generic map (
				TIMING_TABLE				=> (0 => CLOCK_FREQ/TIME_STARTUP_INVERSE)	-- timing table
			)
			port map (
				Clock								=> Clock,				-- clock
				Enable							=> StartUp,			-- enable counter
				Load								=> '0',					-- load Timing Value from TIMING_TABLE selected by slot
				Slot								=> 0,						--
				Timeout							=> TC_Timeout		-- timing reached
			);

		StartUp	<= not TC_Timeout;

		process(StartUp, UserTemperature_sync, OverTemperature_sync)
		begin
			if		(StartUp = '1') then								PWM_PWMIn <= to_slv(2**PWM_RESOLUTION - 1, PWM_RESOLUTION);			-- 100%; start up
			elsif (OverTemperature_sync = '1') then		PWM_PWMIn <= to_slv(2**PWM_RESOLUTION - 1, PWM_RESOLUTION);			-- 100%
			elsif (UserTemperature_sync = '1') then		PWM_PWMIn <= to_slv(2**(PWM_RESOLUTION - 1), PWM_RESOLUTION);			-- 50%
			else																			PWM_PWMIn <= to_slv(4, PWM_RESOLUTION);														-- 13%
			end if;
		end process;
	end generate;

	-- PWM signal modulator
	-- ==========================================================================================================================================================
	PWM : entity PoC.io_PulseWidthModulation
		generic map (
			CLOCK_FREQ					=> CLOCK_FREQ,				--
			PWM_FREQ						=> PWM_FREQ,					--
			PWM_RESOLUTION			=> PWM_RESOLUTION			--
		)
		port map (
			Clock								=> Clock,
			Reset								=> Reset,
			PWMIn								=> PWM_PWMIn,
			PWMOut							=> PWM_PWMOut
		);

	-- registered output
	Fan_PWM 		<= PWM_PWMOut	when rising_edge(Clock);

	-- tacho signal interpretation -> convert to RPM
	-- ==========================================================================================================================================================
	genNoTacho : if not ENABLE_TACHO generate
		TachoFrequency <= (TachoFrequency'range => 'X');
	end generate;
	genTacho : if ENABLE_TACHO generate
		signal Tacho_sync					: std_logic;
		signal Tacho_Freq					: std_logic_vector(TACHO_RESOLUTION - 1 downto 0);
	begin
		-- Input Synchronization
		genNoSync : if not ADD_INPUT_SYNCHRONIZERS generate
			Tacho_sync <= Fan_Tacho;
		end generate;
		genSync : if ADD_INPUT_SYNCHRONIZERS generate
			sync_i : entity PoC.sync_Bits
				port map (
					Clock  		=> Clock,					-- Clock to be synchronized to
					Input(0)  => Fan_Tacho,			-- Data to be synchronized
					Output(0) => Tacho_sync			-- synchronised data
				);
		end generate;

		Tacho : entity PoC.io_FrequencyCounter
			generic map (
				CLOCK_FREQ					=> CLOCK_FREQ,					--
				TIMEBASE						=> (60 sec / 64),				-- ca. 1 second
				RESOLUTION					=> 8										-- max. ca. 256 RPS -> max. ca. 16k RPM
			)
			port map (
				Clock								=> Clock,
				Reset								=> Reset,
				FreqIn							=> Tacho_sync,
				FreqOut							=> Tacho_Freq
			);

		-- multiply by 64; divide by 2 for RPMs (2 impulses per revolution) => append 5x '0'
		TachoFrequency	<= resize(Tacho_Freq & "00000", TachoFrequency'length);		-- resizing to 16 bit
	end generate;
end;
