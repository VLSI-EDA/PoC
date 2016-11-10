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
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.math.all;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;

library OSVVM;
use			OSVVM.RandomPkg.all;


entity gearbox_up_cc_tb is
end entity;


architecture tb of gearbox_up_cc_tb is
	type T_TUPLE is record
		InputBits			: positive;
		OutputBits		: positive;
	end record;
	type T_TUPLE_VECTOR is array(natural range <>) of T_TUPLE;

	constant TB_GENERATOR_LIST	: T_TUPLE_VECTOR	:= ((8, 32), (8, 20), (8, 36), (64, 66), (12, 128));

	constant CLOCK_FREQ					: FREQ						:= 100 MHz;
	signal Clock								: std_logic				:= '1';

begin
	-- initialize global simulation status
	simInitialize;

	simGenerateClock(Clock, CLOCK_FREQ);


	genInstances : for i in TB_GENERATOR_LIST'range generate
		constant INPUT_BITS						: positive		:= TB_GENERATOR_LIST(i).InputBits;
		constant OUTPUT_BITS					: positive		:= TB_GENERATOR_LIST(i).OutputBits;
		constant OUTPUT_ORDER					: T_BIT_ORDER	:= MSB_FIRST;
		constant ADD_INPUT_REGISTERS	: boolean			:= TRUE;
		constant ADD_OUTPUT_REGISTERS	: boolean			:= FALSE;

		constant BITS_PER_CHUNK				: positive		:= greatestCommonDivisor(INPUT_BITS, OUTPUT_BITS);
		constant INPUT_CHUNKS					: positive		:= INPUT_BITS / BITS_PER_CHUNK;
		constant OUTPUT_CHUNKS				: positive		:= OUTPUT_BITS / BITS_PER_CHUNK;

		subtype T_CHUNK			is std_logic_vector(BITS_PER_CHUNK - 1 downto 0);
		type T_CHUNK_VECTOR	is array(natural range <>) of T_CHUNK;

		function to_slv(slvv : T_CHUNK_VECTOR) return std_logic_vector is
			variable slv			: std_logic_vector((slvv'length * BITS_PER_CHUNK) - 1 downto 0);
		begin
			for i in slvv'range loop
				slv(((i + 1) * BITS_PER_CHUNK) - 1 downto (i * BITS_PER_CHUNK))		:= slvv(i);
			end loop;
			return slv;
		end function;

		constant LOOP_COUNT						: positive		:= 64;
		constant DELAY								: positive		:= 16;

		signal SyncIn									: std_logic;
		signal ValidIn								: std_logic;
		signal DataIn									: std_logic_vector(INPUT_BITS - 1 downto 0);

		signal SyncOut								: std_logic;
		signal ValidOut								: std_logic;
		signal DataOut								: std_logic_vector(OUTPUT_BITS - 1 downto 0);
		signal FirstOut								: std_logic;
		signal LastOut								: std_logic;

		constant simTestID : T_SIM_TEST_ID		:= simCreateTest("Test setup for " & integer'image(INPUT_BITS) & "->" & INTEGER'image(OUTPUT_BITS));

	begin
		procGenerator : process
			constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Generator " & integer'image(i) & " for " & INTEGER'image(INPUT_BITS) & "->" & integer'image(OUTPUT_BITS));	--, "aaa/bbb/ccc");	--globalSimulationStatus'instance_name);
			-- protected type from RandomPkg
			variable RandomVar		: RandomPType;

			impure function genChunkedRandomValue return std_logic_vector is
				variable Temp			: T_CHUNK_VECTOR(INPUT_CHUNKS - 1 downto 0);
			begin
				for j in 0 to INPUT_CHUNKS - 1 loop
					Temp(j)	:= to_slv(RandomVar.RandInt(0, 2**BITS_PER_CHUNK - 1), BITS_PER_CHUNK);
				end loop;
				return to_slv(Temp);
			end function;

		begin
			RandomVar.InitSeed(RandomVar'instance_name);		-- Generate initial seeds

			SyncIn		<= '0';
			DataIn		<= (others => 'U');
			ValidIn		<= '0';
			for i in 0 to 7 loop
				wait until falling_edge(Clock);
			end loop;

			SyncIn		<= '1';
			ValidIn		<= '1';
			DataIn		<= genChunkedRandomValue;
			wait until falling_edge(Clock);

			SyncIn		<= '0';
			for i in 0 to LOOP_COUNT - 1 loop
				DataIn		<= genChunkedRandomValue;
				ValidIn		<= '1';
				wait until falling_edge(Clock);
			end loop;

			SyncIn		<= '1';
			ValidIn		<= '1';
			DataIn		<= genChunkedRandomValue;
			wait until falling_edge(Clock);

			SyncIn		<= '0';
			for i in 0 to LOOP_COUNT - 1 loop
				if (i mod 2 = 1) then
					DataIn		<= genChunkedRandomValue;
					ValidIn		<= '1';
				else
					ValidIn		<= '0';
				end if;
				wait until falling_edge(Clock);
			end loop;

			DataIn		<= (others => '0');
			ValidIn		<= '0';

			-- This process is finished
			simDeactivateProcess(simProcessID);
			wait;		-- forever
		end process;

		gear : entity PoC.gearbox_up_cc
			generic map (
				INPUT_BITS						=> INPUT_BITS,
				OUTPUT_BITS						=> OUTPUT_BITS,
				META_BITS							=> 0,	--META_BITS,
				-- OUTPUT_ORDER					=> OUTPUT_ORDER,
				ADD_INPUT_REGISTERS		=> ADD_INPUT_REGISTERS,
				ADD_OUTPUT_REGISTERS	=> ADD_OUTPUT_REGISTERS
			)
			port map (
				Clock				=> Clock,

				In_Sync			=> SyncIn,
				In_Valid		=> ValidIn,
				In_Data			=> DataIn,
				In_Meta			=> (others => '0'),	--MetaIn,

				Out_Sync		=> SyncOut,
				Out_Valid		=> ValidOut,
				Out_Data		=> DataOut,
				Out_Meta		=> open,	--MetaOut
				Out_First		=> FirstOut,
				Out_Last		=> LastOut
			);

		procChecker : process
			variable simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess(simTestID, "Checker " & integer'image(i) & " for " & INTEGER'image(INPUT_BITS) & "->" & integer'image(OUTPUT_BITS));
			variable Check				: boolean;
		begin
			Check		:= TRUE;

			wait until rising_edge(Clock) and (FirstOut = '1');

			for i in 0 to LOOP_COUNT - 1 loop
				wait until rising_edge(Clock);
				-- simAssertion(Check, "TODO: ");
			end loop;

			for i in 0 to LOOP_COUNT - 1 loop
				wait until rising_edge(Clock);
				-- simAssertion(Check, "TODO: ");
			end loop;

			for i in 0 to DELAY - 1 loop
				wait until rising_edge(Clock);
			end loop;

			-- This process is finished
			simDeactivateProcess(simProcessID);
			simFinalizeTest(simTestID);
			wait;		-- forever
		end process;
	end generate;
end architecture;
