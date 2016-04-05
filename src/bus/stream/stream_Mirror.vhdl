-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Patrick Lehmann
-- 
-- Module:				 	A generic buffer module for the PoC.Stream protocol.
--
-- Description:
-- ------------------------------------
--		This module implements a generic buffer (FIFO) for the PoC.Stream protocol.
--		It is generic in DATA_BITS and in META_BITS as well as in FIFO depths for
--		data and meta information.
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
-- WITHOUT WARRANTIES OR CONDITIONS of ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- ============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.vectors.all;


entity stream_Mirror is
	generic (
		portS											: POSITIVE									:= 2;
		DATA_BITS									: POSITIVE									:= 8;
		META_BITS									: T_POSVEC									:= (0 => 8);
		META_LENGTH								: T_POSVEC									:= (0 => 16)
	);
	port (
		Clock											: in	STD_LOGIC;
		Reset											: in	STD_LOGIC;
		
		In_Valid									: in	STD_LOGIC;
		In_Data										: in	STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);
		In_SOF										: in	STD_LOGIC;
		In_EOF										: in	STD_LOGIC;
		In_Ack										: out	STD_LOGIC;
		In_Meta_rst								: out	STD_LOGIC;
		In_Meta_nxt								: out	STD_LOGIC_VECTOR(META_BITS'length - 1 downto 0);
		In_Meta_Data							: in	STD_LOGIC_VECTOR(isum(META_BITS) - 1 downto 0);
		
		Out_Valid									: out	STD_LOGIC_VECTOR(portS - 1 downto 0);
		Out_Data									: out	T_SLM(portS - 1 downto 0, DATA_BITS - 1 downto 0);
		Out_SOF										: out	STD_LOGIC_VECTOR(portS - 1 downto 0);
		Out_EOF										: out	STD_LOGIC_VECTOR(portS - 1 downto 0);
		Out_Ack										: in	STD_LOGIC_VECTOR(portS - 1 downto 0);
		Out_Meta_rst							: in	STD_LOGIC_VECTOR(portS - 1 downto 0);
		Out_Meta_nxt							: in	T_SLM(portS - 1 downto 0, META_BITS'length - 1 downto 0);
		Out_Meta_Data							: out	T_SLM(portS - 1 downto 0, isum(META_BITS) - 1 downto 0)
	);
end entity;


architecture rtl of stream_Mirror is
	attribute KEEP							: BOOLEAN;
	attribute FSM_ENCODING			: STRING;
	
	signal FIFOGlue_put					: STD_LOGIC;
	signal FIFOGlue_DataIn			: STD_LOGIC_VECTOR(DATA_BITS + 1 downto 0);
	signal FIFOGlue_Full				: STD_LOGIC;
	signal FIFOGlue_Valid				: STD_LOGIC;
	signal FIFOGlue_DataOut			: STD_LOGIC_VECTOR(DATA_BITS + 1 downto 0);
	signal FIFOGlue_got					: STD_LOGIC;
	
	signal Ack_i								: STD_LOGIC;
	signal Mask_r								: STD_LOGIC_VECTOR(portS - 1 downto 0)												:= (others => '1');
	
	signal MetaOut_rst					: STD_LOGIC_VECTOR(portS - 1 downto 0);
	
	signal Out_Data_i						: T_SLM(portS - 1 downto 0, DATA_BITS - 1 downto 0)						:= (others => (others => 'Z'));
	signal Out_Meta_Data_i			: T_SLM(portS - 1 downto 0, isum(META_BITS) - 1 downto 0)			:= (others => (others => 'Z'));
begin
	
	-- Data path
	-- ==========================================================================================================================================================
	FIFOGlue_put															<= In_Valid;
	FIFOGlue_DataIn(DATA_BITS - 1 downto 0)		<= In_Data;
	FIFOGlue_DataIn(DATA_BITS + 0)						<= In_SOF;
	FIFOGlue_DataIn(DATA_BITS + 1)						<= In_EOF;
	
	In_Ack																		<= not FIFOGlue_Full;
	
	FIFOGlue : entity PoC.fifo_glue
		generic map (
			D_BITS		=> DATA_BITS + 2					-- Data Width
		)
		port map (
			-- Control
			clk				=> Clock,									-- Clock
			rst				=> Reset,									-- Synchronous Reset
	
			-- Input
			put				=> FIFOGlue_put,					-- Put Value
			di				=> FIFOGlue_DataIn,				-- Data Input
			ful				=> FIFOGlue_Full,					-- Full
	
			-- Output
			vld				=> FIFOGlue_Valid,				-- Data Available
			do				=> FIFOGlue_DataOut,			-- Data Output
			got				=> FIFOGlue_got						-- Data Consumed
  );

	genPorts : for i in 0 to portS - 1 generate
		assign_row(Out_Data_i, FIFOGlue_DataOut(DATA_BITS - 1 downto 0), i);
	end generate;
	
	Ack_i					<= slv_and(Out_Ack) or slv_and(not Mask_r or Out_Ack);
	FIFOGlue_got	<= Ack_i	;

	Out_Valid			<= (portS - 1 downto 0 => FIFOGlue_Valid) and Mask_r;
	Out_Data			<= Out_Data_i;
	Out_SOF				<= (portS - 1 downto 0 => FIFOGlue_DataOut(DATA_BITS + 0));
	Out_EOF				<= (portS - 1 downto 0 => FIFOGlue_DataOut(DATA_BITS + 1));
		
	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or Ack_i	) = '1') then
				Mask_r		<= (others => '1');
			else
				Mask_r		<= Mask_r and not Out_Ack;
			end if;
		end if;
	end process;
	
	-- Metadata path
	-- ==========================================================================================================================================================	
	In_Meta_rst		<= slv_and(MetaOut_rst);
	
	genMeta : for i in 0 to META_BITS'length - 1 generate
		subtype T_METAMEMORY						is STD_LOGIC_VECTOR(META_BITS(i) - 1 downto 0);
		type T_METAMEMORY_VECTOR				is array(NATURAL range <>) of T_METAMEMORY;
		
	begin
		genReg : if (META_LENGTH(i) = 1) generate
			signal MetaMemory_en					: STD_LOGIC;
			signal MetaMemory							: T_METAMEMORY;
		begin
			MetaMemory_en		<= In_Valid and In_SOF;
		
			process(Clock)
			begin
				if rising_edge(Clock) then
					if (MetaMemory_en = '1') then
						MetaMemory		<= In_Meta_Data(high(META_BITS, i) downto low(META_BITS, i));
					end if;
				end if;
			end process;
			
			genReader : FOR J IN 0 to portS - 1 generate
				assign_row(Out_Meta_Data_i, MetaMemory, J, high(META_BITS, i), low(META_BITS, i));
			end generate;
		end generate;
		genMem : if (META_LENGTH(i) > 1) generate
			signal MetaMemory_en					: STD_LOGIC;
			signal MetaMemory							: T_METAMEMORY_VECTOR(META_LENGTH(i) - 1 downto 0);
			
			signal Writer_CounterControl	: STD_LOGIC																						:= '0';
			
			signal Writer_en							: STD_LOGIC;
			signal Writer_rst							: STD_LOGIC;
			signal Writer_us							: UNSIGNED(log2ceilnz(META_LENGTH(i)) - 1 downto 0)		:= (others => '0');
		begin
			-- MetaMemory Write Pointer Control
			process(Clock)
			begin
				if rising_edge(Clock) then
					if (Reset = '1') then
						Writer_CounterControl			<= '0';
					else
						if ((In_Valid and In_SOF) = '1') then
							Writer_CounterControl		<= '1';
						elsif (Writer_us = (META_LENGTH(i) - 1)) then
							Writer_CounterControl		<= '0';
						end if;
					end if;
				end if;
			end process;
		
			Writer_en				<= (In_Valid and In_SOF) or Writer_CounterControl;
			
			In_Meta_nxt(i)	<= Writer_en;
			MetaMemory_en		<= Writer_en;
			MetaOut_rst(i)	<= NOT Writer_en;
			
			-- MetaMemory - Write Pointer
			process(Clock)
			begin
				if rising_edge(Clock) then
					if (Writer_en = '0') then
						Writer_us			<= (others => '0');
					else
						Writer_us			<= Writer_us + 1;
					end if;
				end if;
			end process;

			-- MetaMemory
			process(Clock)
			begin
				if rising_edge(Clock) then
					if (MetaMemory_en = '1') then
						MetaMemory(to_integer(Writer_us))		<= In_Meta_Data(high(META_BITS, i) downto low(META_BITS, i));
					end if;
				end if;
			end process;
		
			genReader : for j in 0 to portS - 1 generate
				signal Row							: T_METAMEMORY;
				
				signal Reader_en				: STD_LOGIC;
				signal Reader_rst				: STD_LOGIC;
				signal Reader_us				: UNSIGNED(log2ceilnz(META_LENGTH(i)) - 1 downto 0)		:= (others => '0');
			begin
				Reader_rst		<= Out_Meta_rst(j) or (In_Valid and In_SOF);
				Reader_en			<= Out_Meta_nxt(j, i);
			
				process(Clock)
				begin
					if rising_edge(Clock) then
						if (Reader_rst = '1') then
							Reader_us			<= (others => '0');
						elsif (Reader_en = '1') then
							Reader_us			<= Reader_us + 1;
						end if;
					end if;
				end process;
			
				Row <= MetaMemory(to_integer(Reader_us));
				assign_row(Out_Meta_Data_i, Row, j, high(META_BITS, i), low(META_BITS, i));
			end generate;		-- for each port
		end generate;		-- if length > 1
	end generate;		-- for each metadata stream
	
	Out_Meta_Data		<= Out_Meta_Data_i;
	
end architecture;
