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
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;
use			IEEE.math_real.all;

library PoC;
use			PoC.utils.all;
-- use			PoC.strings.all;
use			PoC.vectors.all;
-- use			PoC.physical.all;


package sim_types is
	constant C_SIM_VERBOSE					: BOOLEAN		:= TRUE;		-- POC_VERBOSE

	-- ===========================================================================
  -- Simulation Task and Status Management
	-- ===========================================================================
	type		T_SIM_BOOLVEC						is array(INTEGER range <>) of BOOLEAN;
	
	subtype T_SIM_TEST_ID						is INTEGER range -1 to 1023;
	subtype T_SIM_TEST_NAME					is STRING(1 to 256);
	subtype T_SIM_PROCESS_ID				is NATURAL range 0 to 1023;
	subtype T_SIM_PROCESS_NAME			is STRING(1 to 64);
	subtype T_SIM_PROCESS_INSTNAME	is STRING(1 to 256);
	type		T_SIM_PROCESS_ID_VECTOR	is array(NATURAL range <>) of T_SIM_PROCESS_ID;
	
	type T_SIM_TEST_STATUS is (
		SIM_TEST_STATUS_CREATED,
		SIM_TEST_STATUS_ACTIVE,
		SIM_TEST_STATUS_ENDED
	);
	
	type T_SIM_PROCESS_STATUS is (
		SIM_PROCESS_STATUS_ACTIVE,
		SIM_PROCESS_STATUS_ENDED
	);
	
	type T_SIM_TEST is record
		ID									: T_SIM_TEST_ID;
		Name								: T_SIM_TEST_NAME;
		Status							: T_SIM_TEST_STATUS;
		ProcessIDs					: T_SIM_PROCESS_ID_VECTOR(T_SIM_PROCESS_ID);
		ProcessCount				: T_SIM_PROCESS_ID;
		ActiveProcessCount	: T_SIM_PROCESS_ID;
	end record;
	type T_SIM_TEST_VECTOR	is array(INTEGER range <>) of T_SIM_TEST;
	
	type T_SIM_PROCESS is record
		ID						: T_SIM_PROCESS_ID;
		TestID				: T_SIM_TEST_ID;
		Name					: T_SIM_PROCESS_NAME;
		Status				: T_SIM_PROCESS_STATUS;
		IsLowPriority	: BOOLEAN;
	end record;
	type T_SIM_PROCESS_VECTOR is array(NATURAL range <>) of T_SIM_PROCESS;
	
	constant C_SIM_DEFAULT_TEST_ID		: T_SIM_TEST_ID		:= -1;
	constant C_SIM_DEFAULT_TEST_NAME	: STRING					:= "Default test";
	
	-- ===========================================================================
	-- Random Numbers
	-- ===========================================================================
	type T_SIM_RAND_SEED is record
		Seed1	: INTEGER;
		Seed2	: INTEGER;
	end record;

	procedure randInitializeSeed(Seed : inout T_SIM_RAND_SEED);
	
	procedure randUniformDistibutedValue(Seed : inout T_SIM_RAND_SEED; Value : out REAL; Minimum : REAL; Maximum : REAL);
	
	procedure randNormalDistibutedValue(Seed : inout T_SIM_RAND_SEED; Value : out REAL; StandardDeviation : REAL := 1.0; Mean : REAL := 0.0);
	procedure randNormalDistibutedValue(Seed : inout T_SIM_RAND_SEED; Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);
	
	procedure randPoissonDistibutedValue(Seed : inout T_SIM_RAND_SEED; Value : out REAL; Mean : in REAL);
	procedure randPoissonDistibutedValue(Seed : inout T_SIM_RAND_SEED; Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);
	
	-- ===========================================================================
	-- Clock Generation
	-- ===========================================================================
	-- type T_PERCENT is INTEGER'range units
	type T_PERCENT is range INTEGER'low to INTEGER'high units
		ppb;
		ppm			= 1000 ppb;
		permil	= 1000 ppm;
		percent	= 10 permil;
		one			= 100 percent;
	end units;
	subtype T_WANDER		is T_PERCENT range -1 one to 1 one;
	subtype T_DUTYCYCLE	is T_PERCENT range	0 ppb to 1 one;
	
	type T_DEGREE is range INTEGER'low to INTEGER'high units
		second;
		minute	= 60 second;
		deg			= 60 minute;
	end units;
	subtype T_PHASE is T_DEGREE range	-360 deg to 360 deg;
	
	function ite(cond : BOOLEAN; value1 : T_DEGREE; value2 : T_DEGREE) return T_DEGREE;
	
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
	
