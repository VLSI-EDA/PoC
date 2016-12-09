-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					Sorting Network: Stream to sortnet adapter
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
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.components.all;
use			PoC.sortnet.all;


entity sortnet_Stream_Adapter2 is
	generic (
		STREAM_DATA_BITS			: positive				:= 32;
		STREAM_META_BITS			: positive				:= 2;
		DATA_COLUMNS					: positive				:= 2;
		SORTNET_IMPL					: T_SORTNET_IMPL	:= SORT_SORTNET_IMPL_ODDEVEN_MERGESORT;
		SORTNET_SIZE					: positive				:= 32;
		SORTNET_KEY_BITS			: positive				:= 32;
		SORTNET_DATA_BITS			: natural					:= 32;
		SORTNET_REG_AFTER			: natural					:= 2;
		MERGENET_STAGES				: positive				:= 2
	);
	port (
		Clock				: in	std_logic;
		Reset				: in	std_logic;

		Inverse			: in	std_logic				:= '0';

		In_Valid		: in	std_logic;
		In_Data			: in	std_logic_vector(STREAM_DATA_BITS - 1 downto 0);
		In_Meta			: in	std_logic_vector(STREAM_META_BITS - 1 downto 0);
		In_SOF			: in	std_logic;
		In_IsKey		: in	std_logic;
		In_EOF			: in	std_logic;
		In_Ack			: out	std_logic;

		Out_Valid		: out	std_logic;
		Out_Data		: out	std_logic_vector(STREAM_DATA_BITS - 1 downto 0);
		Out_Meta		: out	std_logic_vector(STREAM_META_BITS - 1 downto 0);
		Out_SOF			: out	std_logic;
		Out_IsKey		: out	std_logic;
		Out_EOF			: out	std_logic;
		Out_Ack			: in	std_logic
	);
end entity;


architecture rtl of sortnet_Stream_Adapter2 is
	constant C_VERBOSE							: boolean			:= FALSE;

	constant GEARBOX_BITS						: positive		:= SORTNET_SIZE * SORTNET_DATA_BITS;
	constant TRANSFORM_BITS					: positive		:= DATA_COLUMNS * SORTNET_DATA_BITS;
	constant MERGE_BITS							: positive		:= TRANSFORM_BITS;

	constant META_ISKEY_BIT					: natural			:= 0;
	constant META_BITS							: positive		:= STREAM_META_BITS + 1;

	signal Synchronized_r						: std_logic		:= '0';

	signal SyncIn										: std_logic;
	signal MetaIn										: std_logic_vector(META_BITS - 1 downto 0);

	signal gearup_Sync							: std_logic;
	signal gearup_Valid							: std_logic;
	signal gearup_Data							: std_logic_vector(GEARBOX_BITS - 1 downto 0);
	signal gearup_Meta							: std_logic_vector(META_BITS - 1 downto 0);
	signal gearup_First							: std_logic;
	signal gearup_Last							: std_logic;

	signal sort_Valid								: std_logic;
	signal sort_IsKey								: std_logic;
	signal sort_Data								: std_logic_vector(GEARBOX_BITS - 1 downto 0);
	signal sort_Meta								: std_logic_vector(STREAM_META_BITS - 1 downto 0);

	signal transform_Valid					: std_logic;
	signal transform_Data						: std_logic_vector(TRANSFORM_BITS - 1 downto 0);
	signal transform_Meta						: std_logic_vector(STREAM_META_BITS - 1 downto 0);
	signal transform_SOF						: std_logic;
	signal transform_EOF						: std_logic;

	signal merge_Sync								: std_logic;
	signal merge_Valid							: std_logic;
	signal merge_Data								: std_logic_vector(MERGE_BITS - 1 downto 0);
	signal merge_Meta								: std_logic_vector(STREAM_META_BITS - 1 downto 0);
	signal merge_SOF								: std_logic;
	signal merge_EOF								: std_logic;
	signal merge_Ack								: std_logic;

	signal geardown_nxt							: std_logic;
	signal geardown_Meta						: std_logic_vector(STREAM_META_BITS - 1 downto 0);
	signal geardown_First						: std_logic;
	signal geardown_Last						: std_logic;
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

	genOES : if SORTNET_IMPL = SORT_SORTNET_IMPL_ODDEVEN_SORT generate
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


	genOEMS : if SORTNET_IMPL = SORT_SORTNET_IMPL_ODDEVEN_MERGESORT generate
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


	genBS : if SORTNET_IMPL = SORT_SORTNET_IMPL_BITONIC_SORT generate
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
		subtype T_MERGE_DATA				is std_logic_vector(TRANSFORM_BITS - 1 downto 0);
		type		T_MERGE_DATA_VECTOR	is array(natural range <>) of T_MERGE_DATA;

		signal MergeSortMatrix_Valid					: std_logic_vector(MERGENET_STAGES downto 0);
		signal MergeSortMatrix_Data						: T_MERGE_DATA_VECTOR(MERGENET_STAGES downto 0);
		signal MergeSortMatrix_SOF						: std_logic_vector(MERGENET_STAGES downto 0);
		signal MergeSortMatrix_EOF						: std_logic_vector(MERGENET_STAGES downto 0);
		signal MergeSortMatrix_Ack						: std_logic_vector(MERGENET_STAGES downto 0);
	begin
		MergeSortMatrix_Valid(0)	<= transform_Valid;
		MergeSortMatrix_Data(0)		<= transform_Data;
		MergeSortMatrix_SOF(0)		<= transform_SOF;
		MergeSortMatrix_EOF(0)		<= transform_EOF;
		merge_Ack									<= MergeSortMatrix_Ack(0);

		genMerge : for i in 0 to MERGENET_STAGES - 1 generate
			constant FIFO_DEPTH		: positive	:= 2**i * SORTNET_SIZE;
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
