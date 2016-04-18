-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:					Patrick Lehmann
-- 
-- Package:					VHDL package for component declarations, types and
--									functions associated to the PoC.io.pmod namespace
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


package pmod is
	type T_PMOD_KYPD_KEYPAD is record
		Key0	: STD_LOGIC;
		Key1	: STD_LOGIC;
		Key2	: STD_LOGIC;
		Key3	: STD_LOGIC;
		Key4	: STD_LOGIC;
		Key5	: STD_LOGIC;
		Key6	: STD_LOGIC;
		Key7	: STD_LOGIC;
		Key8	: STD_LOGIC;
		Key9	: STD_LOGIC;
		KeyA	: STD_LOGIC;
		KeyB	: STD_LOGIC;
		KeyC	: STD_LOGIC;
		KeyD	: STD_LOGIC;
		KeyE	: STD_LOGIC;
		KeyF	: STD_LOGIC;
	end record;

	type T_PMOD_SSD_PINS is record
		AnodeA	: STD_LOGIC;
		AnodeB	: STD_LOGIC;
		AnodeC	: STD_LOGIC;
		AnodeD	: STD_LOGIC;
		AnodeE	: STD_LOGIC;
		AnodeF	: STD_LOGIC;
		AnodeG	: STD_LOGIC;
		Cathode	: STD_LOGIC;
	end record;
end package;


package body pmod is


end package body;
