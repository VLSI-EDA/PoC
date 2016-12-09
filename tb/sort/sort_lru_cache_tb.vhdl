-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:				 	Patrick Lehmann
--									Martin Zabel
--
-- Module:				 	Testbench for `sort_lru_cache`
--
-- Description:
-- ------------------------------------
--		TODO
--
-- License:
-- ============================================================================
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
-- ============================================================================


library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.math.all;
use			PoC.utils.all;
use			PoC.vectors.all;
-- simulation only packages
use			PoC.sim_global.all;
use			PoC.sim_types.all;
use			PoC.simulation.all;

library OSVVM;
use			OSVVM.RandomPkg.all;


entity sort_lru_cache_tb is
end entity;


architecture tb of sort_lru_cache_tb is
	constant ELEMENTS					: positive	:= 8;
	constant KEY_BITS					: positive	:= log2ceilnz(ELEMENTS);

	constant LOOP_COUNT				: positive	:= 32;

	constant CLOCK_PERIOD			: time				:= 10 ns;
	signal Clock							: std_logic		:= '1';

	signal Insert							: std_logic;
	signal Free								: std_logic;
	signal KeyIn							: std_logic_vector(KEY_BITS - 1 downto 0);

	signal KeyOut							: std_logic_vector(KEY_BITS - 1 downto 0);

	signal StopSimulation			: std_logic		:= '0';
begin

	simInitialize;

	Clock	<= Clock xnor StopSimulation after CLOCK_PERIOD;

	process
		variable RandomVar	: RandomPType;								-- protected type from RandomPkg
		variable Command		: integer range 0 to 1;--2;
	begin
		RandomVar.InitSeed(RandomVar'instance_name);		-- Generate initial seeds

		Insert			<= '0';
		Free				<= '0';
		KeyIn				<= (others => '0');
		wait until falling_edge(Clock);

		for i in 0 to LOOP_COUNT - 1 loop

			Insert			<= '0';
			Free				<= '0';
			Command			:= RandomVar.RandInt(0, 1);
			case Command is
				when 0 =>	-- NOP
				when 1 =>	-- Insert
					Insert	<= '1';
					KeyIn		<= to_slv(RandomVar.RandInt(0, (2**KEY_BITS - 1)), KEY_BITS);
				-- when 2 =>	-- Free
					-- Free		<= '1';
					-- KeyIn	<= to_slv(RandomVar.RandInt(0, (2**KEY_BITS - 1)), KEY_BITS);
			end case;
			wait until falling_edge(Clock);
		end loop;

		for i in 0 to 3 loop
			wait until falling_edge(Clock);
		end loop;

		StopSimulation		<= '1';
		-- Report overall result
		simFinalize;
		wait;
	end process;

	sort : entity PoC.sort_lru_cache
		generic map (
			ELEMENTS					=> ELEMENTS
		)
		port map (
			Clock							=> Clock,
			Reset							=> '0',

			Insert						=> Insert,
			Free							=> Free,
			KeyIn							=> KeyIn,

			KeyOut 						=> KeyOut
		);

end architecture;
