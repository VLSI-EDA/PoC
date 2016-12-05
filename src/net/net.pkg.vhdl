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
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.strings.all;
use			PoC.io.all;


package net is
	-- ==========================================================================================================================================================
	-- Ethernet: physical layer (PHY)
	-- ==========================================================================================================================================================
	type T_NET_ETH_PHY_DATA_INTERFACE is (
		NET_ETH_PHY_DATA_INTERFACE_MII,
		NET_ETH_PHY_DATA_INTERFACE_GMII,
		NET_ETH_PHY_DATA_INTERFACE_RGMII,
		NET_ETH_PHY_DATA_INTERFACE_SGMII
	);

	type T_NET_ETH_PHY_MANAGEMENT_INTERFACE is (
		NET_ETH_PHY_MANAGEMENT_INTERFACE_NONE,
		NET_ETH_PHY_MANAGEMENT_INTERFACE_MDIO,
		NET_ETH_PHY_MANAGEMENT_INTERFACE_MDIO_OVER_IIC
	);

	type T_NET_ETH_PCSCORE is (
		NET_ETH_PCSCORE_GENERIC_GMII,
		NET_ETH_PCSCORE_XILINX_HARDCORE,
		NET_ETH_PCSCORE_XILINX_PCSCORE
	);

	type T_NET_ETH_PHY_DEVICE is (
		NET_ETH_PHY_DEVICE_MARVEL_88E1111
	);

	subtype T_NET_ETH_PHY_DEVICE_ADDRESS is T_SLV_8;

	type T_NET_ETH_PHYCONTROLLER_COMMAND is (
		NET_ETH_PHYC_CMD_NONE,
		NET_ETH_PHYC_CMD_HARD_RESET,
		NET_ETH_PHYC_CMD_SOFT_RESET
	);

	type T_NET_ETH_PHYCONTROLLER_STATUS is (
		NET_ETH_PHYC_STATUS_POWER_DOWN,
		NET_ETH_PHYC_STATUS_RESETING,
		NET_ETH_PHYC_STATUS_CONNECTING,
		NET_ETH_PHYC_STATUS_CONNECTED,
		NET_ETH_PHYC_STATUS_DISCONNECTING,
		NET_ETH_PHYC_STATUS_DISCONNECTED,
		NET_ETH_PHYC_STATUS_ERROR
	);

	type T_NET_ETH_PHYCONTROLLER_ERROR is (
		NET_ETH_PHYC_ERROR_NONE,
		NET_ETH_PHYC_ERROR_NO_CABLE
	);

	-- FPGA <=> PHY physical interface: GMII (Gigabit Media Independant Interface)
	type T_NET_ETH_PHY_INTERFACE_GMII is record
		RX_RefClock						: std_logic;

		TX_Clock							: std_logic;
		TX_Valid							: std_logic;
		TX_Data								: T_SLV_8;
		TX_Error							: std_logic;

		RX_Clock							: std_logic;
		RX_Valid							: std_logic;
		RX_Data								: T_SLV_8;
		RX_Error							: std_logic;
	end record;

	-- FPGA <=> PHY physical interface: RGMII (Reduced Gigabit Media Independant Interface)
	type T_NET_ETH_PHY_INTERFACE_RGMII is record
		RX_RefClock						: std_logic;

		TX_Clock							: std_logic;
		TX_Data								: T_SLV_4;
		TX_Control						: std_logic;

		RX_Clock							: std_logic;
		RX_Data								: T_SLV_4;
		RX_Control						: std_logic;
	end record;

	-- FPGA <=> PHY physical interface: SGMII (Serial GMII)
	type T_NET_ETH_PHY_INTERFACE_SGMII is record
		DGB_SystemClock_In		: std_logic;
		DGB_AutoNeg_Restart		: std_logic;

		SGMII_RefClock_In			: std_logic;
		SGMII_TXRefClock_Out	: std_logic;
		SGMII_RXRefClock_Out	: std_logic;

		TX_n									: std_logic;
		TX_p									: std_logic;

		RX_n									: std_logic;
		RX_p									: std_logic;
	end record;

	-- FPGA <=> PHY management interface: MDIO (Management Data Input/Output)
	type T_NET_ETH_PHY_INTERFACE_MDIO is record
		Clock_ts							: T_IO_TRISTATE;	-- clock (MDC)
		Data_ts								: T_IO_TRISTATE;	-- data (MDIO)
	end record;

	type T_NET_ETH_PHY_INTERFACE_COMMON is record
		Reset									: std_logic;
		Interrupt							: std_logic;
	end record;

	-- combined interface definition - union-types are still not supported in VHDL
	type T_NET_ETH_PHY_INTERFACES is record
		GMII									: T_NET_ETH_PHY_INTERFACE_GMII;
		RGMII									: T_NET_ETH_PHY_INTERFACE_RGMII;
		SGMII									: T_NET_ETH_PHY_INTERFACE_SGMII;
		MDIO									: T_NET_ETH_PHY_INTERFACE_MDIO;
		Common								: T_NET_ETH_PHY_INTERFACE_COMMON;
	end record;

	-- ==========================================================================================================================================================
	-- Ethernet: physical coding sublayer (PCS)
	-- ==========================================================================================================================================================
	-- 1000BASE-X - synchronization
	type T_NET_ETH_PCS_1000BASE_X_SYNC_STATUS is (
		NET_ETH_PCS_1000BASE_X_SYNC_STATUS_FAIL,
		NET_ETH_PCS_1000BASE_X_SYNC_STATUS_OK
	);

	-- 1000BASE-X - autonegotiation
	type T_NET_ETH_PCS_1000BASE_X_AUTONEG_STATUS is (
		NET_ETH_PCS_1000BASE_X_AUTONEG_STATUS_IDLE,
		NET_ETH_PCS_1000BASE_X_AUTONEG_STATUS_CONFIG,
		NET_ETH_PCS_1000BASE_X_AUTONEG_STATUS_DATA
	);

	-- ==========================================================================================================================================================
	-- Ethernet: reconcilation sublayer (RS)
	-- ==========================================================================================================================================================
	type T_NET_ETH_RS_DATA_INTERFACE is (
		NET_ETH_RS_DATA_INTERFACE_MII,
		NET_ETH_RS_DATA_INTERFACE_GMII,
		NET_ETH_RS_DATA_INTERFACE_TRANSCEIVER
	);

	-- ==========================================================================================================================================================
	-- Ethernet: MAC Control-Layer
	-- ==========================================================================================================================================================
	type T_NET_ETH_COMMAND is (
		NET_ETH_CMD_NONE,
		NET_ETH_CMD_HARD_RESET,
		NET_ETH_CMD_SOFT_RESET--,
--		NET_ETH_CMD_POWER_DOWN,
--		NET_ETH_CMD_POWER_UP
	);

	type T_NET_ETH_STATUS is (
		NET_ETH_STATUS_POWER_DOWN,
		NET_ETH_STATUS_RESETING,
		NET_ETH_STATUS_CONNECTING,
		NET_ETH_STATUS_CONNECTED,
		NET_ETH_STATUS_DISCONNECTING,
		NET_ETH_STATUS_DISCONNECTED,
		NET_ETH_STATUS_ERROR
	);

	type T_NET_ETH_ERROR is (
		NET_ETH_ERROR_NONE,
		NET_ETH_ERROR_MAC_ERROR,
		NET_ETH_ERROR_PHY_ERROR,
		NET_ETH_ERROR_PCS_ERROR,
		NET_ETH_ERROR_NO_CABLE
	);

	-- ==========================================================================================================================================================
	-- Ethernet: ????????????????????
	-- ==========================================================================================================================================================
	function to_net_eth_RSDataInterface(str : string) return T_NET_ETH_RS_DATA_INTERFACE;
	function to_net_eth_PHYDataInterface(str : string) return T_NET_ETH_PHY_DATA_INTERFACE;
	function to_net_eth_PHYManagementInterface(str : string) return T_NET_ETH_PHY_MANAGEMENT_INTERFACE;
	function to_net_eth_PHYDevice(str : string) return T_NET_ETH_PHY_DEVICE;

	-- limitations
	constant C_NET_ETH_PREMABLE_LENGTH					: positive						:= 7;
	constant C_NET_ETH_INTER_FRAME_GAP_LENGTH		: positive						:= 12;
	constant C_NET_ETH_MIN_FRAME_LENGTH					: positive						:= 64;
	constant C_NET_ETH_MAX_NORMALFRAME_LENGTH		: positive						:= 1518;
	constant C_NET_ETH_MAX_TAGGEDFRAME_LENGTH		: positive						:= 1522;
	constant C_NET_ETH_MAX_JUMBOFRAME_LENGTH		: positive						:= 9018;

	-- ==========================================================================================================================================================
	-- Ethernet: MAC Data-Link-Layer
	-- ==========================================================================================================================================================
	-- types
	type T_NET_MAC_ADDRESS								is array (5 downto 0)				of T_SLV_8;
	type T_NET_MAC_ETHERNETTYPE						is array (1 downto 0)				of T_SLV_8;

	-- arrays
	type T_NET_MAC_ADDRESS_VECTOR					is array (natural range <>) of T_NET_MAC_ADDRESS;
	type T_NET_MAC_ETHERNETTYPE_VECTOR		is array (natural range <>)	of T_NET_MAC_ETHERNETTYPE;

	-- predefined constants
	constant C_NET_MAC_ADDRESS_EMPTY			: T_NET_MAC_ADDRESS					:= (others => (others => '0'));
	constant C_NET_MAC_ADDRESS_BROADCAST	: T_NET_MAC_ADDRESS					:= (others => (others => '1'));
	constant C_NET_MAC_MASK_EMPTY					: T_NET_MAC_ADDRESS					:= (others => (others => '0'));
	constant C_NET_MAC_MASK_DEFAULT				: T_NET_MAC_ADDRESS					:= (others => (others => '1'));
	constant C_NET_MAC_ETHERNETTYPE_EMPTY	: T_NET_MAC_ETHERNETTYPE		:= (others => (others => '0'));

	-- type conversion functions
	function to_net_mac_address(slv : T_SLV_48)						return T_NET_MAC_ADDRESS;
	function to_net_mac_address(slvv : T_SLVV_8)					return T_NET_MAC_ADDRESS;
	function to_net_mac_address(str : string)							return T_NET_MAC_ADDRESS;
	function to_net_mac_ethernettype(slv : T_SLV_16)			return T_NET_MAC_ETHERNETTYPE;

	function to_slv(mac : T_NET_MAC_ADDRESS) 							return std_logic_vector;
	function to_slv(Ethtype : T_NET_MAC_ETHERNETTYPE)			return std_logic_vector;

	function to_slvv_8(mac : T_NET_MAC_ADDRESS)						return T_SLVV_8;
	function to_slvv_8(Ethtype : T_NET_MAC_ETHERNETTYPE)	return T_SLVV_8;

	function to_string(mac : T_NET_MAC_ADDRESS)						return string;
	function to_string(Ethtype : T_NET_MAC_ETHERNETTYPE)	return string;

	-- ==========================================================================================================================================================
	-- ETH_Wrapper: configuration data structures
	-- ==========================================================================================================================================================
	type T_NET_MAC_INTERFACE is record
		Address							: T_NET_MAC_ADDRESS;
		Mask								: T_NET_MAC_ADDRESS;
	end record;

	type T_NET_MAC_INTERFACE_VECTOR is array(natural range <>) of T_NET_MAC_INTERFACE;

	constant C_NET_MAC_SOURCEFILTER_NONE	: T_NET_MAC_INTERFACE	:= (Address => to_net_mac_address("00:00:00:00:00:01"), Mask => C_NET_MAC_MASK_EMPTY);

	type T_NET_MAC_CONFIGURATION is record
		Interface						: T_NET_MAC_INTERFACE;
		SourceFilter				: T_NET_MAC_INTERFACE_VECTOR(0 to 7);
		TypeSwitch					: T_NET_MAC_ETHERNETTYPE_VECTOR(0 to 7);
	end record;

	-- arrays
	type T_NET_MAC_CONFIGURATION_VECTOR is array(natural range <>)	of T_NET_MAC_CONFIGURATION;

	-- functions
	function getPortCount(MACConfiguration : T_NET_MAC_CONFIGURATION_VECTOR) return positive;

	-- ==========================================================================================================================================================
	-- local network: sequence and flow control protocol (SFC)
	-- ==========================================================================================================================================================
	-- types
	subtype T_NET_MAC_SFC_TYPE										is T_SLV_16;

	-- arrays
	type		T_ETH_SFC_TYPE_VECTOR									is array (natural range <>) of T_NET_MAC_SFC_TYPE;

	-- predefined constants
	constant C_NET_MAC_SFC_TYPE_EMPTY							: T_NET_MAC_SFC_TYPE			:= (others => '0');

	-- ==========================================================================================================================================================
	-- internet layer: Internet Protocol - common
	-- ==========================================================================================================================================================
	subtype T_NET_IP_PROTOCOL											is T_SLV_8;


	-- ==========================================================================================================================================================
	-- internet layer: Internet Protocol Version 4 (IPv4)
	-- ==========================================================================================================================================================
	-- types
	type		T_NET_IPV4_ADDRESS										is array (3 downto 0)				of T_SLV_8;
	subtype T_NET_IPV4_PROTOCOL										is T_NET_IP_PROTOCOL;
	subtype T_NET_IPV4_TOS_PRECEDENCE							is std_logic_vector(2 downto 0);

	type T_NET_IPV4_TYPE_OF_SERVICE is record
		Precedence					: T_NET_IPV4_TOS_PRECEDENCE;
		Delay								: std_logic;
		Throughput					: std_logic;
		Relibility					: std_logic;
	end record;

	-- arrays
	type		T_NET_IPV4_ADDRESS_VECTOR							is array (natural range <>) of T_NET_IPV4_ADDRESS;
	type		T_NET_IPV4_PROTOCOL_VECTOR						is array (natural range <>) of T_NET_IPV4_PROTOCOL;
	type		T_NET_IPV4_TYPE_OF_SERVICE_VECTOR			is array (natural range <>) of T_NET_IPV4_TYPE_OF_SERVICE;

	-- predefined constants
	constant C_NET_IPV4_ADDRESS_EMPTY							: T_NET_IPV4_ADDRESS				:= (others => (others => '0'));
	constant C_NET_IPV4_PROTOCOL_EMPTY						: T_NET_IPV4_PROTOCOL				:= (others => '0');

	constant C_NET_IPV4_TOS_PRECEDENCE_ROUTINE								: T_NET_IPV4_TOS_PRECEDENCE			:= "000";
	constant C_NET_IPV4_TOS_PRECEDENCE_PRIORITY								: T_NET_IPV4_TOS_PRECEDENCE			:= "001";
	constant C_NET_IPV4_TOS_PRECEDENCE_IMMEDIATE							: T_NET_IPV4_TOS_PRECEDENCE			:= "010";
	constant C_NET_IPV4_TOS_PRECEDENCE_FLASH									: T_NET_IPV4_TOS_PRECEDENCE			:= "011";
	constant C_NET_IPV4_TOS_PRECEDENCE_FLASH_OVERRIDE					: T_NET_IPV4_TOS_PRECEDENCE			:= "100";
	constant C_NET_IPV4_TOS_PRECEDENCE_CRITIC_ECP							: T_NET_IPV4_TOS_PRECEDENCE			:= "101";
	constant C_NET_IPV4_TOS_PRECEDENCE_INTERNETWORK_CONTROL		: T_NET_IPV4_TOS_PRECEDENCE			:= "110";
	constant C_NET_IPV4_TOS_PRECEDENCE_NETWORK_CONTROL				: T_NET_IPV4_TOS_PRECEDENCE			:= "111";

	constant C_NET_IPV4_TOS_DEFAULT								: T_NET_IPV4_TYPE_OF_SERVICE		:= (Precedence => C_NET_IPV4_TOS_PRECEDENCE_ROUTINE, Delay => '0', Throughput => '0', Relibility => '0');

	-- type conversion functions
	function to_net_ipv4_address(slv : T_SLV_32)				return T_NET_IPV4_ADDRESS;
	function to_net_ipv4_address(str : string)					return T_NET_IPV4_ADDRESS;
	function to_net_ipv4_TYPE_of_service(slv : T_SLV_8)	return T_NET_IPV4_TYPE_OF_SERVICE;

	function to_slv(ip : T_NET_IPV4_ADDRESS)						return std_logic_vector;
