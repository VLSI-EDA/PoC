-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Module:					Sorting Network: Stream to sortnet adapter
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
use			PoC.sortnet.all;


entity sortnet_Stream_Adapter2 is
	generic (
		STREAM_DATA_BITS			: POSITIVE				:= 32;
		STREAM_META_BITS			: POSITIVE				:= 2;
		DATA_COLUMNS					: POSITIVE				:= 2;
		SORTNET_IMPL					: T_SORTNET_IMPL	:= SORT_SORTNET_IMPL_ODDEVEN_MERGESORT;
		SORTNET_SIZE					: POSITIVE				:= 32;
		SORTNET_KEY_BITS			: POSITIVE				:= 32;
		SORTNET_DATA_BITS			: NATURAL					:= 32;
		SORTNET_REG_AFTER			: NATURAL					:= 2;
		MERGENET_STAGES				: POSITIVE				:= 2
	);
	port (
		Clock				: in	STD_LOGIC;
		Reset				: in	STD_LOGIC;
				
		Inverse			: in	STD_LOGIC				:= '0';
		
		In_Valid		: in	STD_LOGIC;
		In_Data			: in	STD_LOGIC_VECTOR(STREAM_DATA_BITS - 1 downto 0);
		In_Meta			: in	STD_LOGIC_VECTOR(STREAM_META_BITS - 1 downto 0);
		In_SOF			: in	STD_LOGIC;
		In_IsKey		: in	STD_LOGIC;
		In_EOF			: in	STD_LOGIC;
		In_Ack			: out	STD_LOGIC;
		
		Out_Valid		: out	STD_LOGIC;
		Out_Data		: out	STD_LOGIC_VECTOR(STREAM_DATA_BITS - 1 downto 0);
		Out_Meta		: out	STD_LOGIC_VECTOR(STREAM_META_BITS - 1 downto 0);
		Out_SOF			: out	STD_LOGIC;
		Out_IsKey		: out	STD_LOGIC;
		Out_EOF			: out	STD_LOGIC;
		Out_Ack			: in	STD_LOGIC
	);
end entity;


architecture rtl of sortnet_Stream_Adapter2 is
	constant C_VERBOSE							: BOOLEAN			:= FALSE;
	
	constant GEARBOX_BITS						: POSITIVE		:= SORTNET_SIZE * SORTNET_DATA_BITS;
	constant TRANSFORM_BITS					: POSITIVE		:= DATA_COLUMNS * SORTNET_DATA_BITS;
	constant MERGE_BITS							: POSITIVE		:= TRANSFORM_BITS;
	
	constant META_ISKEY_BIT					: NATURAL			:= 0;
	constant META_BITS							: POSITIVE		:= STREAM_META_BITS + 1;
	
	signal Synchronized_r						: STD_LOGIC		:= '0';
	
	signal SyncIn										: STD_LOGIC;
	signal MetaIn										: STD_LOGIC_VECTOR(META_BITS - 1 downto 0);
	
	signal gearup_Sync							: STD_LOGIC;
	signal gearup_Valid							: STD_LOGIC;
	signal gearup_Data							: STD_LOGIC_VECTOR(GEARBOX_BITS - 1 downto 0);
	signal gearup_Meta							: STD_LOGIC_VECTOR(META_BITS - 1 downto 0);
	signal gearup_First							: STD_LOGIC;
	signal gearup_Last							: STD_LOGIC;
	
	signal sort_Valid								: STD_LOGIC;
	signal sort_IsKey								: STD_LOGIC;
	signal sort_Data								: STD_LOGIC_VECTOR(GEARBOX_BITS - 1 downto 0);
	signal sort_Meta								: STD_LOGIC_VECTOR(STREAM_META_BITS - 1 downto 0);
	
	signal transform_Valid					: STD_LOGIC;
	signal transform_Data						: STD_LOGIC_VECTOR(TRANSFORM_BITS - 1 downto 0);
	signal transform_Meta						: STD_LOGIC_VECTOR(STREAM_META_BITS - 1 downto 0);
	signal transform_SOF						: STD_LOGIC;
	signal transform_EOF						: STD_LOGIC;
	
	signal merge_Sync								: STD_LOGIC;
	signal merge_Valid							: STD_LOGIC;
	signal merge_Data								: STD_LOGIC_VECTOR(MERGE_BITS - 1 downto 0);
	signal merge_Meta								: STD_LOGIC_VECTOR(STREAM_META_BITS - 1 downto 0);
	signal merge_SOF								: STD_LOGIC;
	signal merge_EOF								: STD_LOGIC;
	signal merge_Ack								: STD_LOGIC;
	
	signal geardown_nxt							: STD_LOGIC;
	signal geardown_Meta						: STD_LOGIC_VECTOR(STREAM_META_BITS - 1 downto 0);
	signal geardown_First						: STD_LOGIC;
	signal geardown_Last						: STD_LOGIC;
