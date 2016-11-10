-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
-- 									Martin Zabel
--
-- Entity:					Wrap different cache replacement policies.
--
-- Description:
-- -------------------------------------
--
-- **Supported policies:**
--
-- +----------+-----------------------+-----------+
-- | Abbr.    | Policies              | supported |
-- +==========+=======================+===========+
-- | RR       | round robin           | not yet   |
-- +----------+-----------------------+-----------+
-- | RAND     | random                | not yet   |
-- +----------+-----------------------+-----------+
-- | CLOCK    | clock algorithm       | not yet   |
-- +----------+-----------------------+-----------+
-- | LRU      | least recently used   | YES       |
-- +----------+-----------------------+-----------+
-- | LFU      | least frequently used | not yet   |
-- +----------+-----------------------+-----------+
--
-- **Command thruth table:**
--
-- +-----------+-----------+-------------+---------+-----------------------------------------------------+
-- | TagAccess | ReadWrite | Invalidate  | Replace | Command                                             |
-- +===========+===========+=============+=========+=====================================================+
-- |  0        |           |             |    0    | None                                                |
-- +-----------+-----------+-------------+---------+-----------------------------------------------------+
-- |  1        |    0      |    0        |    0    | TagHit and reading a cache line                     |
-- +-----------+-----------+-------------+---------+-----------------------------------------------------+
-- |  1        |    1      |    0        |    0    | TagHit and writing a cache line                     |
-- +-----------+-----------+-------------+---------+-----------------------------------------------------+
-- |  1        |    0      |    1        |    0    | TagHit and invalidate a  cache line (while reading) |
-- +-----------+-----------+-------------+---------+-----------------------------------------------------+
-- |  1        |    1      |    1        |    0    | TagHit and invalidate a  cache line (while writing) |
-- +-----------+-----------+-------------+---------+-----------------------------------------------------+
-- |  0        |           |    0        |    1    | Replace cache line                                  |
-- +-----------+-----------+-------------+---------+-----------------------------------------------------+
--
-- In a set-associative cache, each cache-set has its own instance of this component.
--
-- The input ``HitWay`` specifies the accessed way in a fully-associative or
-- set-associative cache.
--
-- The output ``ReplaceWay`` identifies the way which will be replaced as next by
-- a replace command. In a set-associative cache, this is the way in a specific
-- cache set (see above).
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
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

library PoC;
use PoC.config.all;
use PoC.utils.all;
use PoC.vectors.all;
use PoC.strings.all;


entity cache_replacement_policy is
	generic (
		REPLACEMENT_POLICY : string		:= "LRU";
		CACHE_WAYS				 : positive := 32
	);
	port (
		Clock : in std_logic;
		Reset : in std_logic;

		-- replacement interface
		Replace		 : in	 std_logic;
		ReplaceWay : out std_logic_vector(log2ceilnz(CACHE_WAYS) - 1 downto 0);

		-- cacheline usage update interface
		TagAccess	 : in std_logic;
		ReadWrite	 : in std_logic;
		Invalidate : in std_logic;
		HitWay		 : in std_logic_vector(log2ceilnz(CACHE_WAYS) - 1 downto 0)
	);
end entity;


architecture rtl of cache_replacement_policy is
	attribute KEEP				 : boolean;
	attribute FSM_ENCODING : string;

	constant KEY_BITS : positive := log2ceilnz(CACHE_WAYS);

begin
	assert (str_equal(REPLACEMENT_POLICY, "RR") or
					str_equal(REPLACEMENT_POLICY, "LRU"))
		report "Unsupported replacement strategy"
		severity error;


	-- ===========================================================================
	-- policy: RR - round robin
	-- ===========================================================================
	genRR : if str_equal(REPLACEMENT_POLICY, "RR") generate
		constant VALID_BIT : natural := 0;

		subtype T_OPTION_LINE is std_logic_vector(0 downto 0);
		type T_OPTION_LINE_VECTOR is array (natural range <>) of T_OPTION_LINE;

		signal OptionMemory : T_OPTION_LINE_VECTOR(CACHE_WAYS - 1 downto 0) := (others => (
			VALID_BIT																																			=> '0')
																																						 );

		signal ValidHit		: std_logic;
		signal Pointer_us : unsigned(log2ceilnz(CACHE_WAYS) - 1 downto 0) := (others => '0');

	begin
--		ValidHit		<= OptionMemory(to_integer(unsigned(HitWay)))(VALID_BIT);
--		IsValid			<= ValidHit;
--
--		process(Clock)
--		begin
--			if rising_edge(Clock) then
--				if (Reset = '1') then
--					for i in 0 to CACHE_WAYS - 1 loop
--						OptionMemory(I)(VALID_BIT)	<= '0';
--					end loop;
--				else
--					if (Insert = '1') then
--						OptionMemory(to_integer(Pointer_us))(VALID_BIT) <= '1';
--					end if;
--
--					if (Invalidate = '1') then
--						OptionMemory(to_integer(unsigned(HitWay)))(VALID_BIT)			<= '0';
--					end if;
--				end if;
--			end if;
--		end process;
--
--		Replace				<= Insert;
--		ReplaceWay		<= std_logic_vector(Pointer_us);
--
--		process(Clock)
--		begin
--			if rising_edge(Clock) then
--				if (Reset = '1') then
--					Pointer_us		<= (others => '0');
--				else
--					if (Insert = '1') then
--						Pointer_us	<= Pointer_us + 1;
--					end if;
--				end if;
--			end if;
--		end process;
	end generate;

	-- ===========================================================================
	-- policy: LRU - least recently used
	-- ===========================================================================
	genLRU : if str_equal(REPLACEMENT_POLICY, "LRU") generate
		signal LRU_Insert			: std_logic;
		signal LRU_Invalidate : std_logic;
		signal KeyIn					: std_logic_vector(log2ceilnz(CACHE_WAYS) - 1 downto 0);
		signal LRU_Key				: std_logic_vector(log2ceilnz(CACHE_WAYS) - 1 downto 0);

	begin
		-- Command Decoding
		LRU_Insert		 <= (TagAccess and not Invalidate) or Replace;
		LRU_Invalidate <= TagAccess and Invalidate;

		KeyIn <= LRU_Key when Replace = '1' else HitWay;

		-- Output
		ReplaceWay <= LRU_Key;

		LRU : entity PoC.sort_lru_cache
			generic map (
				ELEMENTS => CACHE_WAYS
			)
			port map (
				Clock => Clock,
				Reset => Reset,

				Insert => LRU_Insert,
				Free	 => LRU_Invalidate,
				KeyIn	 => KeyIn,

				KeyOut => LRU_Key
			);
	end generate;
end architecture;
