-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	TODO
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
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
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;
use			IEEE.math_real.all;

library PoC;
use			PoC.utils.all;
use			PoC.strings.all;


entity lut_Sine is
	generic (
		REG_OUTPUT		: boolean			:= TRUE;
		MAX_AMPLITUDE	: positive		:= 255;
		POINTS				: positive		:= 4096;
		OFFSET_DEG		: REAL				:= 0.0;
		QUARTERS			: positive		:= 4
	);
	port (
		Clock				: in	std_logic;
		Input				: in	std_logic_vector(log2ceilnz(POINTS) - 1 downto 0);
		Output			:	out	std_logic_vector(log2ceilnz(MAX_AMPLITUDE + ((QUARTERS - 1) / 2)) downto 0)
	);
end entity;


architecture rtl of lut_Sine is
	signal Output_nxt	: std_logic_vector(Output'range);
begin
	-- ===========================================================================
	-- 1 Qudrant LUT
	-- ===========================================================================
	genQ1 : if QUARTERS = 1 generate
		subtype T_RESULT	is natural range 0 to MAX_AMPLITUDE;
		type		T_LUT			is array (natural range <>) of T_RESULT;

		function generateLUT return T_LUT is
			variable Result : T_LUT(0 to POINTS - 1)	:= (others => 0);
			constant STEP					: REAL		:= (90.0 / real(Result'length)) * MATH_DEG_TO_RAD;
			constant AMPLITUDE_I	: REAL		:= real(MAX_AMPLITUDE);
			variable x						: REAL		:= 0.0;
			variable y						: REAL;
		begin
			for i in Result'range loop
				Result(i)	:= integer(sin(x) * AMPLITUDE_I);
				x := x + STEP;
			end loop;
			return Result;
		end function;

		constant LUT	: T_LUT := generateLUT;
	begin
		assert (OFFSET_DEG = 0.0) report "Offset > 0.0° is only supported in 4 quadrant mode." severity FAILURE;

		Output_nxt		<= std_logic_vector(to_unsigned(LUT(to_index(Input, LUT'length)), Output_nxt'length));
	end generate;
	-- ===========================================================================
	-- 2 Qudrant LUT
	-- ===========================================================================
	genQ12 : if QUARTERS = 2 generate
		subtype T_RESULT	is natural range 0 to MAX_AMPLITUDE;
		type		T_LUT			is array (natural range <>) of T_RESULT;

		function generateLUT return T_LUT is
			variable Result : T_LUT(0 to POINTS - 1)	:= (others => 0);
			constant STEP					: REAL		:= (180.0 / real(Result'length)) * MATH_DEG_TO_RAD;
			constant AMPLITUDE_I	: REAL		:= real(MAX_AMPLITUDE);
			variable x						: REAL		:= 0.0;
			variable y						: REAL;
		begin
			for i in Result'range loop
				Result(i)	:= integer(sin(x) * AMPLITUDE_I);
				x := x + STEP;
			end loop;
			return Result;
		end function;

		constant LUT	: T_LUT := generateLUT;
	begin
		assert (OFFSET_DEG = 0.0) report "Offset > 0.0° is only supported in 4 quadrant mode." severity FAILURE;

		Output_nxt		<= std_logic_vector(to_unsigned(LUT(to_index(Input, LUT'length)), Output_nxt'length));
	end generate;
	-- ===========================================================================
	-- 3 Qudrant LUT -> ERROR
	-- ===========================================================================
	genQ13 : if QUARTERS = 3 generate
		assert false report "QUARTERS=3 is not supported." severity FAILURE;
	end generate;
	-- ===========================================================================
	-- 4 Qudrant LUT
	-- ===========================================================================
	genQ14 : if QUARTERS = 4 generate
		subtype T_RESULT	is integer range -MAX_AMPLITUDE to MAX_AMPLITUDE;
		type		T_LUT			is array (natural range <>) of T_RESULT;

		function generateLUT return T_LUT is
			variable Result : T_LUT(0 to POINTS - 1)	:= (others => 0);
			constant STEP					: REAL		:= (360.0 / real(Result'length)) * MATH_DEG_TO_RAD;
			constant AMPLITUDE_I	: REAL		:= real(MAX_AMPLITUDE);
			variable x						: REAL		:= OFFSET_DEG * MATH_DEG_TO_RAD;
			variable y						: REAL;
		begin
			for i in Result'range loop
				Result(i)	:= integer(sin(x) * AMPLITUDE_I);
				x := x + STEP;
			end loop;
			return Result;
		end function;

		constant LUT	: T_LUT := generateLUT;
	begin

		Output_nxt		<= std_logic_vector(to_signed(LUT(to_index(Input, LUT'length)), Output_nxt'length));
	end generate;


	-- ===========================================================================
	-- No output registers
	-- ===========================================================================
	genNoReg : if not REG_OUTPUT generate
	begin
		Output		<= Output_nxt;
	end generate;
	-- ===========================================================================
	-- Output registers
	-- ===========================================================================
	genReg : if REG_OUTPUT generate
		signal Output_d		: std_logic_vector(Output'range)	:= (others => '0');
	begin
		Output_d	<= Output_nxt	when rising_edge(Clock);

		Output		<= Output_d;
	end generate;
end;
