-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				testbench for a command signal synchronizer
--
-- Description:
-- ------------------------------------
--		TODO
-- 
-- License:
-- =============================================================================
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
-- =============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;


entity sync_Command_tb is
end;


architecture test of sync_Command_tb is 
	constant CLOCK_1_PERIOD		: TIME								:= 10.000 ns;
	constant CLOCK_2_PERIOD		: TIME								:= 16.666 ns;
	constant CLOCK_2_OFFSET		: TIME								:=  2.000 ps;
	
	signal Clock1							: STD_LOGIC						:= '1';
	signal Clock2_i						: STD_LOGIC						:= '1';
	signal Clock2							: STD_LOGIC;
	
	signal Sync_in						: STD_LOGIC_VECTOR(1 downto 0)	:= "00";
	signal Sync_out						: STD_LOGIC_VECTOR(1 downto 0);
	signal Sync_Busy					: STD_LOGIC;
	signal Sync_Changed				: STD_LOGIC;
	
begin

	ClockProcess1 : process(Clock1)
  begin
		Clock1 <= not Clock1 after CLOCK_1_PERIOD / 2;
  end process;
	
	ClockProcess2 : process(Clock2_i)
  begin
		Clock2_i <= not Clock2_i after CLOCK_2_PERIOD / 2;
  end process;
	
	Clock2 <= Clock2_i'delayed(CLOCK_2_OFFSET);

	
	process
	begin
		wait for 4 * CLOCK_1_PERIOD;
		
		Sync_in			<= "01";
		wait for 1 * CLOCK_1_PERIOD;
		
		Sync_in			<= "00";
		wait for 1 * CLOCK_1_PERIOD;
		
		Sync_in			<= "XX";
		wait for 1 * CLOCK_1_PERIOD;
		
		Sync_in			<= "00";
		wait for 2 * CLOCK_1_PERIOD;
		
		Sync_in			<= "01";
		wait for 1 * CLOCK_1_PERIOD;
		
		Sync_in			<= "00";
		wait for 6 * CLOCK_1_PERIOD;
	
		Sync_in			<= "10";
		wait for 16 * CLOCK_1_PERIOD;
		
		Sync_in			<= "00";
		wait for 1 * CLOCK_1_PERIOD;
		
		Sync_in			<= "01";
		wait for 1 * CLOCK_1_PERIOD;
		
		Sync_in			<= "00";
		wait for 6 * CLOCK_1_PERIOD;
		
		wait;
	end process;
	
	syncCmd : entity PoC.sync_Command
		generic map (
			BITS							=> 2,										-- number of bit to be synchronized
			INIT							=> "00"									-- 
		)
		port map (
			Clock1						=> Clock1,							-- input clock domain
			Clock2						=> Clock2,							-- output clock domain
			Input							=> Sync_in,						-- input bits
			Output						=> Sync_out,						-- output bits
			Busy							=> Sync_Busy,					-- busy bits
			Changed						=> Sync_Changed				-- busy bits
		);
end;
