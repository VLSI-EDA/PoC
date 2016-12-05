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
use			PoC.physical.all;
use			PoC.cache.all;
use			PoC.net.all;


entity arp_Wrapper is
	generic (
		CLOCK_FREQ													: FREQ																	:= 125 MHz;
		INTERFACE_MACADDRESS								: T_NET_MAC_ADDRESS											:= C_NET_MAC_ADDRESS_EMPTY;
		INITIAL_IPV4ADDRESSES								: T_NET_IPV4_ADDRESS_VECTOR							:= (0 => C_NET_IPV4_ADDRESS_EMPTY);
		INITIAL_ARPCACHE_CONTENT						: T_NET_ARP_ARPCACHE_VECTOR							:= (0 => (Tag => C_NET_IPV4_ADDRESS_EMPTY, MAC => C_NET_MAC_ADDRESS_EMPTY));
		APR_REQUEST_TIMEOUT									: time																	:= 100 ms
	);
	port (
		Clock																: in	std_logic;
		Reset																: in	std_logic;

		IPPool_Announce											: in	std_logic;
		IPPool_Announced										: out	std_logic;

		IPCache_Lookup											: in	std_logic;
		IPCache_IPv4Address_rst							: out	std_logic;
		IPCache_IPv4Address_nxt							: out	std_logic;
		IPCache_IPv4Address_Data						: in	T_SLV_8;

		IPCache_Valid												: out	std_logic;
		IPCache_MACAddress_rst							: in	std_logic;
		IPCache_MACAddress_nxt							: in	std_logic;
		IPCache_MACAddress_Data							: out	T_SLV_8;

		Eth_UC_TX_Valid											: out	std_logic;
		Eth_UC_TX_Data											: out	T_SLV_8;
		Eth_UC_TX_SOF												: out	std_logic;
		Eth_UC_TX_EOF												: out	std_logic;
		Eth_UC_TX_Ack												: in	std_logic;
		Eth_UC_TX_Meta_rst									: in	std_logic;
		Eth_UC_TX_Meta_DestMACAddress_nxt		: in	std_logic;
		Eth_UC_TX_Meta_DestMACAddress_Data	: out	T_SLV_8;

		Eth_UC_RX_Valid											: in	std_logic;
		Eth_UC_RX_Data											: in	T_SLV_8;
		Eth_UC_RX_SOF												: in	std_logic;
		Eth_UC_RX_EOF												: in	std_logic;
		Eth_UC_RX_Ack												: out	std_logic;
		Eth_UC_RX_Meta_rst									: out	std_logic;
		Eth_UC_RX_Meta_SrcMACAddress_nxt		: out	std_logic;
		Eth_UC_RX_Meta_SrcMACAddress_Data		: in	T_SLV_8;
		Eth_UC_RX_Meta_DestMACAddress_nxt		: out	std_logic;
		Eth_UC_RX_Meta_DestMACAddress_Data	: in	T_SLV_8;

		Eth_BC_RX_Valid											: in	std_logic;
		Eth_BC_RX_Data											: in	T_SLV_8;
		Eth_BC_RX_SOF												: in	std_logic;
		Eth_BC_RX_EOF												: in	std_logic;
		Eth_BC_RX_Ack												: out	std_logic;
		Eth_BC_RX_Meta_rst									: out	std_logic;
		Eth_BC_RX_Meta_SrcMACAddress_nxt		: out	std_logic;
		Eth_BC_RX_Meta_SrcMACAddress_Data		: in	T_SLV_8;
		Eth_BC_RX_Meta_DestMACAddress_nxt		: out	std_logic;
		Eth_BC_RX_Meta_DestMACAddress_Data	: in	T_SLV_8
	);
end entity;


