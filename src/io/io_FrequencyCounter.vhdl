-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Patrick Lehmann
-- 
-- Module:				 	TODO
--
-- Description:
-- ------------------------------------
--		TODO
--
-- License:
-- ============================================================================
-- Copyright 2007-2014 Technische Universitaet Dresden - Germany
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

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;
use			PoC.physical.all;


entity io_FrequencyCounter is
	generic (
		CLOCK_FREQ								: FREQ									:= 100 MHz;
		TIMEBASE									: TIME									:= 1 sec;
		RESOLUTION								: POSITIVE							:= 8
	);
	port (
		Clock				: in	STD_LOGIC;
		Reset				: in	STD_LOGIC;
    FreqIn			: in	STD_LOGIC;
		FreqOut			: out	STD_LOGIC_VECTOR(RESOLUTION - 1 downto 0)
	);
end;


architecture rtl of io_FrequencyCounter is
	constant TIMEBASECOUNTER_MAX				: POSITIVE																		:= TimingToCycles(TIMEBASE, CLOCK_FREQ);
	constant TIMEBASECOUNTER_BITS				: POSITIVE																		:= log2ceilnz(TIMEBASECOUNTER_MAX);
	constant REQUENCYCOUNTER_MAX				: POSITIVE																		:= 2**RESOLUTION;
	constant FREQUENCYCOUNTER_BITS			: POSITIVE																		:= RESOLUTION;
	
	signal TimeBaseCounter_us						: UNSIGNED(TIMEBASECOUNTER_BITS - 1 downto 0)	:= (others => '0');
	signal TimeBaseCounter_ov						: STD_LOGIC;
	signal FrequencyCounter_us					: UNSIGNED(FREQUENCYCOUNTER_BITS downto 0)		:= (others => '0');
	signal FrequencyCounter_ov					: STD_LOGIC;
	
	signal FreqIn_d											: STD_LOGIC																		:= '0';
	signal FreqIn_re										: STD_LOGIC;
	
	signal FreqOut_d										: STD_LOGIC_VECTOR(RESOLUTION - 1 downto 0)		:= (others => '0');
	
begin
	FreqIn_d	<= FreqIn when rising_edge(Clock);
	FreqIn_re	<= not FreqIn_d and FreqIn;

	-- timebase counter
	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or TimeBaseCounter_ov) = '1') then
				TimeBaseCounter_us		<= (others => '0');
			else
				TimeBaseCounter_us		<= TimeBaseCounter_us + 1;
			end if;
		end if;
	end process;
	
	TimeBaseCounter_ov	<= to_sl(TimeBaseCounter_us = TIMEBASECOUNTER_MAX);
	
	-- frequency counter
	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or TimeBaseCounter_ov) = '1') then
				FrequencyCounter_us		<= (others => '0');
			elsif (FrequencyCounter_ov = '0') and (FreqIn_re = '1') then
				FrequencyCounter_us		<= FrequencyCounter_us + 1;
			end if;
		end if;
	end process;
	
	FrequencyCounter_ov	<= FrequencyCounter_us(FrequencyCounter_us'high);
	
	-- hold counter value until next TimeBaseCounter event
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				FreqOut_d			<= (others => '0');
			elsif (TimeBaseCounter_ov = '1') then
				if (FrequencyCounter_ov = '1') then
					FreqOut_d	<= (others => '1');
				else
					FreqOut_d	<= std_logic_vector(FrequencyCounter_us(FreqOut_d'range));
				end if;
			end if;
		end if;
	end process;
	
	FreqOut		<= FreqOut_d;
end;
