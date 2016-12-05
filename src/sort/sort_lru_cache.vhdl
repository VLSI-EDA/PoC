-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:         Patrick Lehmann
--                  Martin Zabel
--
-- Entity:          Optimized LRU list implementation for Caches.
--
-- Description:
-- -------------------------------------
-- This is an optimized implementation of ``sort_lru_list`` to be used for caches.
-- Only keys are stored within this list, and these keys are the index of the
-- cache lines. The list initially contains all indizes from 0 to ELEMENTS-1.
-- The least-recently used index ``KeyOut`` is always valid.
--
-- The first outputed least-recently used index will be ELEMENTS-1.
--
-- The inputs ``Insert``, ``Free``, ``KeyIn``, and ``Reset`` are synchronous to the
-- rising-edge of the clock ``clock``. All control signals are high-active.
--
-- Supported operations:
--  * **Insert:** Mark index ``KeyIn`` as recently used, e.g., when a cache-line
--    was accessed.
--  * **Free:** Mark index ``KeyIn`` as least-recently used. Apply this operation,
--    when a cache-line gets invalidated.
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
use PoC.components.all;

entity sort_lru_cache is
	generic (
		ELEMENTS			 : positive					:= 32
	);
	port (
		Clock 	: in std_logic;
		Reset 	: in std_logic;

		Insert 	: in  std_logic;
		Free 		: in  std_logic;
		KeyIn	 	: in  std_logic_vector(log2ceilnz(ELEMENTS) - 1 downto 0);

		KeyOut 	: out std_logic_vector(log2ceilnz(ELEMENTS) - 1 downto 0)
	);
end entity;


architecture rtl of sort_lru_cache is
	constant KEY_BITS : positive := log2ceilnz(ELEMENTS);

	subtype T_ELEMENT is std_logic_vector(KEY_BITS - 1 downto 0);
	type T_ELEMENT_VECTOR is array (natural range <>) of T_ELEMENT;

	signal NewElement    : T_ELEMENT;

	signal ElementsUp			: T_ELEMENT_VECTOR(ELEMENTS downto 0);
	signal ElementsDown		: T_ELEMENT_VECTOR(ELEMENTS downto 0);

	signal MovesDown : std_logic_vector(ELEMENTS downto 0);
	signal MovesUp	 : std_logic_vector(ELEMENTS downto 0);
	signal UnEqual	 : std_logic_vector(ELEMENTS-1 downto 0);

  signal MovesUpCond   		: std_logic_vector(ELEMENTS downto 0);
  signal MovesDownCond 		: std_logic_vector(ELEMENTS downto 0);
  signal MovesDownCondRev : std_logic_vector(ELEMENTS downto 0);
  signal MovesDownRev 		: std_logic_vector(ELEMENTS downto 0);

begin
	-- next element (top)
	ElementsDown(ELEMENTS) 	<= NewElement;
	MovesDownCond(ELEMENTS) <= Insert;

	-- current element
	genElements : for I in ELEMENTS - 1 downto 0 generate
		constant INITIAL_ELEMENT : std_logic_vector(KEY_BITS - 1 downto 0) := std_logic_vector(to_unsigned(ELEMENTS-1 - i, KEY_BITS));
		signal Element_nxt	 : std_logic_vector(KEY_BITS - 1 downto 0);
		signal Element_d		 : std_logic_vector(KEY_BITS - 1 downto 0) := INITIAL_ELEMENT;

		signal MoveDown : std_logic;
		signal MoveUp		: std_logic;

	begin
		-- local movements
		UnEqual(i) <= to_sl(Element_d /= NewElement);

		ElementsUp(I + 1)    <= Element_d;

		-- multiplexer
		Element_nxt	<= mux(MovesDown(I+1), mux(MovesUp(i), Element_d, ElementsUp(I)), ElementsDown(I + 1));

		-- register
		Element_d		<= ffdre(q => Element_d,	d => Element_nxt,	rst => Reset, INIT => INITIAL_ELEMENT)	when rising_edge(Clock);

		ElementsDown(I)		<= Element_d;
	end generate;

	-- MovesUp / MovesDown propagation
	MovesUpCond  (ELEMENTS   downto 1) <= UnEqual;
	MovesDownCond(ELEMENTS-1 downto 0) <= UnEqual;
	MovesDownCondRev <= reverse(MovesDownCond);
	MovesDown        <= reverse(MovesDownRev);

	MovesUpProp: entity poc.arith_prefix_and
		generic map (
			N => ELEMENTS+1)
		port map (
			-- Individual association of 'x' didn't work in QuestaSim
			x => MovesUpCond,
			y => MovesUp);

	MovesDownProp: entity poc.arith_prefix_and
		generic map (
			N => ELEMENTS+1)
		port map (
			-- Individual association of 'x' didn't work in QuestaSim
			x => MovesDownCondRev,
			y => MovesDownRev);

	-- previous element (bottom)
	NewElement        <= KeyIn;
	ElementsUp(0)	 		<= KeyIn;
	MovesUpCond(0) 		<= Free;


	KeyOut <= ElementsDown(0);
end architecture;