architecture rtl of arp_Wrapper is
	signal ARPCache_Command												: T_NET_ARP_ARPCACHE_COMMAND;
	signal IPPool_Command													: T_NET_ARP_IPPOOL_COMMAND;

	signal IPPool_Announce_l											: std_logic							:= '0';
	signal IPPool_Announced_i											: std_logic;

	type T_FSMPOOL_STATE is (
		ST_IDLE,
		ST_IPPOOL_WAIT,
		ST_SEND_RESPONSE,
		ST_SEND_ANNOUNCE,
		ST_ERROR
	);

	signal FSMPool_State													: T_FSMPOOL_STATE				:= ST_IDLE;
	signal FSMPool_NextState											: T_FSMPOOL_STATE;

	signal FSMPool_MACSeq1_SenderMACAddress_rst		: std_logic;
	signal FSMPool_MACSeq1_SenderMACAddress_nxt		: std_logic;

	signal FSMPool_BCRcv_Clear										: std_logic;
	signal FSMPool_BCRcv_Address_rst							: std_logic;
	signal FSMPool_BCRcv_SenderMACAddress_nxt			: std_logic;
	signal FSMPool_BCRcv_SenderIPv4Address_nxt		: std_logic;
	signal FSMPool_BCRcv_TargetIPv4Address_nxt		: std_logic;

	signal FSMPool_Command												: T_NET_ARP_IPPOOL_COMMAND;
	signal FSMPool_NewIPv4Address_Data						: T_NET_IPV4_ADDRESS;
	signal FSMPool_NewMACAddress_Data							: T_NET_MAC_ADDRESS;
	signal FSMPool_IPPool_Lookup									: std_logic;
	signal FSMPool_IPPool_IPv4Address_Data				: T_SLV_8;

	signal FSMPool_UCRsp_SendResponse							: std_logic;
	signal FSMPool_UCRsp_SenderMACAddress_Data		: T_SLV_8;
	signal FSMPool_UCRsp_SenderIPv4Address_Data		: T_SLV_8;
	signal FSMPool_UCRsp_TargetMACAddress_Data		: T_SLV_8;
	signal FSMPool_UCRsp_TargetIPv4Address_Data		: T_SLV_8;

	-- Sender MACAddress sequencer
	signal MACSeq1_SenderMACAddress_Data					: T_SLV_8;

	-- broadcast receiver
	signal BCRcv_Error														: std_logic;

	signal BCRcv_RequestReceived									: std_logic;
	signal BCRcv_SenderMACAddress_Data						: T_SLV_8;
	signal BCRcv_SenderIPv4Address_Data						: T_SLV_8;
	signal BCRcv_TargetIPv4Address_Data						: T_SLV_8;

	-- ippool
	signal IPPool_Insert													: std_logic;
	signal IPPool_UCRsp_SendResponse							: std_logic;
	signal IPPool_IPv4Address_rst									: std_logic;
	signal IPPool_IPv4Address_nxt									: std_logic;
	signal IPPool_PoolResult											: T_CACHE_RESULT;

	-- unicast responder
	signal UCRsp_Complete													: std_logic;

	signal UCRsp_Address_rst											: std_logic;
	signal UCRsp_SenderMACAddress_nxt							: std_logic;
	signal UCRsp_SenderIPv4Address_nxt						: std_logic;
	signal UCRsp_TargetMACAddress_nxt							: std_logic;
	signal UCRsp_TargetIPv4Address_nxt						: std_logic;

	signal UCRsp_TX_Valid													: std_logic;
	signal UCRsp_TX_Data													: T_SLV_8;
	signal UCRsp_TX_SOF														: std_logic;
	signal UCRsp_TX_EOF														: std_logic;
	signal UCRsp_TX_Ack														: std_logic;
	signal UCRsp_TX_Meta_DestMACAddress_rst				: std_logic;
	signal UCRsp_TX_Meta_DestMACAddress_nxt				: std_logic;
	signal UCRsp_TX_Meta_DestMACAddress_Data			: T_SLV_8;

	type T_FSMCACHE_STATE is (
		ST_IDLE,
			ST_CACHE, ST_CACHE_WAIT, ST_READ_CACHE,
			ST_SEND_BROADCAST_REQUEST, ST_SEND_BROADCAST_REQUEST_WAIT, ST_WAIT_FOR_UNICAST_RESPONSE,
			ST_UPDATE_CACHE,
		ST_ERROR
	);

	signal FSMCache_State													: T_FSMCACHE_STATE								:= ST_IDLE;
	signal FSMCache_NextState											: T_FSMCACHE_STATE;

	signal FSMCache_ARPCache_Command							: T_NET_ARP_ARPCACHE_COMMAND;
	signal FSMCache_ARPCache_NewIPv4Address_Data	: T_SLV_8;
	signal FSMCache_ARPCache_NewMACAddress_Data		: T_SLV_8;

	signal FSMCache_MACSeq2_SenderMACAddress_rst	: std_logic;
	signal FSMCache_MACSeq2_SenderMACAddress_nxt	: std_logic;
	signal FSMCache_IPSeq2_SenderIPv4Address_rst	: std_logic;
	signal FSMCache_IPSeq2_SenderIPv4Address_nxt	: std_logic;

	signal FSMCache_UCRcv_Clear										: std_logic;
	signal FSMCache_UCRcv_Address_rst							: std_logic;
	signal FSMCache_UCRcv_SenderMACAddress_nxt		: std_logic;
	signal FSMCache_UCRcv_SenderIPv4Address_nxt		: std_logic;
	signal FSMCache_UCRcv_TargetMACAddress_nxt		: std_logic;
	signal FSMCache_UCRcv_TargetIPv4Address_nxt		: std_logic;

	signal FSMCache_ARPCache_Lookup								: std_logic;
	signal FSMCache_ARPCache_IPv4Address_Data			: T_SLV_8;
	signal FSMCache_ARPCache_MACAddress_rst				: std_logic;
	signal FSMCache_ARPCache_MACAddress_nxt				: std_logic;

	signal FSMCache_BCReq_SendRequest							: std_logic;
	signal FSMCache_BCReq_SenderMACAddress_Data		: T_SLV_8;
	signal FSMCache_BCReq_SenderIPv4Address_Data	: T_SLV_8;
	signal FSMCache_BCReq_TargetMACAddress_Data		: T_SLV_8;
	signal FSMCache_BCReq_TargetIPv4Address_Data	: T_SLV_8;

	-- Sender ***Address sequencer
	signal MACSeq2_SenderMACAddress_Data					: T_SLV_8;
	signal IPSeq2_SenderIPv4Address_Data					: T_SLV_8;

	-- ARP request timeout counter
	constant ARPREQ_TIMEOUTCOUNTER_MAX						: positive																						:= TimingToCycles(APR_REQUEST_TIMEOUT, CLOCK_FREQ);
	constant ARPREQ_TIMEOUTCOUNTER_BITS						: positive																						:= log2ceilnz(ARPREQ_TIMEOUTCOUNTER_MAX);

	signal FSMCache_ARPReq_TimeoutCounter_rst			: std_logic;
	signal ARPReq_TimeoutCounter_s								: signed(ARPREQ_TIMEOUTCOUNTER_BITS downto 0)					:= to_signed(ARPREQ_TIMEOUTCOUNTER_MAX, ARPREQ_TIMEOUTCOUNTER_BITS + 1);
	signal ARPReq_Timeout													: std_logic;

	-- unicast receiver
	signal UCRcv_Error														: std_logic;
	signal UCRcv_ResponseReceived									: std_logic;
	signal UCRcv_SenderMACAddress_Data						: T_SLV_8;
	signal UCRcv_SenderIPv4Address_Data						: T_SLV_8;
	signal UCRcv_TargetMACAddress_Data						: T_SLV_8;
	signal UCRcv_TargetIPv4Address_Data						: T_SLV_8;

	-- arp cache
	signal ARPCache_Status												: T_NET_ARP_ARPCACHE_STATUS;
	signal ARPCache_NewMACAddress_nxt							: std_logic;
	signal ARPCache_NewIPv4Address_nxt						: std_logic;
	signal ARPCache_CacheResult										: T_CACHE_RESULT;
	signal ARPCache_IPv4Address_rst								: std_logic;
	signal ARPCache_IPv4Address_nxt								: std_logic;
	signal ARPCache_MACAddress_Data								: T_SLV_8;

	-- broadcast requester
	signal BCReq_Complete													: std_logic;

	signal BCReq_Address_rst											: std_logic;
	signal BCReq_SenderMACAddress_nxt							: std_logic;
	signal BCReq_SenderIPv4Address_nxt						: std_logic;
	signal BCReq_TargetMACAddress_nxt							: std_logic;
	signal BCReq_TargetIPv4Address_nxt						: std_logic;

	signal BCReq_TX_Valid													: std_logic;
	signal BCReq_TX_Data													: T_SLV_8;
	signal BCReq_TX_SOF														: std_logic;
	signal BCReq_TX_EOF														: std_logic;
	signal BCReq_TX_Ack														: std_logic;
	signal BCReq_TX_Meta_DestMACAddress_rst				: std_logic;
	signal BCReq_TX_Meta_DestMACAddress_nxt				: std_logic;
	signal BCReq_TX_Meta_DestMACAddress_Data			: T_SLV_8;

