-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	TODO
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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
-- =============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.net.all;


entity udp_FrameLoopback is
	generic (
		IP_VERSION										: positive						:= 6;
		MAX_FRAMES										: positive						:= 4
	);
	port (
		Clock													: in	std_logic;
		Reset													: in	std_logic;
		-- IN port
		In_Valid											: in	std_logic;
		In_Data												: in	T_SLV_8;
		In_SOF												: in	std_logic;
		In_EOF												: in	std_logic;
		In_Ack												: out	std_logic;
		In_Meta_rst										: out	std_logic;
		In_Meta_DestIPAddress_nxt			: out	std_logic;
		In_Meta_DestIPAddress_Data		: in	T_SLV_8;
		In_Meta_SrcIPAddress_nxt			: out	std_logic;
		In_Meta_SrcIPAddress_Data			: in	T_SLV_8;
		In_Meta_DestPort							: in	T_NET_UDP_PORT;
		In_Meta_SrcPort								: in	T_NET_UDP_PORT;
		-- OUT port
		Out_Valid											: out	std_logic;
		Out_Data											: out	T_SLV_8;
		Out_SOF												: out	std_logic;
		Out_EOF												: out	std_logic;
		Out_Ack												: in	std_logic;
		Out_Meta_rst									: in	std_logic;
		Out_Meta_DestIPAddress_nxt		: in	std_logic;
		Out_Meta_DestIPAddress_Data		: out	T_SLV_8;
		Out_Meta_SrcIPAddress_nxt			: in	std_logic;
		Out_Meta_SrcIPAddress_Data		: out	T_SLV_8;
		Out_Meta_DestPort							: out	T_NET_UDP_PORT;
		Out_Meta_SrcPort							: out	T_NET_UDP_PORT
	);
end entity;


architecture rtl of udp_FrameLoopback is
	constant IPADDRESS_LENGTH					: positive				:= ite((IP_VERSION = 4), 4, 16);

	constant META_STREAMID_SRCADDR		: natural					:= 0;
	constant META_STREAMID_DESTADDR		: natural					:= 1;
	constant META_STREAMID_SRCPORT		: natural					:= 2;
	constant META_STREAMID_DESTPORT		: natural					:= 3;

	constant META_BITS								: T_POSVEC				:= (
		META_STREAMID_SRCADDR			=> 8,
		META_STREAMID_DESTADDR		=> 8,
		META_STREAMID_SRCPORT			=> 16,
		META_STREAMID_DESTPORT		=> 16
	);

	constant META_FIFO_DEPTHS					: T_POSVEC				:= (
		META_STREAMID_SRCADDR			=> IPADDRESS_LENGTH,
		META_STREAMID_DESTADDR		=> IPADDRESS_LENGTH,
		META_STREAMID_SRCPORT			=> 1,
		META_STREAMID_DESTPORT		=> 1
	);

	signal StmBuf_MetaIn_nxt					: std_logic_vector(META_BITS'length - 1 downto 0);
	signal StmBuf_MetaIn_Data					: std_logic_vector(isum(META_BITS) - 1 downto 0);
	signal StmBuf_MetaOut_nxt					: std_logic_vector(META_BITS'length - 1 downto 0);
	signal StmBuf_MetaOut_Data				: std_logic_vector(isum(META_BITS) - 1 downto 0);

begin
	StmBuf_MetaIn_Data(high(META_BITS, META_STREAMID_SRCADDR)		downto low(META_BITS, META_STREAMID_SRCADDR))		<= In_Meta_SrcIPAddress_Data;
	StmBuf_MetaIn_Data(high(META_BITS, META_STREAMID_DESTADDR)	downto low(META_BITS, META_STREAMID_DESTADDR))	<= In_Meta_DestIPAddress_Data;
	StmBuf_MetaIn_Data(high(META_BITS, META_STREAMID_SRCPORT)		downto low(META_BITS, META_STREAMID_SRCPORT))		<= In_Meta_SrcPort;
	StmBuf_MetaIn_Data(high(META_BITS, META_STREAMID_DESTPORT)	downto low(META_BITS, META_STREAMID_DESTPORT))	<= In_Meta_DestPort;

	In_Meta_SrcIPAddress_nxt		<= StmBuf_MetaIn_nxt(META_STREAMID_SRCADDR);
	In_Meta_DestIPAddress_nxt		<= StmBuf_MetaIn_nxt(META_STREAMID_DESTADDR);

	StmBuf : entity PoC.stream_Buffer
		generic map (
			FRAMES												=> MAX_FRAMES,
			DATA_BITS											=> 8,
			DATA_FIFO_DEPTH								=> 1024,
			META_BITS											=> META_BITS,
			META_FIFO_DEPTH								=> META_FIFO_DEPTHS
		)
		port map (
			Clock													=> Clock,
			Reset													=> Reset,

			In_Valid											=> In_Valid,
			In_Data												=> In_Data,
			In_SOF												=> In_SOF,
			In_EOF												=> In_EOF,
			In_Ack												=> In_Ack,
			In_Meta_rst										=> In_Meta_rst,
			In_Meta_nxt										=> StmBuf_MetaIn_nxt,
			In_Meta_Data									=> StmBuf_MetaIn_Data,

			Out_Valid											=> Out_Valid,
			Out_Data											=> Out_Data,
			Out_SOF												=> Out_SOF,
			Out_EOF												=> Out_EOF,
			Out_Ack												=> Out_Ack,
			Out_Meta_rst									=> Out_Meta_rst,
			Out_Meta_nxt									=> StmBuf_MetaOut_nxt,
			Out_Meta_Data									=> StmBuf_MetaOut_Data
		);

	-- unpack buffer metadata to signals
	Out_Meta_SrcIPAddress_Data									<= StmBuf_MetaOut_Data(high(META_BITS, META_STREAMID_DESTADDR)	downto low(META_BITS, META_STREAMID_DESTADDR));			-- Crossover: Source <= Destination
	Out_Meta_DestIPAddress_Data									<= StmBuf_MetaOut_Data(high(META_BITS, META_STREAMID_SRCADDR)		downto low(META_BITS, META_STREAMID_SRCADDR));			-- Crossover: Destination <= Source
	Out_Meta_SrcPort														<= StmBuf_MetaOut_Data(high(META_BITS, META_STREAMID_DESTPORT)	downto low(META_BITS, META_STREAMID_DESTPORT));			-- Crossover: Source <= Destination
	Out_Meta_DestPort														<= StmBuf_MetaOut_Data(high(META_BITS, META_STREAMID_SRCPORT)		downto low(META_BITS, META_STREAMID_SRCPORT));			-- Crossover: Destination <= Source

	-- pack metadata nxt signals to StmBuf meta vector
	StmBuf_MetaOut_nxt(META_STREAMID_SRCADDR)		<= Out_Meta_DestIPAddress_nxt;
	StmBuf_MetaOut_nxt(META_STREAMID_DESTADDR)	<= Out_Meta_SrcIPAddress_nxt;
	StmBuf_MetaOut_nxt(META_STREAMID_SRCPORT)		<= '0';
	StmBuf_MetaOut_nxt(META_STREAMID_DESTPORT)	<= '0';

end architecture;
