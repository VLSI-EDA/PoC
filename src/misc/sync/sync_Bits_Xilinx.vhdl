-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Module:				 	sync_Bits_Xilinx
-- 
-- Description:
-- ------------------------------------
--		This is a multi-bit clock-domain-crossing circuit optimized for Xilinx FPGAs.
--		It utilizes two 'FD' instances from UniSim.vComponents. If you need a
--		platform independent version of this synchronizer, please use
--		'PoC.misc.sync.sync_Flag', which internally instantiates this module if
--		a Xilinx FPGA is detected.
--		
--		ATTENTION:
--			Use this synchronizer only for long time stable signals (flags).
--
--		CONSTRAINTS:
--			This relative placement of the internal sites is constrained by RLOCs.
--		
--			Xilinx ISE UCF or XCF file:
--				NET "*_async"		TIG;
--				INST "*FF1_METASTABILITY_FFS" TNM = "METASTABILITY_FFS";
--				TIMESPEC "TS_MetaStability" = FROM FFS TO "METASTABILITY_FFS" TIG;
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


entity sync_Bits_Xilinx is
	generic (
		BITS					: POSITIVE						:= 1;									-- number of bit to be synchronized
		INIT					: STD_LOGIC_VECTOR		:= x"00000000"				-- initialitation bits
	);
	port (
		Clock					: in	STD_LOGIC;														-- Clock to be synchronized to
		Input					: in	STD_LOGIC_VECTOR(BITS - 1 downto 0);	-- Data to be synchronized
		Output				: out	STD_LOGIC_VECTOR(BITS - 1 downto 0)		-- synchronised data
	);
end entity;


library IEEE;
use			IEEE.STD_LOGIC_1164.all;


entity sync_Bit_Xilinx is
	generic (
		INIT					: BIT							-- initialitation bit
	);
	port (
		Clock					: in	STD_LOGIC;	-- Clock to be synchronized to
		Input					: in	STD_LOGIC;	-- Data to be synchronized
		Output				: out	STD_LOGIC		-- synchronised data
	);
end entity;


library IEEE;
use			IEEE.STD_LOGIC_1164.all;

library PoC;
use			PoC.utils.ALL;


architecture rtl of sync_Bits_Xilinx is
	constant INIT_I						: BIT_VECTOR		:= to_bitvector(resize(descend(INIT), BITS));
begin
	gen : for i in 0 to BITS - 1 generate
		Sync : entity PoC.sync_Bit_Xilinx
			generic map (
				INIT	=> INIT_I(i)
			)
			port map (
				Clock		=> Clock,
				Input		=> Input(i),
				Output	=> Output(i)
			);
	end generate;
end architecture;


library IEEE;
use			IEEE.STD_LOGIC_1164.all;

library UniSim;
use			UniSim.vComponents.all;


architecture rtl of sync_Bit_Xilinx is
	attribute ASYNC_REG				: STRING;
	attribute SHREG_EXTRACT		: STRING;
	attribute RLOC						: STRING;

	signal Data_async				: STD_LOGIC;
	signal Data_meta				: STD_LOGIC;
	signal Data_sync				: STD_LOGIC;
	
	-- Mark register Data_async's input as asynchronous
	attribute ASYNC_REG			of Data_meta	: signal is "TRUE";

	-- Prevent XST from translating two FFs into SRL plus FF
	attribute SHREG_EXTRACT of Data_meta	: signal is "NO";
	attribute SHREG_EXTRACT of Data_sync	: signal is "NO";
		
	-- Assign synchronization FF pairs to the same slice -> minimal routing delay
	attribute RLOC of Data_meta						: signal is "X0Y0";
	attribute RLOC of Data_sync						: signal is "X0Y0";
		
begin
	Data_async	<= Input;

	FF1_METASTABILITY_FFS : FD
		generic map (
			INIT		=> INIT
		)
		port map (
			C				=> Clock,
			D				=> Data_async,
			Q				=> Data_meta
		);

	FF2 : FD
		generic map (
			INIT		=> INIT
		)
		port map (
			C				=> Clock,
			D				=> Data_meta,
			Q				=> Data_sync
		);
	
	Output	<= Data_sync;
end architecture;