begin
	-- latched inputs (high-active)
	IPPool_Announce_l	<= ((IPPool_Announce or IPPool_Announce_l) and not IPPool_Announced_i) when rising_edge(Clock);
	IPPool_Announced	<= IPPool_Announced_i;

	-- FIXME: assign correct value
	IPPool_Insert		<= '0';

-- =============================================================================
-- Responder Path
-- =============================================================================
	MACSeq1 : entity PoC.misc_Sequencer
		generic map (
			INPUT_BITS						=> 48,
			OUTPUT_BITS						=> 8,
			REGISTERED						=> FALSE
		)
		port map (
			Clock									=> Clock,
			Reset									=> Reset,

			Input									=> to_slv(INTERFACE_MACADDRESS),
			rst										=> FSMPool_MACSeq1_SenderMACAddress_rst,
			rev										=> '1',
			nxt										=> FSMPool_MACSeq1_SenderMACAddress_nxt,
			Output								=> MACSeq1_SenderMACAddress_Data
		);

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				FSMPool_State		<= ST_IDLE;
			else
				FSMPool_State		<= FSMPool_NextState;
			end if;
		end if;
	end process;

	-- sequencer
	--INTERFACE_MACAddress_Data

	process(FSMPool_State,
					IPPool_Announce_l,
					MACSeq1_SenderMACAddress_Data,
					BCRcv_RequestReceived, BCRcv_Error, BCRcv_SenderMACAddress_Data, BCRcv_SenderIPv4Address_Data, BCRcv_TargetIPv4Address_Data,
					IPPool_PoolResult, IPPool_IPv4Address_nxt,
					UCRsp_Address_rst, UCRsp_SenderMACAddress_nxt, UCRsp_SenderIPv4Address_nxt, UCRsp_TargetMACAddress_nxt, UCRsp_TargetIPv4Address_nxt, UCRsp_Complete)
	begin
		FSMPool_NextState											<= FSMPool_State;

--		FSMPool_Command						<= NET_ARP_CACHE_CMD_NONE;
--		FSMPool_NewIPv4Address_Data		<= UCRcv_SenderIPv4Address_Data;
--		FSMPool_NewMACAddress_Data			<= UCRcv_SenderMACAddress_Data;

		IPPool_Announced_i										<= '0';

		FSMPool_MACSeq1_SenderMACAddress_rst	<= '0';
		FSMPool_MACSeq1_SenderMACAddress_nxt	<= '0';

		FSMPool_BCRcv_Clear										<= '0';
		FSMPool_BCRcv_Address_rst							<= '0';
		FSMPool_BCRcv_SenderMACAddress_nxt		<= '0';
		FSMPool_BCRcv_SenderIPv4Address_nxt		<= '0';
		FSMPool_BCRcv_TargetIPv4Address_nxt		<= '0';

		FSMPool_IPPool_Lookup									<= '0';
		FSMPool_IPPool_IPv4Address_Data				<= BCRcv_TargetIPv4Address_Data;

		FSMPool_UCRsp_SendResponse						<= '0';
		FSMPool_UCRsp_SenderMACAddress_Data		<= MACSeq1_SenderMACAddress_Data;
		FSMPool_UCRsp_SenderIPv4Address_Data	<= BCRcv_TargetIPv4Address_Data;
		FSMPool_UCRsp_TargetMACAddress_Data		<= BCRcv_SenderMACAddress_Data;
		FSMPool_UCRsp_TargetIPv4Address_Data	<= BCRcv_SenderIPv4Address_Data;

		case FSMPool_State is
			when ST_IDLE =>
				if (BCRcv_RequestReceived = '1') then
					FSMPool_IPPool_Lookup									<= '1';
					FSMPool_BCRcv_TargetIPv4Address_nxt		<= IPPool_IPv4Address_nxt;

					FSMPool_NextState											<= ST_IPPOOL_WAIT;
				elsif (IPPool_Announce_l = '1') then
