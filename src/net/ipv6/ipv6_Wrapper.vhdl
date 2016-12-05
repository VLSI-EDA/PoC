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


entity ipv6_Wrapper is
	generic (
		DEBUG														: boolean													:= FALSE;
		PACKET_TYPES										: T_NET_IPV6_NEXT_HEADER_VECTOR		:= (0 => x"00")
	);
	port (
		Clock														: in	std_logic;
		Reset														: in	std_logic;
		-- to MAC layer
		MAC_TX_Valid										: out	std_logic;
		MAC_TX_Data											: out	T_SLV_8;
		MAC_TX_SOF											: out	std_logic;
		MAC_TX_EOF											: out	std_logic;
		MAC_TX_Ack											: in	std_logic;
		MAC_TX_Meta_rst									: in	std_logic;
		MAC_TX_Meta_DestMACAddress_nxt	: in	std_logic;
		MAC_TX_Meta_DestMACAddress_Data	: out	T_SLV_8;
		-- from MAC layer
		MAC_RX_Valid										: in	std_logic;
		MAC_RX_Data											: in	T_SLV_8;
		MAC_RX_SOF											: in	std_logic;
		MAC_RX_EOF											: in	std_logic;
		MAC_RX_Ack											: out	std_logic;
		MAC_RX_Meta_rst									: out	std_logic;
		MAC_RX_Meta_SrcMACAddress_nxt		: out	std_logic;
		MAC_RX_Meta_SrcMACAddress_Data	: in	T_SLV_8;
		MAC_RX_Meta_DestMACAddress_nxt	: out	std_logic;
		MAC_RX_Meta_DestMACAddress_Data	: in	T_SLV_8;
		MAC_RX_Meta_EthType							: in	T_SLV_16;
		-- to NDP layer
		NDP_NextHop_Query								: out	std_logic;
		NDP_NextHop_IPv6Address_rst			: in	std_logic;
		NDP_NextHop_IPv6Address_nxt			: in	std_logic;
		NDP_NextHop_IPv6Address_Data		: out	T_SLV_8;
		-- from NDP layer
		NDP_NextHop_Valid								: in	std_logic;
		NDP_NextHop_MACAddress_rst			: out	std_logic;
		NDP_NextHop_MACAddress_nxt			: out	std_logic;
		NDP_NextHop_MACAddress_Data			: in	T_SLV_8;
		-- from upper layer
		TX_Valid												: in	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		TX_Data													: in	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		TX_SOF													: in	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		TX_EOF													: in	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		TX_Ack													: out	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_rst											: out	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_SrcIPv6Address_nxt			: out	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_SrcIPv6Address_Data			: in	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_DestIPv6Address_nxt			: out	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_DestIPv6Address_Data		: in	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_TrafficClass						: in	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_FlowLabel								: in	T_SLVV_24(PACKET_TYPES'length - 1 downto 0);
		TX_Meta_Length									: in	T_SLVV_16(PACKET_TYPES'length - 1 downto 0);
		-- to upper layer
		RX_Valid												: out	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		RX_Data													: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_SOF													: out	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		RX_EOF													: out	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		RX_Ack													: in	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_rst											: in	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_SrcMACAddress_nxt				: in	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_SrcMACAddress_Data			: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_DestMACAddress_nxt			: in	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_DestMACAddress_Data			: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_EthType									: out	T_SLVV_16(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_SrcIPv6Address_nxt			: in	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_SrcIPv6Address_Data			: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_DestIPv6Address_nxt			: in	std_logic_vector(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_DestIPv6Address_Data		: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_TrafficClass						: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_FlowLabel								: out	T_SLVV_24(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_Length									: out	T_SLVV_16(PACKET_TYPES'length - 1 downto 0);
		RX_Meta_NextHeader							: out	T_SLVV_8(PACKET_TYPES'length - 1 downto 0)
	);
end entity;

architecture rtl of ipv6_Wrapper is
	constant IPV6_SWITCH_PORTS								: positive				:= PACKET_TYPES'length;

	constant TXSTMMUX_META_STREAMID_SRCADR		: natural					:= 0;
	constant TXSTMMUX_META_STREAMID_DESTADR		: natural					:= 1;
	constant TXSTMMUX_META_STREAMID_LENGTH		: natural					:= 2;
	constant TXSTMMUX_META_STREAMID_HEADER		: natural					:= 3;

	constant TXSTMMUX_META_BITS								: T_POSVEC				:= (
		TXSTMMUX_META_STREAMID_SRCADR			=> 8,
		TXSTMMUX_META_STREAMID_DESTADR		=> 8,
		TXSTMMUX_META_STREAMID_LENGTH			=> 16,
		TXSTMMUX_META_STREAMID_HEADER			=> 8
	);

	constant TXSTMMUX_META_RST_BIT						: natural					:= 0;
	constant TXSTMMUX_META_SRC_NXT_BIT				: natural					:= 1;
	constant TXSTMMUX_META_DEST_NXT_BIT				: natural					:= 2;

	constant TXSTMMUX_META_REV_BITS						: natural					:= 3;

	signal StmMux_In_Valid										: std_logic_vector(IPV6_SWITCH_PORTS - 1 downto 0);
	signal StmMux_In_Data											: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, T_SLV_8'range)													:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal StmMux_In_Meta											: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, isum(TXSTMMUX_META_BITS) - 1 downto 0)	:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal StmMux_In_Meta_rev									: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, TXSTMMUX_META_REV_BITS - 1 downto 0)		:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal StmMux_In_SOF											: std_logic_vector(IPV6_SWITCH_PORTS - 1 downto 0);
	signal StmMux_In_EOF											: std_logic_vector(IPV6_SWITCH_PORTS - 1 downto 0);
	signal StmMux_In_Ack											: std_logic_vector(IPV6_SWITCH_PORTS - 1 downto 0);

	signal TX_StmMux_Valid										: std_logic;
	signal TX_StmMux_Data											: T_SLV_8;
	signal TX_StmMux_Meta											: std_logic_vector(isum(TXSTMMUX_META_BITS) - 1 downto 0);
	signal TX_StmMux_Meta_rev									: std_logic_vector(TXSTMMUX_META_REV_BITS - 1 downto 0);
	signal TX_StmMux_SOF											: std_logic;
	signal TX_StmMux_EOF											: std_logic;
	signal TX_StmMux_SrcIPv6Address_Data			: T_SLV_8;
	signal TX_StmMux_DestIPv6Address_Data			: T_SLV_8;
	signal TX_StmMux_Length										: T_SLV_16;
	signal TX_StmMux_NextHeader								: T_SLV_8;

	signal IPv6_TX_Ack												: std_logic;
	signal IPv6_TX_Meta_rst										: std_logic;
	signal IPv6_TX_Meta_SrcIPv6Address_nxt		: std_logic;
	signal IPv6_TX_Meta_DestIPv6Address_nxt		: std_logic;

	signal IPv6_RX_Valid											: std_logic;
	signal IPv6_RX_Data												: T_SLV_8;
	signal IPv6_RX_SOF												: std_logic;
	signal IPv6_RX_EOF												: std_logic;

	signal IPv6_RX_Meta_SrcMACAddress_Data		: T_SLV_8;
	signal IPv6_RX_Meta_DestMACAddress_Data		: T_SLV_8;
	signal IPv6_RX_Meta_EthType								: T_SLV_16;
	signal IPv6_RX_Meta_SrcIPv6Address_Data		: T_SLV_8;
	signal IPv6_RX_Meta_DestIPv6Address_Data	: T_SLV_8;
	signal IPv6_RX_Meta_TrafficClass					: T_SLV_8;
	signal IPv6_RX_Meta_FlowLabel							: T_SLV_24;
	signal IPv6_RX_Meta_Length								: T_SLV_16;
	signal IPv6_RX_Meta_NextHeader						: T_SLV_8;

	constant STMDEMUX_META_RST_BIT						: natural					:= 0;
	constant STMDEMUX_META_MACSRC_NXT_BIT			: natural					:= 1;
	constant STMDEMUX_META_MACDEST_NXT_BIT		: natural					:= 2;
	constant STMDEMUX_META_IPV6SRC_NXT_BIT		: natural					:= 3;
	constant STMDEMUX_META_IPV6DEST_NXT_BIT		: natural					:= 4;

	constant STMDEMUX_META_STREAMID_SRCMAC		: natural					:= 0;
	constant STMDEMUX_META_STREAMID_DESTMAC		: natural					:= 1;
	constant STMDEMUX_META_STREAMID_ETHTYPE		: natural					:= 2;
	constant STMDEMUX_META_STREAMID_SRCIP			: natural					:= 3;
	constant STMDEMUX_META_STREAMID_DESTIP		: natural					:= 4;
	constant STMDEMUX_META_STREAMID_LENGTH		: natural					:= 5;
	constant STMDEMUX_META_STREAMID_HEADER		: natural					:= 6;

	constant STMDEMUX_DATA_BITS								: natural					:= 8;							--
	constant STMDEMUX_META_BITS								: T_POSVEC				:= (
		STMDEMUX_META_STREAMID_SRCMAC		=> 8,
		STMDEMUX_META_STREAMID_DESTMAC 	=> 8,
		STMDEMUX_META_STREAMID_ETHTYPE 	=> 16,
		STMDEMUX_META_STREAMID_SRCIP		=> 8,
		STMDEMUX_META_STREAMID_DESTIP		=> 8,
		STMDEMUX_META_STREAMID_LENGTH		=> 16,
		STMDEMUX_META_STREAMID_HEADER		=> 8
	);
	constant STMDEMUX_META_REV_BITS							: natural					:= 5;							-- sum over all control bits (rst, nxt, nxt, nxt, nxt)

	signal RX_StmDeMux_Ack											: std_logic;
	signal RX_StmDeMux_Meta_rst									: std_logic;
	signal RX_StmDeMux_Meta_SrcMACAddress_nxt		: std_logic;
	signal RX_StmDeMux_Meta_DestMACAddress_nxt	: std_logic;
	signal RX_StmDeMux_Meta_SrcIPv6Address_nxt	: std_logic;
	signal RX_StmDeMux_Meta_DestIPv6Address_nxt	: std_logic;

	signal RX_StmDeMux_MetaIn										: std_logic_vector(isum(STMDEMUX_META_BITS) - 1 downto 0);
	signal RX_StmDeMux_MetaIn_rev								: std_logic_vector(STMDEMUX_META_REV_BITS - 1 downto 0);
	signal RX_StmDeMux_Data											: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, STMDEMUX_DATA_BITS - 1 downto 0)				:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal RX_StmDeMux_MetaOut									: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, isum(STMDEMUX_META_BITS) - 1 downto 0)	:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal RX_StmDeMux_MetaOut_rev							: T_SLM(IPV6_SWITCH_PORTS - 1 downto 0, STMDEMUX_META_REV_BITS - 1 downto 0)		:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)

	signal StmDeMux_Control											: std_logic_vector(IPV6_SWITCH_PORTS - 1 downto 0);

begin
-- =============================================================================
-- TX Path
-- =============================================================================
	genTXStmBuf : for i in 0 to IPV6_SWITCH_PORTS - 1 generate
		constant TXSTMBUF_META_STREAMID_SRCADR		: natural					:= 0;
		constant TXSTMBUF_META_STREAMID_DESTADR		: natural					:= 1;
		constant TXSTMBUF_META_STREAMID_LENGTH		: natural					:= 2;

		constant TXSTMBUF_META_BITS								: T_POSVEC				:= (
			TXSTMBUF_META_STREAMID_SRCADR				=> 8,
			TXSTMBUF_META_STREAMID_DESTADR			=> 8,
			TXSTMBUF_META_STREAMID_LENGTH				=> 16
		);

		constant TXSTMBUF_META_FIFO_DEPTHS				: T_POSVEC				:= (
			TXSTMBUF_META_STREAMID_SRCADR				=> 16,
			TXSTMBUF_META_STREAMID_DESTADR			=> 16,
			TXSTMBUF_META_STREAMID_LENGTH				=> 1
		);

		signal StmBuf_DataOut											: T_SLV_8;
--		signal Meta_rst														: STD_LOGIC;
		signal StmBuf_MetaIn_nxt									: std_logic_vector(TXSTMBUF_META_BITS'length - 1 downto 0);
		signal StmBuf_MetaIn_Data									: std_logic_vector(isum(TXSTMBUF_META_BITS) - 1 downto 0);

		signal StmBuf_Meta_rst										: std_logic;
		signal StmBuf_MetaOut_nxt									: std_logic_vector(TXSTMBUF_META_BITS'length - 1 downto 0);
		signal StmBuf_MetaOut_Data								: std_logic_vector(isum(TXSTMBUF_META_BITS) - 1 downto 0);

		signal StmBuf_Meta_SrcIPv6Address_Data		: std_logic_vector(TX_StmMux_SrcIPv6Address_Data'range);
		signal StmBuf_Meta_DestIPv6Address_Data		: std_logic_vector(TX_StmMux_DestIPv6Address_Data'range);
		signal StmBuf_Meta_Length									: std_logic_vector(TX_StmMux_Length'range);
		signal StmBuf_Meta_NextHeader							: std_logic_vector(TX_StmMux_NextHeader'range);

		signal StmMux_MetaIn_Data									: std_logic_vector(isum(TXSTMMUX_META_BITS) - 1 downto 0);

	begin
		StmBuf_MetaIn_Data(high(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_SRCADR)	downto low(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_SRCADR))	<= TX_Meta_SrcIPv6Address_Data(i);
		StmBuf_MetaIn_Data(high(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_DESTADR)	downto low(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_DESTADR))	<= TX_Meta_DestIPv6Address_Data(i);
		StmBuf_MetaIn_Data(high(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_LENGTH)	downto low(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_LENGTH))	<= TX_Meta_Length(i);

--		TX_Meta_rst(i)									<= Meta_rst;
		TX_Meta_SrcIPv6Address_nxt(i)		<= StmBuf_MetaIn_nxt(TXSTMBUF_META_STREAMID_SRCADR);
		TX_Meta_DestIPv6Address_nxt(i)	<= StmBuf_MetaIn_nxt(TXSTMBUF_META_STREAMID_DESTADR);

		TX_StmBuf : entity PoC.stream_Buffer
			generic map (
				FRAMES												=> 2,
				DATA_BITS											=> 8,
				DATA_FIFO_DEPTH								=> 16,
				META_BITS											=> TXSTMBUF_META_BITS,
				META_FIFO_DEPTH								=> TXSTMBUF_META_FIFO_DEPTHS
			)
			port map (
				Clock													=> Clock,
				Reset													=> Reset,

				In_Valid											=> TX_Valid(i),
				In_Data												=> TX_Data(i),
				In_SOF												=> TX_SOF(i),
				In_EOF												=> TX_EOF(i),
				In_Ack												=> TX_Ack	(i),
				In_Meta_rst										=> TX_Meta_rst(i),
				In_Meta_nxt										=> StmBuf_MetaIn_nxt,
				In_Meta_Data									=> StmBuf_MetaIn_Data,

				Out_Valid											=> StmMux_In_Valid(i),
				Out_Data											=> StmBuf_DataOut,
				Out_SOF												=> StmMux_In_SOF(i),
				Out_EOF												=> StmMux_In_EOF(i),
				Out_Ack												=> StmMux_In_Ack	(i),
				Out_Meta_rst									=> StmBuf_Meta_rst,
				Out_Meta_nxt									=> StmBuf_MetaOut_nxt,
				Out_Meta_Data									=> StmBuf_MetaOut_Data
			);

		-- unpack buffer metadata to signals
		StmBuf_Meta_SrcIPv6Address_Data											<= StmBuf_MetaOut_Data(high(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_SRCADR)	downto low(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_SRCADR));
		StmBuf_Meta_DestIPv6Address_Data										<= StmBuf_MetaOut_Data(high(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_DESTADR)	downto low(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_DESTADR));
		StmBuf_Meta_Length																	<= StmBuf_MetaOut_Data(high(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_LENGTH)	downto low(TXSTMBUF_META_BITS, TXSTMBUF_META_STREAMID_LENGTH));

		StmBuf_Meta_rst																			<= StmMux_In_Meta_rev(i, TXSTMMUX_META_RST_BIT);
		StmBuf_MetaOut_nxt(TXSTMBUF_META_STREAMID_SRCADR)		<= StmMux_In_Meta_rev(i, TXSTMMUX_META_SRC_NXT_BIT);
		StmBuf_MetaOut_nxt(TXSTMBUF_META_STREAMID_DESTADR)	<= StmMux_In_Meta_rev(i, TXSTMMUX_META_DEST_NXT_BIT);
		StmBuf_MetaOut_nxt(TXSTMBUF_META_STREAMID_LENGTH)		<= '0';

		-- repack metadata into 1 dim vector for mux
		StmMux_MetaIn_Data(high(TXSTMMUX_META_BITS, TXSTMMUX_META_STREAMID_SRCADR)		downto low(TXSTMMUX_META_BITS, TXSTMMUX_META_STREAMID_SRCADR))		<= StmBuf_Meta_SrcIPv6Address_Data;
		StmMux_MetaIn_Data(high(TXSTMMUX_META_BITS, TXSTMMUX_META_STREAMID_DESTADR)		downto low(TXSTMMUX_META_BITS, TXSTMMUX_META_STREAMID_DESTADR))		<= StmBuf_Meta_DestIPv6Address_Data;
		StmMux_MetaIn_Data(high(TXSTMMUX_META_BITS, TXSTMMUX_META_STREAMID_LENGTH)		downto low(TXSTMMUX_META_BITS, TXSTMMUX_META_STREAMID_LENGTH))		<= StmBuf_Meta_Length;
		StmMux_MetaIn_Data(high(TXSTMMUX_META_BITS, TXSTMMUX_META_STREAMID_HEADER)		downto low(TXSTMMUX_META_BITS, TXSTMMUX_META_STREAMID_HEADER))		<= PACKET_TYPES(i);

		-- assign vectors to matrix
		assign_row(StmMux_In_Data, StmBuf_DataOut,			i);
		assign_row(StmMux_In_Meta, StmMux_MetaIn_Data,	i);
	end generate;

	TX_StmMux : entity PoC.stream_Mux
		generic map (
			PORTS									=> IPV6_SWITCH_PORTS,
			DATA_BITS							=> TX_StmMux_Data'length,
			META_BITS							=> isum(TXSTMMUX_META_BITS),
			META_REV_BITS					=> TXSTMMUX_META_REV_BITS
		)
		port map (
			Clock									=> Clock,
			Reset									=> Reset,

			In_Valid							=> StmMux_In_Valid,
			In_Data								=> StmMux_In_Data,
			In_Meta								=> StmMux_In_Meta,
			In_Meta_rev						=> StmMux_In_Meta_rev,
			In_SOF								=> StmMux_In_SOF,
			In_EOF								=> StmMux_In_EOF,
			In_Ack								=> StmMux_In_Ack,

			Out_Valid							=> TX_StmMux_Valid,
			Out_Data							=> TX_StmMux_Data,
			Out_Meta							=> TX_StmMux_Meta,
			Out_Meta_rev					=> TX_StmMux_Meta_rev,
			Out_SOF								=> TX_StmMux_SOF,
			Out_EOF								=> TX_StmMux_EOF,
			Out_Ack								=> IPv6_TX_Ack
		);

	TX_StmMux_SrcIPv6Address_Data										<= TX_StmMux_Meta(TX_StmMux_SrcIPv6Address_Data'range);
	TX_StmMux_DestIPv6Address_Data									<= TX_StmMux_Meta(TX_StmMux_DestIPv6Address_Data'range);
	TX_StmMux_Length																<= TX_StmMux_Meta(TX_StmMux_Length'range);
	TX_StmMux_NextHeader														<= TX_StmMux_Meta(TX_StmMux_NextHeader'range);

	TX_StmMux_Meta_rev(TXSTMMUX_META_RST_BIT)				<= IPv6_TX_Meta_rst;
	TX_StmMux_Meta_rev(TXSTMMUX_META_SRC_NXT_BIT)		<= IPv6_TX_Meta_SrcIPv6Address_nxt;
	TX_StmMux_Meta_rev(TXSTMMUX_META_DEST_NXT_BIT)	<= IPv6_TX_Meta_DestIPv6Address_nxt;

	TX_IPv6 : entity PoC.ipv6_TX
		generic map (
			DEBUG													=> DEBUG
		)
		port map (
			Clock													=> Clock,
			Reset													=> Reset,

			In_Valid											=> TX_StmMux_Valid,
			In_Data												=> TX_StmMux_Data,
			In_SOF												=> TX_StmMux_SOF,
			In_EOF												=> TX_StmMux_EOF,
			In_Ack												=> IPv6_TX_Ack,
			In_Meta_rst										=> IPv6_TX_Meta_rst,
			In_Meta_SrcIPv6Address_nxt		=> IPv6_TX_Meta_SrcIPv6Address_nxt,
			In_Meta_SrcIPv6Address_Data		=> TX_StmMux_SrcIPv6Address_Data,
			In_Meta_DestIPv6Address_nxt		=> IPv6_TX_Meta_DestIPv6Address_nxt,
			In_Meta_DestIPv6Address_Data	=> TX_StmMux_DestIPv6Address_Data,
			In_Meta_TrafficClass					=> (others => '0'),		-- not connected through StmMux and TX_StmBuf
			In_Meta_FlowLabel							=> (others => '0'),		-- not connected through StmMux and TX_StmBuf
			In_Meta_Length								=> TX_StmMux_Length,
			In_Meta_NextHeader						=> TX_StmMux_NextHeader,

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

-- =============================================================================
-- RX Path
-- =============================================================================
	RX_IPv6 : entity PoC.ipv6_RX
		generic map (
			DEBUG														=> DEBUG
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
			Out_Ack													=> RX_StmDeMux_Ack,
			Out_Meta_rst										=> RX_StmDeMux_Meta_rst,
			Out_Meta_SrcMACAddress_nxt			=> RX_StmDeMux_Meta_SrcMACAddress_nxt,
			Out_Meta_SrcMACAddress_Data			=> IPv6_RX_Meta_SrcMACAddress_Data,
			Out_Meta_DestMACAddress_nxt			=> RX_StmDeMux_Meta_DestMACAddress_nxt,
			Out_Meta_DestMACAddress_Data		=> IPv6_RX_Meta_DestMACAddress_Data,
			Out_Meta_EthType								=> IPv6_RX_Meta_EthType,
			Out_Meta_SrcIPv6Address_nxt			=> RX_StmDeMux_Meta_SrcIPv6Address_nxt,
			Out_Meta_SrcIPv6Address_Data		=> IPv6_RX_Meta_SrcIPv6Address_Data,
			Out_Meta_DestIPv6Address_nxt		=> RX_StmDeMux_Meta_DestIPv6Address_nxt,
			Out_Meta_DestIPv6Address_Data		=> IPv6_RX_Meta_DestIPv6Address_Data,
			Out_Meta_TrafficClass						=> IPv6_RX_Meta_TrafficClass,
			Out_Meta_FlowLabel							=> IPv6_RX_Meta_FlowLabel,
			Out_Meta_Length									=> IPv6_RX_Meta_Length,
			Out_Meta_NextHeader							=> IPv6_RX_Meta_NextHeader
		);

	genStmDeMux_Control : for i in 0 to IPV6_SWITCH_PORTS - 1 generate
		StmDeMux_Control(i)		<= to_sl(IPv6_RX_Meta_NextHeader = PACKET_TYPES(i));
	end generate;

	-- decompress meta_rev vector to single bits
	RX_StmDeMux_Meta_rst									<= RX_StmDeMux_MetaIn_rev(STMDEMUX_META_RST_BIT);
	RX_StmDeMux_Meta_SrcMACAddress_nxt		<= RX_StmDeMux_MetaIn_rev(STMDEMUX_META_MACSRC_NXT_BIT);
	RX_StmDeMux_Meta_DestMACAddress_nxt		<= RX_StmDeMux_MetaIn_rev(STMDEMUX_META_MACDEST_NXT_BIT);
	RX_StmDeMux_Meta_SrcIPv6Address_nxt		<= RX_StmDeMux_MetaIn_rev(STMDEMUX_META_IPV6SRC_NXT_BIT);
	RX_StmDeMux_Meta_DestIPv6Address_nxt	<= RX_StmDeMux_MetaIn_rev(STMDEMUX_META_IPV6DEST_NXT_BIT);

	-- compress meta data vectors to single meta data vector
	RX_StmDeMux_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCMAC)	downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCMAC))		<= IPv6_RX_Meta_SrcMACAddress_Data;
	RX_StmDeMux_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTMAC)	downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTMAC))	<= IPv6_RX_Meta_DestMACAddress_Data;
	RX_StmDeMux_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_ETHTYPE)	downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_ETHTYPE))	<= IPv6_RX_Meta_EthType;
	RX_StmDeMux_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCIP)		downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCIP))		<= IPv6_RX_Meta_SrcIPv6Address_Data;
	RX_StmDeMux_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTIP)	downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTIP))		<= IPv6_RX_Meta_DestIPv6Address_Data;
	RX_StmDeMux_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_LENGTH)	downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_LENGTH))		<= IPv6_RX_Meta_Length;
	RX_StmDeMux_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_HEADER)	downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_HEADER))		<= IPv6_RX_Meta_NextHeader;

	RX_StmDeMux : entity PoC.stream_DeMux
		generic map (
			PORTS										=> IPV6_SWITCH_PORTS,
			DATA_BITS								=> STMDEMUX_DATA_BITS,
			META_BITS								=> isum(STMDEMUX_META_BITS),
			META_REV_BITS						=> STMDEMUX_META_REV_BITS
		)
		port map (
			Clock										=> Clock,
			Reset										=> Reset,

			DeMuxControl						=> StmDeMux_Control,

			In_Valid								=> IPv6_RX_Valid,
			In_Data									=> IPv6_RX_Data,
			In_Meta									=> RX_StmDeMux_MetaIn,
			In_Meta_rev							=> RX_StmDeMux_MetaIn_rev,
			In_SOF									=> IPv6_RX_SOF,
			In_EOF									=> IPv6_RX_EOF,
			In_Ack									=> RX_StmDeMux_Ack,

			Out_Valid								=> RX_Valid,
			Out_Data								=> RX_StmDeMux_Data,
			Out_Meta								=> RX_StmDeMux_MetaOut,
			Out_Meta_rev						=> RX_StmDeMux_MetaOut_rev,
			Out_SOF									=> RX_SOF,
			Out_EOF									=> RX_EOF,
			Out_Ack									=> RX_Ack
		);

	assign_col(RX_StmDeMux_MetaOut_rev, RX_Meta_rst,									STMDEMUX_META_RST_BIT);
	assign_col(RX_StmDeMux_MetaOut_rev, RX_Meta_SrcMACAddress_nxt,		STMDEMUX_META_MACSRC_NXT_BIT);
	assign_col(RX_StmDeMux_MetaOut_rev, RX_Meta_DestMACAddress_nxt,		STMDEMUX_META_MACDEST_NXT_BIT);
	assign_col(RX_StmDeMux_MetaOut_rev, RX_Meta_SrcIPv6Address_nxt,		STMDEMUX_META_IPV6SRC_NXT_BIT);
	assign_col(RX_StmDeMux_MetaOut_rev, RX_Meta_DestIPv6Address_nxt,	STMDEMUX_META_IPV6DEST_NXT_BIT);

	-- new slm_slice funtion to avoid generate statement for wiring => cut multiple columns over all rows and convert to slvv_*
	RX_Data													<= to_slvv_8(RX_StmDeMux_Data);
	RX_Meta_SrcMACAddress_Data			<= to_slvv_8(	slm_slice_cols(RX_StmDeMux_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCMAC),	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCMAC)));
	RX_Meta_DestMACAddress_Data			<= to_slvv_8(	slm_slice_cols(RX_StmDeMux_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTMAC),	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTMAC)));
	RX_Meta_EthType									<= to_slvv_16(slm_slice_cols(RX_StmDeMux_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_ETHTYPE),	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_ETHTYPE)));
	RX_Meta_SrcIPv6Address_Data			<= to_slvv_8(	slm_slice_cols(RX_StmDeMux_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCIP),		low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCIP)));
	RX_Meta_DestIPv6Address_Data		<= to_slvv_8(	slm_slice_cols(RX_StmDeMux_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTIP),	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTIP)));
	RX_Meta_Length									<= to_slvv_16(slm_slice_cols(RX_StmDeMux_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_LENGTH),	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_LENGTH)));
	RX_Meta_NextHeader							<= to_slvv_8(	slm_slice_cols(RX_StmDeMux_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_HEADER),	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_HEADER)));

end architecture;
