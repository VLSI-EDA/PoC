-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					Tag-unit with sequential compare of tag.
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2007-2014 Technische Universitaet Dresden - Germany
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

entity cache_tagunit_seq is
	generic (
		REPLACEMENT_POLICY : string				:= "LRU";
		CACHE_LINES				 : positive			:= 32;
		ASSOCIATIVITY			 : positive			:= 32;
		TAG_BITS					 : positive			:= 128;
		CHUNK_BITS				 : positive			:= 8;
		TAG_BYTE_ORDER		 : T_BYTE_ORDER := LITTLE_ENDIAN;
		USE_INITIAL_TAGS	 : boolean			:= false;
		INITIAL_TAGS			 : T_SLM				:= (0 downto 0 => (127 downto 0 => '0'))
	);
	port (
		Clock : in std_logic;
		Reset : in std_logic;

		Replace							: in	std_logic;
		Replaced						: out std_logic;
		Replace_NewTag_rst	: out std_logic;
		Replace_NewTag_rev	: out std_logic;
		Replace_NewTag_nxt	: out std_logic;
		Replace_NewTag_Data : in	std_logic_vector(CHUNK_BITS - 1 downto 0);
		Replace_NewIndex		: out std_logic_vector(log2ceilnz(CACHE_LINES) - 1 downto 0);

		Request						 : in	 std_logic;
		Request_ReadWrite	 : in	 std_logic;
		Request_Invalidate : in	 std_logic;
		Request_Tag_rst		 : out std_logic;
		Request_Tag_rev		 : out std_logic;
		Request_Tag_nxt		 : out std_logic;
		Request_Tag_Data	 : in	 std_logic_vector(CHUNK_BITS - 1 downto 0);
		Request_Index			 : out std_logic_vector(log2ceilnz(CACHE_LINES) - 1 downto 0);
		Request_TagHit		 : out std_logic;
		Request_TagMiss		 : out std_logic
	);
end entity;


architecture rtl of cache_tagunit_seq is
	attribute KEEP : boolean;

	constant SETS : positive := CACHE_LINES / ASSOCIATIVITY;

begin
	-- ==========================================================================================================================================================
	-- Full-Assoziative Cache
	-- ==========================================================================================================================================================
	genFA : if CACHE_LINES = ASSOCIATIVITY generate
		constant FA_CACHE_LINES				: positive := ASSOCIATIVITY;
		constant FA_TAG_BITS					: positive := TAG_BITS;
		constant FA_CHUNKS						: positive := div_ceil(FA_TAG_BITS, CHUNK_BITS);
		constant FA_CHUNK_INDEX_BITS	: positive := log2ceilnz(FA_CHUNKS);
		constant FA_MEMORY_INDEX_BITS : positive := log2ceilnz(FA_CACHE_LINES);

		constant FA_INITIAL_TAGS_RESIZED : T_SLM := resize(INITIAL_TAGS, FA_CACHE_LINES);

		subtype T_CHUNK is std_logic_vector(CHUNK_BITS - 1 downto 0);
		type T_TAG_LINE is array (natural range <>) of T_CHUNK;

		type T_REPLACE_STATE is (ST_IDLE, ST_REPLACE);
		type T_REQUEST_STATE is (ST_IDLE, ST_COMPARE, ST_READ);

		function to_validvector(slm : T_SLM) return std_logic_vector is
			variable result : std_logic_vector(CACHE_LINES - 1 downto 0);
		begin
			result := (others => '0');
			if not USE_INITIAL_TAGS then return result; end if;

			for I in slm'range loop
				result(I) := '1';
			end loop;
			return result;
		end function;

		function to_tagmemory(slm : T_SLM; row : natural) return T_TAG_LINE is
			constant tag_line : std_logic_vector(slm'high(2) downto slm'low(2)) := get_row(slm, row);
			variable result		: T_TAG_LINE(FA_CHUNKS - 1 downto 0);
		begin
--			report "tagline @row " & INTEGER'image(row) & " = " & to_string(tag_line, 'h') severity NOTE;
			for I in result'range loop
				result(I) := tag_line((I * CHUNK_BITS) + CHUNK_BITS - 1 downto (I * CHUNK_BITS));
			end loop;
			return result;
		end function;

		signal Replace_State		 : T_Replace_STATE := ST_IDLE;
		signal Replace_NextState : T_Replace_STATE;
		signal Request_State		 : T_REQUEST_STATE := ST_IDLE;
		signal Request_NextState : T_REQUEST_STATE;

		signal RequestComplete : std_logic;

		signal NewTagSeqCounter_rst : std_logic;
