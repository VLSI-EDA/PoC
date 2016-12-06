-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:         Patrick Lehmann
--
-- Package:         A parser for VCD files.
--
-- Description:
-- -------------------------------------
-- This function package parses *.VCD files and drives simulation stimulies.
--
-- * "VCD_ReadHeader" reads the file header.
-- * "VCD_ReadLine" reads a line from *.vcd file.
-- * "VCD_Read_StdLogic" parses a vcd one bit value to std_logic.
-- * "VCD_Read_StdLogicVector" parses a vcd N bit value to std_logic_vector with N bits.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
--                     Chair of VLSI-Design, Diagnostics and Architecture
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
--
library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.STD_LOGIC_TEXTIO.all;
use			IEEE.NUMERIC_STD.all;
use			STD.TEXTIO.all;

library PoC;
use			PoC.utils.all;
use			PoC.strings.all;


package sim_VCDParser is
	subtype T_VCDLINE		is		string(1 to 80);

	procedure VCD_ReadHeader(file VCDFile : TEXT; VCDLine : inout T_VCDLINE);
	procedure VCD_ReadLine(file VCDFile : TEXT; VCDLine : out string);

	procedure VCD_Read_StdLogic(VCDLine : string; signal sl : out std_logic; WaveName : string);
	procedure VCD_Read_StdLogicVector(VCDLine : string; signal slv : out std_logic_vector; WaveName : string; def : std_logic := '0');

end package;


package body sim_VCDParser is
	procedure VCD_ReadHeader(file VCDFile : TEXT; VCDLine : inout T_VCDLINE) is
	begin
		while not endfile(VCDFile) loop
			VCD_ReadLine(VCDFile, VCDLine);
			exit when (VCDLine(1) = '#');
		end loop;
	end procedure;

	procedure VCD_ReadLine(file VCDFile : TEXT; VCDLine : out string) is
		variable vcdFileLine	: LINE;
		variable char					: character;
		variable isString			: boolean;
	begin
		readline(VCDFile, vcdFileLine);

		-- clear VCDLine
		VCDLine := (VCDLine'range => C_POC_NUL);

		-- TODO: use imin of ranges, not 'range
		for i in VCDLine'range loop
			read(vcdFileLine, char, isString);
			exit when not isString;
			VCDLine(I)	:= char;
		end loop;
	end procedure;

	procedure VCD_Read_StdLogic(VCDLine : string; signal sl : out std_logic; WaveName : string) is
		constant length	: natural				:= str_length(VCDLine);
	begin
		if (str_equal(VCDLine(2 to length), WaveName)) then
			sl	<= to_sl(VCDLine(1));
		end if;
	end procedure;

	procedure VCD_Read_StdLogicVector(VCDLine : string; signal slv : out std_logic_vector; WaveName : string; def : std_logic := '0') is
		constant length	: natural				:= str_length(VCDLine);
		variable Result	: std_logic_vector(slv'range);
		variable k			: natural;
	begin
		Result	:= (others => def);
		k				:= 0;

		for i in 2 to length loop
			if not is_sl(VCDLine(i)) then
				k				:= i;
				exit;
			else
				Result := Result(Result'high - 1 downto Result'low) & to_sl(VCDLine(i));
			end if;
		end loop;

		if (str_equal(VCDLine(k + 1 to length), WaveName)) then
			slv				<= Result;
		end if;
	end procedure;
end package body;
