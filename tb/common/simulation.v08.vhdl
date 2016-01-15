-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Authors:					Patrick Lehmann
--									Thomas B. Preusser
-- 
-- Package:					Simulation constants, functions and utilities.
-- 
-- Description:
-- ------------------------------------
--		TODO
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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

library IEEE;
use			IEEE.STD_LOGIC_1164.all;

library PoC;
use			PoC.utils.all;
use			PoC.strings.all;
use			PoC.vectors.all;
use			PoC.physical.all;


package simulation is
	-- predefined constants to ease testvector concatenation
	constant U8								: T_SLV_8							:= (others => 'U');
	constant U16							: T_SLV_16						:= (others => 'U');
	constant U24							: T_SLV_24						:= (others => 'U');
	constant U32							: T_SLV_32						:= (others => 'U');

	constant D8								: T_SLV_8							:= (others => '-');
	constant D16							: T_SLV_16						:= (others => '-');
	constant D24							: T_SLV_24						:= (others => '-');
	constant D32							: T_SLV_32						:= (others => '-');

--  -- Testbench Status Management
--	-- ===========================================================================
--	-- VHDL'08: Provide a protected tSimStatus type that may be used for
--	--          other purposes as well. For compatibility with the VHDL'93
--	--          implementation, the plain procedure implementation is also
--	--          provided on top of a package private instance of this type.
--
--	type T_TB_STATUS is protected
--		
--		procedure simInit;
--		
--		-- The status is changed to failed. If a message is provided, it is
--		-- reported as an error.
--    procedure simFail(msg : in string := "");
--
--    -- If the passed condition has evaluated false, the status is marked
--    -- as failed. In this case, the optional message will be reported as
--    -- an error if provided.
--	  procedure simAssert(cond : in boolean; msg : in string := "");
--
--    -- Prints the final status. Unless simFail() or simAssert() with a
--		-- false condition have been called before, a successful completion
--	  -- will be indicated, a failure otherwise.
--	  procedure simReport;
--  end protected;
	
  -- Simulation Task and Status Management
	-- ===========================================================================
	subtype T_SIM_PROCESS_ID				is NATURAL range 0 to 31;
	subtype T_SIM_PROCESS_NAME			is STRING(1 to 32);
	subtype T_SIM_PROCESS_INSTNAME	is STRING(1 to 128);
	
	type T_SIM_PROCESS_STATUS is (
		SIM_PROCESS_STATUS_ACTIVE,
		SIM_PROCESS_STATUS_ENDED
	);
	
	type T_SIM_PROCESS is record
		ID						: T_SIM_PROCESS_ID;
		Name					: T_SIM_PROCESS_NAME;
		InstanceName	: T_SIM_PROCESS_INSTNAME;
		Status				: T_SIM_PROCESS_STATUS;
	end record;
	type T_SIM_PROCESS_VECTOR is array(NATURAL range <>) of T_SIM_PROCESS;
	
	subtype T_SIM_TEST_ID		is NATURAL range 0 to 31;
	subtype T_SIM_TEST_NAME	is STRING(1 to 32);
	
	type T_SIM_TEST_STATUS is (
		SIM_TEST_STATUS_ACTIVE,
		SIM_TEST_STATUS_ENDED
	);
	
	type T_SIM_TEST is record
		ID			: T_SIM_TEST_ID;
		Name		: T_SIM_TEST_NAME;
		Status	: T_SIM_TEST_STATUS;
	end record;
	type T_SIM_TEST_VECTOR	is array(NATURAL range <>) of T_SIM_TEST;
	
	
	type T_SIM_STATUS is protected
		-- Initializer and Finalizer
		procedure initialize;
		procedure finalize;
		
		-- Assertions
    procedure fail(Message : STRING := "");
	  procedure assertion(Condition : BOOLEAN; Message : STRING := "");
	  procedure writeMessage(Message : STRING);
		procedure writeReport;
		
		-- Process Management
		-- impure function	registerProcess(Name : STRING; InstanceName : STRING) return T_SIM_PROCESS_ID;
		impure function	registerProcess(Name : STRING) return T_SIM_PROCESS_ID;
		procedure				deactivateProcess(procID : T_SIM_PROCESS_ID);
		
		-- Test Management
		impure function createTest(Name : STRING) return T_SIM_TEST_ID;
		
		-- Run Management
		procedure				stopAllClocks;
		impure function	isStopped return BOOLEAN;
	end protected;
	
		
	-- The default global status objects.
	-- ===========================================================================
	shared variable globalSimulationStatus		: T_SIM_STATUS;
	
	
	-- Legacy interface for pre VHDL-2002
	-- ===========================================================================
  -- The testbench is marked as failed. If a message is provided, it is
  -- reported as an error.
  procedure tbFail(msg : in string := "");

  -- If the passed condition has evaluated false, the testbench is marked
  -- as failed. In this case, the optional message will be reported as an
  -- error if one was provided.
	procedure tbAssert(cond : in boolean; msg : in string := "");

  -- Prints out the overall testbench result as defined by the automated
  -- testbench process. Unless tbFail() or tbAssert() with a false condition
  -- have been called before, a successful completion will be reported, a
  -- failure otherwise.
	procedure tbPrintResult;

	-- clock generation
	-- ===========================================================================
	subtype T_DutyCycle is REAL range 0.0 to 1.0;
	
	procedure simStopAll;
	impure function simIsStopped return BOOLEAN;
	procedure simGenerateClock(signal Clock : out STD_LOGIC; constant Frequency : in FREQ; constant DutyCycle : T_DutyCycle := 0.5);
	procedure simGenerateClock(signal Clock : out STD_LOGIC; constant Period : in TIME; constant DutyCycle : T_DutyCycle := 0.5);
	
	-- waveform generation
	-- ===========================================================================
	type T_SIM_WAVEFORM_TUPLE_SL is record
		Delay		: TIME;
		Value		: STD_LOGIC;
	end record;
	
	type T_SIM_WAVEFORM_TUPLE_SLV_8 is record
		Delay		: TIME;
		Value		: T_SLV_8;
	end record;
	
	type T_SIM_WAVEFORM_TUPLE_SLV_16 is record
		Delay		: TIME;
		Value		: T_SLV_16;
	end record;
	
	type T_SIM_WAVEFORM_TUPLE_SLV_24 is record
		Delay		: TIME;
		Value		: T_SLV_24;
	end record;
	
	type T_SIM_WAVEFORM_TUPLE_SLV_32 is record
		Delay		: TIME;
		Value		: T_SLV_32;
	end record;
	
	type T_SIM_WAVEFORM_TUPLE_SLV_48 is record
		Delay		: TIME;
		Value		: T_SLV_48;
	end record;
	
	type T_SIM_WAVEFORM_TUPLE_SLV_64 is record
		Delay		: TIME;
		Value		: T_SLV_64;
	end record;
	
	type T_SIM_WAVEFORM_SL			is array(NATURAL range <>) of T_SIM_WAVEFORM_TUPLE_SL;
	type T_SIM_WAVEFORM_SLV_8		is array(NATURAL range <>) of T_SIM_WAVEFORM_TUPLE_SLV_8;
	type T_SIM_WAVEFORM_SLV_16	is array(NATURAL range <>) of T_SIM_WAVEFORM_TUPLE_SLV_16;
	type T_SIM_WAVEFORM_SLV_24	is array(NATURAL range <>) of T_SIM_WAVEFORM_TUPLE_SLV_24;
	type T_SIM_WAVEFORM_SLV_32	is array(NATURAL range <>) of T_SIM_WAVEFORM_TUPLE_SLV_32;
	type T_SIM_WAVEFORM_SLV_48	is array(NATURAL range <>) of T_SIM_WAVEFORM_TUPLE_SLV_48;
	type T_SIM_WAVEFORM_SLV_64	is array(NATURAL range <>) of T_SIM_WAVEFORM_TUPLE_SLV_64;
	
	procedure simGenerateWaveform(signal Wave : out BOOLEAN;		Waveform: T_TIMEVEC;							InitialValue : BOOLEAN);
	procedure simGenerateWaveform(signal Wave : out STD_LOGIC;	Waveform: T_TIMEVEC;							InitialValue : STD_LOGIC := '0');
	procedure simGenerateWaveform(signal Wave : out STD_LOGIC;	Waveform: T_SIM_WAVEFORM_SL;			InitialValue : STD_LOGIC := '0');
	procedure simGenerateWaveform(signal Wave : out T_SLV_8;		Waveform: T_SIM_WAVEFORM_SLV_8;		InitialValue : T_SLV_8);
	procedure simGenerateWaveform(signal Wave : out T_SLV_16;		Waveform: T_SIM_WAVEFORM_SLV_16;	InitialValue : T_SLV_16);
	procedure simGenerateWaveform(signal Wave : out T_SLV_24;		Waveform: T_SIM_WAVEFORM_SLV_24;	InitialValue : T_SLV_24);
	procedure simGenerateWaveform(signal Wave : out T_SLV_32;		Waveform: T_SIM_WAVEFORM_SLV_32;	InitialValue : T_SLV_32);
	procedure simGenerateWaveform(signal Wave : out T_SLV_48;		Waveform: T_SIM_WAVEFORM_SLV_48;	InitialValue : T_SLV_48);
	procedure simGenerateWaveform(signal Wave : out T_SLV_64;		Waveform: T_SIM_WAVEFORM_SLV_64;	InitialValue : T_SLV_64);
	
	function simGenerateWaveform_Reset(constant Pause : TIME := 0 ns; ResetPulse : TIME := 10 ns) return T_TIMEVEC;
	