--		signal NewTagSeqCounter_en			: STD_LOGIC;
		signal NewTagSeqCounter_us	: unsigned(FA_CHUNK_INDEX_BITS - 1 downto 0) := (others => '0');
		signal TagSeqCounter_rst		: std_logic;
--		signal TagSeqCounter_en					: STD_LOGIC;
		signal TagSeqCounter_us			: unsigned(FA_CHUNK_INDEX_BITS - 1 downto 0) := (others => '0');

		signal TagMemory_we : std_logic;

		signal PartialTagHits : std_logic_vector(FA_CACHE_LINES - 1 downto 0);
		signal TagHits_en			: std_logic;
		signal TagHits_nxt		: std_logic_vector(FA_CACHE_LINES - 1 downto 0);
		signal TagHits_nor		: std_logic;
		signal TagHits_r			: std_logic_vector(FA_CACHE_LINES - 1 downto 0) := (others => '1');

		signal MemoryIndex_us : unsigned(FA_MEMORY_INDEX_BITS - 1 downto 0);
		signal MemoryIndex_i	: std_logic_vector(FA_MEMORY_INDEX_BITS - 1 downto 0);

		signal ValidMemory : std_logic_vector(FA_CACHE_LINES - 1 downto 0) := to_validvector(INITIAL_TAGS);
		signal ValidHit		 : std_logic;

		signal Policy_ReplaceIndex	 : std_logic_vector(FA_MEMORY_INDEX_BITS - 1 downto 0);
		signal Policy_ReplaceIndex_d : std_logic_vector(FA_MEMORY_INDEX_BITS - 1 downto 0) := (others => '0');
		signal ReplaceIndex_us			 : unsigned(FA_MEMORY_INDEX_BITS - 1 downto 0);

		signal TagHit_i	 : std_logic;
		signal TagMiss_i : std_logic;

		signal TagAccess : std_logic																					 := '0';
		signal TagIndex	 : std_logic_vector(FA_MEMORY_INDEX_BITS - 1 downto 0) := (others => '0');

	begin
		process(Clock)
		begin
			if rising_edge(Clock) then
				if (Reset = '1') then
					Replace_State <= ST_IDLE;
					Request_State <= ST_IDLE;
				else
					Replace_State <= Replace_NextState;
					Request_State <= Request_NextState;
				end if;
			end if;
		end process;

		process(Replace_State, Replace, NewTagSeqCounter_us)
		begin
			Replace_NextState <= Replace_State;

			Replace_NewTag_rst <= '0';
			Replace_NewTag_rev <= '0';
			Replace_NewTag_nxt <= '0';
			Replaced					 <= '0';

			NewTagSeqCounter_rst <= '0';
--			NewTagSeqCounter_en					<= '0';
			TagMemory_we				 <= '0';

			case Replace_State is
				when ST_IDLE =>
					Replace_NewTag_rst	 <= '1';
					NewTagSeqCounter_rst <= '1';

					if (Replace = '1') then
						Replace_NewTag_rst <= '0';
						Replace_NewTag_nxt <= '1';

						NewTagSeqCounter_rst <= '0';
--						NewTagSeqCounter_en		<= '1';
						TagMemory_we				 <= '1';

						Replace_NextState <= ST_REPLACE;
					end if;

				when ST_REPLACE =>
					Replace_NewTag_nxt <= '1';
--					NewTagSeqCounter_en			<= '1';
					TagMemory_we			 <= '1';

					if NewTagSeqCounter_us = ite((TAG_BYTE_ORDER = LITTLE_ENDIAN), (FA_CHUNKS - 1), 0) then
						Replaced <= '1';

						Replace_NextState <= ST_IDLE;
					end if;

			end case;
		end process;

		process(Request_State, Request, TagSeqCounter_us, TagHits_nor)
		begin
			Request_NextState <= Request_State;

			TagSeqCounter_rst <= '0';
--			TagSeqCounter_en						<= '0';
			TagHits_en				<= '0';

			Request_Tag_rst <= '0';
			Request_Tag_rev <= ite((TAG_BYTE_ORDER = LITTLE_ENDIAN), '0', '1');
			Request_Tag_nxt <= '0';
			RequestComplete <= '0';

			case Request_State is
				when ST_IDLE =>
					Request_Tag_rst		<= '1';
					TagSeqCounter_rst <= '1';

					if (Request = '1') then
						if (TagHits_nor = '1') then
							RequestComplete <= '1';
						else
							Request_Tag_rst <= '0';
							Request_Tag_nxt <= '1';

							TagSeqCounter_rst <= '0';
