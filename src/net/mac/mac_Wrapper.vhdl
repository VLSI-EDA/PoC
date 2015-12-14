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


entity mac_Wrapper is
	generic (
		DEBUG												: BOOLEAN															:= FALSE;
		MAC_CONFIG									: T_NET_MAC_CONFIGURATION_VECTOR
	);
	port (
		Clock												: in	STD_LOGIC;
		Reset												: in	STD_LOGIC;
		
		Eth_TX_Valid								: out	STD_LOGIC;
		Eth_TX_Data									: out	T_SLV_8;
		Eth_TX_SOF									: out	STD_LOGIC;
		Eth_TX_EOF									: out	STD_LOGIC;
		Eth_TX_Ack									: in	STD_LOGIC;
		
		Eth_RX_Valid								: in	STD_LOGIC;
		Eth_RX_Data									: in	T_SLV_8;
		Eth_RX_SOF									: in	STD_LOGIC;
		Eth_RX_EOF									: in	STD_LOGIC;
		Eth_RX_Ack									: out	STD_LOGIC;
		
		TX_Valid										: in	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		TX_Data											: in	T_SLVV_8(getPortCount(MAC_CONFIG) - 1 downto 0);
		TX_SOF											: in	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		TX_EOF											: in	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		TX_Ack											: out	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		Tx_Meta_rst									: out	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		TX_Meta_DestMACAddress_nxt	: out	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		TX_Meta_DestMACAddress_Data	: in	T_SLVV_8(getPortCount(MAC_CONFIG) - 1 downto 0);
		
		RX_Valid										: out	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		RX_Data											: out	T_SLVV_8(getPortCount(MAC_CONFIG) - 1 downto 0);
		RX_SOF											: out	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		RX_EOF											: out	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		RX_Ack											: in	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		RX_Meta_rst									: in	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		RX_Meta_SrcMACAddress_nxt		: in	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		RX_Meta_SrcMACAddress_Data	: out	T_SLVV_8(getPortCount(MAC_CONFIG) - 1 downto 0);
		RX_Meta_DestMACAddress_nxt	: in	STD_LOGIC_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0);
		RX_Meta_DestMACAddress_Data	: out	T_SLVV_8(getPortCount(MAC_CONFIG) - 1 downto 0);
		RX_Meta_EthType							: out	T_NET_MAC_ETHERNETTYPE_VECTOR(getPortCount(MAC_CONFIG) - 1 downto 0)
	);
end entity;


