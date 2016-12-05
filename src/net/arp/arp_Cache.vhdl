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


entity arp_Cache is
	generic (
		CLOCK_FREQ								: FREQ																	:= 125 MHz;
		REPLACEMENT_POLICY				: string																:= "LRU";
		TAG_BYTE_ORDER						: T_BYTE_ORDER													:= BIG_ENDIAN;
		DATA_BYTE_ORDER						: T_BYTE_ORDER													:= BIG_ENDIAN;
		INITIAL_CACHE_CONTENT			: T_NET_ARP_ARPCACHE_VECTOR
	);
	port (
		Clock											: in	std_logic;																	--
		Reset											: in	std_logic;																	--

		Command										: in	T_NET_ARP_ARPCACHE_COMMAND;
		Status										: out	T_NET_ARP_ARPCACHE_STATUS;
		NewIPv4Address_rst				: out	std_logic;
		NewIPv4Address_nxt				: out	std_logic;
		NewIPv4Address_Data				: in	T_SLV_8;
		NewMACAddress_rst					: out	std_logic;
		NewMACAddress_nxt					: out	std_logic;
		NewMACAddress_Data				: in	T_SLV_8;

		Lookup										: in	std_logic;
		IPv4Address_rst						: out	std_logic;
		IPv4Address_nxt						: out	std_logic;
		IPv4Address_Data					: in	T_SLV_8;

		CacheResult								: out	T_CACHE_RESULT;
		MACAddress_rst						: in	std_logic;
		MACAddress_nxt						: in	std_logic;
		MACAddress_Data						: out	T_SLV_8
	);
end entity;


architecture rtl of arp_Cache is
	constant CACHE_LINES							: positive	:= 8;
	constant TAG_BITS									: positive	:= 32;		-- IPv4 address
	constant DATA_BITS								:	positive	:= 48;		-- MAC address
	constant TAGCHUNK_BITS						: positive	:= 8;
	constant DATACHUNK_BITS						: positive	:= 8;

	constant DATACHUNKS								: positive	:= div_ceil(DATA_BITS, DATACHUNK_BITS);
	constant DATACHUNK_INDEX_BITS			: positive	:= log2ceilnz(DATACHUNKS);
	constant CACHEMEMORY_INDEX_BITS		: positive	:= log2ceilnz(CACHE_LINES);

	function to_TagData(CacheContent : T_NET_ARP_ARPCACHE_VECTOR) return T_SLM is
--		variable slvv		: T_SLVV_32(CACHE_LINES - 1 downto 0)	:= (others => (others => '0'));
		variable slvv		: T_SLVV_32(CacheContent'high downto CacheContent'low)	:= (others => (others => '0'));
	begin
		for i in CacheContent'range loop
			slvv(i)	:= to_slv(CacheContent(i).Tag);
		end loop;
		return to_slm(slvv);
	end function;

	function to_CacheData_slvv_48(CacheContent : T_NET_ARP_ARPCACHE_VECTOR) return T_SLVV_48 is
		variable slvv		: T_SLVV_48(CACHE_LINES - 1 downto 0)	:= (others => (others => '0'));
	begin
		for i in CacheContent'range loop
			slvv(i)	:= to_slv(CacheContent(i).MAC);
		end loop;
		return slvv;
	end function;

	function to_CacheMemory(CacheContent : T_NET_ARP_ARPCACHE_VECTOR) return T_SLVV_8 is
		constant BYTES_PER_LINE	: positive																				:= 6;
		constant slvv						: T_SLVV_48(CACHE_LINES - 1 downto 0)							:= to_CacheData_slvv_48(CacheContent);
		variable result					: T_SLVV_8((CACHE_LINES * BYTES_PER_LINE) - 1 downto 0);
	begin
		for i in slvv'range loop
			for j in 0 to BYTES_PER_LINE - 1 loop
				result((i * BYTES_PER_LINE) + j)	:= slvv(i)((j * 8) + 7 downto j * 8);
			end loop;
		end loop;
		return result;
	end function;

	constant INITIAL_TAGS					: T_SLM			:= to_TagData(INITIAL_CACHE_CONTENT);
	constant INITIAL_DATALINES		: T_SLVV_8	:= to_CacheMemory(INITIAL_CACHE_CONTENT);


	signal ReadWrite							: std_logic;

	type T_FSMREPLACE_STATE is (ST_IDLE, ST_REPLACE);

	signal FSMReplace_State				: T_FSMREPLACE_STATE						:= ST_IDLE;
	signal FSMReplace_NextState		: T_FSMREPLACE_STATE;

	signal Insert									: std_logic;

	signal TU_NewTag_rst					: std_logic;
	signal TU_NewTag_nxt					: std_logic;
	signal NewTag_Data						: T_SLV_8;

	signal NewCacheLine_Data			: T_SLV_8;

	signal TU_Tag_rst							: std_logic;
	signal TU_Tag_nxt							: std_logic;
	signal TU_Tag_Data						: T_SLV_8;
	signal CacheHit								: std_logic;
	signal CacheMiss							: std_logic;

	signal TU_Index								: std_logic_vector(CACHEMEMORY_INDEX_BITS - 1 downto 0);
	signal TU_Index_d							: std_logic_vector(CACHEMEMORY_INDEX_BITS - 1 downto 0);
