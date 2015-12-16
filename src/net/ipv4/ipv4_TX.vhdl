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


entity ipv4_TX is
	generic (
		DEBUG														: BOOLEAN							:= FALSE
	);
	port (
		Clock														: in	STD_LOGIC;									-- 
		Reset														: in	STD_LOGIC;									-- 
		-- IN port
		In_Valid												: in	STD_LOGIC;
		In_Data													: in	T_SLV_8;
		In_SOF													: in	STD_LOGIC;
		In_EOF													: in	STD_LOGIC;
		In_Ack													: out	STD_LOGIC;
		In_Meta_rst											: out	STD_LOGIC;
		In_Meta_SrcIPv4Address_nxt			: out	STD_LOGIC;
		In_Meta_SrcIPv4Address_Data			: in	T_SLV_8;
		In_Meta_DestIPv4Address_nxt			: out	STD_LOGIC;
		In_Meta_DestIPv4Address_Data		: in	T_SLV_8;
		In_Meta_Length									: in	T_SLV_16;
		In_Meta_Protocol								: in	T_SLV_8;
		-- ARP port
		ARP_IPCache_Query								: out	STD_LOGIC;
		ARP_IPCache_IPv4Address_rst			: in	STD_LOGIC;
		ARP_IPCache_IPv4Address_nxt			: in	STD_LOGIC;
		ARP_IPCache_IPv4Address_Data		: out	T_SLV_8;
		ARP_IPCache_Valid								: in	STD_LOGIC;
		ARP_IPCache_MACAddress_rst			: out	STD_LOGIC;
		ARP_IPCache_MACAddress_nxt			: out	STD_LOGIC;
		ARP_IPCache_MACAddress_Data			: in	T_SLV_8;
		-- OUT port
		Out_Valid												: out	STD_LOGIC;
		Out_Data												: out	T_SLV_8;
		Out_SOF													: out	STD_LOGIC;
		Out_EOF													: out	STD_LOGIC;
		Out_Ack													: in	STD_LOGIC;
		Out_Meta_rst										: in	STD_LOGIC;
		Out_Meta_DestMACAddress_nxt			: in	STD_LOGIC;
		Out_Meta_DestMACAddress_Data		: out	T_SLV_8
	);
end entity;


