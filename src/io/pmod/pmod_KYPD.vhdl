-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	Digilent Peripherial Module: 4x4 Keypad (Pmod_KYPD)
--
-- Description:
-- -------------------------------------
-- This module drives a 4-bit one-cold encoded column vector to read back a
-- 4-bit rows vector. By scanning column-by-column it's possible to extract
-- the current button state of the whole keypad. This wrapper converts the
-- high-active signals from :doc:`PoC.io.KeypadScanner <../io_KeyPadScanner>`
-- to low-active signals for the pmod. An additional debounce circuit filters
-- the button signals. The scan frequency and bounce time can be configured.
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
use			PoC.vectors.all;
use			PoC.physical.all;
use			PoC.pmod.all;


entity pmod_KYPD is
	generic (
		CLOCK_FREQ		: FREQ				:= 100 MHz;
		SCAN_FREQ			: FREQ				:= 1 kHz;
		BOUNCE_TIME		: time				:= 10 ms
	);
	port (
		Clock					: in	std_logic;
		Reset					: in	std_logic;
		-- Matrix interface
		Keys					: out T_PMOD_KYPD_KEYPAD;
		-- KeyPad interface
		Columns_n			: out	std_logic_vector(3 downto 0);
		Rows_n				: in	std_logic_vector(3 downto 0)
	);
end entity;


architecture rtl of pmod_KYPD is
	signal ColumnVector			: std_logic_vector(3 downto 0);
	signal RowVector				: std_logic_vector(3 downto 0);

	signal KeyPadMatrix			: T_SLM(3 downto 0, 3 downto 0);
	signal KeyPadMatrix_slv	: std_logic_vector(15 downto 0);
	signal KeyPadVector			: std_logic_vector(15 downto 0);
	signal KeyPad						: T_SLM(3 downto 0, 3 downto 0);

begin
	-- KeyPad interface (low-active)
	Columns_n		<= not ColumnVector;
	RowVector		<= Rows_n;

	-- initialize a 4x4 matrix scanner
	scanner : entity PoC.io_KeyPadScanner
		generic map (
			CLOCK_FREQ							=> CLOCK_FREQ,
			SCAN_FREQ								=> SCAN_FREQ,
			COLUMNS									=> 4,
			ROWS										=> 4,
			ADD_INPUT_SYNCHRONIZERS	=> TRUE
		)
		port map (
			Clock					=> Clock,
			Reset					=> Reset,
			KeyPadMatrix	=> KeyPadMatrix,
			ColumnVector	=> ColumnVector,
			RowVector			=> RowVector
		);

	-- serialize the keypad matrix for debouncing
	KeyPadMatrix_slv	<= to_slv(KeyPadMatrix);

	debounce : entity PoC.io_Debounce
		generic map (
			CLOCK_FREQ							=> CLOCK_FREQ,
			BOUNCE_TIME							=> BOUNCE_TIME,
			BITS										=> 16,
			ADD_INPUT_SYNCHRONIZERS	=> FALSE
		)
		port map (
			Clock			=> Clock,
			Input			=> KeyPadMatrix_slv,
			Output		=> KeyPadVector
		);

	KeyPad		<= to_slm(KeyPadVector, 4, 4);
	Keys.Key1	<= KeyPad(0, 0);
	Keys.Key2	<= KeyPad(1, 0);
	Keys.Key3	<= KeyPad(2, 0);
	Keys.KeyA	<= KeyPad(3, 0);
	Keys.Key4	<= KeyPad(0, 1);
	Keys.Key5	<= KeyPad(1, 1);
	Keys.Key6	<= KeyPad(2, 1);
	Keys.KeyB	<= KeyPad(3, 1);
	Keys.Key7	<= KeyPad(0, 2);
	Keys.Key8	<= KeyPad(1, 2);
	Keys.Key9	<= KeyPad(2, 2);
	Keys.KeyC	<= KeyPad(3, 2);
	Keys.Key0	<= KeyPad(0, 3);
	Keys.KeyF	<= KeyPad(1, 3);
	Keys.KeyE	<= KeyPad(2, 3);
	Keys.KeyD	<= KeyPad(3, 3);
end architecture;
