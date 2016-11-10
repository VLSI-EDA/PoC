-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					Sorting Network: Odd-Even-Sort (Transposition)
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
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
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.components.all;


entity sortnet_OddEvenSort is
	generic (
		INPUTS								: positive	:= 8;			-- input count
		KEY_BITS							: positive	:= 32;		-- the first KEY_BITS of In_Data are used as a sorting critera (key)
		DATA_BITS							: positive	:= 32;		-- inclusive KEY_BITS
		META_BITS							: natural		:= 2;			-- additional bits, not sorted but delayed as long as In_Data
		PIPELINE_STAGE_AFTER	: natural		:= 2;			-- add a pipline stage after n sorting stages
		ADD_INPUT_REGISTERS		: boolean		:= FALSE;	--
		ADD_OUTPUT_REGISTERS	: boolean		:= TRUE		--
	);
	port (
		Clock				: in	std_logic;
		Reset				: in	std_logic;

		Inverse			: in	std_logic		:= '0';

		In_Valid		: in	std_logic;
		In_IsKey		: in	std_logic;
		In_Data			: in	T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0);
		In_Meta			: in	std_logic_vector(META_BITS - 1 downto 0);

		Out_Valid		: out	std_logic;
		Out_IsKey		: out	std_logic;
		Out_Data		: out	T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0);
		Out_Meta		: out	std_logic_vector(META_BITS - 1 downto 0)
	);
end entity;


architecture rtl of sortnet_OddEvenSort is
	constant C_VERBOSE				: boolean			:= POC_VERBOSE;

	constant STAGES						: positive		:= INPUTS;
	constant DELAY						: positive		:= (STAGES	/ PIPELINE_STAGE_AFTER) + ite(ADD_INPUT_REGISTERS, 1, 0) + ite(ADD_OUTPUT_REGISTERS, 1, 0);

	constant META_VALID_BIT		: natural			:= 0;
	constant META_ISKEY_BIT		: natural			:= 1;
	constant META_VECTOR_BITS	: positive		:= META_BITS + 2;

	subtype T_META				is std_logic_vector(META_VECTOR_BITS - 1 downto 0);
	type		T_META_VECTOR	is array(natural range <>) of T_META;

	subtype T_DATA				is std_logic_vector(DATA_BITS - 1 downto 0);
	type		T_DATA_VECTOR	is array(natural range <>) of T_DATA;
	type		T_DATA_MATRIX	is array(natural range <>) of T_DATA_VECTOR(INPUTS - 1 downto 0);

	function to_dv(slm : T_SLM) return T_DATA_VECTOR is
		variable Result	: T_DATA_VECTOR(slm'range(1));
	begin
		for i in slm'range(1) loop
			for j in slm'high(2) downto slm'low(2) loop
				Result(i)(j)	:= slm(i, j);
			end loop;
		end loop;
		return Result;
	end function;

	function to_slm(dv : T_DATA_VECTOR) return T_SLM is
		variable Result	: T_SLM(dv'range, T_DATA'range);
	begin
		for i in dv'range loop
			for j in T_DATA'range loop
				Result(i, j)	:= dv(i)(j);
			end loop;
		end loop;
		return Result;
	end function;

	signal In_Valid_d			: std_logic																						:= '0';
	signal In_IsKey_d			: std_logic																						:= '0';
	signal In_Data_d			: T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0)	:= (others => (others => '0'));
	signal In_Meta_d			: std_logic_vector(META_BITS - 1 downto 0)						:= (others => '0');

	signal MetaVector			: T_META_VECTOR(STAGES downto 0)											:= (others => (others => '0'));
	signal DataMatrix			: T_DATA_MATRIX(STAGES downto 0)											:= (others => (others => (others => '0')));

	signal MetaOutputs_d	: T_META																							:= (others => '0');
	signal DataOutputs_d	: T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0)	:= (others => (others => '0'));

