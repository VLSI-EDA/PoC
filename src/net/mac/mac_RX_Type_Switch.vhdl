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


entity mac_RX_Type_Switch is
	generic (
		DEBUG													: boolean													:= FALSE;
		ETHERNET_TYPES								: T_NET_MAC_ETHERNETTYPE_VECTOR		:= (0 => C_NET_MAC_ETHERNETTYPE_EMPTY)
	);
	port (
		Clock													: in	std_logic;
		Reset													: in	std_logic;

		In_Valid											: in	std_logic;
		In_Data												: in	T_SLV_8;
		In_SOF												: in	std_logic;
		In_EOF												: in	std_logic;
		In_Ack												: out	std_logic;
		In_Meta_rst										: out	std_logic;
		In_Meta_SrcMACAddress_nxt			: out	std_logic;
		In_Meta_SrcMACAddress_Data		: in	T_SLV_8;
		In_Meta_DestMACAddress_nxt		: out	std_logic;
		In_Meta_DestMACAddress_Data		: in	T_SLV_8;

		Out_Valid											: out	std_logic_vector(ETHERNET_TYPES'length - 1 downto 0);
		Out_Data											: out	T_SLVV_8(ETHERNET_TYPES'length - 1 downto 0);
		Out_SOF												: out	std_logic_vector(ETHERNET_TYPES'length - 1 downto 0);
		Out_EOF												: out	std_logic_vector(ETHERNET_TYPES'length - 1 downto 0);
		Out_Ack												: in	std_logic_vector(ETHERNET_TYPES'length - 1 downto 0);
		Out_Meta_rst									: in	std_logic_vector(ETHERNET_TYPES'length - 1 downto 0);
		Out_Meta_SrcMACAddress_nxt		: in	std_logic_vector(ETHERNET_TYPES'length - 1 downto 0);
		Out_Meta_SrcMACAddress_Data		: out	T_SLVV_8(ETHERNET_TYPES'length - 1 downto 0);
		Out_Meta_DestMACAddress_nxt		: in	std_logic_vector(ETHERNET_TYPES'length - 1 downto 0);
		Out_Meta_DestMACAddress_Data	: out	T_SLVV_8(ETHERNET_TYPES'length - 1 downto 0);
		Out_Meta_EthType							: out	T_NET_MAC_ETHERNETTYPE_VECTOR(ETHERNET_TYPES'length - 1 downto 0)
	);
end entity;


architecture rtl of mac_RX_Type_Switch is
	attribute FSM_ENCODING					: string;

	constant PORTS									: positive																			:= ETHERNET_TYPES'length;
	constant ETHERNET_TYPES_I				: T_NET_MAC_ETHERNETTYPE_VECTOR(0 to PORTS - 1)	:= ETHERNET_TYPES;

	type T_STATE is (
		ST_IDLE,
			ST_TYPE_1,
			ST_PAYLOAD_1,
			ST_PAYLOAD_N,
		ST_DISCARD_FRAME
	);

	subtype T_ETHERNETTYPE_BYTEINDEX	 is natural range 0 to 1;

	signal State													: T_STATE																	:= ST_IDLE;
	signal NextState											: T_STATE;
	attribute FSM_ENCODING of State				: signal is ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal In_Ack_i												: std_logic;
	signal Is_DataFlow										: std_logic;
	signal Is_SOF													: std_logic;
	signal Is_EOF													: std_logic;

	signal New_Valid_i										: std_logic;
	signal New_SOF_i											: std_logic;
	signal Out_Ack_i											: std_logic;

	signal EthernetType_CompareIndex			: T_ETHERNETTYPE_BYTEINDEX;

	signal CompareRegister_rst						: std_logic;
	signal CompareRegister_init						: std_logic;
	signal CompareRegister_clear					: std_logic;
	signal CompareRegister_en							: std_logic;
	signal CompareRegister_d							: std_logic_vector(PORTS - 1 downto 0)		:= (others => '1');
	signal NoHits													: std_logic;

	signal EthernetType_rst								: std_logic;
	signal EthernetType_en								: std_logic;
	signal EthernetType_sel								: T_ETHERNETTYPE_BYTEINDEX;
	signal EthernetType_d									: T_NET_MAC_ETHERNETTYPE									:= C_NET_MAC_ETHERNETTYPE_EMPTY;

begin

	In_Ack				<= In_Ack_i;
	Is_DataFlow		<= In_Valid and In_Ack_i;
	Is_SOF				<= In_Valid and In_SOF;
	Is_EOF				<= In_Valid and In_EOF;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				State		<= ST_IDLE;
			else
				State		<= NextState;
			end if;
		end if;
	end process;

	process(State, Is_DataFlow, Is_SOF, Is_EOF, In_Valid, NoHits, Out_Ack_i)
	begin
		NextState												<= State;

		In_Ack_i												<= '0';

		New_Valid_i											<= '0';
		New_SOF_i												<= '0';

		CompareRegister_en							<= '0';
		CompareRegister_rst							<= '0';
		CompareRegister_init						<= Is_SOF;
		CompareRegister_clear						<= Is_EOF;

		EthernetType_CompareIndex				<= 1;
		EthernetType_rst								<= '0';
		EthernetType_en									<= '0';
		EthernetType_sel								<= 1;

		case State is
			when ST_IDLE =>
				EthernetType_rst						<= '1';
				EthernetType_en							<= '0';

				if (Is_SOF = '1') then
					EthernetType_rst					<= '0';
					EthernetType_en						<= '1';
					In_Ack_i									<= '1';

					if (Is_EOF = '0') then
						NextState								<= ST_TYPE_1;
					else
						NextState								<= ST_IDLE;
					end if;
				end if;

			when ST_TYPE_1 =>
				EthernetType_CompareIndex		<= 0;
				EthernetType_en							<= In_Valid;
				EthernetType_sel						<= 0;
				CompareRegister_en					<= In_Valid;

				if (In_Valid = '1') then
					In_Ack_i									<= '1';

					if (Is_EOF = '0') then
						NextState								<= ST_PAYLOAD_1;
					else
						NextState								<= ST_IDLE;
					end if;
				end if;

			when ST_PAYLOAD_1 =>
				if (NoHits = '1') then
					if (Is_EOF = '0') then
						In_Ack_i								<= '1';
						NextState								<= ST_DISCARD_FRAME;
					else
						NextState								<= ST_IDLE;
					end if;
				else
					In_Ack_i									<= Out_Ack_i;
					New_Valid_i								<= In_Valid;
					New_SOF_i									<= '1';

					if (Is_DataFlow = '1') then
						if (Is_EOF = '0') then
							NextState							<= ST_PAYLOAD_N;
						else
							NextState							<= ST_IDLE;
						end if;
					end if;
				end if;

			when ST_PAYLOAD_N =>
				In_Ack_i										<= Out_Ack_i;
				New_Valid_i									<= In_Valid;

				if ((Is_DataFlow and Is_EOF) = '1') then
					NextState									<= ST_IDLE;
				end if;

			when ST_DISCARD_FRAME =>
				In_Ack_i										<= '1';

				if ((Is_DataFlow and Is_EOF) = '1') then
					NextState									<= ST_IDLE;
				end if;

		end case;
	end process;


	gen0 : for i in 0 to PORTS - 1 generate
		signal Hit								: std_logic;
	begin
		Hit <= to_sl(In_Data = ETHERNET_TYPES_I(i)(EthernetType_CompareIndex));

		process(Clock)
		begin
			if rising_edge(Clock) then
				if ((Reset or CompareRegister_rst) = '1') then
					CompareRegister_d(i)				<= '0';
				elsif (CompareRegister_init	= '1') then
					CompareRegister_d(i)			<= Hit;
				elsif (CompareRegister_clear	= '1') then
					CompareRegister_d(i)			<= '0';
				elsif (CompareRegister_en  = '1') then
					CompareRegister_d(i)			<= CompareRegister_d(i) and Hit;
				end if;
			end if;
		end process;
	end generate;

	NoHits									<= slv_nor(CompareRegister_d);

--	process(Clock)
--	begin
--		if rising_edge(Clock) then
--			if ((Reset OR EthernetType_rst) = '1') then
--				EthernetType_d		<= C_NET_MAC_ETHERNETTYPE_EMPTY;
--			elsif (EthernetType_en = '1') then
--				EthernetType_d(EthernetType_sel) 	<= In_Data;
--			end if;
--		end if;
--	end process;

	Out_Valid											<= (Out_Valid'range => New_Valid_i) and CompareRegister_d;
	Out_Data											<= (Out_Data'range	=> In_Data);
	Out_SOF												<= (Out_SOF'range		=> New_SOF_i);
	Out_EOF												<= (Out_EOF'range		=> In_EOF);
	Out_Ack_i											<= slv_or(Out_Ack	 and CompareRegister_d);

	-- Meta: rst
	In_Meta_rst										<= slv_or(Out_Meta_rst and CompareRegister_d);

	-- Meta: DestMACAddress
	In_Meta_DestMACAddress_nxt		<= slv_or(Out_Meta_DestMACAddress_nxt and CompareRegister_d);
	Out_Meta_DestMACAddress_Data	<= (Out_Data'range	=> In_Meta_DestMACAddress_Data);

	-- Meta: SrcMACAddress
	In_Meta_SrcMACAddress_nxt			<= slv_or(Out_Meta_SrcMACAddress_nxt and CompareRegister_d);
	Out_Meta_SrcMACAddress_Data		<= (Out_Data'range	=> In_Meta_SrcMACAddress_Data);

	-- Meta: EthType
	genEthType : for i in ETHERNET_TYPES_I'range generate
		Out_Meta_EthType(i)					<= ETHERNET_TYPES_I(i);		--(Out_Data'range	=> EthernetType_d);			-- after exact match, the register value must be the same as in the array => use const arry values => better optimization
	end generate;

end architecture;
