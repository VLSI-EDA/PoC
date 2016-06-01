-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:					Patrick Lehmann
--									Martin Zabel
--
-- Module:					Tag-unit with fully-parallel compare of tag.
--
-- Description:
-- ------------------------------------
-- All inputs are synchronous to the rising-edge of the clock `clock`.
--
-- Command truth table:
--
--	Request | ReadWrite | Invalidate	| Replace | Command
--	--------+-----------+-------------+---------+--------------------------------
--		0			|		0				|		0					|		0			| None
--		1			|		0				|		0					|		0			| Read cache line
--		1			|		1				|		0					|		0			| Update cache line
--		1			|		0				|		1					|		0			| Read cache line and discard it
--		1			|		1				|		1					|		0			| Write cache line and discard it
--		0			|		-				|		0					|		1			| Replace cache line.
--	--------+-----------+-------------+------------------------------------------
--
-- All commands use `Address` to lookup (request) or replace a cache line.
-- Each command is completed within one clock cycle.
--
-- Upon requests, the outputs `CacheMiss` and `CacheHit` indicate (high-active)
-- immediately (combinational) whether the `Address` is stored within the cache, or not.
-- But, the cache-line usage is updated at the rising-edge of the clock.
-- If hit, `LineIndex` specifies the cache line where to find the content.
--
-- The output `ReplaceLineIndex` indicates which cache line will be replaced as
-- next by a replace command. The output `OldAddress` specifies the old tag stored at this
-- index. The replace command will store the `NewAddress` and update the cache-line
-- usage at the rising-edge of the clock.
--
-- For a direct-mapped cache, the number of CACHE_LINES must be a power of 2.
-- For a set-associative cache, the expression (CACHE_LINES / ASSOCIATIVITY)
-- must be a power of 2.
--
-- License:
-- ============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library PoC;
use PoC.utils.all;
use PoC.vectors.all;

entity cache_tagunit_par is
	generic (
		REPLACEMENT_POLICY : string		:= "LRU";
		CACHE_LINES				 : positive := 32;
		ASSOCIATIVITY			 : positive := 32;
		ADDRESS_BITS					 : positive := 8
	);
	port (
		Clock : in std_logic;
		Reset : in std_logic;

		Replace					 : in	 std_logic;
		ReplaceLineIndex : out std_logic_vector(log2ceilnz(CACHE_LINES) - 1 downto 0);
		NewAddress			 : in	 std_logic_vector(ADDRESS_BITS - 1 downto 0);
		OldAddress			 : out std_logic_vector(ADDRESS_BITS - 1 downto 0);

		Request		 : in	 std_logic;
		ReadWrite	 : in	 std_logic;
		Invalidate : in	 std_logic;
		Address		 : in	 std_logic_vector(ADDRESS_BITS - 1 downto 0);
		LineIndex	 : out std_logic_vector(log2ceilnz(CACHE_LINES) - 1 downto 0);
		TagHit		 : out std_logic;
		TagMiss		 : out std_logic
	);
end;

architecture rtl of cache_tagunit_par is
	attribute KEEP : boolean;

	constant SETS : positive := CACHE_LINES / ASSOCIATIVITY;

