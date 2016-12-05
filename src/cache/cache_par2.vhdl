-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:         Martin Zabel
--                  Patrick Lehmann
--
-- Entity:          Cache with parallel tag-unit and data memory.
--
-- Description:
-- -------------------------------------
-- Cache with parallel tag-unit and data memory. For the data memory,
-- :ref:`IP:ocram_sp` is used.
--
-- Configuration
-- *************
--
-- +--------------------+----------------------------------------------------+
-- | Parameter          | Description                                        |
-- +====================+====================================================+
-- | REPLACEMENT_POLICY | Replacement policy. For supported policies see     |
-- |                    | PoC.cache_replacement_policy.                      |
-- +--------------------+----------------------------------------------------+
-- | CACHE_LINES        | Number of cache lines.                             |
-- +--------------------+----------------------------------------------------+
-- | ASSOCIATIVITY      | Associativity of the cache.                        |
-- +--------------------+----------------------------------------------------+
-- | ADDR_BITS          | Number of address bits. Each address identifies    |
-- |                    | exactly one cache line in memory.                  |
-- +--------------------+----------------------------------------------------+
-- | DATA_BITS          | Size of a cache line in bits.                      |
-- |                    | DATA_BITS must be divisible by 8.                  |
-- +--------------------+----------------------------------------------------+
--
--
-- Command truth table
-- *******************
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
-- |  0      |    0      |    0        |    1    | Read cache line before replace. |
-- +---------+-----------+-------------+---------+---------------------------------+
-- |  0      |    1      |    0        |    1    | Replace cache line.             |
-- +---------+-----------+-------------+---------+---------------------------------+
--
--
-- Operation
-- *********
--
-- All inputs are synchronous to the rising-edge of the clock `clock`.
--
-- All commands use ``Address`` to lookup (request) or replace a cache line.
-- ``Address`` and ``OldAddress`` do not include the word/byte select part.
-- Each command is completed within one clock cycle, but outputs are delayed as
-- described below.
--
-- Upon requests, the outputs ``CacheMiss`` and ``CacheHit`` indicate (high-active)
-- whether the ``Address`` is stored within the cache, or not. Both outputs have a
-- latency of one clock cycle (pipelined) if ``HIT_MISS_REG`` is true, otherwise the
-- result is outputted immediately (combinational).
--
-- Upon writing a cache line, the new content is given by ``CacheLineIn``.
-- Only the bytes which are not masked, i.e. the corresponding bit in WriteMask
-- is '0', are actually written.
--
-- Upon reading a cache line, the current content is outputed on ``CacheLineOut``
-- with a latency of one clock cycle.
--
-- Replacing a cache line requires two steps, both with ``Replace = '1'``:
--
-- 1. Read old contents of cache line by setting ``ReadWrite`` to '0'. The old
--    content is outputed on ``CacheLineOut`` and the old tag on ``OldAddress``,
--    both with a latency of one clock cycle.
--
-- 2. Write new cache line by setting ``ReadWrite`` to '1'. The new content is
--    given by ``CacheLineIn``. All bytes shall be written, i.e.
--    ``WriteMask = 0``. The new cache line content will be outputed
--    again on ``CacheLineOut`` in the next clock cycle (latency = 1).
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


entity cache_par2 is
	generic (
		REPLACEMENT_POLICY : string		:= "LRU";
		CACHE_LINES				 : positive := 32;
		ASSOCIATIVITY			 : positive := 32;
		ADDR_BITS					 : positive := 8;
		DATA_BITS					 : positive := 8;
		HIT_MISS_REG			 : boolean	:= true	 -- must be true for Cocotb.
	);
	port (
		Clock : in std_logic;
		Reset : in std_logic;

		Request		 : in std_logic;
		ReadWrite	 : in std_logic;
		WriteMask  : in std_logic_vector(DATA_BITS/8 - 1 downto 0) := (others => '0');
		Invalidate : in std_logic;
		Replace		 : in std_logic;
		Address		 : in std_logic_vector(ADDR_BITS-1 downto 0);

		CacheLineIn	 : in	 std_logic_vector(DATA_BITS - 1 downto 0);
		CacheLineOut : out std_logic_vector(DATA_BITS - 1 downto 0);
		CacheHit		 : out std_logic := '0';
		CacheMiss		 : out std_logic := '0';
		OldAddress	 : out std_logic_vector(ADDR_BITS-1 downto 0)
	);
end entity;


architecture rtl of cache_par2 is
	attribute KEEP : boolean;

	constant LINE_INDEX_BITS : positive := log2ceilnz(CACHE_LINES);

	subtype T_CACHE_LINE is std_logic_vector(DATA_BITS - 1 downto 0);
	type T_CACHE_LINE_VECTOR is array (natural range <>) of T_CACHE_LINE;

	-- look-up (request)
	signal TU_LineIndex : std_logic_vector(LINE_INDEX_BITS - 1 downto 0);
	signal TU_TagHit		: std_logic;
	signal TU_TagMiss		: std_logic;

  -- replace
  signal ReplaceWrite        : std_logic;
  signal TU_ReplaceLineIndex : std_logic_vector(LINE_INDEX_BITS - 1 downto 0);
  signal TU_OldAddress       : std_logic_vector(OldAddress'range);

	-- data memory
	signal MemoryIndex_us : unsigned(LINE_INDEX_BITS - 1 downto 0);
	signal MemoryAccess   : std_logic;

begin

	ReplaceWrite <= Replace and ReadWrite;

	-- Cache TagUnit
	TU : entity PoC.cache_tagunit_par
		generic map (
			REPLACEMENT_POLICY => REPLACEMENT_POLICY,
			CACHE_LINES				 => CACHE_LINES,
			ASSOCIATIVITY			 => ASSOCIATIVITY,
			ADDRESS_BITS			 => ADDR_BITS
		)
		port map (
			Clock => Clock,
			Reset => Reset,

			Replace					 => ReplaceWrite,
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

	MemoryAccess <= (Request and TU_TagHit) or Replace;

	-- Data Memory
	gLane: for i in 0 to DATA_BITS/8 - 1 generate
		signal we : std_logic;
	begin
		we <= ReadWrite and not WriteMask(i);

		data_mem: entity work.ocram_sp
			generic map (
				A_BITS   => LINE_INDEX_BITS,
				D_BITS   => 8, -- 8 bit per lane
				FILENAME => "")
			port map (
				clk => Clock,
				ce  => MemoryAccess,
				we  => we,
				a   => MemoryIndex_us,
				d   => CacheLineIn (i*8+7 downto i*8),
				q   => CacheLineOut(i*8+7 downto i*8));
	end generate gLane;

	-- Hit / Miss
	gNoHitMissReg: if not HIT_MISS_REG generate
		CacheMiss <= TU_TagMiss;
		CacheHit	<= TU_TagHit;
	end generate gNoHitMissReg;

	gHitMissReg: if HIT_MISS_REG generate	-- Pipelined outputs.
		process(Clock)
		begin
			if rising_edge(Clock) then
				if Reset = '1' then
					CacheMiss <= '0';
					CacheHit	<= '0';
				else
					CacheMiss <= TU_TagMiss;
					CacheHit	<= TU_TagHit;
				end if;
			end if;
		end process;
	end generate gHitMissReg;

	-- Same latency as CacheLineOut
	OldAddress <= TU_OldAddress when rising_edge(Clock);

end architecture;