end package;


package body sim_types is
	function ite(cond : BOOLEAN; value1 : T_DEGREE; value2 : T_DEGREE) return T_DEGREE is
	begin
		if cond then
			return value1;
		else
			return value2;
		end if;
	end function;
	
	-- ===========================================================================
	-- Random Numbers
	-- ===========================================================================
	procedure randInitializeSeed(Seed : inout T_SIM_RAND_SEED) is
	begin
		Seed.Seed1	:= 5;
		Seed.Seed2	:= 3423;
	end procedure;

	procedure randUniformDistibutedValue(Seed : inout T_SIM_RAND_SEED; Value : out REAL; Minimum : REAL; Maximum : REAL) is
		variable rand : REAL;
	begin
		if (Maximum < Minimum) then			report "randUniformDistibutedValue: Maximum must be greater than Minimum."	severity FAILURE;		end if;
		ieee.math_real.Uniform(Seed.Seed1, Seed.Seed2, rand);
		Value := scale(rand, Minimum, Maximum);
	end procedure ;

	procedure randNormalDistibutedValue(Seed : inout T_SIM_RAND_SEED; Value : out REAL; StandardDeviation : REAL := 1.0; Mean : REAL := 0.0) is
		variable rand1 : REAL;
		variable rand2 : REAL;
	begin
		if StandardDeviation < 0.0 then	report "randNormalDistibutedValue: Standard deviation must be >= 0.0"			severity FAILURE;		end if;
		-- Box Muller transformation
		ieee.math_real.Uniform(Seed.Seed1, Seed.Seed2, rand1);
		ieee.math_real.Uniform(Seed.Seed1, Seed.Seed2, rand2);
		--													standard normal distribution: mean 0, variance 1
		Value := StandardDeviation * (sqrt(-2.0 * log(rand1)) * cos(MATH_2_PI * rand2)) + Mean;
	end procedure;
	
	procedure randNormalDistibutedValue(Seed : inout T_SIM_RAND_SEED; Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
		variable rand		: REAL;
	begin
		if (Maximum < Minimum) then			report "randNormalDistibutedValue: Maximum must be greater than Minimum."	severity FAILURE;		end if;
		if StandardDeviation < 0.0 then	report "randNormalDistibutedValue: Standard deviation must be >= 0.0"			severity FAILURE;		end if;
		while (TRUE) loop
			randNormalDistibutedValue(Seed, rand, StandardDeviation, Mean);
			exit when ((Minimum <= rand) and (rand <= Maximum));
		end loop;
		Value := rand;
	end procedure;
	
	procedure randPoissonDistibutedValue(Seed : inout T_SIM_RAND_SEED; Value : out REAL; Mean : in REAL) is
		variable Product	: Real;
		variable Bound		: Real;
		variable rand			: Real;
		variable Result		: Real;
	begin
		Product	:= 1.0;
		Result	:= 0.0;
		Bound		:= exp(-1.0 * Mean);
		if ((Mean <= 0.0) or (Bound <= 0.0)) then
			report "randPoissonDistibutedValue: Mean must be greater than 0.0." severity FAILURE;
			return;
		end if;
		
		while (Product >= Bound) loop
			ieee.math_real.Uniform(Seed.Seed1, Seed.Seed2, rand);
			Product		:= Product * rand;
			Result		:= Result + 1.0;
		end loop;
		Value	:= Result;
	end procedure;
	
	procedure randPoissonDistibutedValue(Seed : inout T_SIM_RAND_SEED; Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
		variable rand		: REAL;
	begin
		if (Maximum < Minimum) then			report "randPoissonDistibutedValue: Maximum must be greater than Minimum."	severity FAILURE;		end if;
		while (TRUE) loop
			randPoissonDistibutedValue(Seed, rand, Mean);
			exit when ((Minimum <= rand) and (rand <= Maximum));
		end loop;
		Value := rand;
	end procedure;
end package body;