architecture rtl of ipv4_TX is
	attribute FSM_ENCODING						: STRING;
	
	type T_STATE is (
		ST_IDLE,
			ST_ARP_QUERY,									ST_ARP_QUERY_WAIT,
			ST_CHECKSUM_IPV4_ADDRESSES,
				ST_CHECKSUM_IPVERSION_LENGTH_0,							ST_CHECKSUM_TYPE_OF_SERVICE_LENGTH_1,
				ST_CHECKSUM_IDENTIFICAION_FRAGMENTOFFSET_0,	ST_CHECKSUM_IDENTIFICAION_FRAGMENTOFFSET_1,
				ST_CHECKSUM_TIME_TO_LIVE,				ST_CHECKSUM_PROTOCOL,
			ST_CARRY_0, ST_CARRY_1,
			ST_SEND_VERSION,							ST_SEND_TYPE_OF_SERVICE,	ST_SEND_TOTAL_LENGTH_0,			ST_SEND_TOTAL_LENGTH_1,
			ST_SEND_IDENTIFICATION_0,			ST_SEND_IDENTIFICATION_1,	ST_SEND_FLAGS,							ST_SEND_FRAGMENT_OFFSET,
			ST_SEND_TIME_TO_LIVE,					ST_SEND_PROTOCOL,					ST_SEND_HEADER_CHECKSUM_0,	ST_SEND_HEADER_CHECKSUM_1,
			ST_SEND_SOURCE_ADDRESS,
			ST_SEND_DESTINATION_ADDRESS,
--			ST_SEND_OPTIONS_0,						ST_SEND_OPTIONS_1,				ST_SEND_OPTIONS_2,					ST_SEND_PADDING,
			ST_SEND_DATA,
		ST_DISCARD_FRAME,
		ST_ERROR
	);

	signal State											: T_STATE											:= ST_IDLE;
	signal NextState									: T_STATE;
	attribute FSM_ENCODING of State		: signal IS ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal In_Ack_i										: STD_LOGIC;

	signal UpperLayerPacketLength			: STD_LOGIC_VECTOR(15 downto 0);

	signal InternetHeaderLength				: T_SLV_4;
	signal TypeOfService							: T_NET_IPV4_TYPE_OF_SERVICE;
	signal TotalLength								: T_SLV_16;
	signal Identification							: T_SLV_16;
	signal Flag_DontFragment					: STD_LOGIC;
	signal Flag_MoreFragments					: STD_LOGIC;
	signal FragmentOffset							: STD_LOGIC_VECTOR(12 downto 0);
	signal TimeToLive									: T_SLV_8;
	signal Protocol										: T_SLV_8;
	signal HeaderChecksum							: T_SLV_16;

	signal IPv4SeqCounter_rst					: STD_LOGIC;
	signal IPv4SeqCounter_en					: STD_LOGIC;
	signal IPv4SeqCounter_us					: UNSIGNED(1 downto 0)				:= (others => '0');

	signal Checksum_rst								: STD_LOGIC;
	signal Checksum_en								: STD_LOGIC;
	signal Checksum_Addend0_us				: UNSIGNED(T_SLV_8'range);
	signal Checksum_Addend1_us				: UNSIGNED(T_SLV_8'range);
	signal Checksum0_nxt0_us					: UNSIGNED(T_SLV_8'high + 1 downto 0);
	signal Checksum0_nxt1_us					: UNSIGNED(T_SLV_8'high + 1 downto 0);
	signal Checksum0_d_us							: UNSIGNED(T_SLV_8'high downto 0)												:= (others => '0');
	signal Checksum0_cy								: UNSIGNED(T_SLV_2'range);
	signal Checksum1_nxt_us						: UNSIGNED(T_SLV_8'range);
	signal Checksum1_d_us							: UNSIGNED(T_SLV_8'range)																:= (others => '0');
	signal Checksum0_cy0							: STD_LOGIC;
	signal Checksum0_cy0_d						: STD_LOGIC																							:= '0';
	signal Checksum0_cy1							: STD_LOGIC;
	signal Checksum0_cy1_d						: STD_LOGIC																							:= '0';

	signal Checksum_i									: T_SLV_16;
	signal Checksum										: T_SLV_16;
	signal Checksum_mux_rst						: STD_LOGIC;
	signal Checksum_mux_set						: STD_LOGIC;
	signal Checksum_mux_r							: STD_LOGIC																							:= '0';

begin

	UpperLayerPacketLength	<= std_logic_vector(unsigned(In_Meta_Length) + 20);

	InternetHeaderLength		<= x"5";											-- standard IPv4 header length withou option fields (20 bytes -> 5 * 32-words)
	TypeOfService						<= C_NET_IPV4_TOS_DEFAULT;		-- Type of Service: routine, normal delay, normal throughput, normal relibility
	TotalLength							<= UpperLayerPacketLength;
	Identification					<= x"0000";
	Flag_DontFragment				<= '0';
	Flag_MoreFragments			<= '0';
	FragmentOffset					<= (others => '0');
	TimeToLive							<= x"40";											-- TTL = 64; see RFC 791
	Protocol								<= In_Meta_Protocol;
	
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				State			<= ST_IDLE;
			else
				State			<= NextState;
			end if;
		end if;
	end process;

	process(State, In_Valid, In_SOF, In_EOF, In_Data,
					In_Meta_Length,
					Out_Ack, Out_Meta_rst, Out_Meta_DestMACAddress_nxt,
					ARP_IPCache_Valid, ARP_IPCache_IPv4Address_rst, ARP_IPCache_IPv4Address_nxt, ARP_IPCache_MACAddress_Data,
					In_Meta_DestIPv4Address_Data, In_Meta_SrcIPv4Address_Data, In_Meta_Protocol,
					InternetHeaderLength, UpperLayerPacketLength, TypeOfService, Flag_DontFragment, Flag_MoreFragments,
					Identification, FragmentOffset, TimeToLive, Protocol,
					IPv4SeqCounter_us, Checksum0_cy, Checksum)
	begin
		NextState													<= State;
		
		In_Ack_i													<= '0';
		
		Out_Valid													<= '0';
		Out_Data													<= (others => '0');
		Out_SOF														<= '0';
		Out_EOF														<= '0';

		In_Meta_rst												<= '0';

		ARP_IPCache_Query									<= '0';
		In_Meta_SrcIPv4Address_nxt				<= '0';
		In_Meta_DestIPv4Address_nxt				<= '0';
		ARP_IPCache_IPv4Address_Data			<= In_Meta_DestIPv4Address_Data;
		
		ARP_IPCache_MACAddress_rst				<= Out_Meta_rst;
		ARP_IPCache_MACAddress_nxt				<= Out_Meta_DestMACAddress_nxt;
		Out_Meta_DestMACAddress_Data			<= ARP_IPCache_MACAddress_Data;

		IPv4SeqCounter_rst								<= '0';
		IPv4SeqCounter_en									<= '0';

		Checksum_rst											<= '0';
		Checksum_en												<= '0';
		Checksum_Addend0_us								<= (others => '0');
		Checksum_Addend1_us								<= (others => '0');
		Checksum_mux_rst									<= '0';
		Checksum_mux_set									<= '0';

		case State is
			when ST_IDLE =>
				In_Meta_rst										<= ARP_IPCache_IPv4Address_rst;
				In_Meta_DestIPv4Address_nxt		<= ARP_IPCache_IPv4Address_nxt;
				
				IPv4SeqCounter_rst						<= '1';
				Checksum_rst									<= '1';
				
				if ((In_Valid AND In_SOF) = '1') then
					NextState										<= ST_ARP_QUERY;
				end if;
			
			when ST_ARP_QUERY =>
				Out_Data											<= x"4" & InternetHeaderLength;
				Out_SOF												<= '1';

				In_Meta_rst										<= ARP_IPCache_IPv4Address_rst;
				In_Meta_DestIPv4Address_nxt		<= ARP_IPCache_IPv4Address_nxt;

				ARP_IPCache_Query							<= '1';
				
				if (ARP_IPCache_Valid = '1') then
					Out_Valid										<= '1';
					In_Meta_rst									<= '1';		-- reset metadata
					
--					if (Out_Ack	 = '1') then
--						NextState									<= ST_SEND_TYPE_OF_SERVICE;
--					else
--						NextState									<= ST_SEND_VERSION;
--					end if;
					NextState										<= ST_CHECKSUM_IPV4_ADDRESSES;
				else
					NextState										<= ST_ARP_QUERY_WAIT;
				end if;
			
			when ST_ARP_QUERY_WAIT =>
				Out_Valid											<= '0';
				Out_Data											<= x"4" & InternetHeaderLength;
				Out_SOF												<= '1';
			
				In_Meta_rst										<= ARP_IPCache_IPv4Address_rst;
				In_Meta_DestIPv4Address_nxt		<= ARP_IPCache_IPv4Address_nxt;
			
				if (ARP_IPCache_Valid = '1') then
					Out_Valid										<= '1';
					In_Meta_rst									<= '1';		-- reset metadata
					
--					if (Out_Ack	 = '1') then
--						NextState									<= ST_SEND_TYPE_OF_SERVICE;
--					else
--						NextState									<= ST_SEND_VERSION;
--					end if;
					NextState										<= ST_CHECKSUM_IPV4_ADDRESSES;
				end if;
			
			-- calculate checksum for IPv4 header
			-- ----------------------------------------------------------------------
			when ST_CHECKSUM_IPV4_ADDRESSES =>
				In_Meta_SrcIPv4Address_nxt		<= '1';
				In_Meta_DestIPv4Address_nxt		<= '1';
				
				IPv4SeqCounter_en							<= '1';
				Checksum_en										<= '1';
				Checksum_Addend0_us						<= unsigned(In_Meta_SrcIPv4Address_Data);
				Checksum_Addend1_us						<= unsigned(In_Meta_DestIPv4Address_Data);
				
				if (IPv4SeqCounter_us = 3) then
					NextState										<= ST_CHECKSUM_IPVERSION_LENGTH_0;
				end if;
			
			when ST_CHECKSUM_IPVERSION_LENGTH_0 =>
				Checksum_en										<= '1';
				Checksum_Addend0_us						<= unsigned(UpperLayerPacketLength(15 downto 8));
				Checksum_Addend1_us						<= unsigned(std_logic_vector'(x"4" & InternetHeaderLength));
				
				NextState											<= ST_CHECKSUM_TYPE_OF_SERVICE_LENGTH_1;

			when ST_CHECKSUM_TYPE_OF_SERVICE_LENGTH_1 =>
				Checksum_en										<= '1';
				Checksum_Addend0_us						<= unsigned(UpperLayerPacketLength(7 downto 0));
				Checksum_Addend1_us						<= unsigned(to_slv(TypeOfService));
			
				NextState											<= ST_CHECKSUM_IDENTIFICAION_FRAGMENTOFFSET_0;

			when ST_CHECKSUM_IDENTIFICAION_FRAGMENTOFFSET_0 =>
				Checksum_en										<= '1';
				Checksum_Addend0_us						<= unsigned(Identification(15 downto 8));
				Checksum_Addend1_us						<= unsigned(std_logic_vector'('0' & Flag_DontFragment & Flag_MoreFragments & FragmentOffset(12 downto 8)));
			
				NextState											<= ST_CHECKSUM_IDENTIFICAION_FRAGMENTOFFSET_1;

			when ST_CHECKSUM_IDENTIFICAION_FRAGMENTOFFSET_1 =>
				Checksum_en										<= '1';
				Checksum_Addend0_us						<= unsigned(Identification(7 downto 0));
				Checksum_Addend1_us						<= unsigned(FragmentOffset(7 downto 0));
				
				NextState											<= ST_CHECKSUM_TIME_TO_LIVE;
			
			when ST_CHECKSUM_TIME_TO_LIVE =>
				Checksum_en										<= '1';
				Checksum_Addend0_us						<= unsigned(TimeToLive);
				Checksum_Addend1_us						<= (others => '0');	--unsigned(In_Meta_Checksum(15 downto 8));
				
				NextState											<= ST_CHECKSUM_PROTOCOL;

			when ST_CHECKSUM_PROTOCOL =>
				Checksum_en										<= '1';
				Checksum_Addend0_us						<= unsigned(Protocol);
				Checksum_Addend1_us						<= (others => '0');	--unsigned(In_Meta_Checksum(7 downto 0));
			
				if (Checksum0_cy = "00") then
					NextState										<= ST_SEND_VERSION;
				else
					NextState										<= ST_CARRY_0;
				end if;
				
			-- circulate carry bit
			-- ----------------------------------------------------------------------
			when ST_CARRY_0 =>
				In_Meta_rst										<= Out_Meta_rst;
				
				Checksum_en										<= '1';
				Checksum_mux_set							<= '1';
				
				if (Checksum0_cy = "00") then
					NextState										<= ST_SEND_VERSION;
				else
					NextState										<= ST_CARRY_1;
				end if;
			
			when ST_CARRY_1 =>
				In_Meta_rst										<= Out_Meta_rst;
			
				Checksum_en										<= '1';
				Checksum_mux_rst							<= '1';
				
				NextState											<= ST_SEND_VERSION;
				
			-- assamble header
			-- ----------------------------------------------------------------------
			when ST_SEND_VERSION =>
				Out_Valid											<= '1';
				Out_Data											<= x"4" & InternetHeaderLength;
				Out_SOF												<= '1';

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_TYPE_OF_SERVICE;
				end if;
			
			when ST_SEND_TYPE_OF_SERVICE =>
				Out_Valid											<= '1';
				Out_Data											<= to_slv(TypeOfService);
				
				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_TOTAL_LENGTH_0;
				end if;

			when ST_SEND_TOTAL_LENGTH_0 =>
				Out_Valid											<= '1';
				Out_Data											<= std_logic_vector(TotalLength(15 downto 8));
				
				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_TOTAL_LENGTH_1;
				end if;
				
			when ST_SEND_TOTAL_LENGTH_1 =>
				Out_Valid											<= '1';
				Out_Data											<= std_logic_vector(TotalLength(7 downto 0));
				
				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_IDENTIFICATION_0;
				end if;
				
			when ST_SEND_IDENTIFICATION_0 =>
				Out_Valid											<= '1';
				Out_Data											<= Identification(15 downto 8);
				
				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_IDENTIFICATION_1;
				end if;
				
			when ST_SEND_IDENTIFICATION_1 =>
				Out_Valid											<= '1';
				Out_Data											<= Identification(7 downto 0);
				
				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_FLAGS;
				end if;
				
			when ST_SEND_FLAGS =>
				Out_Valid											<= '1';
				Out_Data(7)										<= '0';
				Out_Data(6)										<= Flag_DontFragment;
				Out_Data(5)										<= Flag_MoreFragments;
				Out_Data(4 downto 0)					<= FragmentOffset(12 downto 8);
				
				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_FRAGMENT_OFFSET;
				end if;
			
			when ST_SEND_FRAGMENT_OFFSET =>
				Out_Valid											<= '1';
				Out_Data											<= FragmentOffset(7 downto 0);
				
				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_TIME_TO_LIVE;
				end if;
				
			when ST_SEND_TIME_TO_LIVE =>
				Out_Valid											<= '1';
				Out_Data											<= TimeToLive;
				
				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_PROTOCOL;
				end if;
				
			when ST_SEND_PROTOCOL =>
				Out_Valid											<= '1';
				Out_Data											<= Protocol;
				
				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_HEADER_CHECKSUM_0;
				end if;
				
			when ST_SEND_HEADER_CHECKSUM_0 =>
				Out_Valid											<= '1';
				Out_Data											<= Checksum(15 downto 8);
				
				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_HEADER_CHECKSUM_1;
				end if;

			when ST_SEND_HEADER_CHECKSUM_1 =>
				Out_Valid											<= '1';
				Out_Data											<= Checksum(7 downto 0);
				
				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_SOURCE_ADDRESS;
				end if;
			
			when ST_SEND_SOURCE_ADDRESS =>
				Out_Valid											<= '1';
				Out_Data											<= In_Meta_SrcIPv4Address_Data;
				
				if (Out_Ack	 = '1') then
					In_Meta_SrcIPv4Address_nxt	<= '1';
					IPv4SeqCounter_en						<= '1';
				
					if (IPv4SeqCounter_us = 3) then
						NextState									<= ST_SEND_DESTINATION_ADDRESS;
					end if;
				end if;
			
			when ST_SEND_DESTINATION_ADDRESS =>
				Out_Valid											<= '1';
				Out_Data											<= In_Meta_DestIPv4Address_Data;
				
				if (Out_Ack	 = '1') then
					In_Meta_DestIPv4Address_nxt	<= '1';
					IPv4SeqCounter_en						<= '1';
				
					if (IPv4SeqCounter_us = 3) then
						NextState									<= ST_SEND_DATA;
					end if;
				end if;
			
			when ST_SEND_DATA =>
				Out_Valid											<= In_Valid;
				Out_Data											<= In_Data;
				Out_EOF												<= In_EOF;
				In_Ack_i											<= Out_Ack;
				
				if ((In_EOF AND Out_Ack) = '1') then
					In_Meta_rst									<= '1';
					NextState										<= ST_IDLE;
				end if;
			
			when ST_DISCARD_FRAME =>
				null;
			
			when ST_ERROR =>
				null;
				
		end case;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset OR IPv4SeqCounter_rst) = '1') then
				IPv4SeqCounter_us		<= (others => '0');
			elsif (IPv4SeqCounter_en = '1') then
				IPv4SeqCounter_us		<= IPv4SeqCounter_us + 1;
			end if;
		end if;
	end process;

Checksum0_nxt0_us		<= ("0" & Checksum1_d_us)
													+ ("0" & Checksum_Addend0_us)
													+ ((Checksum_Addend0_us'range => '0') & Checksum0_cy0_d);
	Checksum0_nxt1_us		<= ("0" & Checksum0_nxt0_us(Checksum0_nxt0_us'high - 1 downto 0))
													+ ("0" & Checksum_Addend1_us)
													+ ((Checksum_Addend1_us'range => '0') & Checksum0_cy1_d);
	Checksum1_nxt_us		<= Checksum0_d_us(Checksum1_d_us'range);
	
	Checksum0_cy0				<= Checksum0_nxt0_us(Checksum0_nxt0_us'high);
	Checksum0_cy1				<= Checksum0_nxt1_us(Checksum0_nxt1_us'high);
	Checksum0_cy				<= Checksum0_cy1 & Checksum0_cy0;

					
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Checksum_rst = '1') then
				Checksum0_d_us		<= (others => '0');
				Checksum1_d_us		<= (others => '0');
			elsif (Checksum_en = '1') then
				Checksum0_d_us		<= Checksum0_nxt1_us(Checksum0_nxt1_us'high - 1 downto 0);
				Checksum1_d_us		<= Checksum1_nxt_us;
					
				Checksum0_cy0_d		<= Checksum0_cy0;
				Checksum0_cy1_d		<= Checksum0_cy1;
			end if;
		end if;
	end process;

	Checksum_i		<= not (std_logic_vector(Checksum0_nxt1_us(Checksum0_nxt1_us'high - 1 downto 0)) & std_logic_vector(Checksum1_nxt_us));
	Checksum			<= ite((Checksum_mux_r = '0'), Checksum_i, swap(Checksum_i, 8));

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset OR Checksum_mux_rst) = '1') then
				Checksum_mux_r		<= '0';
			elsif (Checksum_mux_set = '1') then
				Checksum_mux_r		<= '1';
			end if;
		end if;
	end process;

	In_Ack													<= In_Ack_i;
	
end architecture;