--					FSMPool_UCRsp_SendResponse						<= '1';

--					FSMPool_NextState											<= ST_SEND_ANNOUNCE;
				end if;

			when ST_IPPOOL_WAIT =>
				FSMPool_BCRcv_TargetIPv4Address_nxt			<= IPPool_IPv4Address_nxt;

				if (IPPool_PoolResult = CACHE_RESULT_HIT) then
					FSMPool_BCRcv_Address_rst							<= '1';
					FSMPool_MACSeq1_SenderMACAddress_rst	<= '1';
					FSMPool_UCRsp_SendResponse						<= '1';

					FSMPool_NextState											<= ST_SEND_RESPONSE;
				elsif (IPPool_PoolResult = CACHE_RESULT_MISS) then
					FSMPool_BCRcv_Clear										<= '1';
					FSMPool_NextState											<= ST_IDLE;
				end if;

			when ST_SEND_RESPONSE =>
				FSMPool_BCRcv_Address_rst								<= UCRsp_Address_rst;
				FSMPool_BCRcv_SenderMACAddress_nxt			<= UCRsp_TargetMACAddress_nxt;
				FSMPool_BCRcv_SenderIPv4Address_nxt			<= UCRsp_TargetIPv4Address_nxt;
				FSMPool_MACSeq1_SenderMACAddress_nxt		<= UCRsp_SenderMACAddress_nxt;
				FSMPool_BCRcv_TargetIPv4Address_nxt			<= UCRsp_SenderIPv4Address_nxt;

				if (UCRsp_Complete = '1') then
					FSMPool_BCRcv_Clear							<= '1';
					FSMPool_NextState								<= ST_IDLE;
				end if;

			when ST_SEND_ANNOUNCE =>
				if (UCRsp_Complete = '1') then
					IPPool_Announced_i							<= '1';
					FSMPool_BCRcv_Clear							<= '1';

					FSMPool_NextState								<= ST_IDLE;
				end if;

			when ST_ERROR =>
				null;

		end case;
	end process;

	BCRcv : entity PoC.arp_BroadCast_Receiver
		generic map (
			ALLOWED_PROTOCOL_IPV4					=> TRUE,
			ALLOWED_PROTOCOL_IPV6					=> FALSE
		)
		port map (
			Clock													=> Clock,
			Reset													=> Reset,

			RX_Valid											=> Eth_BC_RX_Valid,
			RX_Data												=> Eth_BC_RX_Data,
			RX_SOF												=> Eth_BC_RX_SOF,
			RX_EOF												=> Eth_BC_RX_EOF,
			RX_Ack												=> Eth_BC_RX_Ack,
			RX_Meta_rst										=> Eth_BC_RX_Meta_rst,
			RX_Meta_SrcMACAddress_nxt			=> Eth_BC_RX_Meta_SrcMACAddress_nxt,
			RX_Meta_SrcMACAddress_Data		=> Eth_BC_RX_Meta_SrcMACAddress_Data,
			RX_Meta_DestMACAddress_nxt		=> Eth_BC_RX_Meta_DestMACAddress_nxt,
			RX_Meta_DestMACAddress_Data		=> Eth_BC_RX_Meta_DestMACAddress_Data,

			Clear													=> FSMPool_BCRcv_Clear,
			Error													=> BCRcv_Error,

			RequestReceived								=> BCRcv_RequestReceived,
			Address_rst										=> FSMPool_BCRcv_Address_rst,
			SenderMACAddress_nxt					=> FSMPool_BCRcv_SenderMACAddress_nxt,
			SenderMACAddress_Data					=> BCRcv_SenderMACAddress_Data,
			SenderIPAddress_nxt						=> FSMPool_BCRcv_SenderIPv4Address_nxt,
			SenderIPAddress_Data					=> BCRcv_SenderIPv4Address_Data,
			TargetIPAddress_nxt						=> FSMPool_BCRcv_TargetIPv4Address_nxt,
			TargetIPAddress_Data					=> BCRcv_TargetIPv4Address_Data
		);

	IPPool : entity PoC.arp_IPPool
		generic map (
			IPPOOL_SIZE										=> 8,
			INITIAL_IPV4ADDRESSES					=> INITIAL_IPV4ADDRESSES
		)
		port map (
			Clock													=> Clock,
			Reset													=> Reset,

--			Command												=> IPPool_Command,
--			IPv4Address_Data							=> (others => '0'),
--			MACAddress_Data								=> (others => '0'),

			Lookup												=> FSMPool_IPPool_Lookup,
			IPv4Address_rst								=> IPPool_IPv4Address_rst,
			IPv4Address_nxt								=> IPPool_IPv4Address_nxt,
			IPv4Address_Data							=> FSMPool_IPPool_IPv4Address_Data,

			PoolResult										=> IPPool_PoolResult
		);

	UCRsp : entity PoC.arp_UniCast_Responder
