-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Module:					Synchronizes a reset signal across clock-domain boundaries
--
-- Description:
-- ------------------------------------
--		This module synchronizes one reset signal from clock-domain 'Clock1' to
--		clock-domain 'Clock'. The clock-domain boundary crossing is done by two
--		synchronizer D-FFs. All bits are independent from each other.
-- 
--		ATTENTION:
--			Use this synchronizer only for reset signals.
--
--		CONSTRAINTS:
--			General:
--				Please add constraints for meta stability to all '_meta' signals and
--				timing ignore constraints to all '_async' signals.
--			
--			Xilinx:
--				In case of a Xilinx device, this module will instantiate the optimized
--				module xil_SyncReset. Please attend to the notes of xil_SyncReset.
--		
--			Altera sdc file:
--				TODO
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

library	IEEE;
use			IEEE.STD_LOGIC_1164.all;

library	PoC;
use			PoC.config.all;
use			PoC.utils.all;


entity sync_Reset is
  port (
		Clock			: in	STD_LOGIC;		-- <Clock>	output clock domain
		Input			: in	STD_LOGIC;		-- @async:	reset input
		Output		: out STD_LOGIC			-- @Clock:	reset output
	);
end;


architecture rtl of sync_Reset is

begin
	genGeneric : if (VENDOR /= VENDOR_XILINX) generate
		attribute ASYNC_REG										: STRING;
		attribute SHREG_EXTRACT								: STRING;
		
		signal Data_async											: STD_LOGIC;
		signal Data_meta											: STD_LOGIC		:= '0';
		signal Data_sync											: STD_LOGIC		:= '0';
		
		-- Mark registers as asynchronous
		attribute ASYNC_REG			of Data_meta	: signal is "TRUE";
		attribute ASYNC_REG			of Data_sync	: signal is "TRUE";

		-- Prevent XST from translating two FFs into SRL plus FF
		attribute SHREG_EXTRACT of Data_meta	: signal is "NO";
		attribute SHREG_EXTRACT of Data_sync	: signal is "NO";
		
	begin
		Data_async	<= Input;
	
		process(Clock, Input)
		begin
			if (Data_async = '1') then
				Data_meta		<= '1';
				Data_sync		<= '1';
			elsif rising_edge(Clock) then
				Data_meta		<= '0';
				Data_sync		<= Data_meta;
			end if;
		end process;		
				
		Output		<= Data_sync;
	end generate;

	genXilinx : if (VENDOR = VENDOR_XILINX) generate
		-- locally component declaration removes the dependancy to 'PoC.xil.all'
		component xil_SyncReset is
			port (
				Clock		: in	STD_LOGIC;	-- Clock to be synchronized to
				Input		: in	STD_LOGIC;	-- high active asynchronous reset
				Output	: out	STD_LOGIC		-- "Synchronised" reset signal
			);
		end component;
	begin
		-- use dedicated and optimized 2 D-FF synchronizer for Xilinx FPGAs
		sync : xil_SyncReset
			port map (
				Clock			=> Clock,
				Input			=> Input,
				Output		=> Output
			);
	end generate;
end;
