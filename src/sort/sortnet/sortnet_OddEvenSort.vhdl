-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Module:					Sorting Network: Odd-Even-Sort (Transposition)
--
-- Description:
-- ------------------------------------
--	TODO
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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
-- =============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.components.all;


entity sortnet_OddEvenSort is
	generic (
		INPUTS								: POSITIVE	:= 8;			-- input count
		KEY_BITS							: POSITIVE	:= 32;		-- the first KEY_BITS of In_Data are used as a sorting critera (key)
		DATA_BITS							: POSITIVE	:= 32;		-- inclusive KEY_BITS
		META_BITS							: NATURAL		:= 2;			-- additional bits, not sorted but delayed as long as In_Data
		PIPELINE_STAGE_AFTER	: NATURAL		:= 2;			-- add a pipline stage after n sorting stages
		ADD_INPUT_REGISTERS		: BOOLEAN		:= FALSE;	-- 
		ADD_OUTPUT_REGISTERS	: BOOLEAN		:= TRUE		-- 
	);
	port (
		Clock				: in	STD_LOGIC;
		Reset				: in	STD_LOGIC;
		
		Inverse			: in	STD_LOGIC		:= '0';
		
		In_Valid		: in	STD_LOGIC;
		In_IsKey		: in	STD_LOGIC;
		In_Data			: in	T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0);
		In_Meta			: in	STD_LOGIC_VECTOR(META_BITS - 1 downto 0);
		
		Out_Valid		: out	STD_LOGIC;
		Out_IsKey		: out	STD_LOGIC;
		Out_Data		: out	T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0);
		Out_Meta		: out	STD_LOGIC_VECTOR(META_BITS - 1 downto 0)
	);
end entity;


architecture rtl of sortnet_OddEvenSort is
	constant C_VERBOSE				: BOOLEAN			:= POC_VERBOSE;

	constant STAGES						: POSITIVE		:= INPUTS;
	constant DELAY						: POSITIVE		:= (STAGES	/ PIPELINE_STAGE_AFTER) + ite(ADD_INPUT_REGISTERS, 1, 0) + ite(ADD_OUTPUT_REGISTERS, 1, 0);

	constant META_VALID_BIT		: NATURAL			:= 0;
	constant META_ISKEY_BIT		: NATURAL			:= 1;
	constant META_VECTOR_BITS	: POSITIVE		:= META_BITS + 2;
	
	subtype T_META				is STD_LOGIC_VECTOR(META_VECTOR_BITS - 1 downto 0);
	type		T_META_VECTOR	is array(NATURAL range <>) of T_META;
	
	subtype T_DATA				is STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);
	type		T_DATA_VECTOR	is array(NATURAL range <>) of T_DATA;
	type		T_DATA_MATRIX	is array(NATURAL range <>) of T_DATA_VECTOR(INPUTS - 1 downto 0);

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
	
	signal In_Valid_d			: STD_LOGIC																						:= '0';
	signal In_IsKey_d			: STD_LOGIC																						:= '0';
	signal In_Data_d			: T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0)	:= (others => (others => '0'));
	signal In_Meta_d			: STD_LOGIC_VECTOR(META_BITS - 1 downto 0)						:= (others => '0');
	
	signal MetaVector			: T_META_VECTOR(STAGES downto 0)											:= (others => (others => '0'));
	signal DataMatrix			: T_DATA_MATRIX(STAGES downto 0)											:= (others => (others => (others => '0')));
	
	signal MetaOutputs_d	: T_META																							:= (others => '0');
	signal DataOutputs_d	: T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0)	:= (others => (others => '0'));
	
begin
	assert (not C_VERBOSE)
		report "sortnet_OddEvenSort:" & CR &
					 "  DATA_BITS=" & INTEGER'image(DATA_BITS) &
					 "  KEY_BITS=" & INTEGER'image(KEY_BITS) &
					 "  META_BITS=" & INTEGER'image(META_BITS)
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
		constant STAGE_INDEX							: NATURAL	:= stage;
		constant INSERT_PIPELINE_REGISTER : BOOLEAN	:= ((PIPELINE_STAGE_AFTER > 0) and (STAGE_INDEX mod PIPELINE_STAGE_AFTER = 0));
	begin
		assert (not C_VERBOSE) report "STAGE_INDEX: " & INTEGER'image(STAGE_INDEX) & "  reg=" & BOOLEAN'image(INSERT_PIPELINE_REGISTER) severity NOTE;
		
		MetaVector(STAGE_INDEX + 1)		<= MetaVector(STAGE_INDEX) when registered(Clock, INSERT_PIPELINE_REGISTER);
		
		genEven : if (STAGE_INDEX mod 2 = 0) generate
			genEvenSwitch : for i in 0 to (INPUTS / 2) - 1 generate
				constant SRC0	: NATURAL		:= 2 * i;
				constant SRC1	: NATURAL		:= SRC0 + 1;
						
				signal Greater		: STD_LOGIC;
				signal Switch_d		: STD_LOGIC;
				signal Switch_en	: STD_LOGIC;
				signal Switch_r		: STD_LOGIC		:= '0';
				signal Switch			: STD_LOGIC;
				signal NewData0		: T_DATA;
				signal NewData1		: T_DATA;
			begin
				assert (not C_VERBOSE) report INTEGER'image(STAGE_INDEX) & ": " & INTEGER'image(SRC0) & " <-> " & INTEGER'image(SRC1) severity NOTE;
	
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
				constant SRC0	: NATURAL		:= 2 * i + 1;
				constant SRC1	: NATURAL		:= SRC0 + 1;
						
				signal Greater		: STD_LOGIC;
				signal Switch_d		: STD_LOGIC;
				signal Switch_en	: STD_LOGIC;
				signal Switch_r		: STD_LOGIC		:= '0';
				signal Switch			: STD_LOGIC;
				signal NewData0		: T_DATA;
				signal NewData1		: T_DATA;
			begin
				assert (not C_VERBOSE) report INTEGER'image(STAGE_INDEX) & ": " & INTEGER'image(SRC0) & " <-> " & INTEGER'image(SRC1) severity NOTE;
	
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
