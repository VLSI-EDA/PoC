-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Patrick Lehmann
-- 
-- Module:				 	Sorting network: bitonic sort
--
-- Description:
-- ------------------------------------
--		This sorting network uses the 'bitonic sort' algorithm.
--
-- License:
-- ============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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
-- ============================================================================

library IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library PoC;
use			PoC.utils.all;
use			PoC.math.all;
use			PoC.vectors.all;
use			PoC.components.all;


entity sortnet_BitonicSort is
	generic (
		INPUTS								: POSITIVE	:= 8;
		KEY_BITS							: POSITIVE	:= 32;
		DATA_BITS							: POSITIVE	:= 8;
		PIPELINE_STAGE_AFTER	: NATURAL		:= 2
	);
	port (
		Clock				: in	STD_LOGIC;
		Reset				: in	STD_LOGIC;
		
		DataIn			: in	T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0);
		DataOut			: out	T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0)
	);
end entity;


architecture rtl of sortnet_BitonicSort is
	constant BLOCKS					: POSITIVE				:= log2ceil(INPUTS);
	constant STAGES					: POSITIVE				:= triangularNumber(BLOCKS);
	constant COMPARATORS		: POSITIVE				:= STAGES * (INPUTS / 2);
	
	subtype T_DATA					is STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);
	type		T_INPUT_VECTOR	is array(NATURAL range <>) of T_DATA;
	type		T_STAGE_VECTOR	is array(NATURAL range <>) of T_INPUT_VECTOR(INPUTS - 1 downto 0);

	signal DataMatrix			: T_STAGE_VECTOR(STAGES downto 0);
	signal DataOut_i			: T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0)	:= (others => (others => 'Z'));
	
begin
	genInputs : for i in 0 to INPUTS - 1 generate
		DataMatrix(0)(i)	<= get_row(DataIn, i);
	end generate;
	genBlocks : for b in 0 to BLOCKS - 1 generate
		constant START_DISTANCE		: POSITIVE	:= 2**b;
	begin
		genStage : for s in 0 to b generate
			constant STAGE_INDEX		: NATURAL		:= triangularNumber(b) + s;
			constant DISTANCE				: POSITIVE	:= 2**(b - s);
			constant GROUPS					: POSITIVE	:= INPUTS / (DISTANCE * 2);
		begin
			genGroups : for g in 0 to GROUPS - 1 generate
				constant INVERSE			: STD_LOGIC	:= to_sl(g / (2 ** s) mod 2 = 1);
			begin
				genLoop : for l in 0 to DISTANCE - 1 generate
					constant SRC0			: NATURAL		:= g * (DISTANCE * 2) + l;
					constant SRC1			: NATURAL		:= SRC0 + DISTANCE;
					
					signal Greater		: STD_LOGIC;
					signal Switch			: STD_LOGIC;
					signal NewData0		: T_DATA;
					signal NewData1		: T_DATA;
					
				begin
					Greater		<= to_sl(unsigned(DataMatrix(STAGE_INDEX)(SRC0)(KEY_BITS - 1 downto 0)) > unsigned(DataMatrix(STAGE_INDEX)(SRC1)(KEY_BITS - 1 downto 0)));
					Switch		<= Greater xor INVERSE;
	
					NewData0		<= mux(Switch, DataMatrix(STAGE_INDEX)(SRC0), DataMatrix(STAGE_INDEX)(SRC1));
					NewData1		<= mux(Switch, DataMatrix(STAGE_INDEX)(SRC1), DataMatrix(STAGE_INDEX)(SRC0));
	
					genNoReg : if ((PIPELINE_STAGE_AFTER = 0) or (STAGE_INDEX mod PIPELINE_STAGE_AFTER /= 0)) generate
						DataMatrix(STAGE_INDEX + 1)(SRC0)		<= NewData0;
						DataMatrix(STAGE_INDEX + 1)(SRC1)		<= NewData1;
					end generate;
					genReg : if ((PIPELINE_STAGE_AFTER /= 0) and (STAGE_INDEX mod PIPELINE_STAGE_AFTER = 0)) generate
						DataMatrix(STAGE_INDEX + 1)(SRC0)		<= NewData0	when rising_edge(Clock);
						DataMatrix(STAGE_INDEX + 1)(SRC1)		<= NewData1	when rising_edge(Clock);
					end generate;
				end generate;
			end generate;
		end generate;
	end generate;
	genOutputs : for i in 0 to INPUTS - 1 generate
		genLoop : for j in 0 to DATA_BITS - 1 generate
			DataOut(i, j)		<= DataMatrix(STAGES)(i)(j);
		end generate;
	end generate;
end architecture;
	