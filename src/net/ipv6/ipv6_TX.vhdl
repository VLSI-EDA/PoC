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


entity ipv6_TX is
	generic (
		DEBUG														: boolean							:= FALSE
	);
	port (
		Clock														: in	std_logic;								--
		Reset														: in	std_logic;								--
		-- IN port
		In_Valid												: in	std_logic;
		In_Data													: in	T_SLV_8;
		In_SOF													: in	std_logic;
		In_EOF													: in	std_logic;
		In_Ack													: out	std_logic;
		In_Meta_rst											: out	std_logic;
		In_Meta_SrcIPv6Address_nxt			: out	std_logic;
		In_Meta_SrcIPv6Address_Data			: in	T_SLV_8;
		In_Meta_DestIPv6Address_nxt			: out	std_logic;
		In_Meta_DestIPv6Address_Data		: in	T_SLV_8;
		In_Meta_TrafficClass						: in	T_SLV_8;
		In_Meta_FlowLabel								: in	T_SLV_24;	--STD_LOGIC_VECTOR(19 downto 0);
		In_Meta_Length									: in	T_SLV_16;
		In_Meta_NextHeader							: in	T_SLV_8;
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
		-- OUT port
		Out_Valid												: out	std_logic;
		Out_Data												: out	T_SLV_8;
		Out_SOF													: out	std_logic;
		Out_EOF													: out	std_logic;
		Out_Ack													: in	std_logic;
		Out_Meta_rst										: in	std_logic;
		Out_Meta_DestMACAddress_nxt			: in	std_logic;
		Out_Meta_DestMACAddress_Data		: out	T_SLV_8
	);
end entity;


architecture rtl of ipv6_TX is
	attribute FSM_ENCODING						: string;

	type T_STATE is (
		ST_IDLE,
			ST_NDP_QUERY,								ST_NDP_QUERY_WAIT,
			ST_SEND_VERSION,
			ST_SEND_TRAFFIC_CLASS,
			ST_SEND_FLOW_LABEL_1,				ST_SEND_FLOW_LABEL_2,
			ST_SEND_In_Meta_Length_0,		ST_SEND_In_Meta_Length_1,
			ST_SEND_NEXT_HEADER,				ST_SEND_HOP_LIMIT,
			ST_SEND_SOURCE_ADDRESS,
			ST_SEND_DESTINATION_ADDRESS,
			ST_SEND_DATA,
		ST_DISCARD_FRAME,
		ST_ERROR
	);

	signal State											: T_STATE											:= ST_IDLE;
	signal NextState									: T_STATE;
	attribute FSM_ENCODING of State		: signal is ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal In_Ack_i										: std_logic;

	signal IPv6SeqCounter_rst					: std_logic;
	signal IPv6SeqCounter_en					: std_logic;
	signal IPv6SeqCounter_us					: unsigned(3 downto 0)				:= (others => '0');

