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

library UNISIM;
-- use			UNISIM.VCOMPONENTS.all;

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.components.all;


entity sort_LeastRecentlyUsed is
	generic (
		ELEMENTS									: POSITIVE												:= 32;
		KEY_BITS									: POSITIVE												:= 5;
		DATA_BITS									: POSITIVE												:= 5;
		INITIAL_ELEMENTS					:	T_SLM														:= (0 to 31 => (0 to 4 => '0'));
		INITIAL_VALIDS						: STD_LOGIC_VECTOR								:= (0 to 31 => '0')
	);
	port (
		Clock											: in	STD_LOGIC;
		Reset											: in	STD_LOGIC;
		
		Insert										: in	STD_LOGIC;
		Invalidate								: in	STD_LOGIC;
		KeyIn											: in	STD_LOGIC_VECTOR(KEY_BITS - 1 downto 0);
		
		Valid											: out	STD_LOGIC;
		LRU_Element								: out	STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);
		
		DBG_Elements							: out	T_SLM(ELEMENTS - 1 downto 0, DATA_BITS - 1 downto 0);
		DBG_Valids								: out STD_LOGIC_VECTOR(ELEMENTS - 1 downto 0)
	);
end entity;


architecture rtl of sort_LeastRecentlyUsed is
	subtype T_ELEMENT			is STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);
	type T_ELEMENT_VECTOR	is array (NATURAL range <>) OF T_ELEMENT;
	
	signal NewElementsUp	: T_ELEMENT_VECTOR(ELEMENTS downto 0);
	
	signal ElementsUp			: T_ELEMENT_VECTOR(ELEMENTS downto 0);
	signal ElementsDown		: T_ELEMENT_VECTOR(ELEMENTS downto 0);
	signal ValidsUp				: STD_LOGIC_VECTOR(ELEMENTS downto 0);
	signal ValidsDown			: STD_LOGIC_VECTOR(ELEMENTS downto 0);
	
	signal MovesDown			: STD_LOGIC_VECTOR(ELEMENTS downto 0);
	signal MovesUp				: STD_LOGIC_VECTOR(ELEMENTS downto 0);
	
	signal DBG_Elements_i	: T_SLM(ELEMENTS - 1 downto 0, DATA_BITS - 1 downto 0)			:= (others => (others => 'Z'));
	
begin
	-- next element (top)
	ElementsDown(ELEMENTS)	<= NewElementsUp(ELEMENTS);
	ValidsDown(ELEMENTS)		<= '1';
	
	MovesDown(ELEMENTS)			<= Insert;
	
	-- current element
	genElements : for i in ELEMENTS - 1 downto 0 generate
		constant INITIAL_ELEMENT	: STD_LOGIC_VECTOR(KEY_BITS - 1 downto 0)					:= get_row(INITIAL_ELEMENTS, i);
		constant INITIAL_VALID		: STD_LOGIC																				:= INITIAL_VALIDS(i);

		signal Element_nxt				: STD_LOGIC_VECTOR(KEY_BITS - 1 downto 0);
		signal Element_d					: STD_LOGIC_VECTOR(KEY_BITS - 1 downto 0)					:= INITIAL_ELEMENT;
		signal Valid_nxt					: STD_LOGIC;
		signal Valid_d						: STD_LOGIC																				:= INITIAL_VALID;
		
		signal Unequal						: STD_LOGIC;
		signal MoveDown						: STD_LOGIC;
		signal MoveUp							: STD_LOGIC;
		
	begin
		-- local movements
		Unequal				<= to_sl(Element_d(KEY_BITS - 1 downto 0) /= NewElementsUp(i)(KEY_BITS - 1 downto 0));
		
		genXilinx : IF (VENDOR = VENDOR_XILINX) GENERATE
			component MUXCY
				port (
					O			: out	STD_ULOGIC;
					CI		: in	STD_ULOGIC;
					DI		: in	STD_ULOGIC;
					S			: in	STD_ULOGIC
				);
			end component;
		begin
			a : MUXCY
				port map (
					S		=> Unequal,
					CI	=> MovesDown(i + 1),
					DI	=> '0',
					O		=> MovesDown(i)
				);

			b : MUXCY
				port map (
					S		=> Unequal,
					CI	=> MovesUp(i),
					DI	=> '0',
					O		=> MovesUp(i + 1)
				);
		end generate;
		
		-- movements for the current element	
		MoveDown		<= MovesDown(i + 1);
		MoveUp			<= MovesUp(i);
		
		-- passthrought all new
		NewElementsUp(i + 1)	<= NewElementsUp(i);
		
		ElementsUp(i + 1)			<= Element_d;
		ValidsUp(i + 1)				<= Valid_d;
		
		-- multiplexer
		Element_nxt	<= mux(MoveDown, mux(MoveUp,	Element_d,	ElementsUp(i)),	ElementsDown(i + 1));
		Valid_nxt		<= mux(MoveDown, mux(MoveUp,	Valid_d,		ValidsUp(i)	 ),	ValidsDown(i + 1)	 );
		
		Element_d		<= ffdre(q => Element_d,	d => Element_nxt,	rst => Reset, INIT => INITIAL_ELEMENT)	when rising_edge(Clock);
		Valid_d			<= ffdre(q => Valid_d,		d => Valid_nxt,		rst => Reset, INIT => INITIAL_VALID)  	when rising_edge(Clock);
		
		ElementsDown(i)		<= Element_d;
		ValidsDown(i)			<= Valid_d;
		
		assign_row(DBG_Elements_i, Element_d, i);
		
		DBG_Valids(i)			<= Valid_d;
	end generate;

	-- previous element (buttom)
	NewElementsUp(0)		<= KeyIn;
	MovesUp(0)					<= Invalidate;
	ElementsUp(0)				<= KeyIn;
	ValidsUp(0)					<= '0';
	
	LRU_Element					<= ElementsDown(0);
	Valid								<= ValidsDown(0);

	DBG_Elements				<= DBG_Elements_i;
end architecture;