--	function to_slv(proto : T_NET_IPV4_PROTOCOL)				return STD_LOGIC_VECTOR;
	function to_slv(tos : T_NET_IPV4_TYPE_OF_SERVICE)		return std_logic_vector;

	function to_slvv_8(ip : T_NET_IPV4_ADDRESS)		return T_SLVV_8;

	function to_string(ip : T_NET_IPV4_ADDRESS)		return string;

	-- ==========================================================================================================================================================
	-- internet layer: Internet Protocol Version 6 (IPv6)
	-- ==========================================================================================================================================================
	-- types
	type		T_NET_IPV6_ADDRESS								is array (15 downto 0)				of T_SLV_8;
	type		T_NET_IPV6_PREFIX									is record
		Prefix				: T_NET_IPV6_ADDRESS;
		PrefixLength	: std_logic_vector(6 downto 0);
	end record;
	subtype T_NET_IPV6_NEXT_HEADER						is T_NET_IP_PROTOCOL;

	-- arrays
	type		T_NET_IPV6_ADDRESS_VECTOR					is array (natural range <>) of T_NET_IPV6_ADDRESS;
	type		T_NET_IPV6_PREFIX_VECTOR					is array (natural range <>) of T_NET_IPV6_PREFIX;
	type		T_NET_IPV6_NEXT_HEADER_VECTOR			is array (natural range <>) of T_NET_IPV6_NEXT_HEADER;

	-- predefined constants
	constant C_NET_IPV6_ADDRESS_EMPTY					: T_NET_IPV6_ADDRESS				:= (others => (others => '0'));
	constant C_NET_IPV6_NEXT_HEADER_EMPTY			: T_NET_IPV6_NEXT_HEADER		:= (others => '0');

	-- type conversion functions
	function to_net_ipv6_address(slv : T_SLV_128) 	return T_NET_IPV6_ADDRESS;
	function to_net_ipv6_address(str : string)			return T_NET_IPV6_ADDRESS;
	function to_net_ipv6_prefix(str : string)				return T_NET_IPV6_PREFIX;

	function to_slv(ip : T_NET_IPV6_ADDRESS)				return std_logic_vector;
	function to_slvv_8(ip : T_NET_IPV6_ADDRESS)			return T_SLVV_8;

	function to_string(IP : T_NET_IPV6_ADDRESS)			return string;
	function to_string(Prefix : T_NET_IPV6_PREFIX)	return string;

	-- ==========================================================================================================================================================
	-- internet layer: Address Resolution Protocol (ARP)
	-- ==========================================================================================================================================================

	-- commands
	type T_NET_ARP_ARPCACHE_COMMAND is (
		NET_ARP_ARPCACHE_CMD_NONE,
--		NET_ARP_ARPCACHE_CMD_CLEAR,
		NET_ARP_ARPCACHE_CMD_ADD
--		NET_ARP_ARPCACHE_CMD_INVALIDATE
	);

	-- status
	type T_NET_ARP_ARPCACHE_STATUS is (
		NET_ARP_ARPCACHE_STATUS_IDLE,
		NET_ARP_ARPCACHE_STATUS_UPDATING,
		NET_ARP_ARPCACHE_STATUS_UPDATE_COMPLETE
	);

	type T_NET_ARP_IPPOOL_COMMAND is (
		NET_ARP_IPPOOL_CMD_NONE,
		NET_ARP_IPPOOL_CMD_ADD,
		NET_ARP_IPPOOL_CMD_EDIT,
		NET_ARP_IPPOOL_CMD_REMOVE
	);

	type T_NET_ARP_ARPCACHE_LINE is record
		Tag				: T_NET_IPV4_ADDRESS;
		MAC				: T_NET_MAC_ADDRESS;
	end record;

	type T_NET_ARP_ARPCACHE_VECTOR		is array (natural range <>) of T_NET_ARP_ARPCACHE_LINE;

	-- commands
	type T_NET_ARP_TESTER_COMMAND is (
		NET_ARP_TESTER_CMD_NONE,
		NET_ARP_TESTER_CMD_LOOP
	);

	-- status
	type T_NET_ARP_TESTER_STATUS is (
		NET_ARP_TESTER_STATUS_IDLE,
		NET_ARP_TESTER_STATUS_TESTING,
		NET_ARP_TESTER_STATUS_TEST_COMPLETE
	);

	-- ==========================================================================================================================================================
	-- internet layer: Internet Control Message Protocol (ICMP)
	-- ==========================================================================================================================================================
	subtype T_NET_ICMPV4_TYPE						is T_SLV_8;
	subtype T_NET_ICMPV4_CODE						is T_SLV_8;

	-- commands
	type T_NET_ICMPV4_COMMAND is (
		NET_ICMPV4_CMD_NONE,
		NET_ICMPV4_CMD_ECHO_REQUEST
	);

	type T_NET_ICMPV4_TX_COMMAND is (
		NET_ICMPV4_TX_CMD_NONE,
		NET_ICMPV4_TX_CMD_ECHO_REQUEST,
		NET_ICMPV4_TX_CMD_ECHO_REPLY
	);

	type T_NET_ICMPV4_RX_COMMAND is (
		NET_ICMPV4_RX_CMD_NONE,
		NET_ICMPV4_RX_CMD_CLEAR
	);

	-- status
	type T_NET_ICMPV4_STATUS is (
		NET_ICMPV4_STATUS_IDLE,
		NET_ICMPV4_STATUS_SENDING,
		NET_ICMPV4_STATUS_SEND_COMPLETE,
		NET_ICMPV4_STATUS_ERROR
	);

	type T_NET_ICMPV4_TX_STATUS is (
		NET_ICMPV4_TX_STATUS_IDLE,
		NET_ICMPV4_TX_STATUS_SENDING,
		NET_ICMPV4_TX_STATUS_SEND_COMPLETE,
		NET_ICMPV4_TX_STATUS_ERROR
	);

	type T_NET_ICMPV4_RX_STATUS is (
		NET_ICMPV4_RX_STATUS_IDLE,
		NET_ICMPV4_RX_STATUS_RECEIVING,
		NET_ICMPV4_RX_STATUS_RECEIVED_ECHO_REQUEST,
		NET_ICMPV4_RX_STATUS_RECEIVED_ECHO_REPLY,
		NET_ICMPV4_RX_STATUS_ERROR
	);

	-- errors
	type T_NET_ICMPV4_ERROR is (
		NET_ICMPV4_ERROR_NONE,
		NET_ICMPV4_ERROR_TIMEOUT,
		NET_ICMPV4_ERROR_RECEIVED_CORRUPT_MESSAGE,
		NET_ICMPV4_ERROR_MESSAGE_NOT_SUPPORTED,
		NET_ICMPV4_ERROR_FSM
	);

	type T_NET_ICMPV4_TX_ERROR is (
		NET_ICMPV4_TX_ERROR_NONE,
		NET_ICMPV4_TX_ERROR_FSM
	);

	type T_NET_ICMPV4_RX_ERROR is (
		NET_ICMPV4_RX_ERROR_NONE,
		NET_ICMPV4_RX_ERROR_UNKNOWN_CODE,
		NET_ICMPV4_RX_ERROR_UNKNOWN_TYPE,
		NET_ICMPV4_RX_ERROR_CHECKSUM_ERROR,
		NET_ICMPV4_RX_ERROR_FSM
	);

	-- ==========================================================================================================================================================
	-- internet layer: Internet Control Message Protocol for IPv6 (ICMPv6)
	-- ==========================================================================================================================================================
	subtype T_NET_ICMPV6_TYPE						is T_SLV_8;
	subtype T_NET_ICMPV6_CODE						is T_SLV_8;

	-- ==========================================================================================================================================================
	-- internet layer: Neighbor Discovery Protocol (NDP)
	-- ==========================================================================================================================================================
	type T_NET_NDP_DESTINATIONCACHE_LINE is record
		Tag				: T_NET_IPV6_ADDRESS;
		NextHop		: T_NET_IPV6_ADDRESS;
	end record;

	type T_NET_NDP_NEIGHBORCACHE_LINE is record
		Tag				: T_NET_IPV6_ADDRESS;
		MAC				: T_NET_MAC_ADDRESS;
	end record;

	type T_NET_NDP_DESTINATIONCACHE_VECTOR	is array (natural range <>)	of T_NET_NDP_DESTINATIONCACHE_LINE;
	type T_NET_NDP_NEIGHBORCACHE_VECTOR			is array (natural range <>)	of T_NET_NDP_NEIGHBORCACHE_LINE;

	type T_NET_NDP_REACHABILITY_STATE is (
		NET_NDP_REACHABILITY_STATE_UNKNOWN,
		NET_NDP_REACHABILITY_STATE_INCOMPLETE,
		NET_NDP_REACHABILITY_STATE_REACHABLE,
		NET_NDP_REACHABILITY_STATE_STALE,
		NET_NDP_REACHABILITY_STATE_DELAY,
		NET_NDP_REACHABILITY_STATE_PROBE
	);

	-- ==========================================================================================================================================================
	-- transport layer: User Datagram Protocol (UDP)
	-- ==========================================================================================================================================================
	subtype T_NET_UDP_PORT								is T_SLV_16;


	type		T_NET_UDP_PORTPAIR is record
		Ingress			: T_NET_UDP_PORT;				-- incoming port number
		Egress			: T_NET_UDP_PORT;				-- outgoing port number
	end record;

	type		T_NET_UDP_PORTPAIR_VECTOR			is array(natural range <>) of T_NET_UDP_PORTPAIR;


	-- ==========================================================================================================================================================
	-- Ethernet: known Ethernet Types
	-- ==========================================================================================================================================================
	--	add user defined ethernet types here:
	constant C_NET_MAC_ETHERNETTYPE_SSFC						: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"A987");		-- Andreas Hoeer - SFC Protocol - simple version (length-field, type-field)
	constant C_NET_MAC_ETHERNETTYPE_SWAP						: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"FFFE");		-- Xilinx Ethernet Frame Swap Module
	constant C_NET_MAC_ETHERNETTYPE_LOOPBACK				: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"FFFF");		-- Frame loopback module