--							TagSeqCounter_en		<= '1';
							TagHits_en				<= '1';

							Request_NextState <= ST_COMPARE;
						end if;
					end if;

				when ST_COMPARE =>
					Request_Tag_nxt <= '1';
--					TagSeqCounter_en				<= '1';
					TagHits_en			<= '1';

					if (TagHits_nor = '1') then
						Request_Tag_rst		<= '1';
						TagSeqCounter_rst <= '1';
						RequestComplete		<= '1';

						Request_NextState <= ST_IDLE;
					else
						if TagSeqCounter_us = ite((TAG_BYTE_ORDER = LITTLE_ENDIAN), (FA_CHUNKS - 1), 0) then
							RequestComplete <= '1';

							Request_NextState <= ST_READ;
						end if;
					end if;

				when ST_READ =>
					Request_Tag_rst		<= '1';
					TagSeqCounter_rst <= '1';

					if (Request = '1') then
						if (TagHits_nor = '1') then
							RequestComplete		<= '1';
							Request_NextState <= ST_IDLE;
						else
							Request_Tag_rst <= '0';
							Request_Tag_nxt <= '1';

							TagSeqCounter_rst <= '0';
--							TagSeqCounter_en		<= '1';
							TagHits_en				<= '1';

							Request_NextState <= ST_COMPARE;
						end if;
					end if;

			end case;
		end process;

		-- Counters
		process(Clock)
		begin
			if rising_edge(Clock) then
				-- NewTagSeqCounter
				if ((Reset or NewTagSeqCounter_rst) = '1') then
					if TAG_BYTE_ORDER = LITTLE_ENDIAN then
						NewTagSeqCounter_us <= to_unsigned(0, NewTagSeqCounter_us'length);
					else
						NewTagSeqCounter_us <= to_unsigned((FA_CHUNKS - 1), NewTagSeqCounter_us'length);
					end if;
				else
					if TAG_BYTE_ORDER = LITTLE_ENDIAN then
						NewTagSeqCounter_us <= NewTagSeqCounter_us + 1;
					else
						NewTagSeqCounter_us <= NewTagSeqCounter_us - 1;
					end if;
				end if;

				-- TagSeqCounter
				if ((Reset or TagSeqCounter_rst) = '1') then
					if TAG_BYTE_ORDER = LITTLE_ENDIAN then
						TagSeqCounter_us <= to_unsigned(0, TagSeqCounter_us'length);
					else
						TagSeqCounter_us <= to_unsigned((FA_CHUNKS - 1), TagSeqCounter_us'length);
					end if;
				else
					if TAG_BYTE_ORDER = LITTLE_ENDIAN then
						TagSeqCounter_us <= TagSeqCounter_us + 1;
					else
						TagSeqCounter_us <= TagSeqCounter_us - 1;
					end if;
				end if;
			end if;
		end process;

		-- generate comparators
		genVectors : for I in 0 to FA_CACHE_LINES - 1 generate
			constant C_TAGMEMORY : T_TAG_LINE(FA_CHUNKS - 1 downto 0) := to_tagmemory(FA_INITIAL_TAGS_RESIZED, I);
			signal TagMemory		 : T_TAG_LINE(FA_CHUNKS - 1 downto 0) := C_TAGMEMORY;
		begin
--			genASS : for j in 0 to FA_CHUNKS - 1 generate
--				assert FALSE report "line=" & INTEGER'image(I) & "	chunk=" & INTEGER'image(J) & "	tag=" & to_string(C_TAGMEMORY(J), 'h') severity NOTE;
--			end generate;

			process(Clock)
			begin
				if rising_edge(Clock) then
					if ((ReplaceIndex_us = I) and (TagMemory_we = '1')) then
						TagMemory(to_integer(NewTagSeqCounter_us)) <= Replace_NewTag_Data;
					end if;
				end if;
			end process;

			PartialTagHits(I) <= to_sl(TagMemory(to_integer(TagSeqCounter_us)) = Request_Tag_Data);
		end generate;

		-- TagHit accumulator
		TagHits_nxt <= TagHits_r and PartialTagHits;
		TagHits_nor <= slv_nor(TagHits_nxt);

		process(Clock)
		begin
			if rising_edge(Clock) then
				if ((TagHit_i or TagMiss_i) = '1') then
					TagHits_r <= (others => '1');
				elsif (TagHits_en = '1') then
					TagHits_r <= TagHits_nxt;
				end if;
			end if;
		end process;

		-- convert hit-vector to binary index (cache line address)
		MemoryIndex_us <= onehot2bin(TagHits_nxt);
		MemoryIndex_i	 <= std_logic_vector(MemoryIndex_us);

		-- latching the ReplaceIndex
		process(Clock)
		begin
			if rising_edge(Clock) then
				if (Replace = '1') then
					Policy_ReplaceIndex_d <= Policy_ReplaceIndex;
				end if;
			end if;
		end process;

		ReplaceIndex_us <= unsigned(ite((Replace = '1'), Policy_ReplaceIndex, Policy_ReplaceIndex_d));

		-- Memories
		process(Clock)
		begin
			if rising_edge(Clock) then
				if (Replace = '1') then
					ValidMemory(to_integer(unsigned(Policy_ReplaceIndex))) <= '1';
				end if;
			end if;
		end process;

		ValidHit <= ValidMemory(to_integer(MemoryIndex_us));

		-- hit/miss calculation
		TagHit_i	<= slv_or(TagHits_nxt) and ValidHit and RequestComplete;
		TagMiss_i <= not (slv_or(TagHits_nxt) and ValidHit) and RequestComplete;

		-- outputs
		Request_Index		<= MemoryIndex_i;
		Request_TagHit	<= TagHit_i;
		Request_TagMiss <= TagMiss_i;

		Replace_NewIndex <= Policy_ReplaceIndex;

		TagAccess <= TagHit_i			 when rising_edge(Clock);
		TagIndex	<= MemoryIndex_i when rising_edge(Clock);

		-- replacement policy
		Policy : entity PoC.cache_replacement_policy
			generic map (
				REPLACEMENT_POLICY => REPLACEMENT_POLICY,
				CACHE_WAYS				 => FA_CACHE_LINES
			)
			port map (
				Clock => Clock,
				Reset => Reset,

				Replace		 => Replace,
				ReplaceWay => Policy_ReplaceIndex,

				TagAccess	 => TagAccess,
				ReadWrite	 => Request_ReadWrite,
				Invalidate => Request_Invalidate,
				HitWay		 => TagIndex
			);
	end generate;
	-- ==========================================================================================================================================================
	-- Direct-Mapped Cache
	-- ==========================================================================================================================================================
	genDM : if ASSOCIATIVITY = 1 generate
		constant FA_CACHE_LINES				: positive := CACHE_LINES;
		constant FA_TAG_BITS					: positive := TAG_BITS;
		constant FA_MEMORY_INDEX_BITS : positive := log2ceilnz(FA_CACHE_LINES);

		signal FA_Tag	 : std_logic_vector(FA_TAG_BITS - 1 downto 0);
		signal TagHits : std_logic_vector(FA_CACHE_LINES - 1 downto 0);

		signal FA_MemoryIndex_i		: std_logic_vector(FA_MEMORY_INDEX_BITS - 1 downto 0);
		signal FA_MemoryIndex_us	: unsigned(FA_MEMORY_INDEX_BITS - 1 downto 0);
		signal FA_ReplaceIndex_us : unsigned(FA_MEMORY_INDEX_BITS - 1 downto 0);

		signal ValidHit	 : std_logic;
		signal TagHit_i	 : std_logic;
		signal TagMiss_i : std_logic;
	begin
--		-- generate comparators
--		genVectors : for i in 0 to FA_CACHE_LINES - 1 generate
--			TagHits(I)			<= to_sl(TagMemory(I) = FA_Tag);
--		end generate;
--
--		-- convert hit-vector to binary index (cache line address)
--		FA_MemoryIndex_us		<= onehot2bin(TagHits);
--		FA_MemoryIndex_i		<= std_logic_vector(FA_MemoryIndex_us);
--
--		-- Memories
--		FA_ReplaceIndex_us	<= FA_MemoryIndex_us;
--
--		process(Clock)
--		begin
--			if rising_edge(Clock) then
--				if (Replace = '1') then
--					TagMemory(to_integer(FA_ReplaceIndex_us))		<= NewTag;
--					ValidMemory(to_integer(FA_ReplaceIndex_us)) <= '1';
--				end if;
--			end if;
--		end process;
--
--		-- access valid-vector
--		ValidHit					<= ValidMemory(to_integer(FA_MemoryIndex_us));
--
--		-- hit/miss calculation
--		TagHit_i					<=			slv_or(TagHits) AND ValidHit	AND Request;
--		TagMiss_i				<= NOT (slv_or(TagHits) AND ValidHit) AND Request;
--
--		-- outputs
--		Index					<= FA_MemoryIndex_i;
--		TagHit				<= TagHit_i;
--		TagMiss				<= TagMiss_i;
--
--		genPolicy : for i in 0 to SETS - 1 generate
--			policy : entity PoC.cache_replacement_policy
--				generic map (
--					REPLACEMENT_POLICY				=> REPLACEMENT_POLICY,
--					CACHE_LINES								=> ASSOCIATIVITY,
--					INITIAL_VALIDS						=> INITIAL_VALIDS(I * ASSOCIATIVITY + ASSOCIATIVITY - 1 downto I * ASSOCIATIVITY)
--				)
--				port map (
--					Clock											=> Clock,
--					Reset											=> Reset,
--
--					Replace										=> Policy_Replace(I),
--					ReplaceIndex							=> Policy_ReplaceIndex(I),
--
--					TagAccess									=> TagAccess(I),
--					Request_ReadWrite									=> Request_ReadWrite(I),
--					Invalidate								=> Invalidate(I),
--					Index											=> Policy_Index(I)
--				);
--		end generate;
	end generate;
	-- ==========================================================================================================================================================
	-- Set-Assoziative Cache
	-- ==========================================================================================================================================================
	genSA : if (ASSOCIATIVITY > 1) and (SETS > 1) generate
		constant FA_CACHE_LINES				: positive := CACHE_LINES;
		constant SETINDEX_BITS				: natural	 := log2ceil(SETS);
		constant FA_TAG_BITS					: positive := TAG_BITS;
		constant FA_MEMORY_INDEX_BITS : positive := log2ceilnz(FA_CACHE_LINES);

		signal FA_Tag	 : std_logic_vector(FA_TAG_BITS - 1 downto 0);
		signal TagHits : std_logic_vector(FA_CACHE_LINES - 1 downto 0);

		signal FA_MemoryIndex_i		: std_logic_vector(FA_MEMORY_INDEX_BITS - 1 downto 0);
		signal FA_MemoryIndex_us	: unsigned(FA_MEMORY_INDEX_BITS - 1 downto 0);
		signal FA_ReplaceIndex_us : unsigned(FA_MEMORY_INDEX_BITS - 1 downto 0);

		signal ValidHit	 : std_logic;
		signal TagHit_i	 : std_logic;
		signal TagMiss_i : std_logic;
	begin
--		-- generate comparators
--		genVectors : for i in 0 to FA_CACHE_LINES - 1 generate
--			TagHits(I)			<= to_sl(TagMemory(I) = FA_Tag);
--		end generate;
--
--		-- convert hit-vector to binary index (cache line address)
--		FA_MemoryIndex_us		<= onehot2bin(TagHits);
--		FA_MemoryIndex_i		<= std_logic_vector(FA_MemoryIndex_us);
--
--		-- Memories
--		FA_ReplaceIndex_us	<= FA_MemoryIndex_us;
--
--		process(Clock)
--		begin
--			if rising_edge(Clock) then
--				if (Replace = '1') then
--					TagMemory(to_integer(FA_ReplaceIndex_us))		<= NewTag;
--					ValidMemory(to_integer(FA_ReplaceIndex_us)) <= '1';
--				end if;
--			end if;
--		end process;
--
--		-- access valid-vector
--		ValidHit					<= ValidMemory(to_integer(FA_MemoryIndex_us));
--
--		-- hit/miss calculation
--		TagHit_i					<=			slv_or(TagHits) AND ValidHit	AND Request;
--		TagMiss_i				<= NOT (slv_or(TagHits) AND ValidHit) AND Request;
--
--		-- outputs
--		Index					<= FA_MemoryIndex_i;
--		TagHit				<= TagHit_i;
--		TagMiss				<= TagMiss_i;
--
--		genPolicy : for i in 0 to SETS - 1 generate
--			policy : entity PoC.cache_replacement_policy
--				generic map (
--					REPLACEMENT_POLICY				=> REPLACEMENT_POLICY,
--					CACHE_LINES								=> ASSOCIATIVITY,
--					INITIAL_VALIDS						=> INITIAL_VALIDS(I * ASSOCIATIVITY + ASSOCIATIVITY - 1 downto I * ASSOCIATIVITY)
--				)
--				port map (
--					Clock											=> Clock,
--					Reset											=> Reset,
--
--					Replace										=> Policy_Replace(I),
--					ReplaceIndex							=> Policy_ReplaceIndex(I),
--
--					TagAccess									=> TagAccess(I),
--					Request_ReadWrite									=> Request_ReadWrite(I),
--					Invalidate								=> Invalidate(I),
--					Index											=> Policy_Index(I)
--				);
--		end generate;
	end generate;
end architecture;
