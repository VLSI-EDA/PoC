-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				TODO
--
-- Description:
-- ------------------------------------
--	TODO
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
use			PoC.physical.all;
use			PoC.sortnet.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;

library OSVVM;
use			OSVVM.RandomPkg.all;


entity sortnet_Stream_Adapter2_tb is
end entity;


architecture tb of sortnet_Stream_Adapter2_tb is
	constant DEBUG									: boolean			:= TRUE;

	constant TAG_BITS								: positive		:= 4;

	constant STREAM_DATA_BITS				: positive		:= ite(DEBUG, 16,	 32);
	constant STREAM_META_BITS				: positive		:= TAG_BITS;

	constant DATA_COLUMNS						: positive		:= 2;

	constant SORTNET_SIZE						: positive		:= ite(DEBUG, 8,	 32);	--128);
	constant SORTNET_KEY_BITS				: positive		:= ite(DEBUG, 8,	 32);
	constant SORTNET_DATA_BITS			: positive		:= ite(DEBUG, 16,	 64);
	constant SORTNET_REG_AFTER			: positive		:= 2;

	constant MERGENET_STAGES				: positive		:= ite(DEBUG, 2,	 4);

	constant LOOP_COUNT							: positive		:= 2;
	constant SORTNET_BLOCK_COUNT		: positive		:= 2**MERGENET_STAGES * DATA_COLUMNS * LOOP_COUNT;	--ite(DEBUG, 10,	 32);	--1024);

	-- constant STAGES									: POSITIVE		:= SORTNET_SIZE;
	constant DELAY									: natural			:= 3 * 2**MERGENET_STAGES * SORTNET_SIZE + 50;	--STAGES / PIPELINE_STAGE_AFTER;

	constant CLOCK_FREQ							: FREQ				:= 100 MHz;
	signal Clock										: std_logic		:= '1';

	signal Generator_Valid					: std_logic;
	signal Generator_Data						: std_logic_vector(STREAM_DATA_BITS - 1 downto 0);
	signal Generator_SOF						: std_logic;
	signal Generator_IsKey					: std_logic;
	signal Generator_EOF						: std_logic;
	signal Generator_Meta						: std_logic_vector(TAG_BITS - 1 downto 0);

	signal Sort_Out_Valid						: std_logic;
	signal Sort_Out_Data						: std_logic_vector(STREAM_DATA_BITS - 1 downto 0);
	signal Sort_Out_IsKey						: std_logic;

	signal Tester_Ack								: std_logic;

