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
use			PoC.cache.all;
use			PoC.net.all;


entity arp_IPPool is
	generic (
		IPPOOL_SIZE										: positive;
		INITIAL_IPV4ADDRESSES					: T_NET_IPV4_ADDRESS_VECTOR			:= (0 to 7 => C_NET_IPV4_ADDRESS_EMPTY)
	);
	port (
		Clock													: in	std_logic;																	--
		Reset													: in	std_logic;																	--

--		Command												: in	T_ETHERNET_ARP_IPPOOL_COMMAND;
--		IPv4Address										: in	T_NET_IPV4_ADDRESS;
--		MACAddress										: in	T_ETHERNET_MAC_ADDRESS;

		Lookup												: in	std_logic;
		IPv4Address_rst								: out	std_logic;
		IPv4Address_nxt								: out	std_logic;
		IPv4Address_Data							: in	T_SLV_8;

		PoolResult										: out	T_CACHE_RESULT
	);
end entity;


architecture rtl of arp_IPPool is
	constant CACHE_LINES							: positive			:= imax(IPPOOL_SIZE, INITIAL_IPV4ADDRESSES'length);
	constant TAG_BITS									: positive			:= 32;
	constant TAGCHUNK_BITS						: positive			:= 8;

--	constant TAGCHUNKS										: POSITIVE	:= div_ceil(TAG_BITS, CHUNK_BITS);
--	constant CHUNK_INDEX_BITS					: POSITIVE	:= log2ceilnz(CHUNKS);
	constant CACHEMEMORY_INDEX_BITS		: positive	:= log2ceilnz(CACHE_LINES);

	function to_TagData(CacheContent : T_NET_IPV4_ADDRESS_VECTOR) return T_SLM is
		variable slvv		: T_SLVV_32(CACHE_LINES - 1 downto 0)	:= (others => (others => '0'));
	begin
		for i in CacheContent'range loop
			slvv(i)	:= to_slv(CacheContent(i));
		end loop;
		return to_slm(slvv);
	end function;

	constant INITIAL_TAGS						: T_SLM			:= to_TagData(INITIAL_IPV4ADDRESSES);

	signal ReadWrite								: std_logic;

	signal Insert										: std_logic;
	signal TU_NewTag_rst						: std_logic;
	signal TU_NewTag_nxt						: std_logic;
	signal NewTag_Data							: T_SLV_8;
	signal TU_Tag_rst								: std_logic;
	signal TU_Tag_nxt								: std_logic;
	signal TU_Tag_Data							: T_SLV_8;
	signal CacheHit									: std_logic;
	signal CacheMiss								: std_logic;

	signal TU_Index									: std_logic_vector(CACHEMEMORY_INDEX_BITS - 1 downto 0);
	signal TU_Index_d								: std_logic_vector(CACHEMEMORY_INDEX_BITS - 1 downto 0);
	signal TU_Index_us							: unsigned(CACHEMEMORY_INDEX_BITS - 1 downto 0);
	signal TU_NewIndex							: std_logic_vector(CACHEMEMORY_INDEX_BITS - 1 downto 0);
	signal TU_Replace								: std_logic;

	signal TU_TagHit								: std_logic;
	signal TU_TagMiss								: std_logic;

begin
--	process(Command)
--	begin
--		Insert		<= '0';
--
--		case Command is
--			when NET_NDP_NeighborCache_CMD_NONE =>		null;
--			when NET_NDP_NeighborCache_CMD_ADD =>		Insert <= '1';
--
--		end case;
--	end process;

	-- FIXME: add correct assignment
	Insert							<= '0';

	ReadWrite						<= '0';
	NewTag_Data					<= (others => '0');

	TU_Tag_Data					<= IPv4Address_Data;
	IPv4Address_rst			<= TU_Tag_rst;
	IPv4Address_nxt			<= TU_Tag_nxt;

	PoolResult					<= to_Cache_Result(CacheHit, CacheMiss);

	-- Cache TagUnit
--	TU : entity PoC.Cache_TagUnit_seq
	TU : entity PoC.cache_TagUnit_seq
		generic map (
			REPLACEMENT_POLICY				=> "LRU",
			CACHE_LINES								=> CACHE_LINES,
			ASSOCIATIVITY							=> CACHE_LINES,
			TAG_BITS									=> TAG_BITS,
			CHUNK_BITS								=> TAGCHUNK_BITS,
			TAG_BYTE_ORDER						=> BIG_ENDIAN,
			INITIAL_TAGS							=> INITIAL_TAGS
		)
		port map (
			Clock											=> Clock,
			Reset											=> Reset,

			Replace										=> Insert,
			Replace_NewTag_rst				=> TU_NewTag_rst,
			Replace_NewTag_nxt				=> TU_NewTag_nxt,
			Replace_NewTag_Data				=> NewTag_Data,
			Replace_NewIndex					=> TU_NewIndex,
			Replaced									=> TU_Replace,

			Request										=> Lookup,
			Request_ReadWrite					=> '0',
			Request_Invalidate				=> '0',--Invalidate,
			Request_Tag_rst						=> TU_Tag_rst,
			Request_Tag_nxt						=> TU_Tag_nxt,
			Request_Tag_Data					=> TU_Tag_Data,
			Request_Index							=> open,--TU_Index,
			Request_TagHit						=> TU_TagHit,
			Request_TagMiss						=> TU_TagMiss
		);

	-- latch TU_Index on TagHit
--	TU_Index_us		<= unsigned(TU_Index) when rising_edge(Clock) AND (TU_TagHit = '1');

	CacheHit			<= TU_TagHit;
	CacheMiss			<= TU_TagMiss;
end architecture;
