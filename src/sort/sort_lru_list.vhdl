-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:          Patrick Lehmann
--                   Martin Zabel
--
-- Entity:           List storing key-value pairs in recently-used order.
--
-- Description:
-- -------------------------------------
-- List storing ``(key, value)`` pairs. The least-recently inserted pair is
-- outputed on ``DataOut`` if ``Valid = '1'``. If ``Valid = '0'``, then the list
-- empty.
--
-- The inputs ``Insert``, ``Remove``, ``DataIn``, and ``Reset`` are synchronous
-- to the rising-edge of the clock ``clock``. All control signals are high-active.
--
-- Supported operations:
--  * **Insert:** Insert ``DataIn`` as  recently used ``(key, value)`` pair. If
--    key is already within the list, then the corresponding value is updated and
--    the pair is moved to the recently used position.
--  * **Remove:** Remove ``(key, value)`` pair with the given key. The list is not
--    modified if key is not within the list.
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
use			PoC.components.all;


entity sort_lru_list is
	generic (
		ELEMENTS									: positive												:= 16;
		KEY_BITS									: positive												:= 4;
		DATA_BITS									: positive												:= 8;
		INITIAL_ELEMENTS					:	T_SLM														:= (0 to 15 => (0 to 7 => '0'));
		INITIAL_VALIDS						: std_logic_vector								:= (0 to 15 => '0')
	);
	port (
		Clock											: in	std_logic;
		Reset											: in	std_logic;

		Insert										: in	std_logic;
		Remove										: in	std_logic;
		DataIn										: in	std_logic_vector(DATA_BITS - 1 downto 0);

		Valid											: out	std_logic;
		DataOut										: out	std_logic_vector(DATA_BITS - 1 downto 0)
	);
end entity;


architecture rtl of sort_lru_list is
	subtype T_ELEMENT			is std_logic_vector(DATA_BITS - 1 downto 0);
	type T_ELEMENT_VECTOR	is array (natural range <>) of T_ELEMENT;

	signal NewElementsUp	: T_ELEMENT_VECTOR(ELEMENTS downto 0);

	signal ElementsUp			: T_ELEMENT_VECTOR(ELEMENTS downto 0);
	signal ElementsDown		: T_ELEMENT_VECTOR(ELEMENTS downto 0);
	signal ValidsUp				: std_logic_vector(ELEMENTS downto 0);
	signal ValidsDown			: std_logic_vector(ELEMENTS downto 0);

	signal Unequal				: std_logic_vector(ELEMENTS-1 downto 0);

	signal MovesDown			: std_logic_vector(ELEMENTS downto 0);
	signal MovesUp				: std_logic_vector(ELEMENTS downto 0);

	signal DataOutDown 		: T_ELEMENT_VECTOR(ELEMENTS downto 0);

  signal MovesUpCond   		: std_logic_vector(ELEMENTS downto 0);
  signal MovesDownCond 		: std_logic_vector(ELEMENTS downto 0);
  signal MovesDownCondRev : std_logic_vector(ELEMENTS downto 0);
  signal MovesDownRev 		: std_logic_vector(ELEMENTS downto 0);

begin
	-- next element (top)
	ElementsDown(ELEMENTS)	<= NewElementsUp(ELEMENTS);
	ValidsDown(ELEMENTS)		<= '1';

	MovesDownCond(ELEMENTS) <= Insert;

	DataOutDown(ELEMENTS) 	<= (others => '-');

	-- current element
	genElements : for i in ELEMENTS - 1 downto 0 generate
		constant INITIAL_ELEMENT	: std_logic_vector(DATA_BITS - 1 downto 0)					:= get_row(INITIAL_ELEMENTS, I);
		constant INITIAL_VALID		: std_logic																				:= INITIAL_VALIDS(I);

		signal Element_nxt				: std_logic_vector(DATA_BITS - 1 downto 0);
		signal Element_d					: std_logic_vector(DATA_BITS - 1 downto 0)					:= INITIAL_ELEMENT;
		signal Valid_nxt					: std_logic;
		signal Valid_d						: std_logic																				:= INITIAL_VALID;

		signal MoveDown						: std_logic;
		signal MoveUp							: std_logic;

	begin
		-- local movements
		Unequal(I)				<= not Valid_d or to_sl(Element_d(KEY_BITS - 1 downto 0) /= NewElementsUp(I)(KEY_BITS - 1 downto 0));

		-- movements for the current element
		MoveDown		<= MovesDown(I + 1);
		MoveUp			<= MovesUp(I);

		-- passthrought all new
		NewElementsUp(I + 1)	<= NewElementsUp(I);

		ElementsUp(I + 1)			<= Element_d;
		ValidsUp(I + 1)				<= Valid_d;

		-- multiplexer
		Element_nxt	<= mux(MoveDown, mux(MoveUp,	Element_d,	ElementsUp(I)),	ElementsDown(I + 1));
		Valid_nxt		<= mux(MoveDown, mux(MoveUp,	Valid_d,		ValidsUp(I)	 ),	ValidsDown(I + 1)	 );

		Element_d		<= ffdre(q => Element_d,	d => Element_nxt,	rst => Reset, INIT => INITIAL_ELEMENT)	when rising_edge(Clock);
		Valid_d			<= ffdre(q => Valid_d,		d => Valid_nxt,		rst => Reset, INIT => INITIAL_VALID)  	when rising_edge(Clock);

		ElementsDown(I)		<= Element_d;
		ValidsDown(I)			<= Valid_d;

		-- not very efficient :-(
		DataOutDown(I)  <= Element_d when Valid_d = '1' else DataOutDown(I+1);
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

	-- previous element (buttom)
	NewElementsUp(0)		<= DataIn;
	MovesUpCond(0)      <= Remove and slv_nand(Unequal);
	ElementsUp(0)				<= DataIn;
	ValidsUp(0)					<= '0';

	DataOut							<= DataOutDown(0);
	Valid								<= slv_or(ValidsDown(ELEMENTS-1 downto 0));
end architecture;