begin
	-- initialize global simulation status
	simInitialize;

	simWriteMessage("SETTINGS");
	simWriteMessage("  SORTNET_BLOCK_COUNT: " & integer'image(SORTNET_BLOCK_COUNT));
	simWriteMessage("  BYTES TRANSFERED:    " & integer'image(SORTNET_BLOCK_COUNT * SORTNET_SIZE * SORTNET_DATA_BITS / 8));

	-- generate global testbench clock
	simGenerateClock(Clock, CLOCK_FREQ);

	procGenerator : process
		constant simProcessID	: T_SIM_PROCESS_ID		:= simRegisterProcess("Generator");
		variable RandomVar		: RandomPType;					-- protected type from RandomPkg

		variable KeyInput		: std_logic_vector(SORTNET_KEY_BITS - 1 downto 0);
		variable DataInput	: std_logic_vector(SORTNET_DATA_BITS - SORTNET_KEY_BITS - 1 downto 0);
		variable TagInput		: std_logic_vector(TAG_BITS - 1 downto 0);

	begin
		RandomVar.InitSeed(RandomVar'instance_name);		-- Generate initial seeds

		Generator_Valid			<= '0';
		Generator_Data			<= (others => '0');
		Generator_SOF				<= '0';
		Generator_IsKey			<= '0';
		Generator_EOF				<= '0';
		Generator_Meta			<= (others => '0');

		wait until rising_edge(Clock);

		Generator_Valid			<= '1';
		for i in 0 to SORTNET_BLOCK_COUNT - 1 loop
			TagInput					:= to_slv(i mod 2**TAG_BITS, TAG_BITS);

			Generator_IsKey		<= to_sl(i mod DATA_COLUMNS = 0);
			Generator_Meta		<= resize(TagInput, STREAM_META_BITS);

			for j in 0 to SORTNET_SIZE - 1 loop
				KeyInput				:= RandomVar.RandSlv(SORTNET_KEY_BITS);
				DataInput				:= RandomVar.RandSlv(SORTNET_DATA_BITS - SORTNET_KEY_BITS);

				-- assemble data vector and write to stream interface
				Generator_SOF		<= to_sl((j = 0) and (i mod DATA_COLUMNS = 0));
				Generator_Data	<= resize(DataInput & KeyInput, STREAM_DATA_BITS);
				Generator_EOF		<= to_sl((j = SORTNET_SIZE - 1) and (i mod DATA_COLUMNS = DATA_COLUMNS - 1));

				wait until rising_edge(Clock);
			end loop;
		end loop;

		Generator_Valid				<= '0';

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;		-- forever
	end process;

	sort : entity PoC.sortnet_Stream_Adapter2
		generic map (
			STREAM_DATA_BITS			=> STREAM_DATA_BITS,
			STREAM_META_BITS			=> STREAM_META_BITS,
			DATA_COLUMNS					=> DATA_COLUMNS,
			-- SORTNET_IMPL					=> SORT_SORTNET_IMPL_BITONIC_SORT,
			-- SORTNET_IMPL					=> SORT_SORTNET_IMPL_ODDEVEN_SORT,
			SORTNET_IMPL					=> SORT_SORTNET_IMPL_ODDEVEN_MERGESORT,
			SORTNET_SIZE					=> SORTNET_SIZE,
			SORTNET_KEY_BITS			=> SORTNET_KEY_BITS,
			SORTNET_DATA_BITS			=> SORTNET_DATA_BITS,
			MERGENET_STAGES				=> MERGENET_STAGES
		)
		port map (
			Clock				=> Clock,
			Reset				=> '0',

			Inverse			=> '0',

			In_Valid		=> Generator_Valid,
			In_Data			=> Generator_Data,
			In_Meta			=> Generator_Meta,
			In_SOF			=> Generator_SOF,
			In_IsKey		=> Generator_IsKey,
			In_EOF			=> Generator_EOF,
			In_Ack			=> open,

			Out_Valid		=> Sort_Out_Valid,
			Out_Data		=> Sort_Out_Data,
			Out_Meta		=> open,
			Out_SOF			=> open,
			Out_IsKey		=> Sort_Out_IsKey,
			Out_EOF			=> open,
			Out_Ack			=> Tester_Ack
		);

	procChecker : process
		constant simProcessID	: T_SIM_PROCESS_ID		:= simRegisterProcess("Checker");

		variable Check				: boolean;
		variable CurValue			: unsigned(SORTNET_KEY_BITS - 1 downto 0);
		variable LastValue		: unsigned(SORTNET_KEY_BITS - 1 downto 0);
	begin
		Tester_Ack		<= '0';

		simWaitUntilRisingEdge(Clock, 8);

		wait until (Sort_Out_Data /= (STREAM_DATA_BITS - 1 downto 0 => '0'));

		Tester_Ack		<= '1';
		for i in 0 to SORTNET_BLOCK_COUNT - 1 loop
			Check			:= TRUE;
			LastValue	:= (others => '0');
			for j in 0 to SORTNET_SIZE - 1 loop
				wait until rising_edge(Clock);

				if (Sort_Out_IsKey = '1') then
					CurValue	:= unsigned(Sort_Out_Data(SORTNET_KEY_BITS - 1 downto 0));
					Check			:= Check and (LastValue <= CurValue);
					LastValue	:= CurValue;
				end if;
			end loop;
			simAssertion(Check, "Result is not monotonic.");
		end loop;

		simWaitUntilRisingEdge(Clock, 512);

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;

end architecture;
