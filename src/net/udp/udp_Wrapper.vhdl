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


entity udp_Wrapper is
	generic (
		DEBUG															: boolean											:= FALSE;
		IP_VERSION												: positive										:= 6;
		PORTPAIRS													: T_NET_UDP_PORTPAIR_VECTOR		:= (0 => (x"0000", x"0000"))
	);
	port (
		Clock															: in	std_logic;
		Reset															: in	std_logic;
		-- from IP layer
		IP_TX_Valid												: out	std_logic;
		IP_TX_Data												: out	T_SLV_8;
		IP_TX_SOF													: out	std_logic;
		IP_TX_EOF													: out	std_logic;
		IP_TX_Ack													: in	std_logic;
		IP_TX_Meta_rst										: in	std_logic;
		IP_TX_Meta_SrcIPAddress_nxt				: in	std_logic;
		IP_TX_Meta_SrcIPAddress_Data			: out	T_SLV_8;
		IP_TX_Meta_DestIPAddress_nxt			: in	std_logic;
		IP_TX_Meta_DestIPAddress_Data			: out	T_SLV_8;
		IP_TX_Meta_Length									: out	T_SLV_16;
		-- to IP layer
		IP_RX_Valid												: in	std_logic;
		IP_RX_Data												: in	T_SLV_8;
		IP_RX_SOF													: in	std_logic;
		IP_RX_EOF													: in	std_logic;
		IP_RX_Ack													: out	std_logic;
		IP_RX_Meta_rst										: out	std_logic;
		IP_RX_Meta_SrcMACAddress_nxt			: out	std_logic;
		IP_RX_Meta_SrcMACAddress_Data			: in	T_SLV_8;
		IP_RX_Meta_DestMACAddress_nxt			: out	std_logic;
		IP_RX_Meta_DestMACAddress_Data		: in	T_SLV_8;
		IP_RX_Meta_EthType								: in	T_SLV_16;
		IP_RX_Meta_SrcIPAddress_nxt				: out	std_logic;
		IP_RX_Meta_SrcIPAddress_Data			: in	T_SLV_8;
		IP_RX_Meta_DestIPAddress_nxt			: out	std_logic;
		IP_RX_Meta_DestIPAddress_Data			: in	T_SLV_8;
--		IP_RX_Meta_TrafficClass						: in	T_SLV_8;
--		IP_RX_Meta_FlowLabel							: in	T_SLV_24;
		IP_RX_Meta_Length									: in	T_SLV_16;
		IP_RX_Meta_Protocol								: in	T_SLV_8;
		-- from upper layer
		TX_Valid													: in	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		TX_Data														: in	T_SLVV_8(PORTPAIRS'length - 1 downto 0);
		TX_SOF														: in	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		TX_EOF														: in	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		TX_Ack														: out	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		TX_Meta_rst												: out	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		TX_Meta_SrcIPAddress_nxt					: out	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		TX_Meta_SrcIPAddress_Data					: in	T_SLVV_8(PORTPAIRS'length - 1 downto 0);
		TX_Meta_DestIPAddress_nxt					: out	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		TX_Meta_DestIPAddress_Data				: in	T_SLVV_8(PORTPAIRS'length - 1 downto 0);
		TX_Meta_SrcPort										: in	T_SLVV_16(PORTPAIRS'length - 1 downto 0);
		TX_Meta_DestPort									: in	T_SLVV_16(PORTPAIRS'length - 1 downto 0);
		TX_Meta_Length										: in	T_SLVV_16(PORTPAIRS'length - 1 downto 0);
		-- to upper layer
		RX_Valid													: out	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		RX_Data														: out	T_SLVV_8(PORTPAIRS'length - 1 downto 0);
		RX_SOF														: out	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		RX_EOF														: out	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		RX_Ack														: in	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		RX_Meta_rst												: in	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		RX_Meta_SrcMACAddress_nxt					: in	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		RX_Meta_SrcMACAddress_Data				: out	T_SLVV_8(PORTPAIRS'length - 1 downto 0);
		RX_Meta_DestMACAddress_nxt				: in	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		RX_Meta_DestMACAddress_Data				: out	T_SLVV_8(PORTPAIRS'length - 1 downto 0);
		RX_Meta_EthType										: out	T_SLVV_16(PORTPAIRS'length - 1 downto 0);
		RX_Meta_SrcIPAddress_nxt					: in	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		RX_Meta_SrcIPAddress_Data					: out	T_SLVV_8(PORTPAIRS'length - 1 downto 0);
		RX_Meta_DestIPAddress_nxt					: in	std_logic_vector(PORTPAIRS'length - 1 downto 0);
		RX_Meta_DestIPAddress_Data				: out	T_SLVV_8(PORTPAIRS'length - 1 downto 0);
--		RX_Meta_TrafficClass							: out	T_SLVV_8(PORTPAIRS'length - 1 downto 0);
--		RX_Meta_FlowLabel									: out	T_SLVV_24(PORTPAIRS'length - 1 downto 0);
		RX_Meta_Length										: out	T_SLVV_16(PORTPAIRS'length - 1 downto 0);
		RX_Meta_Protocol									: out	T_SLVV_8(PORTPAIRS'length - 1 downto 0);
		RX_Meta_SrcPort										: out	T_SLVV_16(PORTPAIRS'length - 1 downto 0);
		RX_Meta_DestPort									: out	T_SLVV_16(PORTPAIRS'length - 1 downto 0)
	);
end entity;


architecture rtl of udp_Wrapper is
	constant UDP_SWITCH_PORTS										: positive				:= PORTPAIRS'length;

	constant STMMUX_META_RST_BIT								: natural					:= 0;
	constant STMMUX_META_SRCIP_NXT_BIT					: natural					:= 1;
	constant STMMUX_META_DESTIP_NXT_BIT					: natural					:= 2;

	constant STMMUX_META_REV_BITS								: natural					:= 3;

	constant STMMUX_META_STREAMID_SRCIP					: natural					:= 0;
	constant STMMUX_META_STREAMID_DESTIP				: natural					:= 1;
	constant STMMUX_META_STREAMID_SRCPORT				: natural					:= 2;
	constant STMMUX_META_STREAMID_DESTPORT			: natural					:= 3;
	constant STMMUX_META_STREAMID_LENGTH				: natural					:= 4;

	constant STMMUX_META_BITS										: T_POSVEC				:= (
		STMMUX_META_STREAMID_SRCIP			=> 8,
		STMMUX_META_STREAMID_DESTIP			=> 8,
		STMMUX_META_STREAMID_SRCPORT		=> 16,
		STMMUX_META_STREAMID_DESTPORT		=> 16,
		STMMUX_META_STREAMID_LENGTH			=> 16
	);

	signal StmMux_In_Valid											: std_logic_vector(UDP_SWITCH_PORTS - 1 downto 0);
	signal StmMux_In_Data												: T_SLM(UDP_SWITCH_PORTS - 1 downto 0, T_SLV_8'range)												:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal StmMux_In_Meta												: T_SLM(UDP_SWITCH_PORTS - 1 downto 0, isum(STMMUX_META_BITS) - 1 downto 0)	:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal StmMux_In_Meta_rev										: T_SLM(UDP_SWITCH_PORTS - 1 downto 0, STMMUX_META_REV_BITS - 1 downto 0)		:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal StmMux_In_SOF												: std_logic_vector(UDP_SWITCH_PORTS - 1 downto 0);
	signal StmMux_In_EOF												: std_logic_vector(UDP_SWITCH_PORTS - 1 downto 0);
	signal StmMux_In_Ack												: std_logic_vector(UDP_SWITCH_PORTS - 1 downto 0);

	signal StmMux_Out_Valid											: std_logic;
	signal StmMux_Out_Data											: T_SLV_8;
	signal StmMux_Out_Meta											: std_logic_vector(isum(STMMUX_META_BITS) - 1 downto 0);
	signal StmMux_Out_Meta_rev									: std_logic_vector(STMMUX_META_REV_BITS - 1 downto 0);
	signal StmMux_Out_SOF												: std_logic;
	signal StmMux_Out_EOF												: std_logic;
	signal StmMux_Out_SrcIPAddress_Data					: T_SLV_8;
	signal StmMux_Out_DestIPAddress_Data				: T_SLV_8;
	signal StmMux_Out_Length										: T_SLV_16;
	signal StmMux_Out_Protocol									: T_SLV_8;

	constant TX_FCS_META_STREAMID_SRCIP					: natural					:= 0;
	constant TX_FCS_META_STREAMID_DESTIP				: natural					:= 1;
	constant TX_FCS_META_STREAMID_SRCPORT				: natural					:= 2;
	constant TX_FCS_META_STREAMID_DESTPORT			: natural					:= 3;
	constant TX_FCS_META_STREAMID_LEN						: natural					:= 4;

	constant TX_FCS_META_BITS                   : T_POSVEC				:= (
		TX_FCS_META_STREAMID_SRCIP			=> 8,
		TX_FCS_META_STREAMID_DESTIP			=> 8,
		TX_FCS_META_STREAMID_SRCPORT		=> 16,
		TX_FCS_META_STREAMID_DESTPORT		=> 16,
		TX_FCS_META_STREAMID_LEN				=> 16
	);

	constant TX_FCS_META_FIFO_DEPTHS            : T_POSVEC				:= (
		TX_FCS_META_STREAMID_SRCIP			=> ite((IP_VERSION = 6), 16, 4),
		TX_FCS_META_STREAMID_DESTIP			=> ite((IP_VERSION = 6), 16, 4),
		TX_FCS_META_STREAMID_SRCPORT		=> 1,
		TX_FCS_META_STREAMID_DESTPORT		=> 1,
		TX_FCS_META_STREAMID_LEN				=> 1
	);

	signal TX_FCS_Valid													: std_logic;
	signal TX_FCS_Data													: T_SLV_8;
	signal TX_FCS_SOF														: std_logic;
	signal TX_FCS_EOF														: std_logic;
	signal TX_FCS_MetaOut_rst										: std_logic;
	signal TX_FCS_MetaOut_nxt										: std_logic_vector(TX_FCS_META_BITS'length - 1 downto 0);
	signal TX_FCS_MetaOut_Data									: std_logic_vector(isum(TX_FCS_META_BITS) - 1 downto 0);
	signal TX_FCS_Meta_SrcIPAddress_Data				: T_SLV_8;
	signal TX_FCS_Meta_DestIPAddress_Data				: T_SLV_8;
	signal TX_FCS_Meta_SrcPort									: T_SLV_16;
	signal TX_FCS_Meta_DestPort									: T_SLV_16;
	signal TX_FCS_Meta_Checksum									: T_SLV_16;
	signal TX_FCS_Meta_Length										: T_SLV_16;

	signal TX_FCS_Ack														: std_logic;
	signal TX_FCS_MetaIn_rst										: std_logic;
	signal TX_FCS_MetaIn_nxt										: std_logic_vector(TX_FCS_META_BITS'length - 1 downto 0);
	signal TX_FCS_MetaIn_Data										: std_logic_vector(isum(TX_FCS_META_BITS) - 1 downto 0);

	signal UDP_TX_Ack														: std_logic;
	signal UDP_TX_Meta_rst											: std_logic;
	signal UDP_TX_Meta_SrcIPAddress_nxt					: std_logic;
	signal UDP_TX_Meta_DestIPAddress_nxt				: std_logic;

	signal UDP_RX_Valid													: std_logic;
	signal UDP_RX_Data													: T_SLV_8;
	signal UDP_RX_SOF														: std_logic;
	signal UDP_RX_EOF														: std_logic;

	signal UDP_RX_Meta_SrcMACAddress_Data				: T_SLV_8;
	signal UDP_RX_Meta_DestMACAddress_Data			: T_SLV_8;
	signal UDP_RX_Meta_EthType									: T_SLV_16;
	signal UDP_RX_Meta_SrcIPAddress_Data				: T_SLV_8;
	signal UDP_RX_Meta_DestIPAddress_Data				: T_SLV_8;
	signal UDP_RX_Meta_Length										: T_SLV_16;
	signal UDP_RX_Meta_Protocol									: T_SLV_8;
	signal UDP_RX_Meta_SrcPort									: T_SLV_16;
	signal UDP_RX_Meta_DestPort									: T_SLV_16;

	constant STMDEMUX_META_RST_BIT							: natural					:= 0;
	constant STMDEMUX_META_MACSRC_NXT_BIT				: natural					:= 1;
	constant STMDEMUX_META_MACDEST_NXT_BIT			: natural					:= 2;
	constant STMDEMUX_META_IPSRC_NXT_BIT				: natural					:= 3;
	constant STMDEMUX_META_IPDEST_NXT_BIT				: natural					:= 4;

	constant STMDEMUX_META_STREAMID_SRCMAC			: natural					:= 0;
	constant STMDEMUX_META_STREAMID_DESTMAC			: natural					:= 1;
	constant STMDEMUX_META_STREAMID_ETHTYPE			: natural					:= 2;
	constant STMDEMUX_META_STREAMID_SRCIP				: natural					:= 3;
	constant STMDEMUX_META_STREAMID_DESTIP			: natural					:= 4;
	constant STMDEMUX_META_STREAMID_LENGTH			: natural					:= 5;
	constant STMDEMUX_META_STREAMID_PROTO				: natural					:= 6;
	constant STMDEMUX_META_STREAMID_SRCPORT			: natural					:= 7;
	constant STMDEMUX_META_STREAMID_DESTPORT		: natural					:= 8;

	constant STMDEMUX_DATA_BITS									: natural					:= 8;							--
	constant STMDEMUX_META_BITS									: T_POSVEC				:= (
		STMDEMUX_META_STREAMID_SRCMAC			=> 8,
		STMDEMUX_META_STREAMID_DESTMAC 		=> 8,
		STMDEMUX_META_STREAMID_ETHTYPE 		=> 16,
		STMDEMUX_META_STREAMID_SRCIP			=> 8,
		STMDEMUX_META_STREAMID_DESTIP			=> 8,
		STMDEMUX_META_STREAMID_LENGTH			=> 16,
		STMDEMUX_META_STREAMID_PROTO			=> 8,
		STMDEMUX_META_STREAMID_SRCPORT		=> 16,
		STMDEMUX_META_STREAMID_DESTPORT		=> 16
	);
	constant STMDEMUX_META_REV_BITS							: natural					:= 5;							-- sum over all control bits (rst, nxt, nxt, nxt, nxt)

	signal StmDeMux_Out_Ack											: std_logic;
	signal StmDeMux_Out_Meta_rst								: std_logic;
	signal StmDeMux_Out_Meta_SrcMACAddress_nxt	: std_logic;
	signal StmDeMux_Out_Meta_DestMACAddress_nxt	: std_logic;
	signal StmDeMux_Out_Meta_SrcIPAddress_nxt		: std_logic;
	signal StmDeMux_Out_Meta_DestIPAddress_nxt	: std_logic;

	signal StmDeMux_Out_MetaIn									: std_logic_vector(isum(STMDEMUX_META_BITS) - 1 downto 0);
	signal StmDeMux_Out_MetaIn_rev							: std_logic_vector(STMDEMUX_META_REV_BITS - 1 downto 0);
	signal StmDeMux_Out_Data										: T_SLM(UDP_SWITCH_PORTS - 1 downto 0, STMDEMUX_DATA_BITS - 1 downto 0)				:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal StmDeMux_Out_MetaOut									: T_SLM(UDP_SWITCH_PORTS - 1 downto 0, isum(STMDEMUX_META_BITS) - 1 downto 0)	:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
	signal StmDeMux_Out_MetaOut_rev							: T_SLM(UDP_SWITCH_PORTS - 1 downto 0, STMDEMUX_META_REV_BITS - 1 downto 0)		:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)

	signal StmDeMux_Control											: std_logic_vector(UDP_SWITCH_PORTS - 1 downto 0);

begin
	assert ((IP_VERSION = 4) or (IP_VERSION = 6)) report "Unsupported Internet Protocol (IP) version."	severity ERROR;

-- =============================================================================
-- TX Path
-- =============================================================================
	StmMux_In_Data		<= to_slm(TX_Data);

	genStmMuxIn : for i in 0 to UDP_SWITCH_PORTS - 1 generate
		signal Meta			: std_logic_vector(isum(STMMUX_META_BITS) - 1 downto 0);
	begin
		Meta(high(STMMUX_META_BITS, STMMUX_META_STREAMID_SRCIP)			downto	low(STMMUX_META_BITS, STMMUX_META_STREAMID_SRCIP))		<= TX_Meta_SrcIPAddress_Data(i);
		Meta(high(STMMUX_META_BITS, STMMUX_META_STREAMID_DESTIP)		downto	low(STMMUX_META_BITS, STMMUX_META_STREAMID_DESTIP))		<= TX_Meta_DestIPAddress_Data(i);
		Meta(high(STMMUX_META_BITS, STMMUX_META_STREAMID_SRCPORT)		downto	low(STMMUX_META_BITS, STMMUX_META_STREAMID_SRCPORT))	<= TX_Meta_SrcPort(i);
		Meta(high(STMMUX_META_BITS, STMMUX_META_STREAMID_DESTPORT)	downto	low(STMMUX_META_BITS, STMMUX_META_STREAMID_DESTPORT))	<= TX_Meta_DestPort(i);
		Meta(high(STMMUX_META_BITS, STMMUX_META_STREAMID_LENGTH)		downto	low(STMMUX_META_BITS, STMMUX_META_STREAMID_LENGTH))		<= TX_Meta_Length(i);

		assign_row(StmMux_In_Meta, Meta,	i);
	end generate;

	TX_Meta_rst								<= get_col(StmMux_In_Meta_rev,	STMMUX_META_RST_BIT);
	TX_Meta_SrcIPAddress_nxt	<= get_col(StmMux_In_Meta_rev,	STMMUX_META_SRCIP_NXT_BIT);
	TX_Meta_DestIPAddress_nxt	<= get_col(StmMux_In_Meta_rev,	STMMUX_META_DESTIP_NXT_BIT);

	TX_StmMux : entity PoC.stream_Mux
		generic map (
			PORTS									=> UDP_SWITCH_PORTS,
			DATA_BITS							=> StmMux_Out_Data'length,
			META_BITS							=> isum(STMMUX_META_BITS),
			META_REV_BITS					=> STMMUX_META_REV_BITS
		)
		port map (
			Clock									=> Clock,
			Reset									=> Reset,

			In_Valid							=> TX_Valid,
			In_Data								=> StmMux_In_Data,
			In_Meta								=> StmMux_In_Meta,
			In_Meta_rev						=> StmMux_In_Meta_rev,
			In_SOF								=> TX_SOF,
			In_EOF								=> TX_EOF,
			In_Ack								=> TX_Ack,

			Out_Valid							=> StmMux_Out_Valid,
			Out_Data							=> StmMux_Out_Data,
			Out_Meta							=> StmMux_Out_Meta,
			Out_Meta_rev					=> StmMux_Out_Meta_rev,
			Out_SOF								=> StmMux_Out_SOF,
			Out_EOF								=> StmMux_Out_EOF,
			Out_Ack								=> TX_FCS_Ack
		);

	StmMux_Out_Meta_rev(STMMUX_META_RST_BIT)				<= TX_FCS_MetaIn_rst;
	StmMux_Out_Meta_rev(STMMUX_META_SRCIP_NXT_BIT)	<= TX_FCS_MetaIn_nxt(TX_FCS_META_STREAMID_SRCIP);
	StmMux_Out_Meta_rev(STMMUX_META_DESTIP_NXT_BIT)	<= TX_FCS_MetaIn_nxt(TX_FCS_META_STREAMID_DESTIP);

	TX_FCS_MetaIn_Data	<= StmMux_Out_Meta;

	TX_FCS : entity PoC.net_FrameChecksum
		generic map (
			MAX_FRAMES						=> 4,
			MAX_FRAME_LENGTH			=> 2048,
			META_BITS							=> TX_FCS_META_BITS,
			META_FIFO_DEPTH				=> TX_FCS_META_FIFO_DEPTHS
		)
		port map (
			Clock									=> Clock,
			Reset									=> Reset,

			In_Valid							=> StmMux_Out_Valid,
			In_Data								=> StmMux_Out_Data,
			In_SOF								=> StmMux_Out_SOF,
			In_EOF								=> StmMux_Out_EOF,
			In_Ack								=> TX_FCS_Ack,
			In_Meta_rst						=> TX_FCS_MetaIn_rst,
			In_Meta_nxt						=> TX_FCS_MetaIn_nxt,
			In_Meta_Data					=> TX_FCS_MetaIn_Data,

			Out_Valid							=> TX_FCS_Valid,
			Out_Data							=> TX_FCS_Data,
			Out_SOF								=> TX_FCS_SOF,
			Out_EOF								=> TX_FCS_EOF,
			Out_Ack								=> UDP_TX_Ack,
			Out_Meta_rst					=> TX_FCS_MetaOut_rst,
			Out_Meta_nxt					=> TX_FCS_MetaOut_nxt,
			Out_Meta_Data					=> TX_FCS_MetaOut_Data,
			Out_Meta_Checksum			=> TX_FCS_Meta_Checksum,
			Out_Meta_Length				=> TX_FCS_Meta_Length
		);

	TX_FCS_MetaOut_rst																<= UDP_TX_Meta_rst;
	TX_FCS_MetaOut_nxt(TX_FCS_META_STREAMID_SRCIP)		<= UDP_TX_Meta_SrcIPAddress_nxt;
	TX_FCS_MetaOut_nxt(TX_FCS_META_STREAMID_DESTIP)		<= UDP_TX_Meta_DestIPAddress_nxt;
	TX_FCS_MetaOut_nxt(TX_FCS_META_STREAMID_SRCPORT)	<= '0';
	TX_FCS_MetaOut_nxt(TX_FCS_META_STREAMID_DESTPORT)	<= '0';

	TX_FCS_Meta_SrcIPAddress_Data			<= TX_FCS_MetaOut_Data(high(TX_FCS_META_BITS, TX_FCS_META_STREAMID_SRCIP)		 downto low(TX_FCS_META_BITS, TX_FCS_META_STREAMID_SRCIP));
	TX_FCS_Meta_DestIPAddress_Data		<= TX_FCS_MetaOut_Data(high(TX_FCS_META_BITS, TX_FCS_META_STREAMID_DESTIP)	 downto low(TX_FCS_META_BITS, TX_FCS_META_STREAMID_DESTIP));
	TX_FCS_Meta_SrcPort								<= TX_FCS_MetaOut_Data(high(TX_FCS_META_BITS, TX_FCS_META_STREAMID_SRCPORT)	 downto low(TX_FCS_META_BITS, TX_FCS_META_STREAMID_SRCPORT));
	TX_FCS_Meta_DestPort							<= TX_FCS_MetaOut_Data(high(TX_FCS_META_BITS, TX_FCS_META_STREAMID_DESTPORT) downto low(TX_FCS_META_BITS, TX_FCS_META_STREAMID_DESTPORT));
--	TX_FCS_Meta_Length								<= TX_FCS_MetaOut_Data(high(TX_FCS_META_BITS, TX_FCS_META_STREAMID_LEN)			 downto low(TX_FCS_META_BITS, TX_FCS_META_STREAMID_LEN));

	TX_UDP : entity PoC.udp_TX
		generic map (
			DEBUG												=> DEBUG,
			IP_VERSION									=> IP_VERSION
		)
		port map (
			Clock												=> Clock,
			Reset												=> Reset,

			In_Valid										=> TX_FCS_Valid,
			In_Data											=> TX_FCS_Data,
			In_SOF											=> TX_FCS_SOF,
			In_EOF											=> TX_FCS_EOF,
			In_Ack											=> UDP_TX_Ack,
			In_Meta_rst									=> UDP_TX_Meta_rst,
			In_Meta_SrcIPAddress_nxt		=> UDP_TX_Meta_SrcIPAddress_nxt,
			In_Meta_SrcIPAddress_Data		=> TX_FCS_Meta_SrcIPAddress_Data,
			In_Meta_DestIPAddress_nxt		=> UDP_TX_Meta_DestIPAddress_nxt,
			In_Meta_DestIPAddress_Data	=> TX_FCS_Meta_DestIPAddress_Data,
			In_Meta_SrcPort							=> TX_FCS_Meta_SrcPort,
			In_Meta_DestPort						=> TX_FCS_Meta_DestPort,
			In_Meta_Length							=> TX_FCS_Meta_Length,
			In_Meta_Checksum						=> TX_FCS_Meta_Checksum,

			Out_Valid										=> IP_TX_Valid,
			Out_Data										=> IP_TX_Data,
			Out_SOF											=> IP_TX_SOF,
			Out_EOF											=> IP_TX_EOF,
			Out_Ack											=> IP_TX_Ack,
			Out_Meta_rst								=> IP_TX_Meta_rst,
			Out_Meta_SrcIPAddress_nxt		=> IP_TX_Meta_SrcIPAddress_nxt,
			Out_Meta_SrcIPAddress_Data	=> IP_TX_Meta_SrcIPAddress_Data,
			Out_Meta_DestIPAddress_nxt	=> IP_TX_Meta_DestIPAddress_nxt,
			Out_Meta_DestIPAddress_Data	=> IP_TX_Meta_DestIPAddress_Data,
			Out_Meta_Length							=> IP_TX_Meta_Length
		);

-- =============================================================================
-- RX Path
-- =============================================================================
	RX_UDP : entity PoC.udp_RX
		generic map (
			DEBUG														=> DEBUG,
			IP_VERSION											=> IP_VERSION
		)
		port map (
			Clock														=> Clock,
			Reset														=> Reset,

			In_Valid												=> IP_RX_Valid,
			In_Data													=> IP_RX_Data,
			In_SOF													=> IP_RX_SOF,
			In_EOF													=> IP_RX_EOF,
			In_Ack													=> IP_RX_Ack,
			In_Meta_rst											=> IP_RX_Meta_rst,
			In_Meta_SrcMACAddress_nxt				=> IP_RX_Meta_SrcMACAddress_nxt,
			In_Meta_SrcMACAddress_Data			=> IP_RX_Meta_SrcMACAddress_Data,
			In_Meta_DestMACAddress_nxt			=> IP_RX_Meta_DestMACAddress_nxt,
			In_Meta_DestMACAddress_Data			=> IP_RX_Meta_DestMACAddress_Data,
			In_Meta_EthType									=> IP_RX_Meta_EthType,
			In_Meta_SrcIPAddress_nxt				=> IP_RX_Meta_SrcIPAddress_nxt,
			In_Meta_SrcIPAddress_Data				=> IP_RX_Meta_SrcIPAddress_Data,
			In_Meta_DestIPAddress_nxt				=> IP_RX_Meta_DestIPAddress_nxt,
			In_Meta_DestIPAddress_Data			=> IP_RX_Meta_DestIPAddress_Data,
			In_Meta_Length									=> IP_RX_Meta_Length,
			In_Meta_Protocol								=> IP_RX_Meta_Protocol,

			Out_Valid												=> UDP_RX_Valid,
			Out_Data												=> UDP_RX_Data,
			Out_SOF													=> UDP_RX_SOF,
			Out_EOF													=> UDP_RX_EOF,
			Out_Ack													=> StmDeMux_Out_Ack,
			Out_Meta_rst										=> StmDeMux_Out_Meta_rst,
			Out_Meta_SrcMACAddress_nxt			=> StmDeMux_Out_Meta_SrcMACAddress_nxt,
			Out_Meta_SrcMACAddress_Data			=> UDP_RX_Meta_SrcMACAddress_Data,
			Out_Meta_DestMACAddress_nxt			=> StmDeMux_Out_Meta_DestMACAddress_nxt,
			Out_Meta_DestMACAddress_Data		=> UDP_RX_Meta_DestMACAddress_Data,
			Out_Meta_EthType								=> UDP_RX_Meta_EthType,
			Out_Meta_SrcIPAddress_nxt				=> StmDeMux_Out_Meta_SrcIPAddress_nxt,
			Out_Meta_SrcIPAddress_Data			=> UDP_RX_Meta_SrcIPAddress_Data,
			Out_Meta_DestIPAddress_nxt			=> StmDeMux_Out_Meta_DestIPAddress_nxt,
			Out_Meta_DestIPAddress_Data			=> UDP_RX_Meta_DestIPAddress_Data,
			Out_Meta_Length									=> UDP_RX_Meta_Length,
			Out_Meta_Protocol								=> UDP_RX_Meta_Protocol,
			Out_Meta_SrcPort								=> UDP_RX_Meta_SrcPort,
			Out_Meta_DestPort								=> UDP_RX_Meta_DestPort
		);

	genStmDeMux_Control : for i in 0 to UDP_SWITCH_PORTS - 1 generate
		StmDeMux_Control(i)		<= to_sl(UDP_RX_Meta_DestPort = PORTPAIRS(i).Ingress);
	end generate;

	-- decompress meta_rev vector to single bits
	StmDeMux_Out_Meta_rst									<= StmDeMux_Out_MetaIn_rev(STMDEMUX_META_RST_BIT);
	StmDeMux_Out_Meta_SrcMACAddress_nxt		<= StmDeMux_Out_MetaIn_rev(STMDEMUX_META_MACSRC_NXT_BIT);
	StmDeMux_Out_Meta_DestMACAddress_nxt	<= StmDeMux_Out_MetaIn_rev(STMDEMUX_META_MACDEST_NXT_BIT);
	StmDeMux_Out_Meta_SrcIPAddress_nxt		<= StmDeMux_Out_MetaIn_rev(STMDEMUX_META_IPSRC_NXT_BIT);
	StmDeMux_Out_Meta_DestIPAddress_nxt		<= StmDeMux_Out_MetaIn_rev(STMDEMUX_META_IPDEST_NXT_BIT);

	-- compress meta data vectors to single meta data vector
	StmDeMux_Out_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCMAC)		downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCMAC))		<= UDP_RX_Meta_SrcMACAddress_Data;
	StmDeMux_Out_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTMAC)	downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTMAC))	<= UDP_RX_Meta_DestMACAddress_Data;
	StmDeMux_Out_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_ETHTYPE)	downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_ETHTYPE))	<= UDP_RX_Meta_EthType;
	StmDeMux_Out_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCIP)		downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCIP))		<= UDP_RX_Meta_SrcIPAddress_Data;
	StmDeMux_Out_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTIP)		downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTIP))		<= UDP_RX_Meta_DestIPAddress_Data;
	StmDeMux_Out_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_LENGTH)		downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_LENGTH))		<= UDP_RX_Meta_Length;
	StmDeMux_Out_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_PROTO)		downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_PROTO))		<= UDP_RX_Meta_Protocol;
	StmDeMux_Out_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCPORT) 	downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCPORT))	<= UDP_RX_Meta_SrcPort;
	StmDeMux_Out_MetaIn(high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTPORT)	downto	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTPORT))	<= UDP_RX_Meta_DestPort;

	RX_StmDeMux : entity PoC.stream_DeMux
		generic map (
			PORTS										=> UDP_SWITCH_PORTS,
			DATA_BITS								=> STMDEMUX_DATA_BITS,
			META_BITS								=> isum(STMDEMUX_META_BITS),
			META_REV_BITS						=> STMDEMUX_META_REV_BITS
		)
		port map (
			Clock										=> Clock,
			Reset										=> Reset,

			DeMuxControl						=> StmDeMux_Control,

			In_Valid								=> UDP_RX_Valid,
			In_Data									=> UDP_RX_Data,
			In_Meta									=> StmDeMux_Out_MetaIn,
			In_Meta_rev							=> StmDeMux_Out_MetaIn_rev,
			In_SOF									=> UDP_RX_SOF,
			In_EOF									=> UDP_RX_EOF,
			In_Ack									=> StmDeMux_Out_Ack,

			Out_Valid								=> RX_Valid,
			Out_Data								=> StmDeMux_Out_Data,
			Out_Meta								=> StmDeMux_Out_MetaOut,
			Out_Meta_rev						=> StmDeMux_Out_MetaOut_rev,
			Out_SOF									=> RX_SOF,
			Out_EOF									=> RX_EOF,
			Out_Ack									=> RX_Ack
		);

	assign_col(StmDeMux_Out_MetaOut_rev, RX_Meta_rst,									STMDEMUX_META_RST_BIT);
	assign_col(StmDeMux_Out_MetaOut_rev, RX_Meta_SrcMACAddress_nxt,		STMDEMUX_META_MACSRC_NXT_BIT);
	assign_col(StmDeMux_Out_MetaOut_rev, RX_Meta_DestMACAddress_nxt,	STMDEMUX_META_MACDEST_NXT_BIT);
	assign_col(StmDeMux_Out_MetaOut_rev, RX_Meta_SrcIPAddress_nxt,		STMDEMUX_META_IPSRC_NXT_BIT);
	assign_col(StmDeMux_Out_MetaOut_rev, RX_Meta_DestIPAddress_nxt,		STMDEMUX_META_IPDEST_NXT_BIT);

	-- new slm_slice funtion to avoid generate statement for wiring => cut multiple columns over all rows and convert to slvv_*
	RX_Data													<= to_slvv_8(StmDeMux_Out_Data);
	RX_Meta_SrcMACAddress_Data			<= to_slvv_8(	slm_slice_cols(StmDeMux_Out_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCMAC),		low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCMAC)));
	RX_Meta_DestMACAddress_Data			<= to_slvv_8(	slm_slice_cols(StmDeMux_Out_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTMAC),	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTMAC)));
	RX_Meta_EthType									<= to_slvv_16(slm_slice_cols(StmDeMux_Out_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_ETHTYPE),	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_ETHTYPE)));
	RX_Meta_SrcIPAddress_Data				<= to_slvv_8(	slm_slice_cols(StmDeMux_Out_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCIP),		low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCIP)));
	RX_Meta_DestIPAddress_Data			<= to_slvv_8(	slm_slice_cols(StmDeMux_Out_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTIP),		low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTIP)));
	RX_Meta_Length									<= to_slvv_16(slm_slice_cols(StmDeMux_Out_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_LENGTH),		low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_LENGTH)));
	RX_Meta_Protocol								<= to_slvv_8(	slm_slice_cols(StmDeMux_Out_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_PROTO),		low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_PROTO)));
	RX_Meta_SrcPort									<= to_slvv_16(slm_slice_cols(StmDeMux_Out_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCPORT),	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_SRCPORT)));
	RX_Meta_DestPort								<= to_slvv_16(slm_slice_cols(StmDeMux_Out_MetaOut, high(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTPORT),	low(STMDEMUX_META_BITS, STMDEMUX_META_STREAMID_DESTPORT)));

end architecture;