begin

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
					Out_Ack, Out_Meta_rst, Out_Meta_DestMACAddress_nxt,--Out_Meta_DestMACAddress_rev,
					NDP_NextHop_Valid, NDP_NextHop_IPv6Address_rst, NDP_NextHop_IPv6Address_nxt, NDP_NextHop_MACAddress_Data,--NDP_NextHop_IPv6Address_rev,
					In_Meta_DestIPv6Address_Data, In_Meta_SrcIPv6Address_Data, In_Meta_TrafficClass, In_Meta_FlowLabel, In_Meta_NextHeader,
					IPv6SeqCounter_us)
	begin
		NextState													<= State;

		In_Ack_i												<= '0';

		Out_Valid													<= '0';
		Out_Data													<= (others => '0');
		Out_SOF														<= '0';
		Out_EOF														<= '0';

		In_Meta_rst												<= '0';

		NDP_NextHop_Query									<= '0';
		In_Meta_SrcIPv6Address_nxt				<= '0';
		In_Meta_DestIPv6Address_nxt				<= '0';
		NDP_NextHop_IPv6Address_Data			<= In_Meta_DestIPv6Address_Data;

		NDP_NextHop_MACAddress_rst				<= Out_Meta_rst;
		NDP_NextHop_MACAddress_nxt				<= Out_Meta_DestMACAddress_nxt;
		Out_Meta_DestMACAddress_Data			<= NDP_NextHop_MACAddress_Data;

		IPv6SeqCounter_rst								<= '0';
		IPv6SeqCounter_en									<= '0';

		case State is
			when ST_IDLE =>
				In_Meta_rst										<= NDP_NextHop_IPv6Address_rst;
				In_Meta_DestIPv6Address_nxt		<= NDP_NextHop_IPv6Address_nxt;

				if ((In_Valid and In_SOF) = '1') then
					NextState										<= ST_NDP_QUERY;
				end if;

			when ST_NDP_QUERY =>
				Out_Data											<= x"6" & In_Meta_TrafficClass(7 downto 4);
				Out_SOF												<= '1';

				In_Meta_rst											<= NDP_NextHop_IPv6Address_rst;
				In_Meta_DestIPv6Address_nxt		<= NDP_NextHop_IPv6Address_nxt;

				NDP_NextHop_Query							<= '1';

				if (NDP_NextHop_Valid = '1') then
					Out_Valid										<= '1';
					In_Meta_rst									<= '1';		-- reset metadata

					if (Out_Ack	 = '1') then
						NextState									<= ST_SEND_TRAFFIC_CLASS;
					else
						NextState									<= ST_SEND_VERSION;
					end if;
				else
					NextState										<= ST_NDP_QUERY_WAIT;
				end if;

			when ST_NDP_QUERY_WAIT =>
				Out_Valid											<= '0';
				Out_Data											<= x"6" & In_Meta_TrafficClass(7 downto 4);
				Out_SOF												<= '1';

				In_Meta_rst										<= NDP_NextHop_IPv6Address_rst;
				In_Meta_DestIPv6Address_nxt		<= NDP_NextHop_IPv6Address_nxt;

				if (NDP_NextHop_Valid = '1') then
					Out_Valid										<= '1';
					In_Meta_rst									<= '1';		-- reset metadata

					if (Out_Ack	 = '1') then
						NextState									<= ST_SEND_TRAFFIC_CLASS;
					else
						NextState									<= ST_SEND_VERSION;
					end if;
				end if;

			when ST_SEND_VERSION =>
				Out_Valid											<= '1';
				Out_Data											<= x"6" & In_Meta_TrafficClass(7 downto 4);
				Out_SOF												<= '1';

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_TRAFFIC_CLASS;
				end if;

			when ST_SEND_TRAFFIC_CLASS =>
				Out_Valid											<= '1';
				Out_Data											<= In_Meta_TrafficClass(3 downto 0) & In_Meta_FlowLabel(19 downto 16);

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_FLOW_LABEL_1;
				end if;

			when ST_SEND_FLOW_LABEL_1 =>
				Out_Valid											<= '1';
				Out_Data											<= In_Meta_FlowLabel(15 downto 8);

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_FLOW_LABEL_2;
				end if;

			when ST_SEND_FLOW_LABEL_2 =>
				Out_Valid											<= '1';
				Out_Data											<= In_Meta_FlowLabel(7 downto 0);

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_In_Meta_Length_0;
				end if;

			when ST_SEND_In_Meta_Length_0 =>
				Out_Valid											<= '1';
				Out_Data											<= In_Meta_Length(15 downto 8);

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_In_Meta_Length_1;
				end if;

			when ST_SEND_In_Meta_Length_1 =>
				Out_Valid											<= '1';
				Out_Data											<= In_Meta_Length(7 downto 0);

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_NEXT_HEADER;
				end if;

			when ST_SEND_NEXT_HEADER =>
				Out_Valid											<= '1';
				Out_Data											<= In_Meta_NextHeader;

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_HOP_LIMIT;
				end if;

			when ST_SEND_HOP_LIMIT =>
				Out_Valid											<= '1';
				Out_Data											<= x"02";		-- TODO: read from cache / routing info

				if (Out_Ack	 = '1') then
					NextState										<= ST_SEND_SOURCE_ADDRESS;
				end if;

			when ST_SEND_SOURCE_ADDRESS =>
				Out_Valid											<= '1';
				Out_Data											<= In_Meta_SrcIPv6Address_Data;

				if (Out_Ack	 = '1') then
					In_Meta_SrcIPv6Address_nxt			<= '1';
					IPv6SeqCounter_en						<= '1';

					if (IPv6SeqCounter_us = 15) then
						NextState									<= ST_SEND_DESTINATION_ADDRESS;
					end if;
				end if;

			when ST_SEND_DESTINATION_ADDRESS =>
				Out_Valid											<= '1';
				Out_Data											<= In_Meta_DestIPv6Address_Data;

				if (Out_Ack	 = '1') then
					In_Meta_DestIPv6Address_nxt	<= '1';
					IPv6SeqCounter_en						<= '1';

					if (IPv6SeqCounter_us = 15) then
						NextState									<= ST_SEND_DATA;
					end if;
				end if;

			when ST_SEND_DATA =>
				Out_Valid												<= In_Valid;
				Out_Data												<= In_Data;
				Out_EOF													<= In_EOF;
				In_Ack_i											<= Out_Ack;

				if ((In_EOF and Out_Ack) = '1') then
					In_Meta_rst										<= '1';
					NextState											<= ST_IDLE;
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
			if ((Reset or IPv6SeqCounter_rst) = '1') then
				IPv6SeqCounter_us			<= (others => '0');
			elsif (IPv6SeqCounter_en = '1') then
				IPv6SeqCounter_us			<= IPv6SeqCounter_us + 1;
			end if;
		end if;
	end process;

	In_Ack													<= In_Ack_i;

end architecture;
