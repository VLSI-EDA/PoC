-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					measures a input frequency relativ to a reference frequency
--
-- Description:
-- -------------------------------------
-- This module counts 1 second in a reference timer at reference clock. This
-- reference time is used to start and stop a timer at input clock. The counter
-- value is the measured frequency in Hz.
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

library PoC;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.physical.all;
use			PoC.components.all;


entity misc_FrequencyMeasurement is
	generic (
		REFERENCE_CLOCK_FREQ	: FREQ			:= 100 MHz
	);
	port (
		Reference_Clock		: in	std_logic;
		Input_Clock				: in	std_logic;

		Start							: in	std_logic;
		Done							: out	std_logic;
		Result						: out	T_SLV_32
	);
end entity;


architecture rtl of misc_FrequencyMeasurement is
	constant TIMEBASE_COUNTER_MAX			: positive																:= TimingToCycles(ite(SIMULATION, 10 us, 1 sec), REFERENCE_CLOCK_FREQ);
	constant TIMEBASE_COUNTER_BITS		: positive																:= log2ceilnz(TIMEBASE_COUNTER_MAX);

	signal TimeBase_Counter_rst				: std_logic;
	signal TimeBase_Counter_s					: signed(TIMEBASE_COUNTER_BITS downto 0)	:= to_signed(-1, TIMEBASE_COUNTER_BITS + 1);
	signal TimeBase_Counter_nxt				: signed(TIMEBASE_COUNTER_BITS downto 0);
	signal TimeBase_Counter_uf				: std_logic;

	signal Stop												: std_logic;
	signal sync_Start									: std_logic;
	signal sync_Stop									: std_logic;
	signal sync1_Busy									: T_SLV_2;

	signal Frequency_Counter_en_r			: std_logic																:= '0';
	signal Frequency_Counter_us				: unsigned(31 downto 0)										:= (others => '0');

	signal CaptureResult							: std_logic;
	signal CaptureResult_d						: std_logic																:= '0';
	signal Result_en									: std_logic;
	signal Result_d										: T_SLV_32																:= (others => '0');
	signal Done_r											: std_logic																:= '0';
begin

	TimeBase_Counter_rst	<= Start;
	TimeBase_Counter_nxt	<= TimeBase_Counter_s - 1;

	process(Reference_Clock)
	begin
		if rising_edge(Reference_Clock) then
			if (TimeBase_Counter_rst = '1') then
				TimeBase_Counter_s	<= to_signed(TIMEBASE_COUNTER_MAX - 2, TimeBase_Counter_s'length);
			elsif (TimeBase_Counter_uf = '0') then
				TimeBase_Counter_s	<= TimeBase_Counter_nxt;
			end if;
		end if;
	end process;

	TimeBase_Counter_uf		<= TimeBase_Counter_s(TimeBase_Counter_s'high);
	Stop									<= not TimeBase_Counter_s(TimeBase_Counter_s'high) and TimeBase_Counter_nxt(TimeBase_Counter_nxt'high);

	sync1 : entity poc.sync_Strobe
		generic map (
			BITS			=> 2													-- number of bit to be synchronized
		)
		port map (
			Clock1		=> Reference_Clock,						-- <Clock>	input clock
			Clock2		=> Input_Clock,								-- <Clock>	output clock
			Input(0)	=> Start,											-- @Clock1	input vector
			Input(1)	=> Stop,											--
			Output(0)	=> sync_Start,								-- @Clock2:	output vector
			Output(1)	=> sync_Stop,									--
			Busy			=> sync1_Busy
		);

	Frequency_Counter_en_r	<= ffrs(q => Frequency_Counter_en_r, set => sync_Start, rst => sync_Stop) when rising_edge(Input_Clock);

	process(Input_Clock)
	begin
		if rising_edge(Input_Clock) then
			if (sync_Start = '1') then
				Frequency_Counter_us	<= to_unsigned(1, Frequency_Counter_us'length);
			elsif (Frequency_Counter_en_r = '1') then
				Frequency_Counter_us	<= Frequency_Counter_us + 1;
			end if;
		end if;
	end process;

	CaptureResult		<= sync1_Busy(1);
	CaptureResult_d	<= CaptureResult		when rising_edge(Reference_Clock);
	Result_en				<= CaptureResult_d	and not CaptureResult;

	-- Result_d can becaptured from Frequency_Counter_us, because it's stable
	-- for more than one clock cycle and will not change until the next Start
	process(Reference_Clock)
	begin
		if rising_edge(Reference_Clock) then
			if (Result_en = '1') then
				Result_d	<= std_logic_vector(Frequency_Counter_us);
				Done_r		<= '1';
			elsif (Start = '1') then
				Done_r		<= '0';
			end if;
		end if;
	end process;

	Done		<= Done_r;
	Result	<= Result_d;
end;
