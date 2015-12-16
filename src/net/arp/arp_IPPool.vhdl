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
use			PoC.cache.all;
use			PoC.net.all;


entity arp_IPPool is
	generic (
		IPPOOL_SIZE										: POSITIVE;
		INITIAL_IPV4ADDRESSES					: T_NET_IPV4_ADDRESS_VECTOR			:= (0 to 7 => C_NET_IPV4_ADDRESS_EMPTY)
	);
	port (
		Clock													: in	STD_LOGIC;																	-- 
		Reset													: in	STD_LOGIC;																	-- 

--		Command												: in	T_ETHERNET_ARP_IPPOOL_COMMAND;
--		IPv4Address										: in	T_NET_IPV4_ADDRESS;
--		MACAddress										: in	T_ETHERNET_MAC_ADDRESS;
		
		Lookup												: in	STD_LOGIC;
		IPv4Address_rst								: out	STD_LOGIC;
		IPv4Address_nxt								: out	STD_LOGIC;
		IPv4Address_Data							: in	T_SLV_8;

		PoolResult										: out	T_CACHE_RESULT
	);
end entity;


architecture rtl of arp_IPPool is
	constant CACHE_LINES							: POSITIVE			:= imax(IPPOOL_SIZE, INITIAL_IPV4ADDRESSES'length);
	constant TAG_BITS									: POSITIVE			:= 32;
	constant TAGCHUNK_BITS						: POSITIVE			:= 8;
	
--	constant TAGCHUNKS										: POSITIVE	:= div_ceil(TAG_BITS, CHUNK_BITS);
--	constant CHUNK_INDEX_BITS					: POSITIVE	:= log2ceilnz(CHUNKS);
	constant CACHEMEMORY_INDEX_BITS		: POSITIVE	:= log2ceilnz(CACHE_LINES);
	
	function to_TagData(CacheContent : T_NET_IPV4_ADDRESS_VECTOR) return T_SLM is
		variable slvv		: T_SLVV_32(CACHE_LINES - 1 downto 0)	:= (others => (others => '0'));
	begin
		for i in CacheContent'range loop
			slvv(I)	:= to_slv(CacheContent(I));
		end loop;
		return to_slm(slvv);
	end function;
	
	constant INITIAL_TAGS						: T_SLM			:= to_TagData(INITIAL_IPV4ADDRESSES);
	
	signal ReadWrite								: STD_LOGIC;
	
	signal Insert										: STD_LOGIC;
	signal TU_NewTag_rst						: STD_LOGIC;
	signal TU_NewTag_nxt						: STD_LOGIC;
	signal NewTag_Data							: T_SLV_8;
	signal TU_Tag_rst								: STD_LOGIC;
	signal TU_Tag_nxt								: STD_LOGIC;
	signal TU_Tag_Data							: T_SLV_8;
	signal CacheHit									: STD_LOGIC;
	signal CacheMiss								: STD_LOGIC;
	
	signal TU_Index									: STD_LOGIC_VECTOR(CACHEMEMORY_INDEX_BITS - 1 downto 0);
	signal TU_Index_d								: STD_LOGIC_VECTOR(CACHEMEMORY_INDEX_BITS - 1 downto 0);
	signal TU_Index_us							: UNSIGNED(CACHEMEMORY_INDEX_BITS - 1 downto 0);
	signal TU_NewIndex							: STD_LOGIC_VECTOR(CACHEMEMORY_INDEX_BITS - 1 downto 0);
	signal TU_Replace								: STD_LOGIC;
	
	signal TU_TagHit								: STD_LOGIC;
	signal TU_TagMiss								: STD_LOGIC;
	
begin
--	process(Command)
--	begin
--		Insert		<= '0';
--		
--		case Command IS
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

	PoolResult					<= to_cache_result(CacheHit, CacheMiss);

	-- Cache TagUnit
--	TU : entity L_Global.Cache_TagUnit_seq
	TU : entity PoC.Cache_TagUnit_seq
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