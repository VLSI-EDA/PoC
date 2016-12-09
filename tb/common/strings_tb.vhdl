-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				Tests global constants, functions and settings
--
-- Description:
-- ------------------------------------
--		TODO
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
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library	PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.strings.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;


entity strings_tb is
end entity;


architecture tb of strings_tb is

	constant raw_format_slv_dec_result0		: string		:= raw_format_slv_dec(std_logic_vector'(x"12"));
	constant raw_format_slv_dec_result1		: string		:= raw_format_slv_dec(x"3456");
	constant raw_format_slv_dec_result2		: string		:= raw_format_slv_dec(x"12345678");
	constant raw_format_slv_dec_result3		: string		:= raw_format_slv_dec(x"A1B2C3D4E5F607A8");

	constant str_length_result0						: integer		:= str_length("");
	constant str_length_result1						: integer		:= str_length((1 to 3 => C_POC_NUL));
	constant str_length_result2						: integer		:= str_length("Hello");
	constant str_length_result3						: integer		:= str_length("Hello" & (1 to 3 => C_POC_NUL));

	constant str_match_result0						: boolean		:= str_match("", "");
	constant str_match_result1						: boolean		:= str_match("", (1 to 3 => C_POC_NUL));
	constant str_match_result2						: boolean		:= str_match("Hello", "hello");
	constant str_match_result3						: boolean		:= str_match("Hello", "Hello");
	constant str_match_result4						: boolean		:= str_match("Hello World", "Hello");
	constant str_match_result5						: boolean		:= str_match("Hello", "Hello World");
	constant str_match_result6						: boolean		:= str_match("Hello", "Hello" & (1 to 3 => C_POC_NUL));

	constant str_imatch_result0						: boolean		:= str_imatch("", "");
	constant str_imatch_result1						: boolean		:= str_imatch("", (1 to 3 => C_POC_NUL));
	constant str_imatch_result2						: boolean		:= str_imatch("Hello", "hello");
	constant str_imatch_result3						: boolean		:= str_imatch("Hello", "Hello");
	constant str_imatch_result4						: boolean		:= str_imatch("Hello World", "Hello");
	constant str_imatch_result5						: boolean		:= str_imatch("Hello", "Hello World");
	constant str_imatch_result6						: boolean		:= str_imatch("Hello", "Hello" & (1 to 3 => C_POC_NUL));

begin
	procChecker : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Checker");
	begin
		-- raw_format_slv_dec tests
		simAssertion((raw_format_slv_dec_result0 = "18"),										"raw_format_slv_dec(0x12)="								& raw_format_slv_dec_result0	&	"    Expected='18'");
		simAssertion((raw_format_slv_dec_result1 = "13398"),								"raw_format_slv_dec(0x3456)="							& raw_format_slv_dec_result1	&	"    Expected='13398'");
		simAssertion((raw_format_slv_dec_result2 = "305419896"),						"raw_format_slv_dec(0x12345678)="					& raw_format_slv_dec_result2	&	"    Expected='305419896'");
		simAssertion((raw_format_slv_dec_result3 = "11651590505119483816"),	"raw_format_slv_dec(0xA1b2c3d4e5f607a8)="	& raw_format_slv_dec_result3	&	"    Expected='11651590505119483816'");

		-- str_length tests
		simAssertion((str_length_result0 = 0),			"str_length('')="											& integer'image(str_length_result0)	& "  Expected=0");
		simAssertion((str_length_result1 = 0),			"str_length('\0\0\0')="								& integer'image(str_length_result1)	& "  Expected=0");
		simAssertion((str_length_result2 = 5),			"str_length('Hello')="								& integer'image(str_length_result2)	& "  Expected=5");
		simAssertion((str_length_result3 = 5),			"str_length('Hello\0\0\0')="					& integer'image(str_length_result3)	& "  Expected=5");

		-- str_match tests
		simAssertion((str_match_result0 = TRUE),		"str_match('', '')="									& boolean'image(str_match_result0)	& "  Expected=TRUE");
		simAssertion((str_match_result1 = TRUE),		"str_match('', '\0\0\0')="						& boolean'image(str_match_result1)	& "  Expected=TRUE");
		simAssertion((str_match_result2 = FALSE),		"str_match('Hello', 'hello')="				& boolean'image(str_match_result2)	& "  Expected=FALSE");
		simAssertion((str_match_result3 = TRUE),		"str_match('Hello', 'Hello')="				& boolean'image(str_match_result3)	& "  Expected=TRUE");
		simAssertion((str_match_result4 = FALSE),		"str_match('Hello World', 'Hello')="	& boolean'image(str_match_result4)	& "  Expected=FALSE");
		simAssertion((str_match_result5 = FALSE),		"str_match('Hello', 'Hello World')="	& boolean'image(str_match_result5)	& "  Expected=FALSE");
		simAssertion((str_match_result6 = TRUE),		"str_match('Hello', 'Hello\0\0\0')="	& boolean'image(str_match_result6)	& "  Expected=TRUE");

		-- str_imatch tests
		simAssertion((str_imatch_result0 = TRUE),		"str_imatch('', '')="									& boolean'image(str_imatch_result0) & "  Expected=TRUE");
		simAssertion((str_imatch_result1 = TRUE),		"str_imatch('', '\0\0\0')="						& boolean'image(str_imatch_result1) & "  Expected=TRUE");
		simAssertion((str_imatch_result2 = TRUE),		"str_imatch('Hello', 'hello')="				& boolean'image(str_imatch_result2) & "  Expected=TRUE");
		simAssertion((str_imatch_result3 = TRUE),		"str_imatch('Hello', 'Hello')="				& boolean'image(str_imatch_result3) & "  Expected=TRUE");
		simAssertion((str_imatch_result4 = FALSE),	"str_imatch('Hello World', 'Hello')="	& boolean'image(str_imatch_result4) & "  Expected=FALSE");
		simAssertion((str_imatch_result5 = FALSE),	"str_imatch('Hello', 'Hello World')="	& boolean'image(str_imatch_result5) & "  Expected=FALSE");
		simAssertion((str_imatch_result6 = TRUE),		"str_imatch('Hello', 'Hello\0\0\0')="	& boolean'image(str_imatch_result6) & "  Expected=TRUE");

		-- str_pos tests
		-- str_ipos tests
		-- str_find tests
		-- str_ifind tests
		-- str_replace tests
		-- str_substr tests
		-- str_ltrim tests
		-- str_rtrim tests
		-- str_trim tests
		-- str_toLower tests
		-- str_toUpper tests

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;
end architecture;
