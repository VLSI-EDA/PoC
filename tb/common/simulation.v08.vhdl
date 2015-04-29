-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Testbench:				Simulation constants, functions and utilities.
-- 
-- Authors:					Patrick Lehmann
--									Thomas B. Preusser
-- 
-- Description:
-- ------------------------------------
--		TODO
--
-- License:
-- =============================================================================
-- Copyright 2007-2014 Technische Universitaet Dresden - Germany
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
-- =============================================================================

LIBRARY IEEE;
USE			IEEE.STD_LOGIC_1164.ALL;

LIBRARY PoC;
USE			PoC.vectors.ALL;

package simulation is
	constant U8								: T_SLV_8							:= (others => 'U');
	constant U16							: T_SLV_16						:= (others => 'U');
	constant U24							: T_SLV_24						:= (others => 'U');
	constant U32							: T_SLV_32						:= (others => 'U');

	constant D8								: T_SLV_8							:= (others => '-');
	constant D16							: T_SLV_16						:= (others => '-');
	constant D24							: T_SLV_24						:= (others => '-');
	constant D32							: T_SLV_32						:= (others => '-');

  --+ Test Bench Status Management ++++++++++++++++++++++++++++++++++++++++++

	-- VHDL'08: Provide a protected tSimStatus type that may be used for
	--          other purposes as well. For compatibility with the VHDL'93
	--          implementation, the plain procedure implementation is also
	--          provided on top of a package private instance of this type.

	type tSimStatus is protected
    --* The status is changed to failed. If a message is provided, it is
    --* reported as an error.
    procedure simFail(msg : in string := "");

    --* If the passed condition has evaluated false, the status is marked
    --* as failed. In this case, the optional message will be reported as
    --* an error if provided.
	  procedure simAssert(cond : in boolean; msg : in string := "");

    --* Prints the final status. Unless simFail() or simAssert() with a
		--* false condition have been called before, a successful completion
	  --* will be indicated, a failure otherwise.
	  procedure simReport;
  end protected;

  --* The testbench is marked as failed. If a message is provided, it is
  --* reported as an error.
  procedure tbFail(msg : in string := "");

  --* If the passed condition has evaluated false, the testbench is marked
  --* as failed. In this case, the optional message will be reported as an
  --* error if one was provided.
	procedure tbAssert(cond : in boolean; msg : in string := "");

  --* Prints out the overall testbench result as defined by the automated
  --* testbench process. Unless tbFail() or tbAssert() with a false condition
  --* have been called before, a successful completion will be reported, a
  --* failure otherwise.
	procedure tbPrintResult;

end;


use	std.TextIO.all;

package body simulation is

  --+ Test Bench Status Management ++++++++++++++++++++++++++++++++++++++++++

  type tSimStatus is protected body
    --* Internal state variable to log a failure condition for final reporting.
    --* Once de-asserted, this variable will never return to a value of true.
		variable  pass : boolean := true;

	  procedure simFail(msg : in string := "") is
		begin
	  	if msg'length > 0 then
		  	report msg severity error;
		  end if;
		  pass := false;
		end;

	  procedure simAssert(cond : in boolean; msg : in string := "") is
  	begin
		  if not cond then
		    simFail(msg);
		  end if;
	  end;

	  procedure simReport is
		  variable l : line;
	  begin
		  write(l, string'("SIMULATION RESULT = "));
		  if pass then
			  write(l, string'("PASSED"));
		  else
		  	write(l, string'("FAILED"));
		  end if;
		  writeline(output, l);
		end;

  end protected body;

	--* The default global tSimStatus object.
  shared variable  status : tSimStatus;

  procedure tbFail(msg : in string := "") is
  begin
		status.simFail(msg);
  end;

  procedure tbAssert(cond : in boolean; msg : in string := "") is
	begin
		status.simAssert(cond, msg);
	end;

	procedure tbPrintResult is
	begin
		status.simReport;
	end procedure;

end package body;
