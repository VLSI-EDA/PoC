-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	time multiplexed 7 Segment Display Controller for BCD chars
--
-- Description:
-- -------------------------------------
-- This module is a 7 segment display controller that uses time multiplexing
-- to control a common anode for each digit in the display. The shown characters
-- are BCD encoded. A dot per digit is optional. A minus sign for negative
-- numbers is supported.
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

library	IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;
use			PoC.physical.all;
use			PoC.components.all;
use			PoC.io.all;


entity io_7SegmentMux_BCD is
	generic (
		CLOCK_FREQ			: FREQ				:= 100 MHz;
		REFRESH_RATE		: FREQ				:= 1 kHz;
		DIGITS					: positive		:= 4
	);
  port (
	  Clock						: in	std_logic;

		BCDDigits				: in	T_BCD_VECTOR(DIGITS - 1 downto 0);
		BCDDots					: in	std_logic_vector(DIGITS - 1 downto 0);

		SegmentControl	: out	std_logic_vector(7 downto 0);
		DigitControl		: out	std_logic_vector(DIGITS - 1 downto 0)
	);
end entity;


architecture rtl of io_7SegmentMux_BCD is
	signal DigitCounter_rst		: std_logic;
	signal DigitCounter_en		: std_logic;
	signal DigitCounter_us		: unsigned(log2ceilnz(DIGITS) - 1 downto 0)	:= (others => '0');
begin

	Strobe : entity PoC.misc_StrobeGenerator
		generic map (
			STROBE_PERIOD_CYCLES	=> TimingToCycles(to_time(REFRESH_RATE), CLOCK_FREQ),
			INITIAL_STROBE				=> FALSE
		)
		port map (
			Clock		=> Clock,
			O				=> DigitCounter_en
		);

	--
	DigitCounter_rst	<= upcounter_equal(DigitCounter_us, DIGITS - 1) and DigitCounter_en;
	DigitCounter_us		<= upcounter_next(DigitCounter_us, DigitCounter_rst, DigitCounter_en) when rising_edge(Clock);
	DigitControl			<= resize(bin2onehot(std_logic_vector(DigitCounter_us)), DigitControl'length);

	process(BCDDigits, BCDDots, DigitCounter_us)
		variable BCDDigit : T_BCD;
		variable BCDDot 	: std_logic;
	begin
		BCDDigit	:= BCDDigits(to_index(DigitCounter_us, BCDDigits'length));
		BCDDot		:= BCDDots(to_index(DigitCounter_us, BCDDigits'length));

		if BCDDigit < C_BCD_MINUS then
			SegmentControl	<= io_7SegmentDisplayEncoding(BCDDigit, BCDDot, WITH_DOT => TRUE);
		elsif BCDDigit = C_BCD_MINUS then
			SegmentControl	<= BCDDot & "1000000";
		else
			SegmentControl	<= "00000000";
		end if;
	end process;
end;
