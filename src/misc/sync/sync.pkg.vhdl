-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:					Patrick Lehmann
-- 
-- Package:					VHDL package for component declarations, types and
--									functions associated to the PoC.misc.sync namespace
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

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.utils.all;
use			PoC.physical.all;


package sync is
	component sync_Bits is
		generic (
			BITS					: POSITIVE						:= 1;									-- number of bit to be synchronized
			INIT					: STD_LOGIC_VECTOR		:= x"00000000"				-- initialitation bits
		);
		port (
			Clock					: in	STD_LOGIC;														-- <Clock>	output clock domain
			Input					: in	STD_LOGIC_VECTOR(BITS - 1 downto 0);	-- @async:	input bits
			Output				: out STD_LOGIC_VECTOR(BITS - 1 downto 0)		-- @Clock:	output bits
		);
	end component;

	component sync_Bits_Altera is
		generic (
			BITS					: POSITIVE						:= 1;									-- number of bit to be synchronized
			INIT					: STD_LOGIC_VECTOR		:= x"00000000"				-- initialitation bits
		);
		port (
			Clock					: in	STD_LOGIC;														-- Clock to be synchronized to
			Input					: in	STD_LOGIC_VECTOR(BITS - 1 downto 0);	-- Data to be synchronized
			Output				: out	STD_LOGIC_VECTOR(BITS - 1 downto 0)		-- synchronised data
		);
	end component;

	component sync_Bits_Xilinx is
		generic (
			BITS					: POSITIVE						:= 1;									-- number of bit to be synchronized
			INIT					: STD_LOGIC_VECTOR		:= x"00000000"				-- initialitation bits
		);
		port (
			Clock					: in	STD_LOGIC;														-- Clock to be synchronized to
			Input					: in	STD_LOGIC_VECTOR(BITS - 1 downto 0);	-- Data to be synchronized
			Output				: out	STD_LOGIC_VECTOR(BITS - 1 downto 0)		-- synchronised data
		);
	end component;

	component sync_Reset is
		port (
			Clock			: in	STD_LOGIC;				-- <Clock>	output clock domain
			Input			: in	STD_LOGIC;				-- @async:	reset input
			Output		: out STD_LOGIC					-- @Clock:	reset output
		);
	end component;

	component sync_Reset_Altera is
		port (
			Clock					: in	STD_LOGIC;		-- Clock to be synchronized to
			Input					: in	STD_LOGIC;		-- Data to be synchronized
			Output				: out	STD_LOGIC			-- synchronised data
		);
	end component;

	component sync_Reset_Xilinx is
		port (
			Clock				: in	STD_LOGIC;			-- Clock to be synchronized to
			Input				: in	STD_LOGIC;			-- high active asynchronous reset
			Output			: out	STD_LOGIC				-- "Synchronised" reset signal
		);
	end component;

end package;


package body sync is

end package body;