architecture rtl of mac_Wrapper is
	function getInterfaceAddresses(MAC_CONFIG : T_NET_MAC_CONFIGURATION_VECTOR) return T_NET_MAC_ADDRESS_VECTOR IS
		variable temp : T_NET_MAC_ADDRESS_VECTOR(MAC_CONFIG'range);
	begin
		for i in MAC_CONFIG'range loop
			temp(I) := MAC_CONFIG(I).Interface.Address;
		end loop;
	
		return temp;
	end function;

	function getInterfaceMasks(MAC_CONFIG : T_NET_MAC_CONFIGURATION_VECTOR) return T_NET_MAC_ADDRESS_VECTOR IS
		variable temp : T_NET_MAC_ADDRESS_VECTOR(MAC_CONFIG'range);
	begin
		for i in MAC_CONFIG'range loop
			temp(I) := MAC_CONFIG(I).Interface.Mask;
		end loop;
	
		return temp;
	end function;
	
	function getSourceFilterCount(Interfaces : T_NET_MAC_INTERFACE_VECTOR) return NATURAL IS
		variable count : NATURAL		:= 0;
	begin
		for i in Interfaces'range loop
			if ((Interfaces(I).Address /= C_NET_MAC_ADDRESS_EMPTY) OR (Interfaces(I).Mask /= C_NET_MAC_MASK_EMPTY)) then
				count := count + 1;
			end if;
		end loop;
	
		return count;
	end function;
	
	function getSourceFilterAddresses(Interfaces : T_NET_MAC_INTERFACE_VECTOR) return T_NET_MAC_ADDRESS_VECTOR IS
		variable temp : T_NET_MAC_ADDRESS_VECTOR(Interfaces'range);
	begin
		for i in Interfaces'range loop
			temp(I) := Interfaces(I).Address;
		end loop;
	
		return temp;
	end function;

	function getSourceFilterMasks(Interfaces : T_NET_MAC_INTERFACE_VECTOR) return T_NET_MAC_ADDRESS_VECTOR IS
		variable temp : T_NET_MAC_ADDRESS_VECTOR(Interfaces'range);
	begin
		for i in Interfaces'range loop
			temp(I) := Interfaces(I).Mask;
		end loop;
	
		return temp;
	end function;
	
	function getTypeSwitchCount(Types : T_NET_MAC_ETHERNETTYPE_VECTOR) return NATURAL IS
		variable count : NATURAL		:= 0;
	begin
		for i in Types'range loop
			if (Types(I) /= C_NET_MAC_ETHERNETTYPE_EMPTY) then
				count := count + 1;
			end if;
		end loop;
	
		return count;
	end function;
	
	function calcPortIndex(MAC_CONFIG : T_NET_MAC_CONFIGURATION_VECTOR; CurrentInterfaceID : NATURAL) return NATURAL IS
		variable count : NATURAL		:= 0;
	begin
		if (CurrentInterfaceID = 0) then
			return 0;
		end if;
	
		for i in 0 to CurrentInterfaceID - 1 loop
			count := count + getTypeSwitchCount(MAC_CONFIG(I).TypeSwitch);
		end loop;
		
		return count;
	end function;
	
	
	constant PORTS															: POSITIVE												:= getPortCount(MAC_CONFIG);
	constant INTERFACE_COUNT										: POSITIVE												:= MAC_CONFIG'length;
	constant INTERFACE_ADDRESSES								: T_NET_MAC_ADDRESS_VECTOR				:= getInterfaceAddresses(MAC_CONFIG);
	constant INTERFACE_MASKS										: T_NET_MAC_ADDRESS_VECTOR				:= getInterfaceMasks(MAC_CONFIG);
					
	signal DestEth_RX_Valid											: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);
	signal DestEth_RX_Data											: T_SLVV_8(INTERFACE_COUNT - 1 downto 0);
	signal DestEth_RX_SOF												: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);
	signal DestEth_RX_EOF												: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);
	signal DestEth_RX_Meta_DestMACAddress_Data	: T_SLVV_8(INTERFACE_COUNT - 1 downto 0);

	signal SrcEth_RX_Ack												: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);
	signal SrcEth_RX_Meta_rst										: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);
	signal SrcEth_RX_Meta_DestMACAddress_nxt		: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);

	signal EthType_TX_Valid											: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);
	signal EthType_TX_Data											: T_SLVV_8(INTERFACE_COUNT - 1 downto 0);
	signal EthType_TX_SOF												: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);
	signal EthType_TX_EOF												: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);
	signal EthType_TX_Meta_DestMACAddress_Data	: T_SLVV_8(INTERFACE_COUNT - 1 downto 0);
	
	signal SrcEth_TX_Valid											: STD_LOGIC;
	signal SrcEth_TX_Data												: T_SLV_8;
	signal SrcEth_TX_SOF												: STD_LOGIC;
	signal SrcEth_TX_EOF												: STD_LOGIC;
	signal SrcEth_TX_Ack												: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);
	signal SrcEth_TX_Meta_rst										: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);
	signal SrcEth_TX_Meta_DestMACAddress_nxt		: STD_LOGIC_VECTOR(INTERFACE_COUNT - 1 downto 0);
	signal SrcEth_TX_Meta_DestMACAddress_Data		: T_SLV_8;
							
	signal DestEth_TX_Ack												: STD_LOGIC;
	signal DestEth_TX_Meta_rst									: STD_LOGIC;
	signal DestEth_TX_Meta_DestMACAddress_nxt		: STD_LOGIC;
	
