-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				Sorting Network: Odd-Even-Merge-Sort
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
use			PoC.math.all;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.strings.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;

library OSVVM;
use			OSVVM.RandomPkg.all;


entity sortnet_OddEvenMergeSort_tb is
end entity;


architecture tb of sortnet_OddEvenMergeSort_tb is

	constant TAG_BITS								: POSITIVE	:= 4;

	constant INPUTS									: POSITIVE	:= 64;
	constant DATA_COLUMNS						: POSITIVE	:= 2;

	constant KEY_BITS								: POSITIVE	:= 8;
	constant DATA_BITS							: POSITIVE	:= 32;
	constant META_BITS							: POSITIVE	:= TAG_BITS;
	constant PIPELINE_STAGE_AFTER		: NATURAL		:= 2;

	constant LOOP_COUNT							: POSITIVE	:= 1024;

	constant STAGES									: POSITIVE	:= triangularNumber(log2ceil(INPUTS));
	constant DELAY									: NATURAL		:= STAGES / PIPELINE_STAGE_AFTER;

	subtype T_DATA				is STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);
	type T_DATA_VECTOR		is array(NATURAL range <>) of T_DATA;

	function to_dv(slm : T_SLM) return T_DATA_VECTOR is
		variable Result	: T_DATA_VECTOR(slm'range(1));
	begin
		for i in slm'high(1) downto slm'low(1) loop
			for j in T_DATA'range loop
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

	constant CLOCK_FREQ				: FREQ				:= 100 MHz;
	signal Clock							: STD_LOGIC		:= '1';

	signal Generator_Valid		: STD_LOGIC;
	signal Generator_IsKey		: STD_LOGIC;
	signal Generator_Data			: T_DATA_VECTOR(INPUTS - 1 downto 0);
	signal Generator_Meta			: STD_LOGIC_VECTOR(META_BITS - 1 downto 0);

	signal Sort_Valid					: STD_LOGIC;
	signal Sort_IsKey					: STD_LOGIC;
	signal Sort_Data					: T_DATA_VECTOR(INPUTS - 1 downto 0);
	signal Sort_Meta					: STD_LOGIC_VECTOR(META_BITS - 1 downto 0);

	signal DataInputMatrix		: T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0);
	signal DataOutputMatrix		: T_SLM(INPUTS - 1 downto 0, DATA_BITS - 1 downto 0);

begin
	-- initialize global simulation status
	simInitialize;

	simWriteMessage("SETTINGS");
	simWriteMessage("  INPUTS:    " & INTEGER'image(INPUTS));
	simWriteMessage("  KEY_BITS:  " & INTEGER'image(KEY_BITS));
	simWriteMessage("  DATA_BITS: " & INTEGER'image(DATA_BITS));
	simWriteMessage("  REG AFTER: " & INTEGER'image(PIPELINE_STAGE_AFTER));

	simGenerateClock(Clock, CLOCK_FREQ);

	procGenerator : process
		constant simProcessID	: T_SIM_PROCESS_ID		:= simRegisterProcess("Generator");
		variable RandomVar		: RandomPType;					-- protected type from RandomPkg

		variable KeyInput		: STD_LOGIC_VECTOR(KEY_BITS - 1 downto 0);
		variable DataInput	: STD_LOGIC_VECTOR(DATA_BITS - KEY_BITS - 1 downto 0);
		variable TagInput		: STD_LOGIC_VECTOR(TAG_BITS - 1 downto 0);

	begin
		RandomVar.InitSeed(RandomVar'instance_name);		-- Generate initial seeds

		Generator_Valid		<= '0';
		Generator_IsKey		<= '0';
		Generator_Data		<= (others => (others => '0'));
		Generator_Meta		<= (others => '0');
		wait until rising_edge(Clock);

		Generator_Valid		<= '1';
		for i in 0 to LOOP_COUNT - 1 loop
			Generator_IsKey			<= to_sl(i mod DATA_COLUMNS = 0);
			for j in 0 to INPUTS - 1 loop
				KeyInput					:= RandomVar.RandSlv(KEY_BITS);
				DataInput					:= RandomVar.RandSlv(DATA_BITS - KEY_BITS);
				TagInput					:= RandomVar.RandSlv(TAG_BITS);

				Generator_Data(j)	<= DataInput & KeyInput;
				Generator_Meta		<= resize(TagInput, META_BITS);
			end loop;
			wait until rising_edge(Clock);
		end loop;

		Generator_Valid				<= '0';
		wait until rising_edge(Clock);

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;		-- forever
	end process;

	DataInputMatrix		<= to_slm(Generator_Data);

	sort : entity PoC.sortnet_OddEvenMergeSort
		generic map (
			INPUTS								=> INPUTS,
			KEY_BITS							=> KEY_BITS,
			DATA_BITS							=> DATA_BITS,
			META_BITS							=> META_BITS,
			PIPELINE_STAGE_AFTER	=> PIPELINE_STAGE_AFTER
		)
		port map (
			Clock				=> Clock,
			Reset				=> '0',

			In_Valid		=> Generator_Valid,
			In_IsKey		=> Generator_IsKey,
			In_Data			=> DataInputMatrix,
			In_Meta			=> Generator_Meta,

			Out_Valid		=> Sort_Valid,
			Out_IsKey		=> Sort_IsKey,
			Out_Data		=> DataOutputMatrix,
			Out_Meta		=> Sort_Meta
		);

	Sort_Data	<= to_dv(DataOutputMatrix);

	procChecker : process
		constant simProcessID	: T_SIM_PROCESS_ID		:= simRegisterProcess("Checker");
		variable Check				: BOOLEAN;
		variable CurValue			: UNSIGNED(KEY_BITS - 1 downto 0);
		variable LastValue		: UNSIGNED(KEY_BITS - 1 downto 0);
	begin
		wait until rising_edge(Sort_Valid);

		for i in 0 to LOOP_COUNT - 1 loop
			wait until falling_edge(Clock);

			Check		:= TRUE;
			if (Sort_IsKey = '1') then
				LastValue	:= (others => '0');
				for j in 0 to INPUTS - 1 loop
					CurValue	:= unsigned(Sort_Data(j)(KEY_BITS - 1 downto 0));
					Check			:= Check and (LastValue <= CurValue);
					LastValue	:= CurValue;
				end loop;
				simAssertion(Check, "Result is not monotonic." & raw_format_slv_hex(std_logic_vector(LastValue)));
			else
				-- no routine implemented to check if sorting network is switched as in the previous cycles
			end if;
		end loop;

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;
end architecture;
