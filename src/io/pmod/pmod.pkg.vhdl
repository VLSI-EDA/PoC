-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Package:					VHDL package for component declarations, types and
--									functions associated to the PoC.io.pmod namespace
--
-- Description:
-- -------------------------------------
--		For detailed documentation see below.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany,
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


package pmod is
	type T_PMOD_KYPD_KEYPAD is record
		Key0	: std_logic;
		Key1	: std_logic;
		Key2	: std_logic;
		Key3	: std_logic;
		Key4	: std_logic;
		Key5	: std_logic;
		Key6	: std_logic;
		Key7	: std_logic;
		Key8	: std_logic;
		Key9	: std_logic;
		KeyA	: std_logic;
		KeyB	: std_logic;
		KeyC	: std_logic;
		KeyD	: std_logic;
		KeyE	: std_logic;
		KeyF	: std_logic;
	end record;

	type T_PMOD_SSD_PINS is record
		AnodeA	: std_logic;
		AnodeB	: std_logic;
		AnodeC	: std_logic;
		AnodeD	: std_logic;
		AnodeE	: std_logic;
		AnodeF	: std_logic;
		AnodeG	: std_logic;
		Cathode	: std_logic;
	end record;
end package;


package body pmod is


end package body;
