-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:					Martin Zabel
--									Patrick Lehmann
-- 
-- Package:					VHDL package for component declarations, types and
--									functions associated to the PoC.io.ddrio namespace
--
-- Description:
-- ------------------------------------
--		For detailed documentation see below.
--
-- License:
-- ============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany,
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

library	IEEE;
use			IEEE.std_logic_1164.ALL;


package ddrio is
  component ddrio_in is
		generic (
			INIT_VALUES	: BIT_VECTOR		:= ('1', '1');
			WIDTH				: positive
		);
		port (
			clk		: in	std_logic;
			ce		: in	std_logic;
			i			: in	std_logic_vector(WIDTH-1 downto 0);
			dh		: out	std_logic_vector(WIDTH-1 downto 0);
			dl		: out	std_logic_vector(WIDTH-1 downto 0)
		);
	end component;

  component ddrio_out is
		generic (
			NO_OE				: boolean		:= false;
			INIT_VALUE	: BIT				:= '1';
			WIDTH				: positive
		);
		port (
			clk		: in	std_logic;
			ce		: in	std_logic;
			dh		: in	std_logic_vector(WIDTH-1 downto 0);
			dl		: in	std_logic_vector(WIDTH-1 downto 0);
			oe		: in	std_logic;
			q			: out	std_logic_vector(WIDTH-1 downto 0)
		);
	end component;
	
	component ddrio_in_xilinx is
		generic (
			INIT_VALUES	: BIT_VECTOR			:= ('1', '1');
			WIDTH				: positive
		);
		port (
			clk		: in	std_logic;
			ce		: in	std_logic;
			i			: in	std_logic_vector(WIDTH-1 downto 0);
			dh		: out	std_logic_vector(WIDTH-1 downto 0);
			dl		: out	std_logic_vector(WIDTH-1 downto 0)
		);
	end component;
	
	component ddrio_out_xilinx is
		generic (
			NO_OE				: boolean		:= false;
			INIT_VALUE	: BIT				:= '1';
			WIDTH				: positive
		);
		port (
			clk		: in	std_logic;
			ce		: in	std_logic;
			dh		: in	std_logic_vector(WIDTH-1 downto 0);
			dl		: in	std_logic_vector(WIDTH-1 downto 0);
			oe		: in	std_logic;
			q			: out	std_logic_vector(WIDTH-1 downto 0)
		);
	end component;
	
	component ddrio_out_altera is
		generic (
			INIT_VALUE	: BIT				:= '1';
			WIDTH				: positive
		);
		port (
			clk		: in	std_logic;
			ce		: in	std_logic;
			dh		: in	std_logic_vector(WIDTH-1 downto 0);
			dl		: in	std_logic_vector(WIDTH-1 downto 0);
			oe		: in	std_logic;
			q			: out	std_logic_vector(WIDTH-1 downto 0)
		);
	end component;
end package;


package body ddrio is

end package body;
