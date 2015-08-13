-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Module:				 	sync_Reset_Altera
-- 
-- Description:
-- ------------------------------------
--		This is a clock-domain-crossing circuit for reset signals optimized for
--		Altera FPGAs. It infers 2 flip flops with asynchronous preset and notifies
--		Quartus II, that these flip flops are synchronizer flip flops. If you need
--		a platform independent version of this synchronizer, please use
--		'PoC.misc.sync.sync_Reset', which internally instantiates this module if
--		a Altera FPGA is detected.
--		
--		ATTENTION:
--			Use this synchronizer only for reset signals.
--
--		CONSTRAINTS:
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


entity sync_Reset_Altera is
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


architecture rtl of sync_Reset_Altera is
	attribute altera_attribute	: STRING;
	attribute preserve					: BOOLEAN;
begin
	gen : for i in 0 to BITS - 1 generate
		signal Data_async				: STD_LOGIC;
		signal Data_meta				: STD_LOGIC		:= '1';
		signal Data_sync				: STD_LOGIC		:= '1';

		-- Apply a SDC constraint to meta stable flip flop
		attribute altera_attribute of rtl					: architecture is "-name SDC_STATEMENT ""set_false_path -to *|sync_Reset_Altera:*|Data_meta """;
		-- Notity the synthesizer / timing analysator to identity a synchronizer circuit
		attribute altera_attribute of Data_meta		: signal is "-name SYNCHRONIZER_IDENTIFICATION ""FORCED IF ASYNCHRONOUS""";
		-- preserve both registers (no optimization, shift register extraction, ...)
		attribute preserve of Data_meta						: signal is TRUE;
		attribute preserve of Data_sync						: signal is TRUE;
	begin
		Data_async	<= '0';
	
		process(Clock)
		begin
			if (Input = '1') then
				Data_meta <= '1';
				Data_sync <= '1';
			elsif rising_edge(Clock) then
				Data_meta <= Data_async;
				Data_sync <= Data_meta;
			end if;
		end process;
			
		Output(i)		<= Data_sync;
	end generate;
	
end architecture;