begin

	RX_DestMAC : entity PoC.mac_RX_DestMAC_Switch
		generic map (
			DEBUG								=> DEBUG,
			MAC_ADDRESSES									=> INTERFACE_ADDRESSES,
			MAC_ADDRESSE_MASKS						=> INTERFACE_MASKS
		)
		port map(
			Clock													=> Clock,
			Reset													=> Reset,
			
			In_Valid											=> Eth_RX_Valid,
			In_Data												=> Eth_RX_Data,
			In_SOF												=> Eth_RX_SOF,
			In_EOF												=> Eth_RX_EOF,
			In_Ack												=> Eth_RX_Ack,

			Out_Valid											=> DestEth_RX_Valid,
			Out_Data											=> DestEth_RX_Data,
			Out_SOF												=> DestEth_RX_SOF,
			Out_EOF												=> DestEth_RX_EOF,
			Out_Ack												=> SrcEth_RX_Ack,
			Out_Meta_DestMACAddress_rst		=> SrcEth_RX_Meta_rst,
			Out_Meta_DestMACAddress_nxt		=> SrcEth_RX_Meta_DestMACAddress_nxt,
			Out_Meta_DestMACAddress_Data	=> DestEth_RX_Meta_DestMACAddress_Data
		);

	genInterface : for i in MAC_CONFIG'range generate
		constant FILTER_COUNT										: NATURAL												:= getSourceFilterCount(MAC_CONFIG(I).SourceFilter);
		constant FILTER_ADDRESSES								: T_NET_MAC_ADDRESS_VECTOR			:= getSourceFilterAddresses(MAC_CONFIG(I).SourceFilter(0 to FILTER_COUNT - 1));
		constant FILTER_MASKS										: T_NET_MAC_ADDRESS_VECTOR			:= getSourceFilterMasks(MAC_CONFIG(I).SourceFilter(0 to FILTER_COUNT - 1));
		
		constant SWITCH_COUNT										: NATURAL												:= getTypeSwitchCount(MAC_CONFIG(I).TypeSwitch);
		constant SWITCH_TYPES										: T_NET_MAC_ETHERNETTYPE_VECTOR	:= MAC_CONFIG(I).TypeSwitch(0 to SWITCH_COUNT - 1);
		
		constant PORT_INDEX_FROM								: NATURAL												:= calcPortIndex(MAC_CONFIG, I);
		constant PORT_INDEX_TO									: NATURAL												:= PORT_INDEX_FROM + SWITCH_COUNT - 1;
		
		signal SrcEth_RX_Valid									: STD_LOGIC;
		signal SrcEth_RX_Data										: T_SLV_8;
		signal SrcEth_RX_SOF										: STD_LOGIC;
		signal SrcEth_RX_EOF										: STD_LOGIC;
		
--		signal SrcEth_RX_Meta_SrcMACAddress_rst			: STD_LOGIC;
--		signal SrcEth_RX_Meta_SrcMACAddress_nxt			: STD_LOGIC;
		signal SrcEth_RX_Meta_DestMACAddress_Data		: T_SLV_8;
		signal SrcEth_RX_Meta_SrcMACAddress_Data		: T_SLV_8;
		
		signal EthEth_RX_Ack												: STD_LOGIC;
		signal EthEth_RX_Meta_rst										: STD_LOGIC;
		signal EthEth_RX_Meta_DestMACAddress_nxt		: STD_LOGIC;
		signal EthEth_RX_Meta_SrcMACAddress_nxt			: STD_LOGIC;
		
	begin
