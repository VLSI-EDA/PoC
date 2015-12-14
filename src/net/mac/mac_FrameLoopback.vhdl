-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Patrick Lehmann
-- 
-- Module:				 	TODO
--
-- Description:
-- ------------------------------------
--		TODO
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
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.net.all;


entity mac_FrameLoopback is
	generic (
		MAX_FRAMES										: POSITIVE						:= 4
	);
	port (
		Clock													: in	STD_LOGIC;
		Reset													: in	STD_LOGIC;
		-- IN Port
		In_Valid											: in	STD_LOGIC;
		In_Data												: in	T_SLV_8;
		In_SOF												: in	STD_LOGIC;
		In_EOF												: in	STD_LOGIC;
		In_Ack												: out	STD_LOGIC;
		In_Meta_rst										: out	STD_LOGIC;
		In_Meta_SrcMACAddress_nxt			: out	STD_LOGIC;
		In_Meta_SrcMACAddress_Data		: in	T_SLV_8;
		In_Meta_DestMACAddress_nxt		: out	STD_LOGIC;
		In_Meta_DestMACAddress_Data		: in	T_SLV_8;
		-- OUT Port
		Out_Valid											: out	STD_LOGIC;
		Out_Data											: out	T_SLV_8;
		Out_SOF												: out	STD_LOGIC;
		Out_EOF												: out	STD_LOGIC;
		Out_Ack												: in	STD_LOGIC;
		Out_Meta_rst									: in	STD_LOGIC;
		Out_Meta_SrcMACAddress_nxt		: in	STD_LOGIC;
		Out_Meta_SrcMACAddress_Data		: out	T_SLV_8;
		Out_Meta_DestMACAddress_nxt		: in	STD_LOGIC;
		Out_Meta_DestMACAddress_Data	: out	T_SLV_8
	);
end entity;


architecture rtl of mac_FrameLoopback is
	constant META_STREAMID_SRCADDR		: NATURAL					:= 0;
	constant META_STREAMID_DESTADDR		: NATURAL					:= 1;
	
	constant META_BITS								: T_POSVEC				:= (
		META_STREAMID_SRCADDR			=> 8,
		META_STREAMID_DESTADDR		=> 8
	);
	
	constant META_FIFO_DEPTHS					: T_POSVEC				:= (
		META_STREAMID_SRCADDR			=> 6,
		META_STREAMID_DESTADDR		=> 6
	);

	signal LLBuf_MetaIn_nxt						: STD_LOGIC_VECTOR(META_BITS'length - 1 downto 0);
	signal LLBuf_MetaIn_Data					: STD_LOGIC_VECTOR(isum(META_BITS) - 1 downto 0);
	signal LLBuf_MetaOut_nxt					: STD_LOGIC_VECTOR(META_BITS'length - 1 downto 0);
	signal LLBuf_MetaOut_Data					: STD_LOGIC_VECTOR(isum(META_BITS) - 1 downto 0);
	
begin
	LLBuf_MetaIn_Data(high(META_BITS, META_STREAMID_SRCADDR)	downto low(META_BITS, META_STREAMID_SRCADDR))		<= In_Meta_SrcMACAddress_Data;
	LLBuf_MetaIn_Data(high(META_BITS, META_STREAMID_DESTADDR)	downto low(META_BITS, META_STREAMID_DESTADDR))	<= In_Meta_DestMACAddress_Data;
	
	In_Meta_SrcMACAddress_nxt		<= LLBuf_MetaIn_nxt(META_STREAMID_SRCADDR);
	In_Meta_DestMACAddress_nxt	<= LLBuf_MetaIn_nxt(META_STREAMID_DESTADDR);

	LLBuf : entity PoC.stream_Buffer
		generic map (
			FRAMES												=> MAX_FRAMES,
			DATA_BITS											=> 8,
			DATA_FIFO_DEPTH								=> 1024,
			META_BITS											=> META_BITS,
			META_FIFO_DEPTH								=> META_FIFO_DEPTHS
		)
		port map(
			Clock													=> Clock,
			Reset													=> Reset,
			
			In_Valid											=> In_Valid,
			In_Data												=> In_Data,
			In_SOF												=> In_SOF,
			In_EOF												=> In_EOF,
			In_Ack												=> In_Ack,
			In_Meta_rst										=> In_Meta_rst,
			In_Meta_nxt										=> LLBuf_MetaIn_nxt,
			In_Meta_Data									=> LLBuf_MetaIn_Data,
			
			Out_Valid											=> Out_Valid,
			Out_Data											=> Out_Data,
			Out_SOF												=> Out_SOF,
			Out_EOF												=> Out_EOF,
			Out_Ack												=> Out_Ack,
			Out_Meta_rst									=> Out_Meta_rst,
			Out_Meta_nxt									=> LLBuf_MetaOut_nxt,
			Out_Meta_Data									=> LLBuf_MetaOut_Data
		);
	
	-- unpack LLBuf metadata to signals
	Out_Meta_SrcMACAddress_Data								<= LLBuf_MetaOut_Data(high(META_BITS, META_STREAMID_DESTADDR)	downto low(META_BITS, META_STREAMID_DESTADDR));			-- Crossover: Source <= Destination
	Out_Meta_DestMACAddress_Data							<= LLBuf_MetaOut_Data(high(META_BITS, META_STREAMID_SRCADDR)	downto low(META_BITS, META_STREAMID_SRCADDR));			-- Crossover: Destination <= Source
	
	-- pack metadata nxt signals to LLBuf meta vector
	LLBuf_MetaOut_nxt(META_STREAMID_SRCADDR)	<= Out_Meta_DestMACAddress_nxt;
	LLBuf_MetaOut_nxt(META_STREAMID_DESTADDR)	<= Out_Meta_SrcMACAddress_nxt;
	
end architecture;