--		generic map (
--
--		)
		port map (
			Clock													=> Clock,
			Reset													=> Reset,

			SendResponse									=> FSMPool_UCRsp_SendResponse,
			Complete											=> UCRsp_Complete,

			Address_rst										=> UCRsp_Address_rst,
			SenderMACAddress_nxt					=> UCRsp_SenderMACAddress_nxt,
			SenderMACAddress_Data					=> FSMPool_UCRsp_SenderMACAddress_Data,					-- self
			SenderIPv4Address_nxt					=> UCRsp_SenderIPv4Address_nxt,
			SenderIPv4Address_Data				=> FSMPool_UCRsp_SenderIPv4Address_Data,				-- self
			TargetMACAddress_nxt					=> UCRsp_TargetMACAddress_nxt,
			TargetMACAddress_Data					=> FSMPool_UCRsp_TargetMACAddress_Data,					-- requester
			TargetIPv4Address_nxt					=> UCRsp_TargetIPv4Address_nxt,
			TargetIPv4Address_Data				=> FSMPool_UCRsp_TargetIPv4Address_Data,				-- requester

			TX_Valid											=> UCRsp_TX_Valid,
			TX_Data												=> UCRsp_TX_Data,
			TX_SOF												=> UCRsp_TX_SOF,
			TX_EOF												=> UCRsp_TX_EOF,
			TX_Ack												=> UCRsp_TX_Ack,
			TX_Meta_DestMACAddress_rst		=> UCRsp_TX_Meta_DestMACAddress_rst,
			TX_Meta_DestMACAddress_nxt		=> UCRsp_TX_Meta_DestMACAddress_nxt,
			TX_Meta_DestMACAddress_Data		=> UCRsp_TX_Meta_DestMACAddress_Data
		);
-- =============================================================================
-- ARPCache Path
-- =============================================================================
	MACSeq2 : entity PoC.misc_Sequencer
		generic map (
			INPUT_BITS						=> 48,
			OUTPUT_BITS						=> 8,
			REGISTERED						=> FALSE
		)
		port map (
			Clock									=> Clock,
			Reset									=> Reset,

			Input									=> to_slv(INTERFACE_MACADDRESS),
			rst										=> FSMCache_MACSeq2_SenderMACAddress_rst,
			rev										=> '1',
			nxt										=> FSMCache_MACSeq2_SenderMACAddress_nxt,
			Output								=> MACSeq2_SenderMACAddress_Data
		);

	IPSeq2 : entity PoC.misc_Sequencer
		generic map (
			INPUT_BITS						=> 32,
			OUTPUT_BITS						=> 8,
			REGISTERED						=> FALSE
		)
		port map (
			Clock									=> Clock,
			Reset									=> Reset,

			Input									=> to_slv(INITIAL_IPV4ADDRESSES(0)),
			rst										=> FSMCache_IPSeq2_SenderIPv4Address_rst,
			rev										=> '1',
			nxt										=> FSMCache_IPSeq2_SenderIPv4Address_nxt,
			Output								=> IPSeq2_SenderIPv4Address_Data
		);

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				FSMCache_State		<= ST_IDLE;
			else
				FSMCache_State		<= FSMCache_NextState;
			end if;
		end if;
	end process;

	process(FSMCache_State,
					IPCache_Lookup, IPCache_IPv4Address_Data,	IPCache_MACAddress_rst, IPCache_MACAddress_nxt,
					MACSeq2_SenderMACAddress_Data, IPSeq2_SenderIPv4Address_Data, ARPReq_Timeout,
					UCRcv_Error, UCRcv_ResponseReceived, UCRcv_SenderIPv4Address_Data, UCRcv_SenderMACAddress_Data, UCRcv_TargetIPv4Address_Data, UCRcv_TargetMACAddress_Data,
					ARPCache_Status, ARPCache_CacheResult, ARPCache_IPv4Address_rst, ARPCache_IPv4Address_nxt, ARPCache_MACAddress_Data, ARPCache_NewMACAddress_nxt, ARPCache_NewIPv4Address_nxt,
					BCReq_Address_rst, BCReq_SenderMACAddress_nxt, BCReq_SenderIPv4Address_nxt, BCReq_TargetMACAddress_nxt, BCReq_TargetIPv4Address_nxt, BCReq_Complete)
	begin
		FSMCache_NextState													<= FSMCache_State;

		IPCache_IPv4Address_rst											<= '0';
		IPCache_IPv4Address_nxt											<= '0';

		IPCache_Valid																<= '0';
		IPCache_MACAddress_Data											<= ARPCache_MACAddress_Data;

		FSMCache_ARPCache_Command										<= NET_ARP_ARPCACHE_CMD_NONE;
		FSMCache_ARPCache_NewMACAddress_Data				<= UCRcv_SenderMACAddress_Data;
		FSMCache_ARPCache_NewIPv4Address_Data				<= UCRcv_SenderIPv4Address_Data;

		FSMCache_MACSeq2_SenderMACAddress_rst				<= '0';
		FSMCache_MACSeq2_SenderMACAddress_nxt				<= '0';
		FSMCache_IPSeq2_SenderIPv4Address_rst				<= '0';
		FSMCache_IPSeq2_SenderIPv4Address_nxt				<= '0';

		FSMCache_ARPReq_TimeoutCounter_rst					<= '1';

		FSMCache_ARPCache_Lookup										<= '0';
		FSMCache_ARPCache_IPv4Address_Data					<= IPCache_IPv4Address_Data;
		FSMCache_ARPCache_MACAddress_rst						<= IPCache_MACAddress_rst;
		FSMCache_ARPCache_MACAddress_nxt						<= IPCache_MACAddress_nxt;

		FSMCache_BCReq_SendRequest									<= '0';
		FSMCache_BCReq_SenderMACAddress_Data				<= MACSeq2_SenderMACAddress_Data;
		FSMCache_BCReq_SenderIPv4Address_Data				<= IPSeq2_SenderIPv4Address_Data;
		FSMCache_BCReq_TargetMACAddress_Data				<= x"00";
		FSMCache_BCReq_TargetIPv4Address_Data				<= IPCache_IPv4Address_Data;

		FSMCache_UCRcv_Clear												<= UCRcv_ResponseReceived;		-- discard all ARP packets, which are not requested / expected
		FSMCache_UCRcv_Address_rst									<= '0';
		FSMCache_UCRcv_SenderMACAddress_nxt					<= '0';
		FSMCache_UCRcv_SenderIPv4Address_nxt				<= '0';
		FSMCache_UCRcv_TargetMACAddress_nxt					<= '0';		-- default assignment for unsed metadata TargetMACAddress
		FSMCache_UCRcv_TargetIPv4Address_nxt				<= '0';		-- default assignment for unsed metadata TargetIPv4Address

		case FSMCache_State is
			when ST_IDLE =>
				IPCache_IPv4Address_rst									<= '1';

				if (IPCache_Lookup = '1') then
					FSMCache_NextState										<= ST_CACHE;
				end if;

			when ST_CACHE =>
				FSMCache_ARPCache_Lookup								<= '1';
				IPCache_IPv4Address_rst									<= ARPCache_IPv4Address_rst;
				IPCache_IPv4Address_nxt									<= ARPCache_IPv4Address_nxt;

				if (ARPCache_CacheResult = CACHE_RESULT_MISS) then
					FSMCache_NextState										<= ST_SEND_BROADCAST_REQUEST;
				else
					FSMCache_NextState										<= ST_CACHE_WAIT;
				end if;

			when ST_CACHE_WAIT =>
				IPCache_IPv4Address_rst									<= ARPCache_IPv4Address_rst;
				IPCache_IPv4Address_nxt									<= ARPCache_IPv4Address_nxt;

				if (ARPCache_CacheResult = CACHE_RESULT_HIT) then
					FSMCache_NextState										<= ST_READ_CACHE;
				elsif (ARPCache_CacheResult = CACHE_RESULT_MISS) then
					FSMCache_NextState										<= ST_SEND_BROADCAST_REQUEST;
				end if;

			when ST_READ_CACHE =>
				IPCache_IPv4Address_rst									<= '1';
				IPCache_Valid														<= '1';

				FSMCache_ARPCache_MACAddress_rst				<= IPCache_MACAddress_rst;
				FSMCache_ARPCache_MACAddress_nxt				<= IPCache_MACAddress_nxt;

				if (IPCache_Lookup = '1') then
					FSMCache_NextState										<= ST_CACHE;
				end if;

			when ST_SEND_BROADCAST_REQUEST =>
				FSMCache_MACSeq2_SenderMACAddress_rst		<= '1';
				FSMCache_IPSeq2_SenderIPv4Address_rst		<= '1';
				FSMCache_BCReq_SendRequest							<= '1';

				IPCache_IPv4Address_rst									<= BCReq_Address_rst;
				IPCache_IPv4Address_nxt									<= BCReq_TargetIPv4Address_nxt;

				FSMCache_NextState											<= ST_SEND_BROADCAST_REQUEST_WAIT;

			when ST_SEND_BROADCAST_REQUEST_WAIT =>
				FSMCache_MACSeq2_SenderMACAddress_rst		<= BCReq_Address_rst;
				FSMCache_MACSeq2_SenderMACAddress_nxt		<= BCReq_SenderMACAddress_nxt;
				FSMCache_IPSeq2_SenderIPv4Address_rst		<= BCReq_Address_rst;
				FSMCache_IPSeq2_SenderIPv4Address_nxt		<= BCReq_SenderIPv4Address_nxt;

				IPCache_IPv4Address_rst									<= BCReq_Address_rst;
				IPCache_IPv4Address_nxt									<= BCReq_TargetIPv4Address_nxt;

				if (BCReq_Complete = '1') then
					FSMCache_NextState										<= ST_WAIT_FOR_UNICAST_RESPONSE;
				end if;

			when ST_WAIT_FOR_UNICAST_RESPONSE =>
				FSMCache_UCRcv_Clear										<= '0';
				FSMCache_ARPReq_TimeoutCounter_rst			<= '0';
				-- TODO: check received ARP packet data with ethernet metadata

				if (UCRcv_Error = '1') then
					-- FIXME: error handling
					FSMCache_NextState										<= ST_ERROR;
				elsif (UCRcv_ResponseReceived = '1') then
					FSMCache_ARPCache_Command							<= NET_ARP_ARPCACHE_CMD_ADD;
					FSMCache_UCRcv_SenderMACAddress_nxt		<= ARPCache_NewMACAddress_nxt;
					FSMCache_UCRcv_SenderIPv4Address_nxt	<= ARPCache_NewIPv4Address_nxt;

					FSMCache_NextState										<= ST_UPDATE_CACHE;
				elsif (ARPReq_Timeout = '1') then
					-- FIXME: error handling
