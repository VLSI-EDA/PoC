-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Module:				 	xil_SyncReset
-- 
-- Description:
-- ------------------------------------
--		This is a clock-domain-crossing circuit for reset signals optimized for
--		Xilinx FPGAs. It utilizes two 'FDP' instances from UniSim.vComponents. If
--		you need a platform independent version of this synchronizer, please use
--		'PoC.misc.sync.sync_Reset', which internally instantiates this module if
--		a Xilinx FPGA is detected.
--		
--		ATTENTION:
--			Only use this synchronizer for reset signals.
--
--		CONSTRAINTS:
--			This relative placement of the internal sites is constrained by RLOCs.
--		
--			Xilinx ISE UCF or XCF file:
--				NET "*_async"		TIG;
--				INST "*_meta"		TNM = "METASTABILITY_FFS";
--				TIMESPEC "TS_MetaStability" = FROM FFS TO "METASTABILITY_FFS" TIG;
--
--				## Assign synchronization FF pairs to the same slice -> minimal routing delay
--				BEGIN MODEL xil_SyncBlock
--				  INST "FF1"	RLOC = X0Y0;
--				  INST "FF2"	RLOC = X0Y0;
--				END;
--			
--			Xilinx Vivado xdc file:
--				TODO
--				TODO
--
-- License:
-- ============================================================================
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
-- ============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;

library UNISIM;
use			UNISIM.VCOMPONENTS.all;


entity xil_SyncReset is
	port (
		Clock				: in	STD_LOGIC;					-- Clock to be synchronized to
		Input				: in	STD_LOGIC;					-- high active asynchronous reset
		Output			: out	STD_LOGIC						-- "Synchronised" reset signal
	);
end;


architecture rtl of xil_SyncReset is
	attribute ASYNC_REG											: STRING;
	attribute SHREG_EXTRACT									: STRING;

	signal Reset_async											: STD_LOGIC;
	signal Reset_meta												: STD_LOGIC;
	signal Reset_sync												: STD_LOGIC;

	-- Mark register "Reset_meta" and "Output" as asynchronous
	attribute ASYNC_REG of Reset_meta				: signal is "TRUE";
	attribute ASYNC_REG of Reset_sync				: signal is "TRUE";

	-- Prevent XST from translating two FFs into SRL plus FF
	attribute SHREG_EXTRACT of Reset_meta		: signal is "NO";
	attribute SHREG_EXTRACT of Reset_sync		: signal is "NO";

begin
	Reset_async		<= Input;

	FF1 : FDP
		generic map (
			INIT		=> '1'
		)
		port map (
			C				=> Clock,
			PRE			=> Reset_async,
			D				=> '0',
			Q				=> Reset_meta
	);

	FF2 : FDP
		generic map (
			INIT		=> '1'
		)
		port map (
			C				=> Clock,
			PRE			=> Reset_async,
			D				=> Reset_meta,
			Q				=> Reset_sync
	);

	Output	<= Reset_sync;
end;
