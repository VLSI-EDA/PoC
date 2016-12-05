-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	Keypad button matrix scanner
--
-- Description:
-- -------------------------------------
-- This module drives a one-hot encoded column vector to read back a rows
-- vector. By scanning column-by-column it's possible to extract the current
-- button state of the whole keypad. The scanner uses high-active logic. The
-- keypad size and scan frequency can be configured. The outputed signal
-- matrix is not debounced.
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


entity io_KeyPadScanner is
	generic (
		CLOCK_FREQ							: FREQ				:= 100 MHz;
		SCAN_FREQ								: FREQ				:= 1 kHz;
		ROWS										: positive		:= 4;
		COLUMNS									: positive		:= 4;
		ADD_INPUT_SYNCHRONIZERS	: boolean			:= TRUE
	);
	port (
		Clock					: in	std_logic;
		Reset					: in	std_logic;
		-- Matrix interface
		KeyPadMatrix	: out T_SLM(COLUMNS - 1 downto 0, ROWS - 1 downto 0);
		-- KeyPad interface
		ColumnVector	: out	std_logic_vector(COLUMNS - 1 downto 0);
		RowVector			: in	std_logic_vector(ROWS - 1 downto 0)
	);
end entity;


architecture rtl of io_KeyPadScanner is
	constant SHIFT_FREQ				: FREQ			:= SCAN_FREQ * COLUMNS;

	constant COLUMNTIMER_MAX	: positive	:= TimingToCycles(to_time(SHIFT_FREQ), CLOCK_FREQ) - 1;
	constant COLUMNTIMER_BITS	: positive	:= log2ceilnz(COLUMNTIMER_MAX) + 1;

	signal ColumnTimer_rst	: std_logic;
	signal ColumnTimer_s		: signed(COLUMNTIMER_BITS - 1 downto 0)	:= to_signed(COLUMNTIMER_MAX, COLUMNTIMER_BITS);

	signal ColumnSelect_en	: std_logic;
	signal ColumnSelect_d		: std_logic_vector(COLUMNS - 1 downto 0)	:= (0 => '1', others => '0');

	signal Rows_sync				: std_logic_vector(ROWS - 1 downto 0);
	signal KeyPadMatrix_r		: T_SLM(COLUMNS - 1 downto 0, ROWS - 1 downto 0)	:= (others => (others => '0'));
begin
	-- generate a < 100 kHz shift enable to 'clock' the ColumnSelect shift register
	ColumnTimer_s		<= downcounter_next(cnt => ColumnTimer_s, rst => ColumnTimer_rst, INIT => COLUMNTIMER_MAX) when rising_edge(Clock);
	ColumnTimer_rst	<= downcounter_neg(cnt => ColumnTimer_s);

	-- generate a column scan signal (one-hot encoded), based on a one-hot rotate register
	ColumnSelect_en	<= ColumnTimer_rst;
	ColumnSelect_d	<= rreg_left(q => ColumnSelect_d, en => ColumnSelect_en) when rising_edge(Clock);
	ColumnVector		<= ColumnSelect_d;

	-- synchronize input signals
	genSync : if ADD_INPUT_SYNCHRONIZERS generate
		sync : entity PoC.sync_Bits
			generic map (
				BITS	=> ROWS
			)
			port map (
				Clock		=> Clock,
				Input		=> RowVector,
				Output	=> Rows_sync
			);
	end generate;
	genNoSync : if not ADD_INPUT_SYNCHRONIZERS generate
		Rows_sync	<= RowVector;
	end generate;

	geni : for i in 0 to COLUMNS - 1 generate
		genj : for j in 0 to ROWS - 1 generate
			KeyPadMatrix_r(i, j)	<= ffsr(q => KeyPadMatrix_r(i, j),
																		set => (ColumnSelect_d(i) and Rows_sync(j)),
																		rst => (Reset or (ColumnSelect_d(i) and not Rows_sync(j))))
																	when rising_edge(Clock);
		end generate;
	end generate;

	KeyPadMatrix	<= KeyPadMatrix_r;
end architecture;