--					FSMCache_NextState										<= ST_ERROR;
					FSMCache_NextState										<= ST_SEND_BROADCAST_REQUEST;
				end if;

			when ST_UPDATE_CACHE =>
				FSMCache_UCRcv_Clear										<= '0';
				FSMCache_UCRcv_SenderMACAddress_nxt			<= ARPCache_NewMACAddress_nxt;
				FSMCache_UCRcv_SenderIPv4Address_nxt		<= ARPCache_NewIPv4Address_nxt;

				if (ARPCache_Status = NET_ARP_ARPCACHE_STATUS_UPDATE_COMPLETE) then
					FSMCache_UCRcv_Clear									<= '1';
					IPCache_IPv4Address_rst								<= '1';

					FSMCache_NextState										<= ST_CACHE;
				end if;

			when ST_ERROR =>
				-- FIXME: error handling
				FSMCache_NextState											<= ST_IDLE;

		end case;
	end process;

	-- ARP request expiration timer
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (FSMCache_ARPReq_TimeoutCounter_rst = '1') then
				ARPReq_TimeoutCounter_s		<= to_signed(ARPREQ_TIMEOUTCOUNTER_MAX, ARPReq_TimeoutCounter_s'length);
			else
				ARPReq_TimeoutCounter_s		<= ARPReq_TimeoutCounter_s - 1;
			end if;
		end if;
	end process;

	ARPReq_Timeout			<= ARPReq_TimeoutCounter_s(ARPReq_TimeoutCounter_s'high);

	UCRcv : entity PoC.arp_UniCast_Receiver
		generic map (
			ALLOWED_PROTOCOL_IPV4					=> TRUE,
			ALLOWED_PROTOCOL_IPV6					=> FALSE
		)
		port map (
			Clock													=> Clock,
			Reset													=> Reset,

			RX_Valid											=> Eth_UC_RX_Valid,
			RX_Data												=> Eth_UC_RX_Data,
			RX_SOF												=> Eth_UC_RX_SOF,
			RX_EOF												=> Eth_UC_RX_EOF,
			RX_Ack												=> Eth_UC_RX_Ack,
			RX_Meta_rst										=> Eth_UC_RX_Meta_rst,
			RX_Meta_SrcMACAddress_nxt			=> Eth_UC_RX_Meta_SrcMACAddress_nxt,
			RX_Meta_SrcMACAddress_Data		=> Eth_UC_RX_Meta_SrcMACAddress_Data,
			RX_Meta_DestMACAddress_nxt		=> Eth_UC_RX_Meta_DestMACAddress_nxt,
			RX_Meta_DestMACAddress_Data		=> Eth_UC_RX_Meta_DestMACAddress_Data,

			Clear													=> FSMCache_UCRcv_Clear,
			Error													=> UCRcv_Error,

			ResponseReceived							=> UCRcv_ResponseReceived,
			Address_rst										=> FSMCache_UCRcv_Address_rst,
			SenderIPAddress_nxt						=> FSMCache_UCRcv_SenderIPv4Address_nxt,
			SenderIPAddress_Data					=> UCRcv_SenderIPv4Address_Data,
			SenderMACAddress_nxt					=> FSMCache_UCRcv_SenderMACAddress_nxt,
			SenderMACAddress_Data					=> UCRcv_SenderMACAddress_Data,
			TargetIPAddress_nxt						=> FSMCache_UCRcv_TargetIPv4Address_nxt,
			TargetIPAddress_Data					=> UCRcv_TargetIPv4Address_Data,
			TargetMACAddress_nxt					=> FSMCache_UCRcv_TargetMACAddress_nxt,
			TargetMACAddress_Data					=> UCRcv_TargetMACAddress_Data
		);

	ARPCache : entity PoC.arp_Cache
		generic map (
			CLOCK_FREQ									=> CLOCK_FREQ,
			REPLACEMENT_POLICY					=> "LRU",
			TAG_BYTE_ORDER							=> BIG_ENDIAN,
			DATA_BYTE_ORDER							=> BIG_ENDIAN,
			INITIAL_CACHE_CONTENT				=> INITIAL_ARPCACHE_CONTENT
		)
		port map (
			Clock												=> Clock,
			Reset												=> Reset,

			Command											=> FSMCache_ARPCache_Command,
			Status											=> ARPCache_Status,
			NewMACAddress_nxt						=> ARPCache_NewMACAddress_nxt,
			NewMACAddress_Data					=> FSMCache_ARPCache_NewMACAddress_Data,
			NewIPv4Address_nxt					=> ARPCache_NewIPv4Address_nxt,
			NewIPv4Address_Data					=> FSMCache_ARPCache_NewIPv4Address_Data,

			Lookup											=> FSMCache_ARPCache_Lookup,
			IPv4Address_rst							=> ARPCache_IPv4Address_rst,
			IPv4Address_nxt							=> ARPCache_IPv4Address_nxt,
			IPv4Address_Data						=> FSMCache_ARPCache_IPv4Address_Data,

			CacheResult									=> ARPCache_CacheResult,
			MACAddress_rst							=> FSMCache_ARPCache_MACAddress_rst,
			MACAddress_nxt							=> FSMCache_ARPCache_MACAddress_nxt,
			MACAddress_Data							=> ARPCache_MACAddress_Data
		);

	BCReq : entity PoC.arp_BroadCast_Requester
--		generic map (
--
--		)
		port map (
			Clock													=> Clock,
			Reset													=> Reset,

			SendRequest										=> FSMCache_BCReq_SendRequest,
			Complete											=> BCReq_Complete,
			Address_rst										=> BCReq_Address_rst,
			SenderMACAddress_nxt					=> BCReq_SenderMACAddress_nxt,
			SenderMACAddress_Data					=> FSMCache_BCReq_SenderMACAddress_Data,			-- self
			SenderIPv4Address_nxt					=> BCReq_SenderIPv4Address_nxt,
			SenderIPv4Address_Data				=> FSMCache_BCReq_SenderIPv4Address_Data,			-- self
			TargetMACAddress_nxt					=> BCReq_TargetMACAddress_nxt,
			TargetMACAddress_Data					=> FSMCache_BCReq_TargetMACAddress_Data,			-- broadcast + request for mac-to-ip mapping
			TargetIPv4Address_nxt					=> BCReq_TargetIPv4Address_nxt,
			TargetIPv4Address_Data				=> FSMCache_BCReq_TargetIPv4Address_Data,			-- broadcast + request for mac-to-ip mapping

			TX_Valid											=> BCReq_TX_Valid,
			TX_Data												=> BCReq_TX_Data,
			TX_SOF												=> BCReq_TX_SOF,
			TX_EOF												=> BCReq_TX_EOF,
			TX_Ack												=> BCReq_TX_Ack,
			TX_Meta_DestMACAddress_rst		=> BCReq_TX_Meta_DestMACAddress_rst,
			TX_Meta_DestMACAddress_nxt		=> BCReq_TX_Meta_DestMACAddress_nxt,
			TX_Meta_DestMACAddress_Data		=> BCReq_TX_Meta_DestMACAddress_Data
		);

	blkStmMux : block
		constant LLMUX_PORT_BCREQ		: natural					:= 0;
		constant LLMUX_PORT_UCRSP		: natural					:= 1;
		constant LLMUX_PORTS				: positive				:= 2;

		constant META_RST_BIT				: natural					:= 0;
		constant META_DEST_NXT_BIT	: natural					:= 1;

		constant META_BITS					: positive				:= 8;
		constant META_REV_BITS			: positive				:= 2;


		signal Temp_Meta						: T_SLVV_48(LLMUX_PORTS - 1 downto 0);
		signal Temp_Meta2						: T_SLV_48;

		signal StmMux_In_Valid			: std_logic_vector(LLMUX_PORTS - 1 downto 0);
		signal StmMux_In_Data				: T_SLM(LLMUX_PORTS - 1 downto 0, T_SLV_8'range)								:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
		signal StmMux_In_Meta				: T_SLM(LLMUX_PORTS - 1 downto 0, META_BITS - 1 downto 0)				:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
		signal StmMux_In_Meta_rev		: T_SLM(LLMUX_PORTS - 1 downto 0, META_REV_BITS - 1 downto 0)		:= (others => (others => 'Z'));		-- necessary default assignment 'Z' to get correct simulation results (iSIM, vSIM, ghdl/gtkwave)
		signal StmMux_In_SOF				: std_logic_vector(LLMUX_PORTS - 1 downto 0);
		signal StmMux_In_EOF				: std_logic_vector(LLMUX_PORTS - 1 downto 0);
		signal StmMux_In_Ack				: std_logic_vector(LLMUX_PORTS - 1 downto 0);

		signal StmMux_Out_Meta			: std_logic_vector(META_BITS - 1 downto 0);
		signal StmMux_Out_Meta_rev	: std_logic_vector(META_REV_BITS - 1 downto 0);

	begin

		-- StmMux Port 0 - broadcast requester
		StmMux_In_Valid(LLMUX_PORT_BCREQ)				<= BCReq_TX_Valid;
		assign_row(StmMux_In_Data, BCReq_TX_Data,	LLMUX_PORT_BCREQ);
		StmMux_In_SOF(LLMUX_PORT_BCREQ)					<= BCReq_TX_SOF;
		StmMux_In_EOF(LLMUX_PORT_BCREQ)					<= BCReq_TX_EOF;
		BCReq_TX_Ack														<= StmMux_In_Ack	(LLMUX_PORT_BCREQ);
		assign_row(StmMux_In_Meta, BCReq_TX_Meta_DestMACAddress_Data, LLMUX_PORT_BCREQ);
		BCReq_TX_Meta_DestMACAddress_rst				<= StmMux_In_Meta_rev(LLMUX_PORT_BCREQ, META_RST_BIT);
		BCReq_TX_Meta_DestMACAddress_nxt				<= StmMux_In_Meta_rev(LLMUX_PORT_BCREQ, META_DEST_NXT_BIT);

		-- StmMux Port 1 - unicast responder
		StmMux_In_Valid(LLMUX_PORT_UCRSP)				<= UCRsp_TX_Valid;
		assign_row(StmMux_In_Data, UCRsp_TX_Data,	LLMUX_PORT_UCRSP);
		StmMux_In_SOF(LLMUX_PORT_UCRSP)					<= UCRsp_TX_SOF;
		StmMux_In_EOF(LLMUX_PORT_UCRSP)					<= UCRsp_TX_EOF;
		UCRsp_TX_Ack														<= StmMux_In_Ack	(LLMUX_PORT_UCRSP);
		UCRsp_TX_Meta_DestMACAddress_rst				<= StmMux_In_Meta_rev(LLMUX_PORT_UCRSP, META_RST_BIT);
		UCRsp_TX_Meta_DestMACAddress_nxt				<= StmMux_In_Meta_rev(LLMUX_PORT_UCRSP, META_DEST_NXT_BIT);
		assign_row(StmMux_In_Meta, UCRsp_TX_Meta_DestMACAddress_Data, LLMUX_PORT_UCRSP);

		StmMux : entity PoC.stream_Mux
			generic map (
				PORTS									=> LLMUX_PORTS,
				DATA_BITS							=> Eth_UC_TX_Data'length,
				META_BITS							=> META_BITS,
				META_REV_BITS					=> META_REV_BITS
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

				Out_Valid							=> Eth_UC_TX_Valid,
				Out_Data							=> Eth_UC_TX_Data,
				Out_Meta							=> StmMux_Out_Meta,
				Out_Meta_rev					=> StmMux_Out_Meta_rev,
				Out_SOF								=> Eth_UC_TX_SOF,
				Out_EOF								=> Eth_UC_TX_EOF,
				Out_Ack								=> Eth_UC_TX_Ack
			);

		StmMux_Out_Meta_rev(META_RST_BIT)				<= Eth_UC_TX_Meta_rst;
		StmMux_Out_Meta_rev(META_DEST_NXT_BIT)	<= Eth_UC_TX_Meta_DestMACAddress_nxt;
		Eth_UC_TX_Meta_DestMACAddress_Data			<= StmMux_Out_Meta(Eth_UC_TX_Meta_DestMACAddress_Data'range);
	end block;
end architecture;
