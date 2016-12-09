-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Package:					Simulation constants, functions and utilities.
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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

use			STD.TextIO.all;

library IEEE;
use			IEEE.STD_LOGIC_1164.all;

library PoC;
use			PoC.utils.all;
use			PoC.strings.all;
use			PoC.vectors.all;
use			PoC.physical.all;

use			PoC.sim_types.all;
use			PoC.sim_global.all;


package sim_unprotected is
  -- Simulation Task and Status Management
	-- ===========================================================================
	-- Initializer and Finalizer
	procedure				initialize(MaxAssertFailures : natural := natural'high; MaxSimulationRuntime : TIME := TIME'high);
	procedure				finalize;

	-- Assertions
	procedure				fail(Message : string := "");
	procedure				assertion(Condition : boolean; Message : string := "");
	procedure				writeMessage(Message : string);
	procedure				writeReport;

	-- Process Management
	impure function	registerProcess(Name : string; IsLowPriority : boolean := FALSE) return T_SIM_PROCESS_ID;
	impure function registerProcess(TestID : T_SIM_TEST_ID; Name : string; IsLowPriority : boolean := FALSE) return T_SIM_PROCESS_ID;
	procedure				deactivateProcess(procID : T_SIM_PROCESS_ID);
	procedure				stopAllProcesses;
	procedure				stopProcesses(TestID	: T_SIM_TEST_ID := C_SIM_DEFAULT_TEST_ID);

	-- Test Management
	procedure				createDefaultTest;
	impure function createTest(Name : string) return T_SIM_TEST_ID;
	procedure				activateDefaultTest;
	impure function	finalizeDefaultTest return boolean;
	procedure				finalizeTest(TestID : T_SIM_TEST_ID);

	-- Clock Management
	procedure				stopAllClocks;
	procedure				stopClocks(TestID		: T_SIM_TEST_ID := C_SIM_DEFAULT_TEST_ID);

	impure function	isStopped(TestID		: T_SIM_TEST_ID := C_SIM_DEFAULT_TEST_ID)	return boolean;
	impure function isFinalized(TestID	: T_SIM_TEST_ID := C_SIM_DEFAULT_TEST_ID)	return boolean;
	impure function isAllFinalized return boolean;
end package;