begin
	assert (not C_VERBOSE)
		report "sortnet_OddEvenSort:" & LF &
					 "  DATA_BITS=" & integer'image(DATA_BITS) &
					 "  KEY_BITS=" & integer'image(KEY_BITS) &
					 "  META_BITS=" & integer'image(META_BITS)
		severity NOTE;

	In_Valid_d	<= In_Valid	when registered(Clock, ADD_INPUT_REGISTERS);
	In_IsKey_d	<= In_IsKey	when registered(Clock, ADD_INPUT_REGISTERS);
	In_Data_d		<= In_Data	when registered(Clock, ADD_INPUT_REGISTERS);
	In_Meta_d		<= In_Meta	when registered(Clock, ADD_INPUT_REGISTERS);

	DataMatrix(0)																														<= to_dv(In_Data_d);
	MetaVector(0)(META_VALID_BIT)																						<= In_Valid_d;
	MetaVector(0)(META_ISKEY_BIT)																						<= In_IsKey_d;
	MetaVector(0)(META_VECTOR_BITS - 1 downto META_VECTOR_BITS - META_BITS)	<= In_Meta_d;

	genStages : for stage in 0 to STAGES - 1 generate
		constant STAGE_INDEX							: natural	:= stage;
		constant INSERT_PIPELINE_REGISTER : boolean	:= ((PIPELINE_STAGE_AFTER > 0) and (STAGE_INDEX mod PIPELINE_STAGE_AFTER = 0));
	begin
		assert (not C_VERBOSE) report "STAGE_INDEX: " & integer'image(STAGE_INDEX) & "  reg=" & BOOLEAN'image(INSERT_PIPELINE_REGISTER) severity NOTE;

		MetaVector(STAGE_INDEX + 1)		<= MetaVector(STAGE_INDEX) when registered(Clock, INSERT_PIPELINE_REGISTER);

		genEven : if (STAGE_INDEX mod 2 = 0) generate
			genEvenSwitch : for i in 0 to (INPUTS / 2) - 1 generate
				constant SRC0	: natural		:= 2 * i;
				constant SRC1	: natural		:= SRC0 + 1;

				signal Greater		: std_logic;
				signal Switch_d		: std_logic;
				signal Switch_en	: std_logic;
				signal Switch_r		: std_logic		:= '0';
				signal Switch			: std_logic;
				signal NewData0		: T_DATA;
				signal NewData1		: T_DATA;
			begin
				assert (not C_VERBOSE) report integer'image(STAGE_INDEX) & ": " & INTEGER'image(SRC0) & " <-> " & integer'image(SRC1) severity NOTE;

				Greater		<= to_sl(unsigned(DataMatrix(STAGE_INDEX)(SRC0)(KEY_BITS - 1 downto 0)) > unsigned(DataMatrix(STAGE_INDEX)(SRC1)(KEY_BITS - 1 downto 0)));
				Switch_d	<= Greater xor Inverse;
				Switch_en	<= MetaVector(STAGE_INDEX)(META_ISKEY_BIT) and MetaVector(STAGE_INDEX)(META_VALID_BIT);
				Switch_r	<= ffdre(q => Switch_r, d => Switch_d, en => Switch_en) when rising_edge(Clock);
				Switch		<= mux(Switch_en, Switch_r, Switch_d);

				NewData0		<= mux(Switch, DataMatrix(STAGE_INDEX)(SRC0), DataMatrix(STAGE_INDEX)(SRC1));
				NewData1		<= mux(Switch, DataMatrix(STAGE_INDEX)(SRC1), DataMatrix(STAGE_INDEX)(SRC0));

				DataMatrix(STAGE_INDEX + 1)(SRC0)		<= NewData0 when registered(Clock, INSERT_PIPELINE_REGISTER);
				DataMatrix(STAGE_INDEX + 1)(SRC1)		<= NewData1 when registered(Clock, INSERT_PIPELINE_REGISTER);
			end generate;
		end generate;
		genOdd : if (STAGE_INDEX mod 2 = 1) generate
			DataMatrix(STAGE_INDEX + 1)(0)					<= DataMatrix(STAGE_INDEX)(0)						when registered(Clock, INSERT_PIPELINE_REGISTER);
			DataMatrix(STAGE_INDEX + 1)(INPUTS - 1)	<= DataMatrix(STAGE_INDEX)(INPUTS - 1)	when registered(Clock, INSERT_PIPELINE_REGISTER);

			genOddSwitch : for i in 0 to ((INPUTS - 1) / 2) - 1 generate
				constant SRC0	: natural		:= 2 * i + 1;
				constant SRC1	: natural		:= SRC0 + 1;

				signal Greater		: std_logic;
				signal Switch_d		: std_logic;
				signal Switch_en	: std_logic;
				signal Switch_r		: std_logic		:= '0';
				signal Switch			: std_logic;
				signal NewData0		: T_DATA;
				signal NewData1		: T_DATA;
			begin
				assert (not C_VERBOSE) report integer'image(STAGE_INDEX) & ": " & INTEGER'image(SRC0) & " <-> " & integer'image(SRC1) severity NOTE;

				Greater		<= to_sl(unsigned(DataMatrix(STAGE_INDEX)(SRC0)(KEY_BITS - 1 downto 0)) > unsigned(DataMatrix(STAGE_INDEX)(SRC1)(KEY_BITS - 1 downto 0)));
				Switch_d	<= Greater xor Inverse;
				Switch_en	<= MetaVector(STAGE_INDEX)(META_ISKEY_BIT) and MetaVector(STAGE_INDEX)(META_VALID_BIT);
				Switch_r	<= ffdre(q => Switch_r, d => Switch_d, en => Switch_en) when rising_edge(Clock);
				Switch		<= mux(Switch_en, Switch_r, Switch_d);

				NewData0		<= mux(Switch, DataMatrix(STAGE_INDEX)(SRC0), DataMatrix(STAGE_INDEX)(SRC1));
				NewData1		<= mux(Switch, DataMatrix(STAGE_INDEX)(SRC1), DataMatrix(STAGE_INDEX)(SRC0));

				DataMatrix(STAGE_INDEX + 1)(SRC0)		<= NewData0	when registered(Clock, INSERT_PIPELINE_REGISTER);
				DataMatrix(STAGE_INDEX + 1)(SRC1)		<= NewData1	when registered(Clock, INSERT_PIPELINE_REGISTER);
			end generate;
		end generate;
	end generate;

	MetaOutputs_d		<= MetaVector(STAGES)					when registered(Clock, ADD_OUTPUT_REGISTERS);
	DataOutputs_d		<= to_slm(DataMatrix(STAGES))	when registered(Clock, ADD_OUTPUT_REGISTERS);

	Out_Valid				<= MetaOutputs_d(META_VALID_BIT);
	Out_IsKey				<= MetaOutputs_d(META_ISKEY_BIT);
	Out_Data				<= DataOutputs_d;
	Out_Meta				<= MetaOutputs_d(META_VECTOR_BITS - 1 downto META_VECTOR_BITS - META_BITS);
end architecture;
