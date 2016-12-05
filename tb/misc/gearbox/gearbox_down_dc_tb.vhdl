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


entity gearbox_down_dc_tb is
end entity;


architecture tb of gearbox_down_dc_tb is
	type T_TUPLE is record
		InputBits			: positive;
		OutputBits		: positive;
	end record;
	type T_TUPLE_VECTOR is array(natural range <>) of T_TUPLE;

	constant TB_GENERATOR_LIST	: T_TUPLE_VECTOR	:= ((32, 8), (128, 8));

begin
	-- initialize global simulation status
	simInitialize;

	genInstances : for i in TB_GENERATOR_LIST'range generate
		constant INPUT_BITS						: positive		:= TB_GENERATOR_LIST(i).InputBits;
		constant OUTPUT_BITS					: positive		:= TB_GENERATOR_LIST(i).OutputBits;
		constant OUTPUT_ORDER					: T_BIT_ORDER	:= MSB_FIRST;
		constant ADD_INPUT_REGISTERS	: boolean			:= TRUE;
		constant ADD_OUTPUT_REGISTERS	: boolean			:= TRUE;

		constant RATIO								: positive		:= INPUT_BITS / OUTPUT_BITS;

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

		constant LOOP_COUNT						: positive		:= 8;
		constant DELAY								: positive		:= 5;

		constant CLOCK2_PERIOD				: time				:= 10 ns;
		constant CLOCK1_PERIOD				: time				:= CLOCK2_PERIOD * RATIO;
		signal Clock1									: std_logic		:= '1';
		signal Clock2									: std_logic		:= '1';

		signal DataIn									: std_logic_vector(INPUT_BITS - 1 downto 0);
		signal DataOut								: std_logic_vector(OUTPUT_BITS - 1 downto 0);

		constant simTestID : T_SIM_TEST_ID		:= simCreateTest("Test setup for " & integer'image(INPUT_BITS) & "->" & INTEGER'image(OUTPUT_BITS));

	begin
		-- generate global testbench clock
		simGenerateClock(simTestID, Clock1,		CLOCK1_PERIOD);
		simGenerateClock(simTestID, Clock2,		CLOCK2_PERIOD);

		procGenerator : process
			-- from Simulation
			constant simProcessID	: T_SIM_PROCESS_ID	:= simRegisterProcess(simTestID, "Generator " & integer'image(i) & " for " & INTEGER'image(INPUT_BITS) & "->" & integer'image(OUTPUT_BITS));	--, "aaa/bbb/ccc");	--globalSimulationStatus'instance_name);
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

			DataIn		<= (others => 'U');
			for i in 0 to LOOP_COUNT - 1 loop
				wait until rising_edge(Clock1);
				DataIn		<= genChunkedRandomValue;
			end loop;

			-- This process is finished
			simDeactivateProcess(simProcessID);
			wait;		-- forever
		end process;

		gear : entity PoC.gearbox_down_dc
			generic map (
				INPUT_BITS						=> INPUT_BITS,
				OUTPUT_BITS						=> OUTPUT_BITS,
				OUTPUT_ORDER					=> OUTPUT_ORDER,
				ADD_INPUT_REGISTERS		=> ADD_INPUT_REGISTERS,
				ADD_OUTPUT_REGISTERS	=> ADD_OUTPUT_REGISTERS
			)
			port map (
				Clock1			=> Clock1,
				Clock2			=> Clock2,

				In_Data			=> DataIn,
				Out_Data		=> DataOut
			);

		procChecker : process
			constant simProcessID	: T_SIM_PROCESS_ID	:= simRegisterProcess(simTestID, "Checker " & integer'image(i) & " for " & INTEGER'image(INPUT_BITS) & "->" & integer'image(OUTPUT_BITS));	--, "aaa/bbb/ccc");	--globalSimulationStatus'instance_name);
		begin
			for i in 0 to (LOOP_COUNT * RATIO) - 1 loop
				wait until rising_edge(Clock2);
			end loop;

			simWaitUntilRisingEdge(simTestID, Clock2, 4);

			-- This process is finished
			simDeactivateProcess(simProcessID);
			simFinalizeTest(simTestID);
			wait;		-- forever
		end process;
	end generate;
end architecture;
