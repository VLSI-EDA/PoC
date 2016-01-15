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
use			PoC.simulation.ALL;

library OSVVM;
use			OSVVM.RandomPkg.all;


entity gearbox_down_dc_tb is
end entity;


architecture tb of gearbox_down_dc_tb is
	constant INPUT_BITS						: POSITIVE		:= 32;
	constant OUTPUT_BITS					: POSITIVE		:= 8;
	constant OUTPUT_ORDER					: T_BIT_ORDER	:= MSB_FIRST;
	constant ADD_INPUT_REGISTERS	: BOOLEAN			:= TRUE;
	constant ADD_OUTPUT_REGISTERS	: BOOLEAN			:= TRUE;
	
	constant RATIO								: POSITIVE		:= INPUT_BITS / OUTPUT_BITS;
	
	constant LOOP_COUNT						: POSITIVE		:= 8;
	constant DELAY								: POSITIVE		:= 5;
	
	constant CLOCK2_PERIOD				: TIME				:= 10 ns;
	constant CLOCK1_PERIOD				: TIME				:= CLOCK2_PERIOD * RATIO;
	signal Clock1									: STD_LOGIC		:= '1';
	signal Clock2									: STD_LOGIC		:= '1';
	
	signal DataIn									: STD_LOGIC_VECTOR(INPUT_BITS - 1 downto 0);
	signal DataOut								: STD_LOGIC_VECTOR(OUTPUT_BITS - 1 downto 0);
	
	signal StopSimulation					: STD_LOGIC		:= '0';
begin

	Clock1	<= Clock1 xnor StopSimulation after CLOCK1_PERIOD;
	Clock2	<= Clock2 xnor StopSimulation after CLOCK2_PERIOD;

	process
		variable RandomVar	: RandomPType;							-- protected type from RandomPkg
		variable Temp				: T_SLVV_8(RATIO - 1 downto 0);
	begin
		RandomVar.InitSeed(RandomVar'instance_name);		-- Generate initial seeds

		DataIn		<= (others => 'U');
		for i in 0 to LOOP_COUNT - 1 loop
			wait until rising_edge(Clock1);
			for j in 0 to RATIO - 1 loop
				Temp(j)	:= to_slv(RandomVar.RandInt(0, 255), OUTPUT_BITS);
			end loop;
			DataIn		<= to_slv(Temp);
		end loop;
		
		for i in 0 to DELAY - 1 loop
			wait until rising_edge(Clock1);
		end loop;
		
		StopSimulation		<= '1';
		wait;
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
	
	process
		variable	Check		: BOOLEAN;
	begin
		Check		:= TRUE;
		
		for i in 0 to (LOOP_COUNT * RATIO) - 1 loop
			wait until rising_edge(Clock2);
		end loop;
		
		tbAssert(Check, "TODO: ");

		-- Report overall result
		tbPrintResult;

    wait;  -- forever
	end process;
end architecture;