-- Ethernet Types, see:			http://en.wikipedia.org/wiki/EtherType
-- for complete liste see:	http://standards.ieee.org/develop/regauth/ethertype/eth.txt
-- see also:								http://www.iana.org/assignments/ieee-802-numbers/ieee-802-numbers.xml
	constant C_NET_MAC_ETHERNETTYPE_IPV4						: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"0800");		-- Internet Protocol, Version 4 (IPv4)
	constant C_NET_MAC_ETHERNETTYPE_ARP							: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"0806");		-- Address Resolution Protocol (ARP)
	constant C_NET_MAC_ETHERNETTYPE_WOL							: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"0842");		-- Wake-on-LAN Magic Packet, as used by ether-wake and Sleep Proxy Service
	constant C_NET_MAC_ETHERNETTYPE_VLAN						: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"8100");		-- VLAN-tagged frame (IEEE 802.1Q) & Shortest Path Bridging IEEE 802.1aq[3]
	constant C_NET_MAC_ETHERNETTYPE_SNMP						: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"814C");		-- Simple Network Management Protocol (SNMP)[4]
	constant C_NET_MAC_ETHERNETTYPE_IPV6						: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"86DD");		-- Internet Protocol, Version 6 (IPv6)
	constant C_NET_MAC_ETHERNETTYPE_MACCONTROL			: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"8808");		-- MAC Control
	constant C_NET_MAC_ETHERNETTYPE_JUMBOFRAMES			: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"8870");		-- Jumbo Frames
	constant C_NET_MAC_ETHERNETTYPE_QINQ						: T_NET_MAC_ETHERNETTYPE		:= to_net_mac_ethernettype(x"9100");		-- Q-in-Q

	-- ==========================================================================================================================================================
	-- Internet Layer: known Upper-Layer Protocols for Internet Protocol
	-- ==========================================================================================================================================================
	constant C_NET_IP_PROTOCOL_LOOPBACK							: T_NET_IP_PROTOCOL					:= x"FF";		-- 					(255) - IANA reserved (used for loopback)

	constant C_NET_IP_PROTOCOL_IPV4									: T_NET_IP_PROTOCOL					:= x"04";		-- 					(	 4) - IPv4 Header																	RFC 2003
	constant C_NET_IP_PROTOCOL_IPv6									: T_NET_IP_PROTOCOL					:= x"29";		-- 					(	41) - IPv6 Header - IPv6 Encapsulation						RFC 2473
	constant C_NET_IP_PROTOCOL_IPV6_HOP_BY_HOP			: T_NET_IP_PROTOCOL					:= x"00";		-- 					(	 0) - IPv6 Ext. Header - Hop-by-Hop Option				RFC 2460
	constant C_NET_IP_PROTOCOL_IPV6_ROUTING					: T_NET_IP_PROTOCOL					:= x"2B";		-- 					(	43) - IPv6 Ext. Header - Routing Header						RFC 2460
	constant C_NET_IP_PROTOCOL_IPV6_FRAGMENTATION		: T_NET_IP_PROTOCOL					:= x"2C";		-- 					(	44) - IPv6 Ext. Header - Fragmentation Header			RFC 2460
	constant C_NET_IP_PROTOCOL_IPV6_ICMP						: T_NET_IP_PROTOCOL					:= x"3A";		-- ICMPv6		(	58) - Internet Control Message Protocol for IPv6	RFC ----
	constant C_NET_IP_PROTOCOL_IPV6_NO_NEXT_HEADER	: T_NET_IP_PROTOCOL					:= x"3B";		-- 					(	59) - IPv6 Ext. Header - No Next Header						RFC 2460
	constant C_NET_IP_PROTOCOL_IPV6_DEST_OPTIONS		: T_NET_IP_PROTOCOL					:= x"3C";		-- 					(	60) - IPv6 Ext. Header - Destination Options			RFC 2460

	constant C_NET_IP_PROTOCOL_ICMP									: T_NET_IP_PROTOCOL					:= x"01";		-- ICMP			(	 1)	- Internet Control Message Protocol						RFC	 792
	constant C_NET_IP_PROTOCOL_IGMP									: T_NET_IP_PROTOCOL					:= x"02";		-- IGMP			(	 2)	- Internet Group Management Protocol					RFC	1112

	constant C_NET_IP_PROTOCOL_TCP									: T_NET_IP_PROTOCOL					:= x"06";		-- TCP			(	 6)	- Transmission Control Protocol								RFC	 793
	constant C_NET_IP_PROTOCOL_SCTP									: T_NET_IP_PROTOCOL					:= x"84";		-- SCTP 		(132) - Stream Control Transmission Protocol				RFC	----
	constant C_NET_IP_PROTOCOL_UDP									: T_NET_IP_PROTOCOL					:= x"11";		-- UDP			(	17)	- User Datagram Protocol											RFC	 768
	constant C_NET_IP_PROTOCOL_UDP_LITE							: T_NET_IP_PROTOCOL					:= x"88";		-- UDPLite	(136) - UDP Lite																		RFC	3828

	constant C_NET_IP_PROTOCOL_L2TP									: T_NET_IP_PROTOCOL					:= x"73";		-- L2TP			(115) - Layer Two Tunneling Protocol								RFC	3931

	-- ==========================================================================================================================================================
	-- Internet Layer: known Internet Control Message Protocol Types and Codes
	-- ==========================================================================================================================================================
	-- ICMPv4 Types
	constant C_NET_ICMPV4_TYPE_EMPTY										: T_NET_ICMPV4_TYPE	:= x"00";		-- empty type field
	constant C_NET_ICMPV4_TYPE_ECHO_REPLY								: T_NET_ICMPV4_TYPE	:= x"00";		-- Echo-Reply
	constant C_NET_ICMPV4_TYPE_DEST_UNREACHABLE					: T_NET_ICMPV4_TYPE	:= x"03";		-- Destination unreachable
	constant C_NET_ICMPV4_TYPE_SOURCE_QUENCH						: T_NET_ICMPV4_TYPE	:= x"04";		-- Source Quench
	constant C_NET_ICMPV4_TYPE_REDIRECT									: T_NET_ICMPV4_TYPE	:= x"05";		-- Redirect
	constant C_NET_ICMPV4_TYPE_ECHO_REQUEST							: T_NET_ICMPV4_TYPE	:= x"08";		-- Echo-Request
	constant C_NET_ICMPV4_TYPE_TIME_EXCEEDED						: T_NET_ICMPV4_TYPE	:= x"0B";		-- Time Exceeded
	constant C_NET_ICMPV4_TYPE_PARAMETER_PROBLEM				: T_NET_ICMPV4_TYPE	:= x"0C";		-- Parameter Problem

	-- ICMPv4 Codes
	constant C_NET_ICMPV4_CODE_EMPTY										: T_NET_ICMPV4_CODE	:= x"00";		-- empty code field

	-- ICMPv4 Codes for type Destination Unreachable
	constant C_NET_ICMPV4_CODE_NET_UNREACHABLE					: T_NET_ICMPV4_CODE	:= x"00";		-- Network unreachable
	constant C_NET_ICMPV4_CODE_HOST_UNREACHABLE					: T_NET_ICMPV4_CODE	:= x"01";		-- Host unreachable
	constant C_NET_ICMPV4_CODE_PROTOCOL_UNREACHABLE			: T_NET_ICMPV4_CODE	:= x"02";		-- Protocol unreachable
	constant C_NET_ICMPV4_CODE_PORT_UNREACHABLE					: T_NET_ICMPV4_CODE	:= x"03";		-- Port unreachable
	constant C_NET_ICMPV4_CODE_FRAGMENTATION_NEEDED			: T_NET_ICMPV4_CODE	:= x"04";		-- Fragmentation needed, but DF set
	constant C_NET_ICMPV4_CODE_SOURCE_ROUTE_FAILED			: T_NET_ICMPV4_CODE	:= x"05";		-- Source route failed

	-- ICMPv4 Codes for type Time Exceeded
	constant C_NET_ICMPV4_CODE_TIME_TO_LIVE_EXCEEDED		: T_NET_ICMPV4_CODE	:= x"00";		-- Hop limit exceeded in transit
	constant C_NET_ICMPV4_CODE_FRAG_REASS_TIME_EXCEEDED	: T_NET_ICMPV4_CODE	:= x"01";		-- Fragment reassembly time exceeded

	-- ICMPv4 Codes for type Echo Request
	constant C_NET_ICMPV4_CODE_ECHO_REQUEST							: T_NET_ICMPV4_CODE	:= x"00";		-- Echo Request

	-- ICMPv4 Codes for type Echo Reply
	constant C_NET_ICMPV4_CODE_ECHO_REPLY								: T_NET_ICMPV4_CODE	:= x"00";		-- Echo Reply


	-- ==========================================================================================================================================================
	-- Internet Layer: known Internet Control Message Protocol (for IPv6) Types and Codes
	-- ==========================================================================================================================================================
	-- ICMPv6 Types - Errors
	constant C_NET_ICMPV6_TYPE_DEST_UNREACHABLE				: T_NET_ICMPV6_TYPE	:= x"01";		-- Destination unreachable
	constant C_NET_ICMPV6_TYPE_PACKET_TOO_BIG					: T_NET_ICMPV6_TYPE	:= x"02";		-- Packet Too Big
	constant C_NET_ICMPV6_TYPE_TIME_EXCEEDED					: T_NET_ICMPV6_TYPE	:= x"03";		-- Time Exceeded
	constant C_NET_ICMPV6_TYPE_PARAMETER_PROBLEM			: T_NET_ICMPV6_TYPE	:= x"04";		-- Parameter Problem
	constant C_NET_ICMPV6_TYPE_ERROR_EXP							: T_NET_ICMPV6_TYPE	:= x"7F";		--
	-- ICMPv6 Types - Information
	constant C_NET_ICMPV6_TYPE_ECHO_REQUEST						: T_NET_ICMPV6_TYPE	:= x"80";		-- Echo Request
	constant C_NET_ICMPV6_TYPE_ECHO_REPLY							: T_NET_ICMPV6_TYPE	:= x"81";		-- Echo Reply
	constant C_NET_ICMPV6_TYPE_INFORMANTION_EXP				: T_NET_ICMPV6_TYPE	:= x"FF";		--

	-- ICMPv6 Codes
	constant C_NET_ICMPV6_CODE_EMPTY									: T_NET_ICMPV6_CODE	:= x"00";		-- empty code field

	-- ICMPv6 Codes for type Destination Unreachable
	constant C_NET_ICMPV6_CODE_NO_ROUTE_TO_DEST				: T_NET_ICMPV6_CODE	:= x"00";		-- No route to destination
	constant C_NET_ICMPV6_CODE_COM_PROHIBITED					: T_NET_ICMPV6_CODE	:= x"01";		-- Communication with destination administratively prohibited
	constant C_NET_ICMPV6_CODE_BEYOND_SCOPE						: T_NET_ICMPV6_CODE	:= x"02";		-- Beyond scope of source address
	constant C_NET_ICMPV6_CODE_ADDRESS_UNREACHABLE		: T_NET_ICMPV6_CODE	:= x"03";		-- Address unreachable
	constant C_NET_ICMPV6_CODE_PORT_UNREACHABLE				: T_NET_ICMPV6_CODE	:= x"04";		-- Port unreachable
	constant C_NET_ICMPV6_CODE_ADDRESS_FAILED_POLICY	: T_NET_ICMPV6_CODE	:= x"05";		-- Source address failed ingress/egress policy
	constant C_NET_ICMPV6_CODE_REJECT_ROUTE_TO_DEST		: T_NET_ICMPV6_CODE	:= x"06";		-- Reject route to destination

	-- ICMPv6 Codes for type Packet Too Big
	constant C_NET_ICMPV6_CODE_PACKET_TOO_BIG					: T_NET_ICMPV6_CODE	:= x"00";		-- Packet Too Big

	-- ICMPv6 Codes for type Time Exceeded
	constant C_NET_ICMPV6_CODE_HOP_LIMIT_EXCEEDED			: T_NET_ICMPV6_CODE	:= x"00";		-- Hop limit exceeded in transit
	constant C_NET_ICMPV6_CODE_REASS_TIME_EXCEEDED		: T_NET_ICMPV6_CODE	:= x"01";		-- Fragment reassembly time exceeded

	-- ICMPv6 Codes for type Parameter Problem
	constant C_NET_ICMPV6_CODE_HEADER_FIELD_ERROR			: T_NET_ICMPV6_CODE	:= x"00";		-- Erroneous header field encountered
	constant C_NET_ICMPV6_CODE_NEXT_HEADER_ERROR			: T_NET_ICMPV6_CODE	:= x"01";		-- Unrecognized Next Header type encountered
	constant C_NET_ICMPV6_CODE_IPV6_OPTION_ERROR			: T_NET_ICMPV6_CODE	:= x"02";		-- Unrecognized IPv6 option encountered

	-- ICMPv6 Codes for type Echo Request
	constant C_NET_ICMPV6_CODE_ECHO_REQUEST						: T_NET_ICMPV6_CODE	:= x"00";		-- Echo Request

	-- ICMPv6 Codes for type Echo Reply
	constant C_NET_ICMPV6_CODE_ECHO_REPLY							: T_NET_ICMPV6_CODE	:= x"00";		-- Echo Reply


	-- ==========================================================================================================================================================
	-- Transport Layer: known User Datagramm Protocol (UDP) Types, Ports and Codes
	-- ==========================================================================================================================================================
	subtype T_NET_TCP_PORT	is T_NET_UDP_PORT;		-- TODO: if TCP is added, move this to the TCP section in this file!

	constant C_NET_TCP_PORTNUMBER_ECHO								: T_NET_TCP_PORT		:= x"0007";		-- Echo Protocol (7) - RFC 862
	constant C_NET_TCP_PORTNUMBER_FTP_DATA						: T_NET_TCP_PORT		:= x"0014";		-- FTP Protocol (20) - RFC 765
	constant C_NET_TCP_PORTNUMBER_FTP_CONTROL					: T_NET_TCP_PORT		:= x"0015";		-- FTP Protocol (21) - RFC 765

	constant C_NET_TCP_PORTNUMBER_LOOPBACK						: T_NET_TCP_PORT		:= x"FFFF";