--		assert FALSE report "Filter:      Count=" & INTEGER'image(FILTER_COUNT) severity NOTE;
--		assert FALSE report "PortIndex:   From="	& INTEGER'image(PORT_INDEX_FROM) & " to=" & INTEGER'image(PORT_INDEX_TO) severity NOTE;
	
		RX_SrcMAC : entity PoC.mac_RX_SrcMAC_Filter
			generic map (
				DEBUG								=> DEBUG,
				MAC_ADDRESSES									=> FILTER_ADDRESSES,
				MAC_ADDRESSE_MASKS						=> FILTER_MASKS
			)
			port map(
				Clock													=> Clock,
				Reset													=> Reset,
				
				In_Valid											=> DestEth_RX_Valid(I),
				In_Data												=> DestEth_RX_Data(I),
				In_SOF												=> DestEth_RX_SOF(I),
				In_EOF												=> DestEth_RX_EOF(I),
				In_Ack					 							=> SrcEth_RX_Ack	(I),
				In_Meta_rst										=> SrcEth_RX_Meta_rst(I),
				In_Meta_DestMACAddress_nxt		=> SrcEth_RX_Meta_DestMACAddress_nxt(I),
				In_Meta_DestMACAddress_Data		=> DestEth_RX_Meta_DestMACAddress_Data(I),

				Out_Valid											=> SrcEth_RX_Valid,
				Out_Data											=> SrcEth_RX_Data,
				Out_SOF												=> SrcEth_RX_SOF,
				Out_EOF												=> SrcEth_RX_EOF,
				Out_Ack												=> EthEth_RX_Ack,
				Out_Meta_rst									=> EthEth_RX_Meta_rst,
				Out_Meta_DestMACAddress_nxt		=> EthEth_RX_Meta_DestMACAddress_nxt,
				Out_Meta_DestMACAddress_Data	=> SrcEth_RX_Meta_DestMACAddress_Data,
				Out_Meta_SrcMACAddress_nxt		=> EthEth_RX_Meta_SrcMACAddress_nxt,
				Out_Meta_SrcMACAddress_Data		=> SrcEth_RX_Meta_SrcMACAddress_Data
			);

		RX_EthType : entity PoC.mac_RX_Type_Switch
			generic map (
				DEBUG								=> DEBUG,
				ETHERNET_TYPES								=> SWITCH_TYPES
			)
			port map(
				Clock													=> Clock,
				Reset													=> Reset,
				
				In_Valid											=> SrcEth_RX_Valid,
				In_Data												=> SrcEth_RX_Data,
				In_SOF												=> SrcEth_RX_SOF,
				In_EOF												=> SrcEth_RX_EOF,
				In_Ack												=> EthEth_RX_Ack,
				In_Meta_rst										=> EthEth_RX_Meta_rst,
				In_Meta_DestMACAddress_nxt		=> EthEth_RX_Meta_DestMACAddress_nxt,
				In_Meta_DestMACAddress_Data		=> SrcEth_RX_Meta_DestMACAddress_Data,
				In_Meta_SrcMACAddress_nxt			=> EthEth_RX_Meta_SrcMACAddress_nxt,
				In_Meta_SrcMACAddress_Data		=> SrcEth_RX_Meta_SrcMACAddress_Data,

				Out_Valid											=> RX_Valid(PORT_INDEX_TO downto PORT_INDEX_FROM),
				Out_Data											=> RX_Data(PORT_INDEX_TO downto PORT_INDEX_FROM),
				Out_SOF												=> RX_SOF(PORT_INDEX_TO downto PORT_INDEX_FROM),
				Out_EOF												=> RX_EOF(PORT_INDEX_TO downto PORT_INDEX_FROM),
				Out_Ack												=> RX_Ack	(PORT_INDEX_TO downto PORT_INDEX_FROM),
				Out_Meta_rst									=> RX_Meta_rst(PORT_INDEX_TO downto PORT_INDEX_FROM),
				Out_Meta_DestMACAddress_nxt		=> RX_Meta_DestMACAddress_nxt(PORT_INDEX_TO downto PORT_INDEX_FROM),
				Out_Meta_DestMACAddress_Data	=> RX_Meta_DestMACAddress_Data(PORT_INDEX_TO downto PORT_INDEX_FROM),
				Out_Meta_SrcMACAddress_nxt		=> RX_Meta_SrcMACAddress_nxt(PORT_INDEX_TO downto PORT_INDEX_FROM),
				Out_Meta_SrcMACAddress_Data		=> RX_Meta_SrcMACAddress_Data(PORT_INDEX_TO downto PORT_INDEX_FROM),
				Out_Meta_EthType							=> RX_Meta_EthType(PORT_INDEX_TO downto PORT_INDEX_FROM)
			);

		-- Ethernet Type prepender
		TX_EthType : entity PoC.mac_TX_Type_Prepender
			generic map (
				ETHERNET_TYPES								=> SWITCH_TYPES
			)
			port map(
				Clock													=> Clock,
				Reset													=> Reset,
				
				In_Valid											=> TX_Valid(PORT_INDEX_TO downto PORT_INDEX_FROM),
				In_Data												=> TX_Data(PORT_INDEX_TO downto PORT_INDEX_FROM),
				In_SOF												=> TX_SOF(PORT_INDEX_TO downto PORT_INDEX_FROM),
				In_EOF												=> TX_EOF(PORT_INDEX_TO downto PORT_INDEX_FROM),
				In_Ack												=> TX_Ack	(PORT_INDEX_TO downto PORT_INDEX_FROM),
				In_Meta_rst										=> TX_Meta_rst(PORT_INDEX_TO downto PORT_INDEX_FROM),
				In_Meta_DestMACAddress_nxt		=> TX_Meta_DestMACAddress_nxt(PORT_INDEX_TO downto PORT_INDEX_FROM),
				In_Meta_DestMACAddress_Data		=> TX_Meta_DestMACAddress_Data(PORT_INDEX_TO downto PORT_INDEX_FROM),
				
				Out_Valid											=> EthType_TX_Valid(I),
				Out_Data											=> EthType_TX_Data(I),
				Out_SOF												=> EthType_TX_SOF(I),
				Out_EOF												=> EthType_TX_EOF(I),
				Out_Ack												=> SrcEth_TX_Ack	(I),
				Out_Meta_rst									=> SrcEth_TX_Meta_rst(I),
				Out_Meta_DestMACAddress_nxt		=> SrcEth_TX_Meta_DestMACAddress_nxt(I),
				Out_Meta_DestMACAddress_Data	=> EthType_TX_Meta_DestMACAddress_Data(I)
			);
	end generate;

	-- Ethernet SourceMAC prepender
	TX_SrcMAC : entity PoC.mac_TX_SrcMAC_Prepender
		generic map (
			MAC_ADDRESSES									=> INTERFACE_ADDRESSES
		)
		port map(
			Clock													=> Clock,
			Reset													=> Reset,
			
			In_Valid											=> EthType_TX_Valid,
			In_Data												=> EthType_TX_Data,
			In_SOF												=> EthType_TX_SOF,
			In_EOF												=> EthType_TX_EOF,
			In_Ack												=> SrcEth_TX_Ack,
			In_Meta_rst										=> SrcEth_TX_Meta_rst,
			In_Meta_DestMACAddress_nxt		=> SrcEth_TX_Meta_DestMACAddress_nxt,
			In_Meta_DestMACAddress_Data		=> EthType_TX_Meta_DestMACAddress_Data,
			
			Out_Valid											=> SrcEth_TX_Valid,
			Out_Data											=> SrcEth_TX_Data,
			Out_SOF												=> SrcEth_TX_SOF,
			Out_EOF												=> SrcEth_TX_EOF,
			Out_Ack												=> DestEth_TX_Ack,
			Out_Meta_rst									=> DestEth_TX_Meta_rst,
			Out_Meta_DestMACAddress_nxt		=> DestEth_TX_Meta_DestMACAddress_nxt,
			Out_Meta_DestMACAddress_Data	=> SrcEth_TX_Meta_DestMACAddress_Data
		);

	-- Ethernet SourceMAC prepender
	TX_DestMAC : entity PoC.mac_TX_DestMAC_Prepender
		port map(
			Clock													=> Clock,
			Reset													=> Reset,
			
			In_Valid											=> SrcEth_TX_Valid,
			In_Data												=> SrcEth_TX_Data,
			In_SOF												=> SrcEth_TX_SOF,
			In_EOF												=> SrcEth_TX_EOF,
			In_Ack												=> DestEth_TX_Ack,

			In_Meta_rst										=> DestEth_TX_Meta_rst,
			In_Meta_DestMACAddress_nxt		=> DestEth_TX_Meta_DestMACAddress_nxt,
			In_Meta_DestMACAddress_Data		=> SrcEth_TX_Meta_DestMACAddress_Data,
			
			Out_Valid											=> Eth_TX_Valid,
			Out_Data											=> Eth_TX_Data,
			Out_SOF												=> Eth_TX_SOF,
			Out_EOF												=> Eth_TX_EOF,
			Out_Ack												=> Eth_TX_Ack	
		);

end architecture;
