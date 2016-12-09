-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--									Thomas B. Preusser
--
-- Package:     		File I/O-related Functions.
--
-- Description:
-- -------------------------------------
--   Exploring the options for providing a more convenient API than std.textio.
--   Not yet recommended for adoption as it depends on the VHDL generation and
--   still is under discussion.
--
--	 Open problems:
--     - verify that std.textio.write(text, string) is, indeed, specified and
--              that it does *not* print a trailing \newline
--          -> would help to eliminate line buffering in shared variables
--     - move C_LINEBREAK to my_config to keep platform dependency out?
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany,
--  					 				 Chair of VLSI-Design, Diagnostics and Architecture
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

use			STD.TextIO.all;

library	PoC;
use			PoC.my_project.all;
use			PoC.strings.all;
use			PoC.utils.all;


package FileIO is
	-- Constant declarations
	constant C_LINEBREAK : string;


	-- Log file
	-- ===========================================================================
	subtype T_LOGFILE_OPEN_KIND is FILE_OPEN_KIND range WRITE_MODE to APPEND_MODE;

	procedure				LogFile_Open(FileName : string; OpenKind : T_LOGFILE_OPEN_KIND := WRITE_MODE);
	procedure				LogFile_Open(Status : out FILE_OPEN_STATUS; FileName : string; OpenKind : T_LOGFILE_OPEN_KIND := WRITE_MODE);
	impure function	LogFile_IsOpen return boolean;
	procedure				LogFile_Print(str : string);
	procedure				LogFile_PrintLine(str : string := "");
	procedure				LogFile_Flush;
	procedure				LogFile_Close;

	-- StdOut
	-- ===========================================================================
	procedure StdOut_Print(str : string);
	procedure StdOut_PrintLine(str : string := "");
	procedure StdOut_Flush;

end package;


package body FileIO is
	constant C_LINEBREAK : string := ite(str_equal(MY_OPERATING_SYSTEM, "WINDOWS"), (CR & LF), (1 => LF));

	-- ===========================================================================
	file						LogFile_FileHandle		: TEXT;
	shared variable	LogFile_State_IsOpen	: boolean		:= FALSE;
	shared variable LogFile_LineBuffer		: LINE;

	procedure LogFile_Open(FileName : string; OpenKind : T_LOGFILE_OPEN_KIND := WRITE_MODE) is
		variable OpenStatus		: FILE_OPEN_STATUS;
	begin
		LogFile_Open(OpenStatus, FileName, OpenKind);
	end procedure;

	procedure LogFile_Open(Status : out FILE_OPEN_STATUS; FileName : string; OpenKind : T_LOGFILE_OPEN_KIND := WRITE_MODE) is
		variable OpenStatus		: FILE_OPEN_STATUS;
	begin
		file_open(OpenStatus, LogFile_FileHandle, FileName, OpenKind);
		LogFile_State_IsOpen	:= OpenStatus = OPEN_OK;
		Status								:= OpenStatus;
	end procedure;

	impure function LogFile_IsOpen return boolean is
	begin
		return LogFile_State_IsOpen;
	end function;

	procedure LogFile_Print(str : string) is
	begin
		write(LogFile_LineBuffer, str);
	end procedure;

	procedure LogFile_PrintLine(str : string := "") is
	begin
		write(LogFile_LineBuffer, str);
		writeline(LogFile_FileHandle, LogFile_LineBuffer);
	end procedure;

	procedure LogFile_Flush is
	begin
		writeline(LogFile_FileHandle, LogFile_LineBuffer);
	end procedure;

	procedure LogFile_Close is
	begin
		if LogFile_State_IsOpen then
			file_close(LogFile_FileHandle);
			LogFile_State_IsOpen	:= FALSE;
		end if;
	end procedure;

	-- ===========================================================================
	shared variable StdOut_LineBuffer : line;

	procedure StdOut_Print(str : string) is
	begin
		write(StdOut_LineBuffer, str);
	end procedure;

	procedure StdOut_PrintLine(str : string := "") is
	begin
		write(StdOut_LineBuffer, str);
		writeline(OUTPUT, StdOut_LineBuffer);
	end procedure;

	procedure StdOut_Flush is
	begin
		writeline(OUTPUT, StdOut_LineBuffer);
	end procedure;

end package body;
