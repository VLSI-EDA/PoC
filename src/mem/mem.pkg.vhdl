-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Martin Zabel
--									Patrick Lehmann
-- 
-- Package:				 	VHDL package for component declarations, types and functions
--									associated to the PoC.mem.ocram namespace
--
-- Description:
-- ------------------------------------
--		On-Chip RAMs (Random-Access-Memory/Read-Write-Memory - RWM) for FPGAs.
--
--		A detailed documentation is included in each module.
--
-- License:
-- ============================================================================
-- Copyright 2008-2015 Technische Universitaet Dresden - Germany
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

library STD;
use			STD.TextIO.all;

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.strings.all;
use			PoC.vectors.all;


package mem is
	type T_MEM_FILEFORMAT is (
		MEM_FILEFORMAT_INTEL_HEX,
		MEM_FILEFORMAT_LATTICE_MEM,
		MEM_FILEFORMAT_XILINX_MEM
	);
	
	type T_MEM_CONTENT is (
		MEM_CONTENT_BINARY,
		MEM_CONTENT_DECIMAL,
		MEM_CONTENT_HEX
	);
	
	function mem_FileExtension(Filename : STRING) return STRING;
	
	impure function mem_ReadMemoryFile(
		FileName : string;
		MemoryLines : POSITIVE;
		BitsPerMemoryLine : POSITIVE;
		FORMAT : T_MEM_FILEFORMAT;
		CONTENT : T_MEM_CONTENT := MEM_CONTENT_HEX
	) return T_SLM;
end package;


package body mem is
	function mem_FileExtension(FileName : STRING) return STRING is
	begin
		for i in FileName'high downto FileName'low loop
			if (FileName(i) = '.') then
				return str_toLower(FileName(i + 1 to FileName'high));
			end if;
		end loop;
		return "";
	end function;
	
	procedure ReadHex(L : inout LINE; Value : out STD_LOGIC_VECTOR; Good : out BOOLEAN) is
		variable ok					: BOOLEAN;
		variable Char				: CHARACTER;
		variable Digit			: T_DIGIT_HEX;
		constant DigitCount	: POSITIVE			:= div_ceil(Value'length, 4);
		variable slv				: STD_LOGIC_VECTOR((DigitCount * 4) - 1 downto 0);
		variable Swapped		: STD_LOGIC_VECTOR((DigitCount * 4) - 1 downto 0);
	begin
		Good		:= TRUE;
		for i in 0 to DigitCount - 1 loop
			read(L, Char, ok);
			if (ok = FALSE) then
				Swapped	:= swap(slv, 4);
				Value		:= Swapped(Value'length - 1 downto 0);
				return;
			end if;
			Digit := to_digit_hex(Char);
			if (Digit = -1) then
				Good := FALSE;
				return;
			end if;
			slv(i * 4 + 3 downto i * 4)	:= to_slv(Digit, 4);
		end loop;
		Swapped	:= swap(slv, 4);
		Value		:= Swapped(Value'length - 1 downto 0);
	end procedure; 
	
	-- Reads a memory file and returns a 2D std_logic matrix
	impure function mem_ReadMemoryFile(
		FileName : string;
		MemoryLines : POSITIVE;
		BitsPerMemoryLine : POSITIVE;
		FORMAT : T_MEM_FILEFORMAT;
		CONTENT : T_MEM_CONTENT := MEM_CONTENT_HEX
	) return T_SLM is
		file FileHandle				: TEXT open READ_MODE is FileName;
		variable CurrentLine	: LINE;
		variable Good					: BOOLEAN;
		variable TempWord			: STD_LOGIC_VECTOR((div_ceil(BitsPerMemoryLine, 4) * 4) - 1 downto 0);
		variable Result				: T_SLM(MemoryLines - 1 downto 0, BitsPerMemoryLine - 1 downto 0);
	begin
		Result := (others => (others => ite(SIMULATION, 'U', '0')));
		
		if (FORMAT = MEM_FILEFORMAT_XILINX_MEM) then
			-- discard the first line of a mem file
			readline(FileHandle, CurrentLine);
		end if;

		for i in 0 to MemoryLines - 1 loop
			exit when endfile(FileHandle);

			readline(FileHandle, CurrentLine);
--			report CurrentLine.all severity NOTE;
			ReadHex(CurrentLine, TempWord, Good);
			if (Good = FALSE) then
				report "Error while reading memory file '" & FileName & "'." severity FAILURE;
				return Result;
			end if;
			for j in 0 to BitsPerMemoryLine - 1 loop
				Result(i, j) := TempWord(j);
			end loop;
		end loop;
		return  Result;
	end function;
end package body;