begin

	In_Ack	<= '1';

	Synchronized_r	<= ffrs(q => Synchronized_r, set => (In_SOF and In_Valid), rst => Reset) when rising_edge(Clock);
	
	SyncIn																										<= (In_SOF and In_Valid) and not Synchronized_r;
	MetaIn(META_ISKEY_BIT)																		<= In_IsKey;
	MetaIn(META_BITS - 1 downto META_BITS - STREAM_META_BITS)	<= In_Meta;
	
	gearup : entity PoC.gearbox_up_cc
		generic map (
			INPUT_BITS						=> STREAM_DATA_BITS,
			OUTPUT_BITS						=> GEARBOX_BITS,
			META_BITS							=> META_BITS,
			ADD_INPUT_REGISTERS		=> TRUE,
			ADD_OUTPUT_REGISTERS	=> FALSE
		)
		port map (
			Clock				=> Clock,
			
			In_Sync			=> SyncIn,
			In_Data			=> In_Data,
			In_Meta			=> MetaIn,
			In_Valid		=> In_Valid,
			Out_Sync		=> gearup_Sync,
			Out_Valid		=> gearup_Valid,
			Out_Data		=> gearup_Data,
			Out_Meta		=> gearup_Meta,
			Out_First		=> gearup_First,
			Out_Last		=> gearup_Last
		);

	genOES : if (SORTNET_IMPL = SORT_SORTNET_IMPL_ODDEVEN_SORT) generate
		signal DataInputMatrix	: T_SLM(SORTNET_SIZE - 1 downto 0, SORTNET_DATA_BITS - 1 downto 0);
		signal DataOutputMatrix	: T_SLM(SORTNET_SIZE - 1 downto 0, SORTNET_DATA_BITS - 1 downto 0);

	begin
		DataInputMatrix		<= to_slm(gearup_Data, SORTNET_SIZE, SORTNET_DATA_BITS);
		-- MetaInputMatric		<= 
		-- mux(gearup_Valid, (SORTNET_SIZE * SORTNET_DATA_BITS downto 1 => 'U'), gearup_Data)
		
		sort : entity PoC.sortnet_OddEvenSort
			generic map (
				INPUTS								=> SORTNET_SIZE,
				KEY_BITS							=> SORTNET_KEY_BITS,
				DATA_BITS							=> SORTNET_DATA_BITS,
				META_BITS							=> STREAM_META_BITS,
				PIPELINE_STAGE_AFTER	=> SORTNET_REG_AFTER,
				ADD_OUTPUT_REGISTERS	=> FALSE
			)
			port map (
				Clock				=> Clock,
				Reset				=> Reset,
				
				Inverse			=> Inverse,
				
				In_Valid		=> gearup_Valid,
				In_IsKey		=> gearup_Meta(META_ISKEY_BIT),
				In_Data			=> DataInputMatrix,
				In_Meta			=> gearup_Meta(META_BITS - 1 downto META_BITS - STREAM_META_BITS),
				
				Out_Valid		=> sort_Valid,
				Out_IsKey		=> sort_IsKey,
				Out_Data		=> DataOutputMatrix,
				Out_Meta		=> sort_Meta
			);
		
		sort_Data		<= to_slv(DataOutputMatrix);
	end generate;
	
	
	genOEMS : if (SORTNET_IMPL = SORT_SORTNET_IMPL_ODDEVEN_MERGESORT) generate
		signal DataInputMatrix	: T_SLM(SORTNET_SIZE - 1 downto 0, SORTNET_DATA_BITS - 1 downto 0);
		signal DataOutputMatrix	: T_SLM(SORTNET_SIZE - 1 downto 0, SORTNET_DATA_BITS - 1 downto 0);

	begin
		DataInputMatrix	<= to_slm(gearup_Data, SORTNET_SIZE, SORTNET_DATA_BITS);
		
		sort : entity PoC.sortnet_OddEvenMergeSort
			generic map (
				INPUTS								=> SORTNET_SIZE,
				KEY_BITS							=> SORTNET_KEY_BITS,
				DATA_BITS							=> SORTNET_DATA_BITS,
				META_BITS							=> STREAM_META_BITS,
				PIPELINE_STAGE_AFTER	=> SORTNET_REG_AFTER,
				ADD_OUTPUT_REGISTERS	=> FALSE
			)
			port map (
				Clock				=> Clock,
				Reset				=> Reset,
				
				Inverse			=> Inverse,
				
				In_Valid		=> gearup_Valid,
				In_IsKey		=> gearup_Meta(META_ISKEY_BIT),
				In_Data			=> DataInputMatrix,
				In_Meta			=> gearup_Meta(META_BITS - 1 downto META_BITS - STREAM_META_BITS),
				
				Out_Valid		=> sort_Valid,
				Out_IsKey		=> sort_IsKey,
				Out_Data		=> DataOutputMatrix,
				Out_Meta		=> sort_Meta
			);
		
		sort_Data		<= to_slv(DataOutputMatrix);
	end generate;

	
	genBS : if (SORTNET_IMPL = SORT_SORTNET_IMPL_BITONIC_SORT) generate
		signal DataInputMatrix	: T_SLM(SORTNET_SIZE - 1 downto 0, SORTNET_DATA_BITS - 1 downto 0);
		signal DataOutputMatrix	: T_SLM(SORTNET_SIZE - 1 downto 0, SORTNET_DATA_BITS - 1 downto 0);

	begin
		DataInputMatrix	<= to_slm(gearup_Data, SORTNET_SIZE, SORTNET_DATA_BITS);
		
		sort : entity PoC.sortnet_BitonicSort
			generic map (
				INPUTS								=> SORTNET_SIZE,
				KEY_BITS							=> SORTNET_KEY_BITS,
				DATA_BITS							=> SORTNET_DATA_BITS,
				META_BITS							=> STREAM_META_BITS,
				PIPELINE_STAGE_AFTER	=> SORTNET_REG_AFTER,
				ADD_OUTPUT_REGISTERS	=> FALSE
			)
			port map (
				Clock				=> Clock,
				Reset				=> Reset,
				
				Inverse			=> Inverse,
				
				In_Valid		=> gearup_Valid,
				In_IsKey		=> gearup_Meta(META_ISKEY_BIT),
				In_Data			=> DataInputMatrix,
				In_Meta			=> gearup_Meta(META_BITS - 1 downto META_BITS - STREAM_META_BITS),
				
				Out_Valid		=> sort_Valid,
				Out_IsKey		=> sort_IsKey,
				Out_Data		=> DataOutputMatrix,
				Out_Meta		=> sort_Meta
			);
		
		sort_Data		<= to_slv(DataOutputMatrix);
	end generate;
	
	blkTransform : block
		signal DataInputMatrix	: T_SLM(SORTNET_SIZE - 1 downto 0, SORTNET_DATA_BITS - 1 downto 0);
		signal DataOutputMatrix	: T_SLM(DATA_COLUMNS - 1 downto 0, SORTNET_DATA_BITS - 1 downto 0);

	begin
		DataInputMatrix	<= to_slm(sort_Data, SORTNET_SIZE, SORTNET_DATA_BITS);
	
		transform : entity PoC.sortnet_Transform
			generic map (
				ROWS				=> SORTNET_SIZE,
				COLUMNS			=> DATA_COLUMNS,
				DATA_BITS		=> SORTNET_DATA_BITS
			)
			port map (
				Clock				=> Clock,
				Reset				=> Reset,
				
				-- In_Sync		=> '0',
				In_Valid	=> sort_Valid,
				In_Data		=> DataInputMatrix,
				In_SOF		=> sort_IsKey,
				In_EOF		=> '0',
				
				Out_Valid	=> transform_Valid,
				Out_Data	=> DataOutputMatrix,
				Out_SOF		=> transform_SOF,
				Out_EOF		=> transform_EOF
			);
		
		transform_Data <= to_slv(DataOutputMatrix);
	end block;
	
	blkMergeSort : block
		subtype T_MERGE_DATA				is STD_LOGIC_VECTOR(TRANSFORM_BITS - 1 downto 0);
		type		T_MERGE_DATA_VECTOR	is array(NATURAL range <>) of T_MERGE_DATA;
		
		signal MergeSortMatrix_Valid					: STD_LOGIC_VECTOR(MERGENET_STAGES downto 0);
		signal MergeSortMatrix_Data						: T_MERGE_DATA_VECTOR(MERGENET_STAGES downto 0);
		signal MergeSortMatrix_SOF						: STD_LOGIC_VECTOR(MERGENET_STAGES downto 0);
		signal MergeSortMatrix_EOF						: STD_LOGIC_VECTOR(MERGENET_STAGES downto 0);
		signal MergeSortMatrix_Ack						: STD_LOGIC_VECTOR(MERGENET_STAGES downto 0);
	begin
		MergeSortMatrix_Valid(0)	<= transform_Valid;
		MergeSortMatrix_Data(0)		<= transform_Data;
		MergeSortMatrix_SOF(0)		<= transform_SOF;
		MergeSortMatrix_EOF(0)		<= transform_EOF;
		merge_Ack									<= MergeSortMatrix_Ack(0);
	
		genMerge : for i in 0 to MERGENET_STAGES - 1 generate
			constant FIFO_DEPTH		: POSITIVE	:= 2**i * SORTNET_SIZE;
		begin
			merge : entity PoC.sortnet_MergeSort_Streamed
				generic map (
					FIFO_DEPTH	=> FIFO_DEPTH,
					KEY_BITS		=> SORTNET_KEY_BITS,
					DATA_BITS		=> MERGE_BITS
				)
				port map (
					Clock				=> Clock,
					Reset				=> Reset,
					
					Inverse			=> Inverse,
				
					In_Valid		=> MergeSortMatrix_Valid(i),
					In_Data			=> MergeSortMatrix_Data(i),
					In_SOF			=> MergeSortMatrix_SOF(i),
					In_IsKey		=> '1',
					In_EOF			=> MergeSortMatrix_EOF(i),
					In_Ack			=> MergeSortMatrix_Ack(i),
					
					Out_Valid		=> MergeSortMatrix_Valid(i + 1),
					Out_Data		=> MergeSortMatrix_Data(i + 1),
					Out_SOF			=> MergeSortMatrix_SOF(i + 1),
					Out_IsKey		=> open,
					Out_EOF			=> MergeSortMatrix_EOF(i + 1),
					Out_Ack			=> MergeSortMatrix_Ack(i + 1)
				);
		end generate;
		
		merge_Valid														<= MergeSortMatrix_Valid(MERGENET_STAGES);
		merge_Data														<= MergeSortMatrix_Data(MERGENET_STAGES);
		merge_Meta														<= (others => 'U');
		merge_SOF															<= MergeSortMatrix_SOF(MERGENET_STAGES);
		merge_EOF															<= MergeSortMatrix_EOF(MERGENET_STAGES);
		MergeSortMatrix_Ack(MERGENET_STAGES)	<= geardown_nxt;
	end block;
	
	merge_Sync		<= merge_SOF and merge_Valid;
	
	geardown : entity PoC.gearbox_down_cc
		generic map (
			INPUT_BITS						=> MERGE_BITS,
			OUTPUT_BITS						=> STREAM_DATA_BITS,
			META_BITS							=> STREAM_META_BITS,
			ADD_INPUT_REGISTERS		=> TRUE,
			ADD_OUTPUT_REGISTERS	=> FALSE
		)
		port map (
			Clock				=> Clock,
			
			In_Sync			=> merge_Sync,
			In_Valid		=> merge_Valid,
			In_Next			=> geardown_nxt,
			In_Data			=> merge_Data,
			In_Meta			=> merge_Meta,
			Out_Sync		=> open,
			Out_Valid		=> Out_Valid,
			Out_Data		=> Out_Data,
			Out_Meta		=> geardown_Meta,
			Out_First		=> geardown_First,
			Out_Last		=> geardown_Last
		);
	
	Out_Meta		<= geardown_Meta;
	Out_SOF			<= geardown_First and 'U';
	Out_EOF			<= geardown_Last and 'U';
end architecture;