--	signal TU_Index_us						: UNSIGNED(CACHEMEMORY_INDEX_BITS - 1 downto 0);

	signal TU_NewIndex						: std_logic_vector(CACHEMEMORY_INDEX_BITS - 1 downto 0);
	signal TU_Replaced						: std_logic;

	signal TU_TagHit							: std_logic;
	signal TU_TagMiss							: std_logic;

	constant TICKCOUNTER_RES			: time																																			:= 10 ms;
	constant TICKCOUNTER_MAX			: positive																																	:= TimingToCycles(TICKCOUNTER_RES, CLOCK_FREQ);
	constant TICKCOUNTER_BITS			: positive																																	:= log2ceilnz(TICKCOUNTER_MAX);

	signal TickCounter_s					: signed(TICKCOUNTER_BITS downto 0)																					:= to_signed(TICKCOUNTER_MAX, TICKCOUNTER_BITS + 1);
	signal Tick										: std_logic;

	signal Exp_Expired						: std_logic;
	signal Exp_KeyOut							: std_logic_vector(CACHEMEMORY_INDEX_BITS - 1 downto 0);

	signal DataChunkIndex_us					: unsigned((CACHEMEMORY_INDEX_BITS + DATACHUNK_INDEX_BITS) - 1 downto 0)		:= (others => '0');
	signal DataChunkIndex_l_us				: unsigned((CACHEMEMORY_INDEX_BITS + DATACHUNK_INDEX_BITS) - 1 downto 0)		:= (others => '0');
	signal NewDataChunkIndex_en				: std_logic;
	signal NewDataChunkIndex_us				: unsigned((CACHEMEMORY_INDEX_BITS + DATACHUNK_INDEX_BITS) - 1 downto 0)		:= (others => '0');
	signal NewDataChunkIndex_max_us		: unsigned((CACHEMEMORY_INDEX_BITS + DATACHUNK_INDEX_BITS) - 1 downto 0)		:= (others => '0');
	signal CacheMemory_we							: std_logic;
	signal CacheMemory								: T_SLVV_8((CACHE_LINES * T_NET_MAC_ADDRESS'length) - 1 downto 0)						:= INITIAL_DATALINES;
	signal Memory_ReadWrite						: std_logic;

begin
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				FSMReplace_State			<= ST_IDLE;
			else
				FSMReplace_State			<= FSMReplace_NextState;
			end if;
		end if;
	end process;

	process(FSMReplace_State, Command, TU_Replaced, TU_NewTag_rst, TU_NewTag_nxt, NewDataChunkIndex_us, NewDataChunkIndex_max_us)
	begin
		FSMReplace_NextState							<= FSMReplace_State;

		Status														<= NET_ARP_ARPCACHE_STATUS_IDLE;

		NewMACAddress_rst									<= '0';
		NewMACAddress_nxt									<= '0';
		NewIPv4Address_rst								<= TU_NewTag_rst;
		NewIPv4Address_nxt								<= TU_NewTag_nxt;

		CacheMemory_we										<= '0';
		NewDataChunkIndex_en							<= '0';

		Insert														<= '0';

		case FSMReplace_State is
			when ST_IDLE =>
				NewMACAddress_rst							<= '1';

				case Command is
					when NET_ARP_ARPCACHE_CMD_NONE =>
						null;

					when NET_ARP_ARPCACHE_CMD_ADD =>
						Status										<= NET_ARP_ARPCACHE_STATUS_UPDATING;

						Insert										<= '1';
						CacheMemory_we						<= '1';
						NewMACAddress_rst					<= '0';
						NewMACAddress_nxt					<= '1';
						NewDataChunkIndex_en			<= '1';

						FSMReplace_NextState			<= ST_REPLACE;

					when others =>
						null;
				end case;

			when ST_REPLACE =>
				Status												<= NET_ARP_ARPCACHE_STATUS_UPDATING;

				CacheMemory_we								<= '1';
				NewMACAddress_nxt							<= '1';
				NewDataChunkIndex_en					<= '1';

				if (NewDataChunkIndex_us = NewDataChunkIndex_max_us) then
					Status											<= NET_ARP_ARPCACHE_STATUS_UPDATE_COMPLETE;
					FSMReplace_NextState				<= ST_IDLE;
				end if;

		end case;
	end process;

	ReadWrite						<= '0';
	NewTag_Data					<= NewIPv4Address_Data;
	NewCacheLine_Data		<= NewMACAddress_Data;

	IPv4Address_rst			<= TU_Tag_rst;
	IPv4Address_nxt			<= TU_Tag_nxt;
	TU_Tag_Data					<= IPv4Address_Data;

	CacheResult					<= to_Cache_Result(CacheHit, CacheMiss);

	-- Cache TagUnit
--	TU : entity PoC.Cache_TagUnit_seq
	TU : entity PoC.cache_TagUnit_seq
		generic map (
			REPLACEMENT_POLICY				=> REPLACEMENT_POLICY,
			CACHE_LINES								=> CACHE_LINES,
			ASSOCIATIVITY							=> CACHE_LINES,
			TAG_BITS									=> TAG_BITS,
			CHUNK_BITS								=> TAGCHUNK_BITS,
			TAG_BYTE_ORDER						=> TAG_BYTE_ORDER,
			USE_INITIAL_TAGS 					=> TRUE,
			INITIAL_TAGS							=> INITIAL_TAGS
		)
		port map (
			Clock											=> Clock,
			Reset											=> Reset,

			Replace										=> Insert,
			Replaced									=> TU_Replaced,
			Replace_NewTag_rst				=> TU_NewTag_rst,
			Replace_NewTag_rev				=> open,
			Replace_NewTag_nxt				=> TU_NewTag_nxt,
			Replace_NewTag_Data				=> NewTag_Data,
			Replace_NewIndex					=> TU_NewIndex,

			Request										=> Lookup,
			Request_ReadWrite					=> '0',
			Request_Invalidate				=> '0',--Invalidate,
			Request_Tag_rst						=> TU_Tag_rst,
			Request_Tag_rev						=> open,
			Request_Tag_nxt						=> TU_Tag_nxt,
			Request_Tag_Data					=> TU_Tag_Data,
			Request_Index							=> TU_Index,
			Request_TagHit						=> TU_TagHit,
			Request_TagMiss						=> TU_TagMiss
		);

	-- expiration time tick generator
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Tick = '1') then
				TickCounter_s		<= to_signed(TICKCOUNTER_MAX, TickCounter_s'length);
			else
				TickCounter_s	<= TickCounter_s - 1;
			end if;
		end if;
	end process;

	Tick			<= TickCounter_s(TickCounter_s'high);

--	Exp : entity PoC.list_expire
	Exp : entity PoC.list_expire
		generic map (
			CLOCK_CYCLE_TICKS				=> 65536,
			EXPIRATION_TIME_TICKS		=> 8192,
			ELEMENTS								=> CACHE_LINES,
			KEY_BITS								=> CACHEMEMORY_INDEX_BITS
		)
		port map (
			Clock										=> Clock,
			Reset										=> Reset,

			Tick										=> Tick,

			Insert									=> Insert,
			KeyIn										=> TU_NewIndex,

			Expired									=> Exp_Expired,
			KeyOut									=> Exp_KeyOut
		);



	-- latch TU_Index on TagHit
--	TU_Index_us		<= unsigned(TU_Index) when rising_edge(Clock) AND (TU_TagHit = '1');

	-- NewDataChunkIndex counter
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (NewDataChunkIndex_en = '0') then
				if (DATA_BYTE_ORDER = LITTLE_ENDIAN) then
					NewDataChunkIndex_us			<= resize(unsigned(TU_NewIndex) * 6, NewDataChunkIndex_us'length);
					NewDataChunkIndex_max_us	<= resize(unsigned(TU_NewIndex) * 6, NewDataChunkIndex_us'length) + to_unsigned((DATACHUNKS - 1), NewDataChunkIndex_us'length);
				else
					NewDataChunkIndex_us			<= resize(unsigned(TU_NewIndex) * 6, NewDataChunkIndex_us'length) + to_unsigned((DATACHUNKS - 1), NewDataChunkIndex_us'length);
					NewDataChunkIndex_max_us	<= resize(unsigned(TU_NewIndex) * 6, NewDataChunkIndex_us'length);
				end if;
			else
				if (DATA_BYTE_ORDER = LITTLE_ENDIAN) then
					NewDataChunkIndex_us	<= NewDataChunkIndex_us + 1;
				else
					NewDataChunkIndex_us	<= NewDataChunkIndex_us - 1;
				end if;
			end if;
		end if;
	end process;

	-- DataChunkIndex counter
	process(Clock, TU_Index)
		variable temp		: unsigned(DataChunkIndex_us'range);
	begin
		if (DATA_BYTE_ORDER = LITTLE_ENDIAN) then
			temp	:= resize(unsigned(TU_Index) * 6, DataChunkIndex_us'length);
		else
			temp	:= resize(unsigned(TU_Index) * 6, DataChunkIndex_us'length) + to_unsigned((DATACHUNKS - 1), DataChunkIndex_us'length);
		end if;

		if rising_edge(Clock) then
			if (TU_TagHit = '1') then
				DataChunkIndex_us				<= temp;
				DataChunkIndex_l_us			<= temp;
			elsif (MACAddress_rst = '1') then
				DataChunkIndex_us				<= DataChunkIndex_l_us;
			elsif (MACAddress_nxt = '1') then
				if (DATA_BYTE_ORDER = LITTLE_ENDIAN) then
					DataChunkIndex_us			<= DataChunkIndex_us + 1;
				else
					DataChunkIndex_us			<= DataChunkIndex_us - 1;
				end if;
			end if;
		end if;
	end process;

	-- Cache Memory - port 1
	Memory_ReadWrite	<= ReadWrite;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (CacheMemory_we = '1') then
				CacheMemory(to_integer(NewDataChunkIndex_us))	<= NewCacheLine_Data;
			end if;
		end if;
	end process;

	CacheHit					<= TU_TagHit;
	CacheMiss					<= TU_TagMiss;
	MACAddress_Data		<= CacheMemory(to_index(DataChunkIndex_us, CacheMemory'high));
end architecture;