end package;


package body net is

	function to_net_eth_RSDataInterface(str : string) return T_NET_ETH_RS_DATA_INTERFACE is
	begin
		for i in T_NET_ETH_RS_DATA_INTERFACE'pos(T_NET_ETH_RS_DATA_INTERFACE'low) to T_NET_ETH_RS_DATA_INTERFACE'pos(T_NET_ETH_RS_DATA_INTERFACE'high) loop
			if str_match(str_toUpper(str), str_toUpper(T_NET_ETH_RS_DATA_INTERFACE'image(T_NET_ETH_RS_DATA_INTERFACE'val(i)))) then
				return T_NET_ETH_RS_DATA_INTERFACE'val(i);
			end if;
		end loop;
		report "Unknown RS_DATA_INTERFACE: " & str severity FAILURE;
	end function;

	function to_net_eth_PHYDataInterface(str : string) return T_NET_ETH_PHY_DATA_INTERFACE is
	begin
		for i in T_NET_ETH_PHY_DATA_INTERFACE'pos(T_NET_ETH_PHY_DATA_INTERFACE'low) to T_NET_ETH_PHY_DATA_INTERFACE'pos(T_NET_ETH_PHY_DATA_INTERFACE'high) loop
			if str_match(str_toUpper(str), str_toUpper(T_NET_ETH_PHY_DATA_INTERFACE'image(T_NET_ETH_PHY_DATA_INTERFACE'val(i)))) then
				return T_NET_ETH_PHY_DATA_INTERFACE'val(i);
			end if;
		end loop;
		report "Unknown PHY_DATA_INTERFACE: " & str severity FAILURE;
	end function;

	function to_net_eth_PHYManagementInterface(str : string) return T_NET_ETH_PHY_MANAGEMENT_INTERFACE is
	begin
		for i in T_NET_ETH_PHY_MANAGEMENT_INTERFACE'pos(T_NET_ETH_PHY_MANAGEMENT_INTERFACE'low) to T_NET_ETH_PHY_MANAGEMENT_INTERFACE'pos(T_NET_ETH_PHY_MANAGEMENT_INTERFACE'high) loop
			if str_match(str_toUpper(str), str_toUpper(T_NET_ETH_PHY_MANAGEMENT_INTERFACE'image(T_NET_ETH_PHY_MANAGEMENT_INTERFACE'val(i)))) then
				return T_NET_ETH_PHY_MANAGEMENT_INTERFACE'val(i);
			end if;
		end loop;
		report "Unknown PHY_MANAGEMENT_INTERFACE: " & str severity FAILURE;
	end function;

	function to_net_eth_PHYDevice(str : string) return T_NET_ETH_PHY_DEVICE is
	begin
		for i in T_NET_ETH_PHY_DEVICE'pos(T_NET_ETH_PHY_DEVICE'low) to T_NET_ETH_PHY_DEVICE'pos(T_NET_ETH_PHY_DEVICE'high) loop
			if str_match(str_toUpper(str), str_toUpper(T_NET_ETH_PHY_DEVICE'image(T_NET_ETH_PHY_DEVICE'val(i)))) then
				return T_NET_ETH_PHY_DEVICE'val(i);
			end if;
		end loop;
		report "Unknown PHY_DEVICE: " & str severity FAILURE;
	end function;


	function getPortCount(MACConfiguration : T_NET_MAC_CONFIGURATION_VECTOR) return positive is
		variable count : natural := 0;
	begin
		for i in MACConfiguration'range loop
			for j in MACConfiguration(i).TypeSwitch'range loop
				if (MACConfiguration(i).TypeSwitch(j) /= C_NET_MAC_ETHERNETTYPE_EMPTY) then
					count := count + 1;
				end if;
			end loop;
		end loop;

		return count;
	end function;

	-- ==========================================================================================================================================================
	-- Ethernet: MAC Data-Link-Layer
	-- ==========================================================================================================================================================
	function to_net_mac_address(slv : T_SLV_48) return T_NET_MAC_ADDRESS is
		variable mac					: T_NET_MAC_ADDRESS;
	begin
		for i in 0 to 5 loop
			mac(i)	:=	slv(((i * 8) + 7) downto (i * 8));
		end loop;
		return mac;
	end function;

	function to_net_mac_address(slvv : T_SLVV_8) return T_NET_MAC_ADDRESS is
		variable mac					: T_NET_MAC_ADDRESS;
	begin
		if (slvv'length /= 6) then report "to_net_mac_address: vector-length mismatch - slvv'length=" & integer'image(slvv'length) severity ERROR; end if;
		for i in slvv'range loop
			mac(i)	:=	slvv(i);
		end loop;
		return mac;
	end function;

	subtype MAC_ADDRESS_SEGMENT					is string(1 to 2);
	type		MAC_ADDRESS_SEGMENT_VECTOR	is array (natural range <>) of MAC_ADDRESS_SEGMENT;

	function mac_split(str : string) return MAC_ADDRESS_SEGMENT_VECTOR is
		variable input								: string(str'range)											:= str_toUpper(str);
		variable Segments							: MAC_ADDRESS_SEGMENT_VECTOR(0 to 5)		:= (others => (others => '0'));
		variable SegmentPointer				: natural																:= 0;
		variable CharPointer					: natural																:= 2;
	begin
--		report "mac_split of " & str severity NOTE;
		for i in str'reverse_range loop
--			report "  char=" & input(i) severity NOTE;
			if (to_digit(input(i), 'h') /= -1) then
				Segments(SegmentPointer)(CharPointer)	:= input(i);
--				report "    copy to seg=" & INTEGER'image(SegmentPointer) & "  pos=" & INTEGER'image(CharPointer) severity NOTE;
				CharPointer					:= CharPointer - 1;
			elsif ((input(i) = ':') or (input(i) = '-')) then
				SegmentPointer		:= SegmentPointer + 1;
				CharPointer				:= 2;
			else
				report "ERROR - unknown char [" & input(i) & "]" severity ERROR;
			end if;
		end loop;

		return Segments;
	end function;

	-- converts MAC address strings to T_NET_MAC_ADDRESS
	-- allowed delimiter signs: ':' or '-'
	function to_net_mac_address(str : string) return T_NET_MAC_ADDRESS is
		variable Segments				: MAC_ADDRESS_SEGMENT_VECTOR(0 to 5)	:= mac_split(str);
		variable MAC						: T_NET_MAC_ADDRESS;
	begin
		for i in Segments'range loop
			MAC(i)	:= to_slv(to_natural_hex(Segments(i)), 8);
		end loop;
		return MAC;
	end function;

	function to_net_mac_ethernettype(slv : T_SLV_16) return T_NET_MAC_ETHERNETTYPE is
		variable EthType					: T_NET_MAC_ETHERNETTYPE;
	begin
		for i in 0 to 1 loop
			EthType(i)	:=	slv(((i * 8) + 7) downto (i * 8));
		end loop;
		return EthType;
	end function;

	function to_slv(mac : T_NET_MAC_ADDRESS) return std_logic_vector is
		variable slv		: T_SLV_48;
	begin
		for i in 0 to 5 loop
			slv(((i * 8) + 7) downto (i * 8))		:= mac(i);
		end loop;
		return slv;
	end function;

	function to_slv(EthType : T_NET_MAC_ETHERNETTYPE) return std_logic_vector is
		variable slv		: T_SLV_16;
	begin
		for i in 0 to 1 loop
			slv(((i * 8) + 7) downto (i * 8))		:= EthType(i);
		end loop;
		return slv;
	end function;

	function to_slvv_8(mac : T_NET_MAC_ADDRESS) return T_SLVV_8 is
		variable slvv : T_SLVV_8(mac'range);
	begin
		for i in mac'range loop
			slvv(i)	:= mac(i);
		end loop;
		return slvv;
	end function;

	function to_slvv_8(EthType : T_NET_MAC_ETHERNETTYPE) return T_SLVV_8 is
		variable slvv : T_SLVV_8(EthType'range);
	begin
		for i in EthType'range loop
			slvv(i)	:= EthType(i);
		end loop;
		return slvv;
	end function;

	function to_string(mac : T_NET_MAC_ADDRESS) return string is
		variable str		: string(1 to 18)		:= (others => ':');
	begin
		for i in 0 to 5 loop
			str((i * 3) + 1 to (i * 3) + 2)	:= to_string(mac(5 - i), 'h');
		end loop;
		return str(1 to 17);
	end function;

	function to_string(EthType : T_NET_MAC_ETHERNETTYPE) return string is
	begin
		-- TODO: replace this case-statement by substring(image(EthType), 10,0)
		case to_slv(EthType) is
			when to_slv(C_NET_MAC_ETHERNETTYPE_EMPTY) =>				return "Empty";
			when to_slv(C_NET_MAC_ETHERNETTYPE_ARP) =>					return "ARP";
			when to_slv(C_NET_MAC_ETHERNETTYPE_IPV4) =>					return "IPv4";
			when to_slv(C_NET_MAC_ETHERNETTYPE_IPV6) =>					return "IPv6";
			when to_slv(C_NET_MAC_ETHERNETTYPE_JUMBOFRAMES) =>	return "Jumbo";
			when to_slv(C_NET_MAC_ETHERNETTYPE_MACCONTROL) =>		return "MACControl";
			when to_slv(C_NET_MAC_ETHERNETTYPE_QINQ) =>					return "QinQ";
			when to_slv(C_NET_MAC_ETHERNETTYPE_SNMP) =>					return "SNMP";
			when to_slv(C_NET_MAC_ETHERNETTYPE_VLAN) =>					return "VLAN";
			when to_slv(C_NET_MAC_ETHERNETTYPE_WOL) =>					return "WOL";

			when to_slv(C_NET_MAC_ETHERNETTYPE_SWAP) =>					return "Swap";
			when to_slv(C_NET_MAC_ETHERNETTYPE_LOOPBACK) =>			return "LoopBack";
			when others =>																			return "0x" & to_string(to_slv(EthType), 'h');
		end case;
	end function;

	-- ==========================================================================================================================================================
	-- internet layer: Internet Protocol Version 4 (IPv4)
	-- ==========================================================================================================================================================
	function to_net_ipv4_address(slv : T_SLV_32) return T_NET_IPV4_ADDRESS is
		variable ip					: T_NET_IPV4_ADDRESS;
	begin
		for i in 0 to 3 loop
			ip(i)	:=	slv(((i * 8) + 7) downto (i * 8));
		end loop;
		return ip;
	end function;

	subtype IPV4_ADDRESS_SEGMENT					is string(1 to 3);
	type		IPV4_ADDRESS_SEGMENT_VECTOR		is array (natural range <>) of IPV4_ADDRESS_SEGMENT;

	function ipv4_split(str : string) return IPV4_ADDRESS_SEGMENT_VECTOR is
		variable input								: string(str'range)											:= str_toUpper(str);
		variable Segments							: IPV4_ADDRESS_SEGMENT_VECTOR(0 to 3)		:= (others => (others => '0'));
		variable SegmentPointer				: natural																:= 0;
		variable CharPointer					: natural																:= 3;
	begin
--		report "ipv4_split of " & str severity NOTE;
		for i in str'reverse_range loop
--			report "  char=" & input(i) severity NOTE;
			if (to_digit(input(i), 'd') /= -1) then
				Segments(SegmentPointer)(CharPointer)	:= input(i);
--				report "    copy to seg=" & INTEGER'image(SegmentPointer) & "  pos=" & INTEGER'image(CharPointer) severity NOTE;
				CharPointer					:= CharPointer - 1;
			elsif (input(i) = '.') then
				SegmentPointer		:= SegmentPointer + 1;
				CharPointer				:= 3;
			else
				report "ERROR - unknown char" severity ERROR;
			end if;
		end loop;

		return Segments;
	end function;

	-- converts MAC address strings to T_NET_MAC_ADDRESS
	--	allowed delimiter sign: '.'
	function to_net_ipv4_address(str : string) return T_NET_IPV4_ADDRESS is
		variable Segments				: IPV4_ADDRESS_SEGMENT_VECTOR(0 to 3)	:= ipv4_split(str);
		variable Segment				: T_SLV_8;
		variable IP							: T_NET_IPV4_ADDRESS;
	begin
		for i in Segments'range loop
			IP(i) := to_slv(to_natural_dec(Segments(i)), 8);
		end loop;
		return IP;
	end function;

	function to_net_ipv4_TYPE_of_service(slv : T_SLV_8)	return T_NET_IPV4_TYPE_OF_SERVICE is
		variable tos			: T_NET_IPV4_TYPE_OF_SERVICE;
	begin
		tos.Precedence		:= slv(2 downto 0);
		tos.Delay					:= slv(3);
		tos.Throughput		:= slv(4);
		tos.Relibility		:= slv(5);
		return tos;
	end function;

	function to_slv(ip : T_NET_IPV4_ADDRESS) return std_logic_vector is
		variable slv						: T_SLV_32;
	begin
		for i in 0 to 3 loop
			slv(((i * 8) + 7) downto (i * 8))		:= ip(i);
		end loop;
		return slv;
	end function;
--
--	function to_slv(proto : T_NET_IPV4_PROTOCOL) return STD_LOGIC_VECTOR is
--		variable slv						: T_SLV_8;
--	begin
--		slv := proto;
--		return slv;
--	end function;

	function to_slv(tos : T_NET_IPV4_TYPE_OF_SERVICE)	return std_logic_vector is
		variable slv						: T_SLV_8;
	begin
		slv(2 downto 0)		:= tos.Precedence;
		slv(3)						:= tos.Delay;
		slv(4)						:= tos.Throughput;
		slv(5)						:= tos.Relibility;
		slv(7 downto 6)		:= "00";
		return slv;
	end function;

	function to_slvv_8(ip : T_NET_IPV4_ADDRESS) return T_SLVV_8 is
		variable slvv						: T_SLVV_8(ip'range);
	begin
		for i in ip'range loop
			slvv(i)	:= ip(i);
		end loop;
		return slvv;
	end function;

	function to_string(IP : T_NET_IPV4_ADDRESS) return string is
		variable temp						: string(1 to 16)			:= (others => '.');
		variable str						: string(1 to 3);
		variable len						: positive;
		variable CharPointer		: natural							:= 1;

	begin
--		report "converting IPv4 address" severity NOTE;
		for i in 3 downto 0 loop
--			report "  I=" & INTEGER'image(i) & "  IP(i)=" & INTEGER'image(to_integer(unsigned(IP(i)))) & "  CP=" & INTEGER'image(CharPointer) severity NOTE;

			str := resize(integer'image(to_integer(unsigned(IP(i)))), str'length);
			len	:= str_length(str);
			temp(CharPointer to CharPointer + len - 1)	:= str(1 to len);
			CharPointer := CharPointer + len + 1;
		end loop;

		return temp(1 to CharPointer - 2);
	end function;

	-- ==========================================================================================================================================================
	-- internet layer: Internet Protocol Version 6 (IPv6)
	-- ==========================================================================================================================================================
	function to_net_ipv6_address(slv : T_SLV_128) return T_NET_IPV6_ADDRESS is
		variable ip					: T_NET_IPV6_ADDRESS;
	begin
		for i in 0 to 15 loop
			ip(i)	:=	slv(((i * 8) + 7) downto (i * 8));
		end loop;

		return ip;
	end function;

	subtype IPV6_ADDRESS_SEGMENT					is string(1 to 4);
	type		IPV6_ADDRESS_SEGMENT_VECTOR		is array (natural range <>) of IPV6_ADDRESS_SEGMENT;

	function ipv6_split(str : string) return IPV6_ADDRESS_SEGMENT_VECTOR is
		variable input								: string(str'range)											:= str_toUpper(str);
		variable Segments							: IPV6_ADDRESS_SEGMENT_VECTOR(0 to 7)		:= (others => (others => '0'));
		variable DelimiterPointer			: natural																:= 0;
		variable SegmentPointer				: natural																:= 0;
		variable CharPointer					: natural																:= 4;
		variable RemainingDelimiters	: natural																:= 0;
	begin
--		report "ipv6_split of " & str severity NOTE;

		for i in str'reverse_range loop
--			report "  char=" & input(i) severity NOTE;
			if (to_digit(input(i), 'h') /= -1) then
				Segments(SegmentPointer)(CharPointer)	:= input(i);
--				report "    copy to seg=" & INTEGER'image(SegmentPointer) & "  pos=" & INTEGER'image(CharPointer) severity NOTE;
				CharPointer					:= CharPointer - 1;
				DelimiterPointer		:= 0;
			elsif (input(i) = ':') then
				if (DelimiterPointer = 0) then
					SegmentPointer		:= SegmentPointer + 1;
					CharPointer				:= 4;
					DelimiterPointer	:= i;
				else
					-- count remaining segments-delimiters
					for j in i - 1 downto input'low loop
						if (input(j) = ':') then
							RemainingDelimiters	:= RemainingDelimiters + 1;
						end if;
					end loop;
--					report "    lookahead rem-del=" & INTEGER'image(RemainingDelimiters) severity NOTE;
					SegmentPointer		:= 7 - RemainingDelimiters;
					CharPointer				:= 4;
					DelimiterPointer	:= 0;
				end if;
			else
				report "    ERROR - unknown char" severity ERROR;
			end if;
		end loop;

		return Segments;
	end function;

	function to_net_ipv6_address(str : string) return T_NET_IPV6_ADDRESS is
		variable Segments				: IPV6_ADDRESS_SEGMENT_VECTOR(0 to 7)	:= ipv6_split(str);
		variable Segment				: T_SLV_16;
		variable IP							: T_NET_IPV6_ADDRESS;
	begin
		for i in Segments'range loop
			Segment								:= to_slv(to_natural_hex(Segments(i)), 16);
			IP(i * 2)							:= Segment(7 downto 0);
			IP((i * 2) + 1)				:= Segment(15 downto 8);
		end loop;
		return IP;
	end function;

	function to_net_ipv6_prefix(str : string) return T_NET_IPV6_PREFIX is
		variable Pos						: positive;
		variable Prefix					: T_NET_IPV6_PREFIX;
		variable IPv6Address		: T_NET_IPV6_ADDRESS;
		variable Len						: natural;
	begin
		for i in str'reverse_range loop
			if (str(i) = '/') then
				Pos := i;
				exit;
			end if;
		end loop;

		if (Pos = str'high) then report "syntax error in IPv6 prefix: " & str severity ERROR;		end if;

		IPv6Address							:= to_net_ipv6_address(str(str'low to Pos - 1));
		Len											:= integer'value(str(Pos + 1 to str'high));

		if (not ((0 < Len) and (Len < 128))) then																								report "IPv6 prefix length is out of range: IPv6=" & str & " Length=" & integer'image(Len) severity ERROR;	end if;
		if ((to_slv(IPv6Address) and genmask_low(128 - Len, 128)) /= (127 downto 0 => '0')) then report "IPv6 prefix is longer then it's mask: IPv6=" & str severity ERROR;																	end if;

		Prefix.Prefix						:= IPv6Address;
		Prefix.PrefixLength			:= to_slv(Len, Prefix.PrefixLength'length);
		return Prefix;
	end function;

	function to_slv(ip : T_NET_IPV6_ADDRESS) return std_logic_vector is
		variable slv						: T_SLV_128;
	begin
		for i in 0 to 15 loop
			slv(((i * 8) + 7) downto (i * 8))		:= ip(i);
		end loop;
		return slv;
	end function;

	function to_slvv_8(ip : T_NET_IPV6_ADDRESS) return T_SLVV_8 is
		variable slvv						: T_SLVV_8(ip'range);
	begin
		for i in ip'range loop
			slvv(i)	:= ip(i);
		end loop;
		return slvv;
	end function;

	function to_string(IP : T_NET_IPV6_ADDRESS) return string is
		variable temp						: string(1 to 40)			:= (others => ':');
		variable CharPointer		: natural							:= 1;
		variable Char						: character;

		variable copy						: boolean							:= FALSE;
	begin
		for i in 7 downto 0 loop
			temp(CharPointer + 0 to CharPointer + 1)	:= to_string(IP((i * 2) + 1), 'h');
			temp(CharPointer + 2 to CharPointer + 3)	:= to_string(IP( i * 2), 'h');
			CharPointer																:= CharPointer + 5;
		end loop;

		-- compress string - remove leading zeros
--		report "compressing IPv6 address" severity NOTE;
		CharPointer			:= 1;
		for i in temp'range loop
--			report "  I=" & INTEGER'image(i) & "  char=" & temp(i) & "  CP=" & INTEGER'image(CharPointer) & "  copy=" & to_string(copy) severity NOTE;

			if (copy = FALSE) then
				if ((temp(i) = '0') and (temp(i + 1) /= ':')) then
					null;
				else
					temp(CharPointer)	:= temp(i);
					CharPointer				:= CharPointer + 1;
					copy							:= TRUE;
				end if;
			else
				if (temp(i) = ':') then
					copy							:= FALSE;
				end if;
				temp(CharPointer)		:= temp(i);
				CharPointer					:= CharPointer + 1;
			end if;
		end loop;

		return temp(1 to CharPointer - 2);
	end function;

	function to_string(Prefix : T_NET_IPV6_PREFIX)	return string is
	begin
		return to_string(Prefix.Prefix) & "/" & to_string(Prefix.PrefixLength, 'd');
	end function;
end package body;