end;


use	std.TextIO.all;

package body simulation is
	-- Simulation process and Status Management
	-- ===========================================================================
	type T_SIM_STATUS is protected body
		-- status
		variable IsInitialized			: BOOLEAN		:= FALSE;
		variable IsFinalized				: BOOLEAN		:= FALSE;
		
    -- Internal state variable to log a failure condition for final reporting.
    -- Once de-asserted, this variable will never return to a value of true.
		variable Passed							: BOOLEAN := TRUE;
		variable AssertCount				: NATURAL		:= 0;
		variable FailedAssertCount	: NATURAL		:= 0;
		
		-- Clock Management
		variable MainClockEnable		: BOOLEAN		:= FALSE;
		
		-- Process Management
		variable ProcessCount				: NATURAL																	:= 0;
		variable ActiveProcessCount	: NATURAL																	:= 0;
		variable Processes					: T_SIM_PROCESS_VECTOR(T_SIM_PROCESS_ID);
		
		-- Test Management
		variable TestCount					: NATURAL																	:= 0;
		variable Tests							: T_SIM_TEST_VECTOR(T_SIM_TEST_ID);
		
		-- Initializer
		procedure initialize is
		begin
			IsInitialized			:= TRUE;
			MainClockEnable		:= TRUE;
		end procedure;
		
		procedure finalize is
		begin
			if (IsFinalized = FALSE) then
				if (ActiveProcessCount = 0) then
					writeReport;
					IsFinalized		:= TRUE;
				end if;
			end if;
		end procedure;
		
	  procedure fail(Message : STRING := "") is
		begin
	  	if (Message'length > 0) then
		  	report Message severity ERROR;
		  end if;
		  Passed := FALSE;
		end;

	  procedure assertion(condition : BOOLEAN; Message : STRING := "") is
  	begin
			AssertCount := AssertCount + 1;
		  if (condition = FALSE) then
		    fail(Message);
				FailedAssertCount := FailedAssertCount + 1;
		  end if;
	  end;

		procedure writeMessage(Message : STRING) is
		  variable LineBuffer : LINE;
	  begin
		  write(LineBuffer, Message);
		  writeline(output, LineBuffer);
		end;
		
	  procedure writeReport is
		  variable LineBuffer : LINE;
	  begin
		  write(LineBuffer,		(CR & STRING'("========================================")));
		  write(LineBuffer,		(CR & STRING'("POC TESTBENCH REPORT")));
		  write(LineBuffer,		(CR & STRING'("========================================")));
			write(LineBuffer,		(CR & STRING'("Assertions   ") & INTEGER'image(AssertCount)));
			write(LineBuffer,		(CR & STRING'("  failed     ") & INTEGER'image(FailedAssertCount)));
			write(LineBuffer,		(CR & STRING'("Processes    ") & INTEGER'image(ProcessCount)));
			write(LineBuffer,		(CR & STRING'("  active     ") & INTEGER'image(ActiveProcessCount)));
			for i in 0 to ProcessCount - 1 loop
				if (Processes(i).Status = SIM_PROCESS_STATUS_ACTIVE) then
					write(LineBuffer,	(CR & STRING'("    ") & str_trim(Processes(i).Name)));
				end if;
			end loop;
			write(LineBuffer,		(CR & STRING'("Tests        ") & INTEGER'image(TestCount)));
			for i in 0 to TestCount - 1 loop
				write(LineBuffer,	(CR & STRING'("  ") & str_ralign(INTEGER'image(i), log10ceil(T_SIM_TEST_ID'high)) & ": " & str_trim(Tests(i).Name)));
			end loop;
		  write(LineBuffer,		(CR & STRING'("========================================")));
			if (AssertCount = 0) then
			  write(LineBuffer, (CR & STRING'("SIMULATION RESULT = NOT IMPLEMENTED")));
		  elsif (Passed = TRUE) then
			  write(LineBuffer, (CR & STRING'("SIMULATION RESULT = PASSED")));
		  else
		  	write(LineBuffer, (CR & STRING'("SIMULATION RESULT = FAILED")));
		  end if;
		  write(LineBuffer,		(CR & STRING'("========================================")));
		  writeline(output, LineBuffer);
		end;
		
		-- impure function registerProcess(Name : STRING; InstanceName : STRING) return T_SIM_PROCESS_ID is
		impure function registerProcess(Name : STRING) return T_SIM_PROCESS_ID is
			variable Proc						: T_SIM_PROCESS;
		begin
			Proc.ID									:= ProcessCount;
			Proc.Name								:= resize(Name, T_SIM_PROCESS_NAME'length);
			-- Proc.InstanceName				:= resize(InstanceName, T_SIM_PROCESS_INSTNAME'length);
			Proc.Status							:= SIM_PROCESS_STATUS_ACTIVE;
			
			Processes(ProcessCount)	:= Proc;
			ProcessCount						:= ProcessCount + 1;
			ActiveProcessCount			:= ActiveProcessCount + 1;
			return Proc.ID;
		end function;
		
		procedure deactivateProcess(ProcID : T_SIM_PROCESS_ID) is
			variable hasActiveProcesses		: BOOLEAN		:= FALSE;
		begin
			if (ProcID < ProcessCount) then
				if (Processes(ProcID).Status = SIM_PROCESS_STATUS_ACTIVE) then
					Processes(ProcID).Status	:= SIM_PROCESS_STATUS_ENDED;
					ActiveProcessCount				:= ActiveProcessCount - 1;
				end if;
			end if;
			
			if (ActiveProcessCount = 0) then
				stopAllClocks;
			end if;
		end procedure;
		
		impure function createTest(Name : STRING) return T_SIM_TEST_ID is
			variable Test			: T_SIM_TEST;
		begin
			Test.ID						:= TestCount;
			Test.Name					:= resize(Name, T_SIM_TEST_NAME'length);
			Test.Status				:= SIM_TEST_STATUS_ACTIVE;
		
			Tests(TestCount)	:= Test;
			TestCount					:= TestCount + 1;
			return Test.ID;
		end function;
		
		procedure stopAllClocks is
		begin
			MainClockEnable		:= FALSE;
		end procedure;
		
		impure function isStopped return BOOLEAN is
		begin
			return not MainClockEnable;
		end function;
	end protected body;
	
	
	-- legacy procedures
	-- ===========================================================================
  procedure tbFail(msg : in string := "") is
  begin
		globalSimulationStatus.fail(msg);
  end;

  procedure tbAssert(cond : in boolean; msg : in string := "") is
	begin
		globalSimulationStatus.assertion(cond, msg);
	end;

	procedure tbPrintResult is
	begin
		globalSimulationStatus.finalize;
	end procedure;

	-- clock generation
	-- ===========================================================================
	procedure simStopAll is
	begin
		globalSimulationStatus.stopAllClocks;
	end procedure;
	
	impure function simIsStopped return BOOLEAN is
	begin
		return globalSimulationStatus.isStopped;
	end function;
	
	procedure simGenerateClock(signal Clock : out STD_LOGIC; constant Frequency : in FREQ; constant DutyCycle : T_DutyCycle := 0.5) is
		constant Period : TIME := to_time(Frequency);
	begin
		simGenerateClock(Clock, Period, DutyCycle);
	end procedure;
	
	procedure simGenerateClock(signal Clock : out STD_LOGIC; constant Period : in TIME; constant DutyCycle : T_DutyCycle := 0.5) is
		constant TIME_HIGH	: TIME := Period * DutyCycle;
		constant TIME_LOW		: TIME := Period - TIME_HIGH;
	begin
		Clock		<= '0';

		while (globalSimulationStatus.isStopped = FALSE) loop
			wait for TIME_LOW;
			Clock		<= '1';
			wait for TIME_HIGH;
			Clock		<= '0';
		end loop;
	end procedure;
	
	-- waveform generation
	-- ===========================================================================
	procedure simGenerateWaveform(signal Wave : out BOOLEAN; Waveform : T_TIMEVEC; InitialValue : BOOLEAN) is
		variable State : BOOLEAN := InitialValue;
	begin
		Wave <= State;
		for i in Waveform'range loop
			wait for Waveform(i);
			State		:= not State;
			Wave		<= State;
		end loop;
	end procedure;
	
	procedure simGenerateWaveform(signal Wave : out STD_LOGIC; Waveform: T_TIMEVEC; InitialValue : STD_LOGIC := '0') is
		variable State : STD_LOGIC := InitialValue;
	begin
		Wave <= State;
		for i in Waveform'range loop
			wait for Waveform(i);
			State		:= not State;
			Wave		<= State;
		end loop;
	end procedure;

	procedure simGenerateWaveform(signal Wave : out STD_LOGIC; Waveform: T_SIM_WAVEFORM_SL; InitialValue : STD_LOGIC := '0') is
	begin
		Wave <= InitialValue;
		for i in Waveform'range loop
			wait for Waveform(i).Delay;
			Wave		<= Waveform(i).Value;
		end loop;
	end procedure;
	
	procedure simGenerateWaveform(signal Wave : out T_SLV_8; Waveform: T_SIM_WAVEFORM_SLV_8; InitialValue : T_SLV_8) is
	begin
		Wave <= InitialValue;
		for i in Waveform'range loop
			wait for Waveform(i).Delay;
			Wave		<= Waveform(i).Value;
		end loop;
	end procedure;
	
	procedure simGenerateWaveform(signal Wave : out T_SLV_16; Waveform: T_SIM_WAVEFORM_SLV_16; InitialValue : T_SLV_16) is
	begin
		Wave <= InitialValue;
		for i in Waveform'range loop
			wait for Waveform(i).Delay;
			Wave		<= Waveform(i).Value;
		end loop;
	end procedure;
	
	procedure simGenerateWaveform(signal Wave : out T_SLV_24; Waveform: T_SIM_WAVEFORM_SLV_24; InitialValue : T_SLV_24) is
	begin
		Wave <= InitialValue;
		for i in Waveform'range loop
			wait for Waveform(i).Delay;
			Wave		<= Waveform(i).Value;
		end loop;
	end procedure;
	
	procedure simGenerateWaveform(signal Wave : out T_SLV_32; Waveform: T_SIM_WAVEFORM_SLV_32; InitialValue : T_SLV_32) is
	begin
		Wave <= InitialValue;
		for i in Waveform'range loop
			wait for Waveform(i).Delay;
			Wave		<= Waveform(i).Value;
		end loop;
	end procedure;
	
	procedure simGenerateWaveform(signal Wave : out T_SLV_48; Waveform: T_SIM_WAVEFORM_SLV_48; InitialValue : T_SLV_48) is
	begin
		Wave <= InitialValue;
		for i in Waveform'range loop
			wait for Waveform(i).Delay;
			Wave		<= Waveform(i).Value;
		end loop;
	end procedure;
	
	procedure simGenerateWaveform(signal Wave : out T_SLV_64; Waveform: T_SIM_WAVEFORM_SLV_64; InitialValue : T_SLV_64) is
	begin
		Wave <= InitialValue;
		for i in Waveform'range loop
			wait for Waveform(i).Delay;
			Wave		<= Waveform(i).Value;
		end loop;
	end procedure;
	
	function simGenerateWaveform_Reset(constant Pause : TIME := 0 ns; ResetPulse : TIME := 10 ns) return T_TIMEVEC is
	begin
		return (0 => Pause, 1 => ResetPulse);
	end function;
end package body;
