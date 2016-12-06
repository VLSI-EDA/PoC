-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:         Patrick Lehmann
--                  Martin Zabel
--
-- Entity:          Cache with parallel tag-unit and data memory.
--
-- Description:
-- -------------------------------------
-- Implements a cache with parallel tag-unit and data memory.
--
-- .. NOTE::
--    This component infers a single-port memory with read-first behavior, that
--    is, upon writes the old-data is returned on the read output. Such memory
--    (e.g. LUT-RAM) is not available on all devices. Thus, synthesis may
--    infer a lot of flip-flops plus multiplexers instead, which is very inefficient.
--    It is recommended to use :doc:`PoC.cache.par2 <cache_par2>` instead which has a
--    slightly different interface.
--
-- All inputs are synchronous to the rising-edge of the clock `clock`.
--
-- **Command truth table:**
--
-- +---------+-----------+-------------+---------+---------------------------------+
-- | Request | ReadWrite | Invalidate  | Replace | Command                         |
-- +=========+===========+=============+=========+=================================+
-- |  0      |    0      |    0        |    0    | None                            |
-- +---------+-----------+-------------+---------+---------------------------------+
-- |  1      |    0      |    0        |    0    | Read cache line                 |
-- +---------+-----------+-------------+---------+---------------------------------+
-- |  1      |    1      |    0        |    0    | Update cache line               |
-- +---------+-----------+-------------+---------+---------------------------------+
-- |  1      |    0      |    1        |    0    | Read cache line and discard it  |
-- +---------+-----------+-------------+---------+---------------------------------+
-- |  1      |    1      |    1        |    0    | Write cache line and discard it |
-- +---------+-----------+-------------+---------+---------------------------------+
-- |  0      |           |    0        |    1    | Replace cache line.             |
-- +---------+-----------+-------------+---------+---------------------------------+
--
-- All commands use ``Address`` to lookup (request) or replace a cache line.
-- ``Address`` and ``OldAddress`` do not include the word/byte select part.
-- Each command is completed within one clock cycle, but outputs are delayed as
-- described below.
--
-- Upon requests, the outputs ``CacheMiss`` and ``CacheHit`` indicate (high-active)
-- whether the ``Address`` is stored within the cache, or not. Both outputs have a
-- latency of one clock cycle.
--
-- Upon writing a cache line, the new content is given by ``CacheLineIn``.
-- Upon reading a cache line, the current content is outputed on ``CacheLineOut``
-- with a latency of one clock cycle.
--
-- Upon replacing a cache line, the new content is given by ``CacheLineIn``. The
-- old content is outputed on ``CacheLineOut`` and the old tag on ``OldAddress``,
-- both with a latency of one clock cycle.
--
-- .. WARNING::
--
--    If the design is synthesized with Xilinx ISE / XST, then the synthesis
--    option "Keep Hierarchy" must be set to SOFT or TRUE.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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


entity cache_par is
	generic (
		REPLACEMENT_POLICY : string		:= "LRU";
		CACHE_LINES				 : positive := 32;--1024;
		ASSOCIATIVITY			 : positive := 32;--4;
		ADDRESS_BITS			 : positive := 8; --32-6;
		DATA_BITS					 : positive := 8  --64*8
	);
	port (
		Clock : in std_logic;
		Reset : in std_logic;

		Request		 : in std_logic;
		ReadWrite	 : in std_logic;
		Invalidate : in std_logic;
		Replace 	 : in std_logic;
		Address		 : in std_logic_vector(ADDRESS_BITS - 1 downto 0);

		CacheLineIn	 : in	 std_logic_vector(DATA_BITS - 1 downto 0);
		CacheLineOut : out std_logic_vector(DATA_BITS - 1 downto 0);
		CacheHit		 : out std_logic := '0';
		CacheMiss		 : out std_logic := '0';
		OldAddress	 : out std_logic_vector(ADDRESS_BITS - 1 downto 0)
	);
end entity;


architecture rtl of cache_par is
	attribute KEEP : boolean;

	constant LINE_INDEX_BITS : positive := log2ceilnz(CACHE_LINES);

	subtype T_CACHE_LINE is std_logic_vector(DATA_BITS - 1 downto 0);
	type T_CACHE_LINE_VECTOR is array (natural range <>) of T_CACHE_LINE;

	-- look-up (request)
	signal TU_LineIndex : std_logic_vector(LINE_INDEX_BITS - 1 downto 0);
	signal TU_TagHit		: std_logic;
	signal TU_TagMiss		: std_logic;

	-- replace
	signal TU_ReplaceLineIndex : std_logic_vector(LINE_INDEX_BITS - 1 downto 0);
	signal TU_OldAddress			 : std_logic_vector(ADDRESS_BITS - 1 downto 0);

	signal MemoryIndex_us : unsigned(LINE_INDEX_BITS - 1 downto 0);
	signal CacheMemory		: T_CACHE_LINE_VECTOR(CACHE_LINES - 1 downto 0);

begin

	-- Cache TagUnit
	TU : entity PoC.cache_tagunit_par
		generic map (
			REPLACEMENT_POLICY => REPLACEMENT_POLICY,
			CACHE_LINES				 => CACHE_LINES,
			ASSOCIATIVITY			 => ASSOCIATIVITY,
			ADDRESS_BITS			 => ADDRESS_BITS
		)
		port map (
			Clock => Clock,
			Reset => Reset,

			Replace					 => Replace,
			ReplaceLineIndex => TU_ReplaceLineIndex,
			OldAddress			 => TU_OldAddress,

			Request		 => Request,
			ReadWrite	 => ReadWrite,
			Invalidate => Invalidate,
			Address		 => Address,
			LineIndex	 => TU_LineIndex,
			TagHit		 => TU_TagHit,
			TagMiss		 => TU_TagMiss
		);

	-- Address selector
	MemoryIndex_us <= unsigned(TU_LineIndex) when Request = '1' else
										unsigned(TU_ReplaceLineIndex);

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Request and TU_TagHit and ReadWrite) or Replace) = '1' then
				CacheMemory(to_integer(MemoryIndex_us)) <= CacheLineIn;
			end if;

			-- Single-port memory with read before write is required here.
			-- Cannot be mapped to `PoC.ocram_sdp`.
			CacheLineOut <= CacheMemory(to_integer(MemoryIndex_us));

			-- Control outputs have same latency as cache line data.
			if Reset = '1' then
				CacheMiss <= '0';
				CacheHit	<= '0';
			else
				CacheMiss <= TU_TagMiss;
				CacheHit	<= TU_TagHit;
			end if;

			OldAddress <= TU_OldAddress;
		end if;
	end process;
end architecture;
