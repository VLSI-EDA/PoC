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


entity ipv6_Wrapper is
	generic (
		DEBUG														: BOOLEAN													:= FALSE;
		PACKET_TYPES										: T_NET_IPV6_NEXT_HEADER_VECTOR		:= (0 => x"00")
	);
	port (
		Clock														: in	STD_LOGIC;
		Reset														: in	STD_LOGIC;
		-- to MAC layer
		MAC_TX_Valid										: out	STD_LOGIC;
		MAC_TX_Data											: out	T_SLV_8;
		MAC_TX_SOF											: out	STD_LOGIC;
		MAC_TX_EOF											: out	STD_LOGIC;
		MAC_TX_Ack											: in	STD_LOGIC;
		MAC_TX_Meta_rst									: in	STD_LOGIC;
		MAC_TX_Meta_DestMACAddress_nxt	: in	STD_LOGIC;
		MAC_TX_Meta_DestMACAddress_Data	: out	T_SLV_8;
		-- from MAC layer
		MAC_RX_Valid										: in	STD_LOGIC;
		MAC_RX_Data											: in	T_SLV_8;
		MAC_RX_SOF											: in	STD_LOGIC;
		MAC_RX_EOF											: in	STD_LOGIC;
		MAC_RX_Ack											: out	STD_LOGIC;
		MAC_RX_Meta_rst									: out	STD_LOGIC;
		MAC_RX_Meta_SrcMACAddress_nxt		: out	STD_LOGIC;
		MAC_RX_Meta_SrcMACAddress_Data	: in	T_SLV_8;
		MAC_RX_Meta_DestMACAddress_nxt	: out	STD_LOGIC;
		MAC_RX_Meta_DestMACAddress_Data	: in	T_SLV_8;
		MAC_RX_Meta_EthType							: in	T_SLV_16;
		-- to NDP layer
		NDP_NextHop_Query								: out	STD_LOGIC;
		NDP_NextHop_IPv6Address_rst			: in	STD_LOGIC;
		NDP_NextHop_IPv6Address_nxt			: in	STD_LOGIC;
		NDP_NextHop_IPv6Address_Data		: out	T_SLV_8;
		-- from NDP layer
		NDP_NextHop_Valid								: in	STD_LOGIC;
		NDP_NextHop_MACAddress_rst			: out	STD_LOGIC;
		NDP_NextHop_MACAddress_nxt			: out	STD_LOGIC;
		NDP_NextHop_MACAddress_Data			: in	T_SLV_8;
		-- from upper layer
		TX_Valid												: in	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		TX_Data													: in	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		TX_SOF													: in	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		TX_EOF													: in	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		TX_Ack													: out	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_rst											: out	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_SrcIPv6Address_nxt			: out	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_SrcIPv6Address_Data			: in	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_DestIPv6Address_nxt			: out	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_DestIPv6Address_Data		: in	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_TrafficClass						: in	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_FlowLabel								: in	T_SLVV_24(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_Length									: in	T_SLVV_16(PACKET_TYPES'length - 1 downto 0);
		-- to upper layer
		RX_Valid												: out	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		RX_Data													: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_SOF													: out	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		RX_EOF													: out	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		RX_Ack													: in	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_rst											: in	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_SrcMACAddress_nxt				: in	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_SrcMACAddress_Data			: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_DestMACAddress_nxt			: in	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_DestMACAddress_Data			: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_EthType									: out	T_SLVV_16(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_SrcIPv6Address_nxt			: in	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_SrcIPv6Address_Data			: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_DestIPv6Address_nxt			: in	STD_LOGIC_VECTOR(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_DestIPv6Address_Data		: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_TrafficClass						: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_FlowLabel								: out	T_SLVV_24(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_Length									: out	T_SLVV_16(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_NextHeader							: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0)
	);
end entity;

architecture rtl of ipv6_Wrapper is
	constant IPV6_SWITCH_PORTS									: POSITIVE				:= PACKET_TYPES'length;
	
	constant LLMUX_META_RST_BIT									: NATURAL					:= 0;
	constant LLMUX_META_SRC_NXT_BIT							: NATURAL					:= 1;
	constant LLMUX_META_DEST_NXT_BIT						: NATURAL					:= 2;
	
	constant LLMUX_META_BITS										: NATURAL					:= 40;
	constant LLMUX_META_REV_BITS								: NATURAL					:= 3;
	
	signal LLMux_In_Valid												: STD_LOGIC_VECTOR(IPV6_SWITCH_PORTS - 1 downto 0);
	signal LLMux_In_Data												: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, T_SLV_8'range)											:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal LLMux_In_Meta												: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, LLMUX_META_BITS - 1 downto 0)				:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal LLMux_In_Meta_rev										: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, LLMUX_META_REV_BITS - 1 downto 0)		:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal LLMux_In_SOF													: STD_LOGIC_VECTOR(IPV6_SWITCH_PORTS - 1 downto 0);
	signal LLMux_In_EOF													: STD_LOGIC_VECTOR(IPV6_SWITCH_PORTS - 1 downto 0);
	signal LLMux_In_Ack													: STD_LOGIC_VECTOR(IPV6_SWITCH_PORTS - 1 downto 0);
	
	signal TX_LLMux_Valid												: STD_LOGIC;
	signal TX_LLMux_Data												: T_SLV_8;
	signal TX_LLMux_Meta												: STD_LOGIC_VECTOR(LLMUX_META_BITS - 1 downto 0);
	signal TX_LLMux_Meta_rev										: STD_LOGIC_VECTOR(LLMUX_META_REV_BITS - 1 downto 0);
	signal TX_LLMux_SOF													: STD_LOGIC;
	signal TX_LLMux_EOF													: STD_LOGIC;
	signal TX_LLMux_SrcIPv6Address_Data					: STD_LOGIC_VECTOR( 7 downto  0);
	signal TX_LLMux_DestIPv6Address_Data				: STD_LOGIC_VECTOR(15 downto  8);
	signal TX_LLMux_Length											: STD_LOGIC_VECTOR(31 downto 16);
	signal TX_LLMux_NextHeader									: STD_LOGIC_VECTOR(39 downto 32);
	
	signal IPv6_TX_Ack													: STD_LOGIC;
	signal IPv6_TX_Meta_rst											: STD_LOGIC;
	signal IPv6_TX_Meta_SrcIPv6Address_nxt			: STD_LOGIC;
	signal IPv6_TX_Meta_DestIPv6Address_nxt			: STD_LOGIC;
	
	signal IPv6_RX_Valid												: STD_LOGIC;
	signal IPv6_RX_Data													: T_SLV_8;
	signal IPv6_RX_SOF													: STD_LOGIC;
	signal IPv6_RX_EOF													: STD_LOGIC;
	
	signal IPv6_RX_Meta_SrcMACAddress_Data			: T_SLV_8;
	signal IPv6_RX_Meta_DestMACAddress_Data			: T_SLV_8;
	signal IPv6_RX_Meta_EthType									: T_SLV_16;
	signal IPv6_RX_Meta_SrcIPv6Address_Data			: T_SLV_8;
	signal IPv6_RX_Meta_DestIPv6Address_Data		: T_SLV_8;
	signal IPv6_RX_Meta_TrafficClass						: T_SLV_8;
	signal IPv6_RX_Meta_FlowLabel								: T_SLV_24;
	signal IPv6_RX_Meta_Length									: T_SLV_16;
	signal IPv6_RX_Meta_NextHeader							: T_SLV_8;
	
	constant LLDEMUX_META_RST_BIT								: NATURAL					:= 0;
	constant LLDEMUX_META_MACSRC_NXT_BIT				: NATURAL					:= 1;
	constant LLDEMUX_META_MACDEST_NXT_BIT				: NATURAL					:= 2;
	constant LLDEMUX_META_IPV6SRC_NXT_BIT				: NATURAL					:= 3;
	constant LLDEMUX_META_IPV6DEST_NXT_BIT			: NATURAL					:= 4;
	
	constant LLDEMUX_META_STREAMID_SRCMAC				: NATURAL					:= 0;
	constant LLDEMUX_META_STREAMID_DESTMAC			: NATURAL					:= 1;
	constant LLDEMUX_META_STREAMID_ETHTYPE			: NATURAL					:= 2;
	constant LLDEMUX_META_STREAMID_SRCIP				: NATURAL					:= 3;
	constant LLDEMUX_META_STREAMID_DESTIP				: NATURAL					:= 4;
	constant LLDEMUX_META_STREAMID_LENGTH				: NATURAL					:= 5;
	constant LLDEMUX_META_STREAMID_HEADER				: NATURAL					:= 6;
	
	constant LLDEMUX_DATA_BITS									: NATURAL					:= 8;							-- 
	constant LLDEMUX_META_BITS									: T_POSVEC				:= (
		LLDEMUX_META_STREAMID_SRCMAC		=> 8,
		LLDEMUX_META_STREAMID_DESTMAC 	=> 8,
		LLDEMUX_META_STREAMID_ETHTYPE 	=> 16,
		LLDEMUX_META_STREAMID_SRCIP			=> 8,
		LLDEMUX_META_STREAMID_DESTIP		=> 8,
		LLDEMUX_META_STREAMID_LENGTH		=> 16,
		LLDEMUX_META_STREAMID_HEADER		=> 8
	);
	constant LLDEMUX_META_REV_BITS							: NATURAL					:= 5;							-- sum over all control bits (rst, nxt, nxt, nxt, nxt)
	
	signal RX_LLDeMux_Ack												: STD_LOGIC;
	signal RX_LLDeMux_Meta_rst									: STD_LOGIC;
	signal RX_LLDeMux_Meta_SrcMACAddress_nxt		: STD_LOGIC;
	signal RX_LLDeMux_Meta_DestMACAddress_nxt		: STD_LOGIC;
	signal RX_LLDeMux_Meta_SrcIPv6Address_nxt		: STD_LOGIC;
	signal RX_LLDeMux_Meta_DestIPv6Address_nxt	: STD_LOGIC;
	
	signal RX_LLDeMux_MetaIn										: STD_LOGIC_VECTOR(isum(LLDEMUX_META_BITS) - 1 downto 0);
	signal RX_LLDeMux_MetaIn_rev								: STD_LOGIC_VECTOR(LLDEMUX_META_REV_BITS - 1 downto 0);
	signal RX_LLDeMux_Data											: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, LLDEMUX_DATA_BITS - 1 downto 0)				:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal RX_LLDeMux_MetaOut										: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, isum(LLDEMUX_META_BITS) - 1 downto 0)	:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal RX_LLDeMux_MetaOut_rev								: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, LLDEMUX_META_REV_BITS - 1 downto 0)		:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	
	signal LLDeMux_Control											: STD_LOGIC_VECTOR(IPV6_SWITCH_PORTS - 1 downto 0);
	
begin
-- ============================================================================================================================================================
-- TX Path
-- ============================================================================================================================================================
	genTXLLBuf : for i in 0 to IPV6_SWITCH_PORTS - 1 generate
		constant TXLLBuf_META_STREAMID_SRC			: NATURAL																									:= 0;
		constant TXLLBuf_META_STREAMID_DEST			: NATURAL																									:= 1;
		constant TXLLBuf_META_STREAMID_LEN			: NATURAL																									:= 2;
		constant TXLLBuf_META_STREAMS						: POSITIVE																								:= 3;		-- Source, Destination, Length
	
		signal Meta_rst													: STD_LOGIC;
		signal Meta_nxt													: STD_LOGIC_VECTOR(TXLLBuf_META_STREAMS - 1 downto 0);
	
		signal LLBuf_DataOut										: T_SLV_8;
		signal LLBuf_MetaIn											: T_SLM(TXLLBuf_META_STREAMS - 1 downto 0, 15 downto 0)		:= (others => (others => 'Z'));
		signal LLBuf_MetaOut										: T_SLM(TXLLBuf_META_STREAMS - 1 downto 0, 15 downto 0);
		signal LLBuf_Meta_rst										: STD_LOGIC;
		signal LLBuf_Meta_nxt										: STD_LOGIC_VECTOR(TXLLBuf_META_STREAMS - 1 downto 0);
		
		signal LLBuf_Meta_SrcIPv6Address_Data		: STD_LOGIC_VECTOR(TX_LLMux_SrcIPv6Address_Data'range);
		signal LLBuf_Meta_DestIPv6Address_Data	: STD_LOGIC_VECTOR(TX_LLMux_DestIPv6Address_Data'range);
		signal LLBuf_Meta_Length								: STD_LOGIC_VECTOR(TX_LLMux_Length'range);
		signal LLBuf_Meta_NextHeader						: STD_LOGIC_VECTOR(TX_LLMux_NextHeader'range);
		
		signal LLMux_MetaIn											: STD_LOGIC_VECTOR(LLBuf_Meta_NextHeader'high downto LLBuf_Meta_SrcIPv6Address_Data'low);
		
	begin
		assign_row(LLBuf_MetaIn, TX_Meta_SrcIPv6Address_Data(I),	TXLLBuf_META_STREAMID_SRC,	0, '0');
		assign_row(LLBuf_MetaIn, TX_Meta_DestIPv6Address_Data(I),	TXLLBuf_META_STREAMID_DEST, 0, '0');
		assign_row(LLBuf_MetaIn, TX_Meta_Length(I),								TXLLBuf_META_STREAMID_LEN);
	
		TX_Meta_rst(I)									<= Meta_rst;
		TX_Meta_SrcIPv6Address_nxt(I)		<= Meta_nxt(TXLLBuf_META_STREAMID_SRC);
		TX_Meta_DestIPv6Address_nxt(I)	<= Meta_nxt(TXLLBuf_META_STREAMID_DEST);
	
		TX_LLBuf : entity PoC.stream_Buffer
			generic map (
				FRAMES												=> 2,
				DATA_BITS											=> 8,
				DATA_FIFO_DEPTH								=> 16,
				META_BITS											=> (TXLLBuf_META_STREAMID_SRC => 8,		TXLLBuf_META_STREAMID_DEST => 8,	TXLLBuf_META_STREAMID_LEN => 16),
				META_FIFO_DEPTH								=> (TXLLBuf_META_STREAMID_SRC => 16,	TXLLBuf_META_STREAMID_DEST => 16,	TXLLBuf_META_STREAMID_LEN => 1)
			)
			port map (
				Clock													=> Clock,
				Reset													=> Reset,
				
				In_Valid											=> TX_Valid(I),
				In_Data												=> TX_Data(I),
				In_SOF												=> TX_SOF(I),
				In_EOF												=> TX_EOF(I),
				In_Ack												=> TX_Ack	(I),
				In_Meta_rst										=> Meta_rst,
				In_Meta_nxt										=> Meta_nxt,
				In_Meta_Data									=> LLBuf_MetaIn,
				
				Out_Valid											=> LLMux_In_Valid(I),
				Out_Data											=> LLBuf_DataOut,
				Out_SOF												=> LLMux_In_SOF(I),
				Out_EOF												=> LLMux_In_EOF(I),
				Out_Ack												=> LLMux_In_Ack	(I),
				Out_Meta_rst									=> LLBuf_Meta_rst,
				Out_Meta_nxt									=> LLBuf_Meta_nxt,
				Out_Meta_Data									=> LLBuf_MetaOut
			);
		
		-- unpack LLBuf metadata to signals
		LLBuf_Meta_SrcIPv6Address_Data												<= get_row(LLBuf_MetaOut, TXLLBuf_META_STREAMID_SRC,	8);
		LLBuf_Meta_DestIPv6Address_Data												<= get_row(LLBuf_MetaOut, TXLLBuf_META_STREAMID_DEST,	8);
		LLBuf_Meta_Length																			<= get_row(LLBuf_MetaOut, TXLLBuf_META_STREAMID_LEN);
		
		LLBuf_Meta_rst																				<= LLMux_In_Meta_rev(I, LLMUX_META_RST_BIT);
		LLBuf_Meta_nxt(TXLLBuf_META_STREAMID_SRC)							<= LLMux_In_Meta_rev(I, LLMUX_META_SRC_NXT_BIT);
		LLBuf_Meta_nxt(TXLLBuf_META_STREAMID_DEST)						<= LLMux_In_Meta_rev(I, LLMUX_META_DEST_NXT_BIT);
		LLBuf_Meta_nxt(TXLLBuf_META_STREAMID_LEN)							<= '0';
		
		-- pack metadata into 1 dim vector
		LLMux_MetaIn(LLBuf_Meta_SrcIPv6Address_Data'range)		<= LLBuf_Meta_SrcIPv6Address_Data;
		LLMux_MetaIn(LLBuf_Meta_DestIPv6Address_Data'range)		<= LLBuf_Meta_DestIPv6Address_Data;
		LLMux_MetaIn(LLBuf_Meta_Length'range)									<= LLBuf_Meta_Length;
		LLMux_MetaIn(LLBuf_Meta_NextHeader'range)							<= PACKET_TYPES(I);
		
		-- assign vectors to matrix
		assign_row(LLMux_In_Data, LLBuf_DataOut, I);
		assign_row(LLMux_In_Meta, LLMux_MetaIn, I);
	end generate;


	TX_LLMux : entity PoC.stream_Mux
		generic map (
			PORTS									=> IPV6_SWITCH_PORTS,
			DATA_BITS							=> TX_LLMux_Data'length,
			META_BITS							=> TX_LLMux_Meta'length,
			META_REV_BITS					=> TX_LLMux_Meta_rev'length
		)
		port map (
			Clock									=> Clock,
			Reset									=> Reset,
			
			In_Valid							=> LLMux_In_Valid,
			In_Data								=> LLMux_In_Data,
			In_Meta								=> LLMux_In_Meta,
			In_Meta_rev						=> LLMux_In_Meta_rev,
			In_SOF								=> LLMux_In_SOF,
			In_EOF								=> LLMux_In_EOF,
			In_Ack								=> LLMux_In_Ack,
			
			Out_Valid							=> TX_LLMux_Valid,
			Out_Data							=> TX_LLMux_Data,
			Out_Meta							=> TX_LLMux_Meta,
			Out_Meta_rev					=> TX_LLMux_Meta_rev,
			Out_SOF								=> TX_LLMux_SOF,
			Out_EOF								=> TX_LLMux_EOF,
			Out_Ack								=> IPv6_TX_Ack	
		);

	TX_LLMux_SrcIPv6Address_Data								<= TX_LLMux_Meta(TX_LLMux_SrcIPv6Address_Data'range);
	TX_LLMux_DestIPv6Address_Data								<= TX_LLMux_Meta(TX_LLMux_DestIPv6Address_Data'range);
	TX_LLMux_Length															<= TX_LLMux_Meta(TX_LLMux_Length'range);
	TX_LLMux_NextHeader													<= TX_LLMux_Meta(TX_LLMux_NextHeader'range);
	
	TX_LLMux_Meta_rev(LLMUX_META_RST_BIT)				<= IPv6_TX_Meta_rst;
	TX_LLMux_Meta_rev(LLMUX_META_SRC_NXT_BIT)		<= IPv6_TX_Meta_SrcIPv6Address_nxt;
	TX_LLMux_Meta_rev(LLMUX_META_DEST_NXT_BIT)	<= IPv6_TX_Meta_DestIPv6Address_nxt;

	TX_IPv6 : entity PoC.ipv6_TX
		generic map (
			DEBUG								=> DEBUG
		)
		port map (
			Clock													=> Clock,
			Reset													=> Reset,
			
			In_Valid											=> TX_LLMux_Valid,
			In_Data												=> TX_LLMux_Data,
			In_SOF												=> TX_LLMux_SOF,
			In_EOF												=> TX_LLMux_EOF,
			In_Ack												=> IPv6_TX_Ack,
			In_Meta_rst										=> IPv6_TX_Meta_rst,
			In_Meta_SrcIPv6Address_nxt		=> IPv6_TX_Meta_SrcIPv6Address_nxt,
			In_Meta_SrcIPv6Address_Data		=> TX_LLMux_SrcIPv6Address_Data,
			In_Meta_DestIPv6Address_nxt		=> IPv6_TX_Meta_DestIPv6Address_nxt,
			In_Meta_DestIPv6Address_Data	=> TX_LLMux_DestIPv6Address_Data,
			In_Meta_TrafficClass					=> (others => '0'),		-- not connected through LLMux and TX_LLBuf
			In_Meta_FlowLabel							=> (others => '0'),		-- not connected through LLMux and TX_LLBuf
			In_Meta_Length								=> TX_LLMux_Length,
			In_Meta_NextHeader						=> TX_LLMux_NextHeader,
			
			NDP_NextHop_Query							=> NDP_NextHop_Query,
			NDP_NextHop_IPv6Address_rst		=> NDP_NextHop_IPv6Address_rst,
			NDP_NextHop_IPv6Address_nxt		=> NDP_NextHop_IPv6Address_nxt,
			NDP_NextHop_IPv6Address_Data	=> NDP_NextHop_IPv6Address_Data,
			
			NDP_NextHop_Valid							=> NDP_NextHop_Valid,
			NDP_NextHop_MACAddress_rst		=> NDP_NextHop_MACAddress_rst,
			NDP_NextHop_MACAddress_nxt		=> NDP_NextHop_MACAddress_nxt,
			NDP_NextHop_MACAddress_Data		=> NDP_NextHop_MACAddress_Data,
			
			Out_Valid											=> MAC_TX_Valid,
			Out_Data											=> MAC_TX_Data,
			Out_SOF												=> MAC_TX_SOF,
			Out_EOF												=> MAC_TX_EOF,
			Out_Ack												=> MAC_TX_Ack,
			Out_Meta_rst									=> MAC_TX_Meta_rst,
			Out_Meta_DestMACAddress_nxt		=> MAC_TX_Meta_DestMACAddress_nxt,
			Out_Meta_DestMACAddress_Data	=> MAC_TX_Meta_DestMACAddress_Data
		);

-- ============================================================================================================================================================
-- RX Path
-- ============================================================================================================================================================
	RX_IPv6 : entity PoC.ipv6_RX
		generic map (
			DEBUG									=> DEBUG
		)
		port map (
			Clock														=> Clock,
			Reset														=> Reset,
		
			In_Valid												=> MAC_RX_Valid,
			In_Data													=> MAC_RX_Data,
			In_SOF													=> MAC_RX_SOF,
			In_EOF													=> MAC_RX_EOF,
			In_Ack													=> MAC_RX_Ack,
			In_Meta_rst											=> MAC_RX_Meta_rst,
			In_Meta_SrcMACAddress_nxt				=> MAC_RX_Meta_SrcMACAddress_nxt,
			In_Meta_SrcMACAddress_Data			=> MAC_RX_Meta_SrcMACAddress_Data,
			In_Meta_DestMACAddress_nxt			=> MAC_RX_Meta_DestMACAddress_nxt,
			In_Meta_DestMACAddress_Data			=> MAC_RX_Meta_DestMACAddress_Data,
			In_Meta_EthType									=> MAC_RX_Meta_EthType,
			
			Out_Valid												=> IPv6_RX_Valid,
			Out_Data												=> IPv6_RX_Data,
			Out_SOF													=> IPv6_RX_SOF,
			Out_EOF													=> IPv6_RX_EOF,
			Out_Ack													=> RX_LLDeMux_Ack,
			Out_Meta_rst										=> RX_LLDeMux_Meta_rst,
			Out_Meta_SrcMACAddress_nxt			=> RX_LLDeMux_Meta_SrcMACAddress_nxt,
			Out_Meta_SrcMACAddress_Data			=> IPv6_RX_Meta_SrcMACAddress_Data,
			Out_Meta_DestMACAddress_nxt			=> RX_LLDeMux_Meta_DestMACAddress_nxt,
			Out_Meta_DestMACAddress_Data		=> IPv6_RX_Meta_DestMACAddress_Data,
			Out_Meta_EthType								=> IPv6_RX_Meta_EthType,
			Out_Meta_SrcIPv6Address_nxt			=> RX_LLDeMux_Meta_SrcIPv6Address_nxt,
			Out_Meta_SrcIPv6Address_Data		=> IPv6_RX_Meta_SrcIPv6Address_Data,
			Out_Meta_DestIPv6Address_nxt		=> RX_LLDeMux_Meta_DestIPv6Address_nxt,
			Out_Meta_DestIPv6Address_Data		=> IPv6_RX_Meta_DestIPv6Address_Data,
			Out_Meta_TrafficClass						=> IPv6_RX_Meta_TrafficClass,
			Out_Meta_FlowLabel							=> IPv6_RX_Meta_FlowLabel,
			Out_Meta_Length									=> IPv6_RX_Meta_Length,
			Out_Meta_NextHeader							=> IPv6_RX_Meta_NextHeader
		);

	genLLDeMux_Control : for i in 0 to IPV6_SWITCH_PORTS - 1 generate
		LLDeMux_Control(I)		<= to_sl(IPv6_RX_Meta_NextHeader = PACKET_TYPES(I));
	end generate;
	
	-- decompress meta_rev vector to single bits
	RX_LLDeMux_Meta_rst									<= RX_LLDeMux_MetaIn_rev(LLDEMUX_META_RST_BIT);
	RX_LLDeMux_Meta_SrcMACAddress_nxt		<= RX_LLDeMux_MetaIn_rev(LLDEMUX_META_MACSRC_NXT_BIT);
	RX_LLDeMux_Meta_DestMACAddress_nxt	<= RX_LLDeMux_MetaIn_rev(LLDEMUX_META_MACDEST_NXT_BIT);
	RX_LLDeMux_Meta_SrcIPv6Address_nxt	<= RX_LLDeMux_MetaIn_rev(LLDEMUX_META_IPV6SRC_NXT_BIT);
	RX_LLDeMux_Meta_DestIPv6Address_nxt	<= RX_LLDeMux_MetaIn_rev(LLDEMUX_META_IPV6DEST_NXT_BIT);
	
	-- compress meta data vectors to single meta data vector
	RX_LLDeMux_MetaIn(high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_SRCMAC)		downto	low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_SRCMAC))		<= IPv6_RX_Meta_SrcMACAddress_Data;
	RX_LLDeMux_MetaIn(high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_DESTMAC)	downto	low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_DESTMAC))	<= IPv6_RX_Meta_DestMACAddress_Data;
	RX_LLDeMux_MetaIn(high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_ETHTYPE)	downto	low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_ETHTYPE))	<= IPv6_RX_Meta_EthType;
	RX_LLDeMux_MetaIn(high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_SRCIP)		downto	low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_SRCIP))		<= IPv6_RX_Meta_SrcIPv6Address_Data;
	RX_LLDeMux_MetaIn(high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_DESTIP)		downto	low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_DESTIP))		<= IPv6_RX_Meta_DestIPv6Address_Data;
	RX_LLDeMux_MetaIn(high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_LENGTH)		downto	low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_LENGTH))		<= IPv6_RX_Meta_Length;
	RX_LLDeMux_MetaIn(high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_HEADER)		downto	low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_HEADER))		<= IPv6_RX_Meta_NextHeader;
	
	RX_LLDeMux : entity PoC.stream_DeMux
		generic map (
			PORTS										=> IPV6_SWITCH_PORTS,
			DATA_BITS								=> LLDEMUX_DATA_BITS,
			META_BITS								=> isum(LLDEMUX_META_BITS),
			META_REV_BITS						=> LLDEMUX_META_REV_BITS
		)
		port map (
			Clock										=> Clock,
			Reset										=> Reset,

			DeMuxControl						=> LLDeMux_Control,

			In_Valid								=> IPv6_RX_Valid,
			In_Data									=> IPv6_RX_Data,
			In_Meta									=> RX_LLDeMux_MetaIn,
			In_Meta_rev							=> RX_LLDeMux_MetaIn_rev,
			In_SOF									=> IPv6_RX_SOF,
			In_EOF									=> IPv6_RX_EOF,
			In_Ack									=> RX_LLDeMux_Ack,
			
			Out_Valid								=> RX_Valid,
			Out_Data								=> RX_LLDeMux_Data,
			Out_Meta								=> RX_LLDeMux_MetaOut,
			Out_Meta_rev						=> RX_LLDeMux_MetaOut_rev,
			Out_SOF									=> RX_SOF,
			Out_EOF									=> RX_EOF,
			Out_Ack									=> RX_Ack	
		);

	assign_col(RX_LLDeMux_MetaOut_rev, RX_Meta_rst,									LLDEMUX_META_RST_BIT);
	assign_col(RX_LLDeMux_MetaOut_rev, RX_Meta_SrcMACAddress_nxt,		LLDEMUX_META_MACSRC_NXT_BIT);
	assign_col(RX_LLDeMux_MetaOut_rev, RX_Meta_DestMACAddress_nxt,	LLDEMUX_META_MACDEST_NXT_BIT);
	assign_col(RX_LLDeMux_MetaOut_rev, RX_Meta_SrcIPv6Address_nxt,	LLDEMUX_META_IPV6SRC_NXT_BIT);
	assign_col(RX_LLDeMux_MetaOut_rev, RX_Meta_DestIPv6Address_nxt, LLDEMUX_META_IPV6DEST_NXT_BIT);

	-- new slm_slice funtion to avoid generate statement for wiring => cut multiple columns over all rows and convert to slvv_*
	RX_Data													<= to_slvv_8(RX_LLDeMux_Data);
	RX_Meta_SrcMACAddress_Data			<= to_slvv_8(	slm_slice_cols(RX_LLDeMux_MetaOut, low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_SRCMAC),	high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_SRCMAC)));
	RX_Meta_DestMACAddress_Data			<= to_slvv_8(	slm_slice_cols(RX_LLDeMux_MetaOut, low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_DESTMAC),	high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_DESTMAC)));
	RX_Meta_EthType									<= to_slvv_16(slm_slice_cols(RX_LLDeMux_MetaOut, low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_ETHTYPE),	high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_ETHTYPE)));
	RX_Meta_SrcIPv6Address_Data			<= to_slvv_8(	slm_slice_cols(RX_LLDeMux_MetaOut, low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_SRCIP),		high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_SRCIP)));
	RX_Meta_DestIPv6Address_Data		<= to_slvv_8(	slm_slice_cols(RX_LLDeMux_MetaOut, low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_DESTIP),	high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_DESTIP)));
	RX_Meta_Length									<= to_slvv_16(slm_slice_cols(RX_LLDeMux_MetaOut, low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_LENGTH),	high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_LENGTH)));
	RX_Meta_NextHeader							<= to_slvv_8(	slm_slice_cols(RX_LLDeMux_MetaOut, low(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_HEADER),	high(LLDEMUX_META_BITS, LLDEMUX_META_STREAMID_HEADER)));
	
end architecture;
