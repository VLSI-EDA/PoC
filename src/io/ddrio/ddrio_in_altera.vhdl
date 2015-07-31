-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:					Martin Zabel
--									Patrick Lehmann
-- 
-- Module:					Instantiates Chip-Specific DDR Input Registers for Altera FPGAs.
--
-- Description:
-- ------------------------------------
--	See PoC.io.ddrio.in for interface description.
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
use			IEEE.std_logic_1164.ALL;

library	Altera_mf;
use			Altera_mf.Altera_MF_Components.all;


entity ddrio_in_xilinx is
	generic (
		BITS						: POSITIVE;
		INIT_VALUE_HIGH	: BIT_VECTOR	:= "1";
		INIT_VALUE_LOW	: BIT_VECTOR	:= "1"
	);
	port (
		Clock					: in	STD_LOGIC;
		ClockEnable		: in	STD_LOGIC;
		DataIn_high		: out	STD_LOGIC_VECTOR(BITS - 1 downto 0);
		DataIn_low		: out	STD_LOGIC_VECTOR(BITS - 1 downto 0);
		Pad						: in	STD_LOGIC_VECTOR(BITS - 1 downto 0)
	);
end entity;


architecture rtl of ddrio_in_xilinx is

begin
	iff : altddio_in
		generic map (
			WIDTH										=> BITS,
			INTENDED_DEVICE_FAMILY	=> "STRATIXII"		-- TODO: built device string from PoC.config information
		)
		port map (
			inclock			=> Clock,
			inclocken		=> ClockEnable,
			dataout_h		=> DataIn_high,
			dataout_l		=> DataIn_low,
			datain			=> Pad
		);
end architecture;
