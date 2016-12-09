-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	Digilent Peritherial Module: Pmod_SSD
--
-- Description:
-- -------------------------------------
-- This module drives a dual-digit 7-segment display (Pmod_SSD). The module
-- expects two binary encoded 4-bit ``Digit<i>`` signals and drives a 2x6 bit
-- Pmod connector (7 anode bits, 1 cathode bit).
--
-- .. code-block:: none
--
--    Segment Pos./ Index
--       AAA      |   000
--      F   B     |  5   1
--      F   B     |  5   1
--       GGG      |   666
--      E   C     |  4   2
--      E   C     |  4   2
--       DDD  DOT |   333  7
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
use			PoC.physical.all;
use			PoC.components.all;
use			PoC.io.all;
use			PoC.pmod.all;


entity pmod_SSD is
	generic (
		CLOCK_FREQ		: FREQ		:= 100 MHz;
		REFRESH_RATE	: FREQ		:= 1 kHz
	);
	port (
		Clock			: in	std_logic;

		Digit0		: in	std_logic_vector(3 downto 0);
		Digit1		: in	std_logic_vector(3 downto 0);

		SSD				: out	T_PMOD_SSD_PINS
	);
end entity;


architecture rtl of pmod_SSD is
	constant REFRESHTIMER_MAX		: positive	:= TimingToCycles(to_time(REFRESH_RATE), CLOCK_FREQ) - 1;
	constant REFRESHTIMER_BITS	: positive	:= log2ceilnz(REFRESHTIMER_MAX) + 1;

	signal RefreshTimer_rst	: std_logic;
	signal RefreshTimer_s		: signed(REFRESHTIMER_BITS - 1 downto 0)	:= to_signed(REFRESHTIMER_MAX, REFRESHTIMER_BITS);

	signal CathodeSelect_en	: std_logic;
	signal CathodeSelect_r	: std_logic		:= '0';

	signal Digit						: std_logic_vector(3 downto 0);
	signal Segments					: std_logic_vector(6 downto 0);
begin
	-- generate a < 1 kHz enable to toggle the CathodeSelect register
	RefreshTimer_s		<= downcounter_next(cnt => RefreshTimer_s, rst => RefreshTimer_rst, INIT => REFRESHTIMER_MAX) when rising_edge(Clock);
	RefreshTimer_rst	<= downcounter_neg(cnt => RefreshTimer_s);

	-- generate a cathode select signal, based on a T-FF
	CathodeSelect_en	<= RefreshTimer_rst;
	CathodeSelect_r		<= fftre(q => CathodeSelect_r, t => CathodeSelect_en) when rising_edge(Clock);

	Digit				<= mux(CathodeSelect_r, Digit0, Digit1);
	Segments		<= io_7SegmentDisplayEncoding(Digit);
	SSD.AnodeA	<= Segments(0);
	SSD.AnodeB	<= Segments(1);
	SSD.AnodeC	<= Segments(2);
	SSD.AnodeD	<= Segments(3);
	SSD.AnodeE	<= Segments(4);
	SSD.AnodeF	<= Segments(5);
	SSD.AnodeG	<= Segments(6);
	SSD.Cathode	<= CathodeSelect_r;
end architecture;
