-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	A downscaling gearbox module with a dependent clock (dc) interface.
--
-- Description:
-- -------------------------------------
-- This module provides a downscaling gearbox with a dependent clock (dc)
-- interface. It perfoems a 'word' to 'byte' splitting. The default order is
-- LITTLE_ENDIAN (starting at byte(0)). Input "In_Data" is of clock domain
-- "Clock1"; output "Out_Data" is of clock domain "Clock2". Optional input and
-- output registers can be added by enabling (ADD_***PUT_REGISTERS = TRUE).
--
-- Assertions:
-- ===========
-- - Clock periods of Clock1 and Clock2 MUST be multiples of each other.
-- - Clock1 and Clock2 MUST be phase aligned (related) to each other.
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
use			PoC.components.all;


entity gearbox_down_dc is
  generic (
		INPUT_BITS						: positive				:= 32;													-- input bits ('words')
		OUTPUT_BITS						: positive				:= 8;														-- output bits ('byte')
		OUTPUT_ORDER					: T_BIT_ORDER			:= LSB_FIRST;										-- LSB_FIRST: start at byte(0), MSB_FIRST: start at byte(n-1)
		ADD_INPUT_REGISTERS		: boolean					:= FALSE;												-- add input register @Clock1
	  ADD_OUTPUT_REGISTERS	: boolean					:= FALSE												-- add output register @Clock2
	);
  port (
	  Clock1								: in	std_logic;																	-- input clock domain
		Clock2								: in	std_logic;																	-- output clock domain
		In_Data								: in	std_logic_vector(INPUT_BITS - 1 downto 0);	-- input word
		Out_Data							: out std_logic_vector(OUTPUT_BITS - 1 downto 0)	-- output word
	);
end entity;


architecture rtl of gearbox_down_dc is
	constant BIT_RATIO		: REAL			:= real(INPUT_BITS) / real(OUTPUT_BITS);
	constant COUNTER_BITS : positive	:= log2ceil(integer(BIT_RATIO));

	type T_MUX_INPUT is array (natural range <>) of std_logic_vector(OUTPUT_BITS - 1 downto 0);

	signal WordBoundary			: std_logic		:= '0';
	signal WordBoundary_d		: std_logic		:= '0';
	signal Align						: std_logic;

	signal Data_d						: std_logic_vector(INPUT_BITS - 1 downto 0)		:= (others => '0');
	signal DataIn						: std_logic_vector(INPUT_BITS - 1 downto 0);
	signal DataOut_d				: std_logic_vector(OUTPUT_BITS - 1 downto 0)	:= (others => '0');
	signal MuxInput					: T_MUX_INPUT(2**COUNTER_BITS - 1 downto 0);
	signal MuxOutput				: std_logic_vector(OUTPUT_BITS - 1 downto 0);
	signal MuxCounter_us		: unsigned(COUNTER_BITS - 1 downto 0)					:= (others => '0');
	signal MuxSelect_us			: unsigned(COUNTER_BITS - 1 downto 0);

begin
	assert (INPUT_BITS > OUTPUT_BITS) report "OUTPUT_BITS must be less than INPUT_BITS, otherwise it's no down-sizing gearbox." severity FAILURE;

	-- input register @Clock1
	Data_d	<= In_Data when registered(Clock1, ADD_INPUT_REGISTERS);

	-- switch byte order if neccessary
	DataIn	<= ite((OUTPUT_ORDER = LSB_FIRST), Data_d, swap(Data_d, OUTPUT_BITS));

	-- selection multiplexer
	genMuxInput : for j in 0 to (2 ** COUNTER_BITS) - 1 generate
		MuxInput(j)	<= DataIn(((j + 1) * OUTPUT_BITS) - 1 downto (j * OUTPUT_BITS));
	end generate;

	-- multiplexer control @Clock2
	MuxCounter_us <= upcounter_next(cnt => MuxCounter_us, rst => Align, INIT => 1) when rising_edge(Clock2);
	MuxSelect_us	<= mux(Align, MuxCounter_us, (MuxCounter_us'range => '0'));
	MuxOutput			<= MuxInput(to_index(MuxSelect_us));

	-- word boundary T-FF @Clock1 and D-FF @Clock2
	WordBoundary		<= not WordBoundary when rising_edge(Clock1);
	WordBoundary_d	<= WordBoundary			when rising_edge(Clock2);
	Align						<= WordBoundary xor WordBoundary_d;

	-- add output register @Clock2
	DataOut_d		<= MuxOutput when registered(Clock2, ADD_OUTPUT_REGISTERS);
	Out_Data		<= DataOut_d;
end architecture;