begin
	-- ===========================================================================
	-- Full-Associative Cache
	-- ===========================================================================
	genFA : if (CACHE_LINES = ASSOCIATIVITY) generate
		constant TAG_BITS		: positive := ADDRESS_BITS;
		constant WAY_BITS 	: positive := log2ceilnz(ASSOCIATIVITY);

		subtype T_TAG_LINE is std_logic_vector(TAG_BITS - 1 downto 0);
		type T_TAG_LINE_VECTOR is array (natural range <>) of T_TAG_LINE;

		signal TagHits : std_logic_vector(CACHE_LINES - 1 downto 0); -- includes Valid

		signal TagMemory		: T_TAG_LINE_VECTOR(CACHE_LINES - 1 downto 0);
		signal ValidMemory : std_logic_vector(CACHE_LINES - 1 downto 0)			:= (others => '0');

		signal HitWay : unsigned(WAY_BITS - 1 downto 0);

		signal Policy_ReplaceWay : std_logic_vector(WAY_BITS - 1 downto 0);
		signal ReplaceWay_us	 	 : unsigned(WAY_BITS - 1 downto 0);

		signal TagHit_i	 : std_logic; -- includes Valid and Request
		signal TagMiss_i : std_logic; -- includes Valid and Request
	begin

		-- generate comparators and convert hit-vector to binary index (cache line address)
		-- use process, so that "onehot2bin" does not report false errors in
		-- simulation due to delta-cycles updates
		process(Address, TagMemory, ValidMemory)
			variable hits : std_logic_vector(CACHE_LINES - 1 downto 0); -- includes Valid
		begin
			for i in 0 to CACHE_LINES - 1 loop
				hits(i) := to_sl(TagMemory(i) = Address and ValidMemory(i) = '1');
			end loop;

			TagHits <= hits;
			HitWay	<= onehot2bin(hits, 0);
		end process;

		process(Clock)
		begin
			if rising_edge(Clock) then
				if (Replace = '1') then
					TagMemory(to_integer(ReplaceWay_us))	 <= NewAddress;
				end if;

				for i in ValidMemory'range loop
					if Reset = '1' then
						ValidMemory(i) <= '0';
					elsif (Replace = '1' and ReplaceWay_us = i) or
						(Invalidate = '1' and TagHits(i) = '1')
					then
						ValidMemory(i) <= Replace; -- clear when Invalidate
					end if;
				end loop;
			end if;
		end process;

		-- hit/miss calculation
		TagHit_i	<= slv_or(TagHits) and Request;
		TagMiss_i <= not (slv_or(TagHits)) and Request;

		-- outputs
		LineIndex <= std_logic_vector(HitWay);
		TagHit		<= TagHit_i;
		TagMiss		<= TagMiss_i;

		ReplaceWay_us		 <= unsigned(Policy_ReplaceWay);
		ReplaceLineIndex <= Policy_ReplaceWay;
		OldAddress			 <= TagMemory(to_integer(ReplaceWay_us));

		-- replacement policy
		Policy : entity PoC.cache_replacement_policy
			generic map (
				REPLACEMENT_POLICY => REPLACEMENT_POLICY,
				CACHE_WAYS				 => ASSOCIATIVITY
			)
			port map (
				Clock => Clock,
				Reset => Reset,

				Replace		 => Replace,
				ReplaceWay => Policy_ReplaceWay,

        TagAccess  => TagHit_i,
        ReadWrite  => ReadWrite,
        Invalidate => Invalidate,
        HitWay     => std_logic_vector(HitWay)
      );
  end generate;

  -- ===========================================================================
  -- Direct-Mapped Cache
  -- ===========================================================================
  genDM : if (ASSOCIATIVITY = 1) generate
    -- Addresses are splitted into a tag part and an index part.
    constant INDEX_BITS : positive := log2ceilnz(CACHE_LINES);
    constant TAG_BITS   : positive := ADDRESS_BITS - INDEX_BITS;

		subtype T_TAG_LINE is std_logic_vector(TAG_BITS-1 downto 0);
		type T_TAG_LINE_VECTOR is array(natural range <>) of T_TAG_LINE;

		signal Address_Tag			: T_TAG_LINE;
		signal Address_Index		: unsigned(INDEX_BITS - 1 downto 0);
		signal NewAddress_Tag		: T_TAG_LINE;
		signal NewAddress_Index : unsigned(INDEX_BITS - 1 downto 0);

		signal DM_TagHit	  : std_logic; -- includes Valid

		signal TagMemory	 : T_TAG_LINE_VECTOR(CACHE_LINES-1 downto 0);
		signal ValidMemory : std_logic_vector(CACHE_LINES-1 downto 0) := (others => '0');

		signal ValidUpdateIndex : unsigned(INDEX_BITS-1 downto 0);

		signal TagHit_i	 : std_logic;
		signal TagMiss_i : std_logic;

  begin
		assert CACHE_LINES = 2**INDEX_BITS report "Unsupported number of cache lines." severity failure;

    -- Split incoming 'Address' and 'NewAddress'
    Address_Tag      <= Address(Address'left downto INDEX_BITS);
    Address_Index    <= unsigned(Address(INDEX_BITS-1 downto 0));
    NewAddress_Tag   <= NewAddress(NewAddress'left downto INDEX_BITS);
    NewAddress_Index <= unsigned(NewAddress(INDEX_BITS-1 downto 0));

		-- access tag memory and compare tags / valids
		DM_TagHit <= to_sl(TagMemory  (to_integer(Address_Index)) = Address_Tag and
											 ValidMemory(to_integer(Address_Index)) = '1');

		-- index for writing into ValidMemory
		ValidUpdateIndex <= NewAddress_Index when Replace = '1' else
												Address_Index;

		process(Clock)
		begin
			if rising_edge(Clock) then
				if (Replace = '1') then
					TagMemory(to_integer(NewAddress_Index)) <= NewAddress_Tag;
				end if;

				if Reset = '1' then
					ValidMemory <= (others => '0');
				elsif (Replace = '1') or (TagHit_i = '1' and Invalidate = '1')	then
					ValidMemory(to_integer(ValidUpdateIndex)) <= Replace; -- clear when Invalidate
				end if;
			end if;
		end process;

		-- hit/miss calculation
		TagHit_i	<= DM_TagHit and Request;
		TagMiss_i <= not (DM_TagHit) and Request;

		-- outputs
		LineIndex <= std_logic_vector(Address_Index);
		TagHit		<= TagHit_i;
		TagMiss		<= TagMiss_i;

		ReplaceLineIndex <= std_logic_vector(NewAddress_Index);
		OldAddress			 <= TagMemory(to_integer(NewAddress_Index)) & std_logic_vector(NewAddress_Index);
	end generate;

	-- ===========================================================================
	-- Set-Assoziative Cache
	-- ===========================================================================
	genSA : if ((ASSOCIATIVITY > 1) and (SETS > 1)) generate
    -- Addresses are splitted into a tag part and an index part.
		constant CACHE_SETS : positive := CACHE_LINES / ASSOCIATIVITY;
    constant INDEX_BITS : positive := log2ceilnz(CACHE_SETS);
    constant TAG_BITS   : positive := ADDRESS_BITS - INDEX_BITS;
		constant WAY_BITS 	: positive := log2ceilnz(ASSOCIATIVITY);

		subtype T_TAG_LINE is std_logic_vector(TAG_BITS-1 downto 0);
		type T_TAG_LINE_VECTOR is array(natural range <>) of T_TAG_LINE;

		type T_WAY_VECTOR is array(natural range<>) of std_logic_vector(WAY_BITS-1 downto 0);

		-- Splitted address
		signal Address_Tag			: T_TAG_LINE;
		signal Address_Index		: unsigned(INDEX_BITS - 1 downto 0);
		signal NewAddress_Tag		: T_TAG_LINE;
		signal NewAddress_Index : unsigned(INDEX_BITS - 1 downto 0);

		-- Way-specific signals
		signal TagHits : std_logic_vector(ASSOCIATIVITY-1 downto 0); -- includes Valid
		signal OldTags : T_TAG_LINE_VECTOR(ASSOCIATIVITY-1 downto 0);

		-- Cache-set specific signals
		signal CS_TagAccess	 : std_logic_vector(CACHE_SETS-1 downto 0);
		signal CS_Invalidate : std_logic_vector(CACHE_SETS-1 downto 0);
		signal CS_Replace		 : std_logic_vector(CACHE_SETS-1 downto 0);
		signal Policy_ReplaceWay : T_WAY_VECTOR(CACHE_SETS-1 downto 0);

		-- Way where hit occurs and way to replace
		signal HitWay			: unsigned(WAY_BITS-1 downto 0);
		signal ReplaceWay : unsigned(WAY_BITS-1 downto 0);

		signal TagHit_i	 : std_logic;
		signal TagMiss_i : std_logic;

	begin

		assert CACHE_SETS = 2**INDEX_BITS report "Unsupported number of cache-sets." severity failure;

		----------------------------------------------------------------------------
    -- Split incoming 'Address' and 'NewAddress'
		-- Enable only one cache-set
		----------------------------------------------------------------------------
    Address_Tag      <= Address(Address'left downto INDEX_BITS);
    Address_Index    <= unsigned(Address(INDEX_BITS-1 downto 0));
    NewAddress_Tag   <= NewAddress(NewAddress'left downto INDEX_BITS);
    NewAddress_Index <= unsigned(NewAddress(INDEX_BITS-1 downto 0));

		----------------------------------------------------------------------------
		-- Generate tag-memory and comparators for each way
		----------------------------------------------------------------------------

		genWay : for way in 0 to ASSOCIATIVITY-1 generate
			signal TagMemory	 : T_TAG_LINE_VECTOR(CACHE_SETS-1 downto 0);
			signal ValidMemory : std_logic_vector(CACHE_SETS-1 downto 0) := (others => '0');
		begin
			-- comparator
			TagHits(way) <= to_sl(TagMemory  (to_integer(Address_Index)) = Address_Tag and
														ValidMemory(to_integer(Address_Index)) = '1');

			-- memory update
			process (Clock) is
			begin  -- process
				if rising_edge(Clock) then
					if Replace = '1' and ReplaceWay = way then
						TagMemory(to_integer(NewAddress_Index)) <= NewAddress_Tag;
					end if;

					if Reset = '1' then
						ValidMemory <= (others => '0');
					elsif Replace = '1' and ReplaceWay = way then
						ValidMemory(to_integer(NewAddress_Index)) <= '1';
					elsif Invalidate = '1' and TagHits(way) = '1' then
						ValidMemory(to_integer(Address_Index)) <= '0';
					end if;
				end if;
			end process;

			-- old address when replacing
			OldTags(way) <= TagMemory(to_integer(NewAddress_Index));
		end generate genWay;

		HitWay <= onehot2bin(TagHits, 0);

		----------------------------------------------------------------------------
		-- Global hit / miss calculation and output
		----------------------------------------------------------------------------
		TagHit_i	<= slv_or(TagHits) and Request;
		TagMiss_i <= not (slv_or(TagHits)) and Request;

		LineIndex <= std_logic_vector(HitWay) & std_logic_vector(Address_Index);
		TagHit		<= TagHit_i;
		TagMiss		<= TagMiss_i;

		----------------------------------------------------------------------------
		-- Generate policy for each cache-set
		----------------------------------------------------------------------------
		process(Address_Index, TagHit_i, Invalidate)
		begin
			CS_TagAccess														 <= (others => '0');
			CS_TagAccess(to_integer(Address_Index))	 <= TagHit_i;
			CS_Invalidate														 <= (others => '0');
			CS_Invalidate(to_integer(Address_Index)) <= Invalidate;
		end process;

		process(NewAddress_Index, Replace)
		begin
			CS_Replace															 <= (others => '0');
			CS_Replace(to_integer(NewAddress_Index)) <= Replace;
		end process;

		genSet : for cs in 0 to CACHE_SETS-1 generate
		begin
			Policy : entity PoC.cache_replacement_policy
				generic map (
					REPLACEMENT_POLICY => REPLACEMENT_POLICY,
					CACHE_WAYS				 => ASSOCIATIVITY
				)
				port map (
					Clock => Clock,
					Reset => Reset,

					Replace		 => CS_Replace(cs),
					ReplaceWay => Policy_ReplaceWay(cs), -- way to replace

					TagAccess	 => CS_TagAccess(cs),
					ReadWrite	 => ReadWrite,
					Invalidate => CS_Invalidate(cs),
					HitWay		 => std_logic_vector(HitWay) -- accessed way
				);
		end generate genSet;

		ReplaceWay <= unsigned(Policy_ReplaceWay(to_integer(NewAddress_Index)));

		----------------------------------------------------------------------------
		-- Replace-specific outputs
		----------------------------------------------------------------------------
		ReplaceLineIndex <= std_logic_vector(ReplaceWay) & std_logic_vector(NewAddress_Index);
		OldAddress			 <= OldTags(to_integer(ReplaceWay)) & std_logic_vector(NewAddress_Index);

	end generate;
end architecture;