package body sim_unprotected is

	-- Simulation process and Status Management
	-- ===========================================================================
	procedure init is
	begin
		if not globalSim_StateIsInitialized then
			if C_SIM_VERBOSE then		report "init:" severity NOTE;			end if;
			globalSim_StateIsInitialized		:= TRUE;
			createDefaultTest;
		end if;
	end procedure;

	procedure initialize(MaxAssertFailures : natural := natural'high; MaxSimulationRuntime : TIME := TIME'high) is
	begin
		if C_SIM_VERBOSE then		report "initialize:" severity NOTE;			end if;
		init;
		globalSim_MaxAssertFailures			:= MaxAssertFailures;
		globalSim_MaxSimulationRuntime	:= MaxSimulationRuntime;
		-- if (MaxSimulationRuntime /= TIME'high) then
			-- wait until (globalSim_StateIsFinalized = TRUE) for MaxSimulationRuntime;
			-- report "initialize: TIMEOUT" severity ERROR;
			-- finalize;
		-- end if;
	end procedure;

	procedure finalize is
		variable Dummy	: boolean;
	begin
		if not globalSim_StateIsFinalized then
			if C_SIM_VERBOSE then		report "finalize: " severity NOTE;		end if;
			globalSim_StateIsFinalized		:= TRUE;
			for i in 0 to globalSim_TestCount - 1 loop
				finalizeTest(i);
			end loop;
			Dummy		:= finalizeDefaultTest;
			writeReport;
		end if;
	end procedure;

	procedure writeReport_Header is
		variable LineBuffer : LINE;
	begin
		write(LineBuffer,		(			string'("========================================")));
		write(LineBuffer,		(LF & string'("POC TESTBENCH REPORT")));
		write(LineBuffer,		(LF & string'("========================================")));
		writeline(output, LineBuffer);
	end procedure;

	procedure writeReport_TestReport(Prefix : string := "") is
		variable LineBuffer : LINE;
	begin
		if (globalSim_Tests(C_SIM_DEFAULT_TEST_ID).Status /= SIM_TEST_STATUS_CREATED) then
			write(LineBuffer,				 Prefix & "Tests          " & integer'image(globalSim_TestCount + 1));
			write(LineBuffer,		LF & Prefix & " " & str_ralign("-1", log10ceilnz(globalSim_TestCount + 1) + 1) & ": " & C_SIM_DEFAULT_TEST_NAME);
		else
			write(LineBuffer,				 Prefix & "Tests          " & integer'image(globalSim_TestCount));
		end if;
		for i in 0 to globalSim_TestCount - 1 loop
			write(LineBuffer,		LF & Prefix & "  " & str_ralign(integer'image(i), log10ceilnz(globalSim_TestCount)) & ": " & str_trim(globalSim_Tests(i).Name));
		end loop;
		writeline(output, LineBuffer);
	end procedure;

	procedure writeReport_AssertReport(Prefix : string := "") is
		variable LineBuffer : LINE;
	begin
		write(LineBuffer,					 Prefix & "Assertions   " & integer'image(globalSim_AssertCount));
		write(LineBuffer,			LF & Prefix & "  failed     " & integer'image(globalSim_FailedAssertCount) & ite((globalSim_FailedAssertCount >= globalSim_MaxAssertFailures), " Too many failed asserts!", ""));
		writeline(output, LineBuffer);
	end procedure;

	procedure writeReport_ProcessReport(Prefix : string := "") is
		variable LineBuffer : LINE;
	begin
		write(LineBuffer,					 Prefix & "Processes    " & integer'image(globalSim_ProcessCount));
		write(LineBuffer,			LF & Prefix & "  active     " & integer'image(globalSim_ActiveProcessCount));
		-- report killed processes
		for i in 0 to globalSim_ProcessCount - 1 loop
			if ((globalSim_Processes(i).Status = SIM_PROCESS_STATUS_ACTIVE) and (globalSim_Processes(i).IsLowPriority = FALSE)) then
				write(LineBuffer,	LF & Prefix & "    " & str_ralign(integer'image(i), log10ceilnz(globalSim_ProcessCount)) & ": " & str_trim(globalSim_Processes(i).Name));
			end if;
		end loop;
		writeline(output, LineBuffer);
	end procedure;

	procedure writeReport_RuntimeReport(Prefix : string := "") is
		variable LineBuffer : LINE;
	begin
		write(LineBuffer,					 Prefix & "Runtime      " & to_string(now, 1));
		writeline(output, LineBuffer);
	end procedure;

	procedure writeReport_SimulationResult is
		variable LineBuffer : LINE;
	begin
		write(LineBuffer,																				(			string'("========================================")));
		if globalSim_AssertCount = 0 then	  write(LineBuffer, (LF & string'("SIMULATION RESULT = NO ASSERTS")));
		elsif globalSim_Passed then  write(LineBuffer, (LF & string'("SIMULATION RESULT = PASSED")));
		else										 						 	write(LineBuffer, (LF & string'("SIMULATION RESULT = FAILED")));
		end if;
		write(LineBuffer,																				(LF & string'("========================================")));
		writeline(output, LineBuffer);
	end procedure;

	procedure writeReport is
		variable LineBuffer : LINE;
	begin
		writeReport_Header;
		writeReport_TestReport("");
		write(LineBuffer, LF & "Overall");
		writeline(output, LineBuffer);
		writeReport_AssertReport("  ");
		writeReport_ProcessReport("  ");
		writeReport_RuntimeReport("  ");
		writeReport_SimulationResult;
	end procedure;

	procedure assertion(condition : boolean; Message : string := "") is
	begin
		globalSim_AssertCount := globalSim_AssertCount + 1;
		if not condition then
			fail(Message);
			globalSim_FailedAssertCount := globalSim_FailedAssertCount + 1;
			if (globalSim_FailedAssertCount >= globalSim_MaxAssertFailures) then
				stopAllProcesses;
			end if;
		end if;
	end procedure;

	procedure fail(Message : string := "") is
	begin
		if (Message'length > 0) then
			report Message severity ERROR;
		end if;
		globalSim_Passed := FALSE;
	end procedure;

	procedure writeMessage(Message : string) is
		variable LineBuffer : LINE;
	begin
		write(LineBuffer, Message);
		writeline(output, LineBuffer);
	end procedure;

	procedure createDefaultTest is
		variable Test							: T_SIM_TEST;
	begin
		if not globalSim_StateIsInitialized then
			init;
		end if;
		if C_SIM_VERBOSE then		report "createDefaultTest(" & C_SIM_DEFAULT_TEST_NAME & "): => " & T_SIM_TEST_ID'image(C_SIM_DEFAULT_TEST_ID) severity NOTE;		end if;
		Test.ID										:= C_SIM_DEFAULT_TEST_ID;
		Test.Name									:= resize(C_SIM_DEFAULT_TEST_NAME, T_SIM_TEST_NAME'length);
		Test.Status								:= SIM_TEST_STATUS_CREATED;
		Test.ProcessIDs						:= (others => 0);
		Test.ProcessCount					:= 0;
		Test.ActiveProcessCount		:= 0;
		-- add to the internal structure
		globalSim_Tests(Test.ID)	:= Test;
	end procedure;

	impure function createTest(Name : string) return T_SIM_TEST_ID is
		variable Test							: T_SIM_TEST;
	begin
		if not globalSim_StateIsInitialized then
			init;
		end if;
		if C_SIM_VERBOSE then		report "createTest(" & Name & "): => " & T_SIM_TEST_ID'image(globalSim_TestCount) severity NOTE;		end if;
		Test.ID										:= globalSim_TestCount;
		Test.Name									:= resize(Name, T_SIM_TEST_NAME'length);
		Test.Status								:= SIM_TEST_STATUS_ACTIVE;
		Test.ProcessIDs						:= (others => 0);
		Test.ProcessCount					:= 0;
		Test.ActiveProcessCount		:= 0;
		-- add to the internal structure
		globalSim_Tests(Test.ID)	:= Test;
		globalSim_TestCount				:= globalSim_TestCount + 1;
		globalSim_ActiveTestCount	:= globalSim_ActiveTestCount + 1;
		-- return TestID for finalizeTest
		return Test.ID;
	end function;

	procedure activateDefaultTest is
	begin
		if (globalSim_Tests(C_SIM_DEFAULT_TEST_ID).Status = SIM_TEST_STATUS_CREATED) then
			globalSim_Tests(C_SIM_DEFAULT_TEST_ID).Status := SIM_TEST_STATUS_ACTIVE;
			globalSim_ActiveTestCount											:= globalSim_ActiveTestCount + 1;
		end if;
	end procedure;

	impure function finalizeDefaultTest return boolean is
	begin
		if (globalSim_Tests(C_SIM_DEFAULT_TEST_ID).Status = SIM_TEST_STATUS_CREATED) then
			if C_SIM_VERBOSE then		report "finalizeDefaultTest: inactive" severity NOTE;		end if;
			globalSim_Tests(C_SIM_DEFAULT_TEST_ID).Status	:= SIM_TEST_STATUS_ENDED;
			stopProcesses(C_SIM_DEFAULT_TEST_ID);
			return TRUE;
		elsif (globalSim_Tests(C_SIM_DEFAULT_TEST_ID).Status = SIM_TEST_STATUS_ACTIVE) then
			if C_SIM_VERBOSE then		report "finalizeDefaultTest: active" severity NOTE;		end if;
			globalSim_Tests(C_SIM_DEFAULT_TEST_ID).Status	:= SIM_TEST_STATUS_ENDED;
			globalSim_ActiveTestCount											:= globalSim_ActiveTestCount - 1;
			stopProcesses(C_SIM_DEFAULT_TEST_ID);
			if globalSim_ActiveTestCount = 0 then
				finalize;
			end if;
			return TRUE;
		end if;
		return FALSE;
	end function;

	procedure finalizeTest(TestID : T_SIM_TEST_ID) is
		variable Dummy	: boolean;
	begin
		if TestID = C_SIM_DEFAULT_TEST_ID then
			if globalSim_ActiveTestCount = 1 then
				if finalizeDefaultTest then
					finalize;
				end if;
			end if;
		elsif TestID < globalSim_TestCount then
			if (globalSim_Tests(TestID).Status /= SIM_TEST_STATUS_ENDED) then
				if C_SIM_VERBOSE then		report "finalizeTest(TestID=" & T_SIM_TEST_ID'image(TestID) & "): " severity NOTE;		end if;
				globalSim_Tests(TestID).Status	:= SIM_TEST_STATUS_ENDED;
				globalSim_ActiveTestCount				:= globalSim_ActiveTestCount - 1;
				stopProcesses(TestID);

				if globalSim_ActiveTestCount = 0 then
					finalize;
				elsif globalSim_ActiveTestCount = 1 then
					if finalizeDefaultTest then
						finalize;
					end if;
				end if;
			end if;
		else
			report "TestID (" & T_SIM_TEST_ID'image(TestID) & ") is unknown." severity FAILURE;
		end if;
	end procedure;

	impure function registerProcess(Name : string; IsLowPriority : boolean := FALSE) return T_SIM_PROCESS_ID is
	begin
		return registerProcess(C_SIM_DEFAULT_TEST_ID, Name, IsLowPriority);
	end function;

	impure function registerProcess(TestID : T_SIM_TEST_ID; Name : string; IsLowPriority : boolean := FALSE) return T_SIM_PROCESS_ID is
		variable Proc						: T_SIM_PROCESS;
		variable TestProcID			: T_SIM_TEST_ID;
	begin
		if not globalSim_StateIsInitialized then
			init;
		end if;
		if TestID = C_SIM_DEFAULT_TEST_ID then
			activateDefaultTest;
		end if;
		if TestID < globalSim_TestCount then
			if C_SIM_VERBOSE then		report "registerProcess(TestID=" & T_SIM_TEST_ID'image(TestID) & ", " & Name & "): => " & T_SIM_PROCESS_ID'image(globalSim_ProcessCount) severity NOTE;		end if;
			Proc.ID									:= globalSim_ProcessCount;
			Proc.TestID							:= TestID;
			Proc.Name								:= resize(Name, T_SIM_PROCESS_NAME'length);
			Proc.Status							:= SIM_PROCESS_STATUS_ACTIVE;
			Proc.IsLowPriority			:= IsLowPriority;

			-- add process to list
			globalSim_Processes(Proc.ID)	:= Proc;
			globalSim_ProcessCount				:= globalSim_ProcessCount + 1;
			globalSim_ActiveProcessCount	:= inc_if(not IsLowPriority, globalSim_ActiveProcessCount);
			-- add process to test
			TestProcID																			:= globalSim_Tests(TestID).ProcessCount;
			globalSim_Tests(TestID).ProcessIDs(TestProcID)	:= Proc.ID;
			globalSim_Tests(TestID).ProcessCount						:= TestProcID + 1;
			globalSim_Tests(TestID).ActiveProcessCount			:= inc_if(not IsLowPriority, globalSim_Tests(TestID).ActiveProcessCount);
			-- return the process ID
			return Proc.ID;
		else
			report "TestID (" & T_SIM_TEST_ID'image(TestID) & ") is unknown." severity FAILURE;
			return T_SIM_PROCESS_ID'high;
		end if;
	end function;

	procedure deactivateProcess(ProcID : T_SIM_PROCESS_ID) is
		variable TestID		: T_SIM_TEST_ID;
	begin
		if ProcID < globalSim_ProcessCount then
			TestID	:= globalSim_Processes(ProcID).TestID;
			-- deactivate process
			if (globalSim_Processes(ProcID).Status = SIM_PROCESS_STATUS_ACTIVE) then
				if C_SIM_VERBOSE then		report "deactivateProcess(ProcID=" & T_SIM_PROCESS_ID'image(ProcID) & "): TestID=" & T_SIM_TEST_ID'image(TestID) & "  Name=" & str_trim(globalSim_Processes(ProcID).Name) severity NOTE;		end if;
				globalSim_Processes(ProcID).Status					:= SIM_PROCESS_STATUS_ENDED;
				globalSim_ActiveProcessCount								:= dec_if(not globalSim_Processes(ProcID).IsLowPriority, globalSim_ActiveProcessCount);
				globalSim_Tests(TestID).ActiveProcessCount	:= dec_if(not globalSim_Processes(ProcID).IsLowPriority, globalSim_Tests(TestID).ActiveProcessCount);
				if (globalSim_Tests(TestID).ActiveProcessCount = 0) then
					finalizeTest(TestID);
				end if;
			end if;
		else
			report "ProcID (" & T_SIM_PROCESS_ID'image(ProcID) & ") is unknown." severity FAILURE;
		end if;
	end procedure;

	procedure stopAllProcesses is
	begin
		if C_SIM_VERBOSE then		report "stopAllProcesses:" severity NOTE;		end if;
		for i in C_SIM_DEFAULT_TEST_ID to globalSim_TestCount - 1 loop
			stopProcesses(i);
		end loop;
	end procedure;

	procedure stopProcesses(TestID : T_SIM_TEST_ID := C_SIM_DEFAULT_TEST_ID) is
	begin
		if TestID < globalSim_TestCount then
			if C_SIM_VERBOSE then		report "stopProcesses(TestID=" & T_SIM_TEST_ID'image(TestID) & "): Name=" & str_trim(globalSim_Tests(TestID).Name) severity NOTE;		end if;
			globalSim_MainProcessEnables(TestID)	:= FALSE;
			stopClocks(TestID);
		else
			report "TestID (" & T_SIM_TEST_ID'image(TestID) & ") is unknown." severity FAILURE;
		end if;
	end procedure;

	procedure stopAllClocks is
	begin
		if C_SIM_VERBOSE then		report "stopAllClocks:" severity NOTE;		end if;
		for i in C_SIM_DEFAULT_TEST_ID to globalSim_TestCount - 1 loop
			stopClocks(i);
		end loop;
	end procedure;

	procedure stopClocks(TestID : T_SIM_TEST_ID := C_SIM_DEFAULT_TEST_ID) is
	begin
		if TestID < globalSim_TestCount then
			if C_SIM_VERBOSE then		report "stopClocks(TestID=" & T_SIM_TEST_ID'image(TestID) & "): Name=" & str_trim(globalSim_Tests(TestID).Name) severity NOTE;		end if;
			globalSim_MainClockEnables(TestID)		:= FALSE;
		else
			report "TestID (" & T_SIM_TEST_ID'image(TestID) & ") is unknown." severity FAILURE;
		end if;
	end procedure;

	impure function isStopped(TestID : T_SIM_TEST_ID := C_SIM_DEFAULT_TEST_ID) return boolean is
	begin
		return not globalSim_MainClockEnables(TestID);
	end function;

	impure function isFinalized(TestID : T_SIM_TEST_ID := C_SIM_DEFAULT_TEST_ID) return boolean is
	begin
		return (globalSim_Tests(TestID).Status = SIM_TEST_STATUS_ENDED);
	end function;

	impure function isAllFinalized return boolean is
	begin
		return (globalSim_ActiveTestCount = 0);
	end function;
end package body;
