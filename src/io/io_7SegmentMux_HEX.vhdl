-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	time multiplexed 7 Segment Display Controller for HEX chars
--
-- Description:
-- -------------------------------------
-- This module is a 7 segment display controller that uses time multiplexing
-- to control a common anode for each digit in the display. The shown characters
-- are HEX encoded. A dot per digit is optional.
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
use			PoC.vectors.all;
use			PoC.physical.all;
use			PoC.components.all;
use			PoC.io.all;


entity io_7SegmentMux_HEX is
	generic (
		CLOCK_FREQ			: FREQ				:= 100 MHz;
		REFRESH_RATE		: FREQ				:= 1 kHz;
		DIGITS					: positive		:= 4
	);
  port (
	  Clock						: in	std_logic;

		HexDigits				: in	T_SLVV_4(DIGITS - 1 downto 0);
		HexDots					: in	std_logic_vector(DIGITS - 1 downto 0);

		SegmentControl	: out	std_logic_vector(7 downto 0);
		DigitControl		: out	std_logic_vector(DIGITS - 1 downto 0)
	);
end entity;


architecture rtl of io_7SegmentMux_HEX is
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

	process(HexDigits, HexDots, DigitCounter_us)
		variable HexDigit : T_SLV_4;
		variable HexDot 	: std_logic;
	begin
		HexDigit	:= HexDigits(to_index(DigitCounter_us, HexDigits'length));
		HexDot		:= HexDots(to_index(DigitCounter_us, HexDigits'length));

		SegmentControl	<= io_7SegmentDisplayEncoding(HexDigit, HexDot, WITH_DOT => TRUE);
	end process;
end;
