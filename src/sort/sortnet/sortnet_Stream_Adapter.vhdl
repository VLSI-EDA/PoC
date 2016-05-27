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


entity sortnet_Stream_Adapter is
	generic (
		STREAM_DATA_BITS			: POSITIVE				:= 32;
		STREAM_META_BITS			: POSITIVE				:= 2;
		SORTNET_IMPL					: T_SORTNET_IMPL	:= SORT_SORTNET_IMPL_ODDEVEN_MERGESORT;
		SORTNET_SIZE					: POSITIVE				:= 32;
		SORTNET_KEY_BITS			: POSITIVE				:= 32;
		SORTNET_DATA_BITS			: NATURAL					:= 32;
		INVERSE								: BOOLEAN					:= FALSE
	);
	port (
		Clock				: in	STD_LOGIC;
		Reset				: in	STD_LOGIC;

		In_Valid		: in	STD_LOGIC;
		In_IsKey		: in	STD_LOGIC;
		In_Data			: in	STD_LOGIC_VECTOR(STREAM_DATA_BITS - 1 downto 0);
		In_Meta			: in	STD_LOGIC_VECTOR(STREAM_META_BITS - 1 downto 0);
		In_Ack			: out	STD_LOGIC;

		Out_Valid		: out	STD_LOGIC;
		Out_IsKey		: out	STD_LOGIC;
		Out_Data		: out	STD_LOGIC_VECTOR(STREAM_DATA_BITS - 1 downto 0);
		Out_Meta		: out	STD_LOGIC_VECTOR(STREAM_META_BITS - 1 downto 0);
		Out_Ack			: in	STD_LOGIC
	);
end entity;


architecture rtl of sortnet_Stream_Adapter is
	constant C_VERBOSE							: BOOLEAN			:= FALSE;

	constant GEARBOX_BITS						: POSITIVE		:= SORTNET_SIZE * SORTNET_DATA_BITS;
	constant PIPELINE_STAGE_AFTER		: NATURAL			:= 2;

	constant META_ISKEY_BIT					: NATURAL			:= 0;
	constant META_BITS							: POSITIVE		:= STREAM_META_BITS + 1;

	signal MetaIn										: STD_LOGIC_VECTOR(META_BITS - 1 downto 0);

	signal gearup_Valid							: STD_LOGIC;
	signal gearup_Data							: STD_LOGIC_VECTOR(GEARBOX_BITS - 1 downto 0);
	signal gearup_Meta							: STD_LOGIC_VECTOR(META_BITS - 1 downto 0);

	signal sort_Valid								: STD_LOGIC;
	signal sort_IsKey								: STD_LOGIC;
	signal sort_Data								: STD_LOGIC_VECTOR(GEARBOX_BITS - 1 downto 0);
	signal sort_Meta								: STD_LOGIC_VECTOR(STREAM_META_BITS - 1 downto 0);

	signal geardown_nxt							: STD_LOGIC;
begin

	In_Ack	<= '1';

	MetaIn(META_ISKEY_BIT)																		<= In_IsKey;
	MetaIn(META_BITS - 1 downto META_BITS - STREAM_META_BITS)	<= In_Meta;

	gearup : entity PoC.gearbox_up_cc
		generic map (
			INPUT_BITS						=> STREAM_DATA_BITS,
			OUTPUT_BITS						=> GEARBOX_BITS,
			META_BITS							=> META_BITS,
			ADD_INPUT_REGISTERS		=> FALSE,
			ADD_OUTPUT_REGISTERS	=> FALSE
		)
		port map (
			Clock				=> Clock,

			In_Sync			=> '0',
			In_Data			=> In_Data,
			In_Meta			=> MetaIn,
			In_Valid		=> In_Valid,
			Out_Sync		=> open,
			Out_Data		=> gearup_Data,
			Out_Meta		=> gearup_Meta,
			Out_Valid		=> gearup_Valid
		);

	genOES : if (SORTNET_IMPL = SORT_SORTNET_IMPL_ODDEVEN_SORT) generate
		signal DataInputMatrix	: T_SLM(SORTNET_SIZE - 1 downto 0, SORTNET_DATA_BITS - 1 downto 0);
		signal DataOutputMatrix	: T_SLM(SORTNET_SIZE - 1 downto 0, SORTNET_DATA_BITS - 1 downto 0);

	begin
		DataInputMatrix	<= to_slm(gearup_Data, SORTNET_SIZE, SORTNET_DATA_BITS);

		-- mux(gearup_Valid, (SORTNET_SIZE * SORTNET_DATA_BITS downto 1 => 'U'), gearup_Data)

		sort : entity PoC.sortnet_OddEvenSort
			generic map (
				INPUTS								=> SORTNET_SIZE,
				KEY_BITS							=> SORTNET_KEY_BITS,
				DATA_BITS							=> SORTNET_DATA_BITS,
				META_BITS							=> STREAM_META_BITS,
				PIPELINE_STAGE_AFTER	=> PIPELINE_STAGE_AFTER,
				ADD_OUTPUT_REGISTERS	=> FALSE
			)
			port map (
				Clock				=> Clock,
				Reset				=> Reset,

				In_Valid		=> gearup_Valid,
				In_IsKey		=> gearup_Meta(META_ISKEY_BIT),
				In_Data			=> DataInputMatrix,
				In_Meta			=> gearup_Meta(META_BITS - 1 downto META_BITS - STREAM_META_BITS),

				Out_Valid		=> sort_Valid,
				Out_IsKey		=> open,
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
				PIPELINE_STAGE_AFTER	=> PIPELINE_STAGE_AFTER,
				ADD_OUTPUT_REGISTERS	=> FALSE
			)
			port map (
				Clock				=> Clock,
				Reset				=> Reset,

				In_Valid		=> gearup_Valid,
				In_IsKey		=> gearup_Meta(META_ISKEY_BIT),
				In_Data			=> DataInputMatrix,
				In_Meta			=> gearup_Meta(META_BITS - 1 downto META_BITS - STREAM_META_BITS),

				Out_Valid		=> sort_Valid,
				Out_IsKey		=> open,
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
				PIPELINE_STAGE_AFTER	=> PIPELINE_STAGE_AFTER,
				ADD_OUTPUT_REGISTERS	=> FALSE
			)
			port map (
				Clock				=> Clock,
				Reset				=> Reset,

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

	geardown : entity PoC.gearbox_down_cc
		generic map (
			INPUT_BITS						=> GEARBOX_BITS,
			OUTPUT_BITS						=> STREAM_DATA_BITS,
			META_BITS							=> STREAM_META_BITS,
			ADD_INPUT_REGISTERS		=> TRUE,
			ADD_OUTPUT_REGISTERS	=> FALSE
		)
		port map (
			Clock				=> Clock,

			In_Sync			=> sort_Valid,
			In_Valid		=> sort_Valid,
			In_Data			=> sort_Data,
			In_Meta			=> sort_Meta,
			In_Next			=> geardown_nxt,
			Out_Sync		=> open,
			Out_Valid		=> Out_Valid,
			Out_Data		=> Out_Data,
			Out_Meta		=> Out_Meta
		);
end architecture;
