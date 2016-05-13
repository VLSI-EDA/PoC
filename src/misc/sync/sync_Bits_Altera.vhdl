-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Module:				 	sync_Bits_Altera
-- 
-- Description:
-- ------------------------------------
--		This is a multi-bit clock-domain-crossing circuit optimized for Altera FPGAs.
--		It generates 2 flip flops per input bit and notifies Quartus II, that these
--		flip flops are synchronizer flip flops. If you need a platform independent
--		version of this synchronizer, please use 'PoC.misc.sync.sync_Flag', which
--		internally instantiates this module if a Altera FPGA is detected.
--		
--		ATTENTION:
--			Use this synchronizer only for long time stable signals (flags).
--
--		CONSTRAINTS:
--
-- License:
-- ============================================================================
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
-- ============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;

library	PoC;
use			PoC.sync.all;


entity sync_Bits_Altera is
	generic (
		BITS					: POSITIVE						:= 1;									-- number of bit to be synchronized
		INIT					: STD_LOGIC_VECTOR		:= x"00000000";				-- initialitation bits
		SYNC_DEPTH		: T_MISC_SYNC_DEPTH		:= 2									-- generate SYNC_DEPTH many stages, at least 2
	);
	port (
		Clock					: in	STD_LOGIC;														-- Clock to be synchronized to
		Input					: in	STD_LOGIC_VECTOR(BITS - 1 downto 0);	-- Data to be synchronized
		Output				: out	STD_LOGIC_VECTOR(BITS - 1 downto 0)		-- synchronised data
	);
end entity;


architecture rtl of sync_Bits_Altera is
	attribute PRESERVE					: BOOLEAN;
	attribute ALTERA_ATTRIBUTE	: STRING;

	-- Apply a SDC constraint to meta stable flip flop
	attribute ALTERA_ATTRIBUTE of rtl				: architecture is "-name SDC_STATEMENT ""set_false_path -to [get_registers {*|sync_Bits_Altera:*|\gen:*:Data_meta}] """;
begin
	gen : for i in 0 to BITS - 1 generate
		signal Data_async				: STD_LOGIC;
		signal Data_meta				: STD_LOGIC																		:= INIT(i);
		signal Data_sync				: STD_LOGIC_VECTOR(SYNC_DEPTH - 1 downto 0)		:= (others => INIT(i));

		-- preserve both registers (no optimization, shift register extraction, ...)
		attribute PRESERVE of Data_meta						: signal is TRUE;
		attribute PRESERVE of Data_sync						: signal is TRUE;
		-- Notity the synthesizer / timing analysator to identity a synchronizer circuit
		attribute ALTERA_ATTRIBUTE of Data_meta		: signal is "-name SYNCHRONIZER_IDENTIFICATION ""FORCED IF ASYNCHRONOUS""";
	begin
		Data_async	<= Input(i);
	
		process(Clock)
		begin
			if rising_edge(Clock) then
				Data_meta <= Data_async;
				Data_sync <= Data_sync(Data_sync'high - 1 downto 0) & Data_meta;
			end if;
		end process;
			
		Output(i)		<= Data_sync(Data_sync'high);
	end generate;
	
end architecture;
