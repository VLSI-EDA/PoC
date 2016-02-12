-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- =============================================================================
-- Authors:					Patrick Lehmann
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
use			PoC.sim_types.all;


package sim_random is
	-- Random Numbers
	-- ===========================================================================
	alias T_SIM_SEED is T_SIM_RAND_SEED;

	-- procedural interface
	-- procedure randomInitializeSeed(Seed : inout T_SIM_SEED);
	
	-- procedure randomUniformDistibutedValue(Seed : inout T_SIM_SEED; Value : out REAL; Minimum : in REAL; Maximum : in REAL);
	
	-- procedure randomNormalDistibutedValue(Seed : inout T_SIM_SEED; Value : out REAL; StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0);
	-- procedure randomNormalDistibutedValue(Seed : inout T_SIM_SEED; Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);
	
	-- procedure randomPoissonDistibutedValue(Seed : inout T_SIM_SEED; Value : out REAL; Mean : in REAL);
	-- procedure randomPoissonDistibutedValue(Seed : inout T_SIM_SEED; Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);
	
	-- protected type interface
	type T_RANDOM is protected
		procedure				SetSeed(Seed : T_SIM_SEED);
		impure function	GetSeed return T_SIM_SEED;
		
		impure function	GetUniformDistibutedValue(Minimum : in REAL; Maximum : in REAL) return REAL;
		procedure				GetUniformDistibutedValue(Value : out REAL; Minimum : in REAL; Maximum : in REAL);
	
		impure function	GetNormalDistibutedValue(StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0) return REAL;
		procedure				GetNormalDistibutedValue(Value : out REAL; StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0);
		impure function	GetNormalDistibutedValue(StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL;
		procedure				GetNormalDistibutedValue(Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);
	
		impure function	GetPoissonDistibutedValue(Mean : in REAL) return REAL;
		procedure				GetPoissonDistibutedValue(Value : out REAL; Mean : in REAL);
		impure function	GetPoissonDistibutedValue(Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL;
		procedure				GetPoissonDistibutedValue(Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);
	end protected;
end package;


package body sim_random is
	type T_RANDOM is protected body
		variable SeedValue		: T_SIM_SEED		:= (Seed1 => 5, Seed2 => 3423);
		
		-- Seed value handling
		procedure SetSeed is
		begin
			SeedValue.Seed1	:= 5;
			SeedValue.Seed2	:= 3423;
		end procedure;
		
		procedure SetSeed(Seed : T_SIM_SEED) is
		begin
			SeedValue		:= Seed;
		end procedure;
		
		impure function GetSeed return T_SIM_SEED is
		begin
			return SeedValue;
		end function;
		
		-- Uniform distribution
		impure function GetUniformDistibutedValue(Minimum : in REAL; Maximum : in REAL) return REAL is
			variable Result		: REAL;
		begin
			randUniformDistibutedValue(SeedValue, Result, Minimum, Maximum);
			return Result;
		end function;
		
		procedure getUniformDistibutedValue(Value : out REAL; Minimum : in REAL; Maximum : in REAL) is
		begin
			randUniformDistibutedValue(SeedValue, Value, Minimum, Maximum);
		end procedure;
		
		-- Normal distribution
		impure function getNormalDistibutedValue(StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0) return REAL is
			variable Result		: REAL;
		begin
			randNormalDistibutedValue(SeedValue, Result, StandardDeviation, Mean);
			return Result;
		end function;
		
		procedure getNormalDistibutedValue(Value : out REAL; StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0) is
		begin
			randNormalDistibutedValue(SeedValue, Value, StandardDeviation, Mean);
		end procedure;
		
		impure function getNormalDistibutedValue(StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL is
			variable Result		: REAL;
		begin
			randNormalDistibutedValue(SeedValue, Result, StandardDeviation, Mean, Minimum, Maximum);
			return Result;
		end function;
		
		procedure getNormalDistibutedValue(Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
		begin
			randNormalDistibutedValue(SeedValue, Value, StandardDeviation, Mean, Minimum, Maximum);
		end procedure;
		
		-- Poisson distribution
		impure function getPoissonDistibutedValue(Mean : in REAL) return REAL is
			variable Result		: REAL;
		begin
			randPoissonDistibutedValue(SeedValue, Result, Mean);
			return Result;
		end function;
		
		procedure getPoissonDistibutedValue(Value : out REAL; Mean : in REAL) is
		begin
			randPoissonDistibutedValue(SeedValue, Value, Mean);
		end procedure;
		
		impure function getPoissonDistibutedValue(Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL is
			variable Result		: REAL;
		begin
			randPoissonDistibutedValue(SeedValue, Result, Mean, Minimum, Maximum);
			return Result;
		end function;
		
		procedure getPoissonDistibutedValue(Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
		begin
			randPoissonDistibutedValue(SeedValue, Value, Mean, Minimum, Maximum);
		end procedure;
	end protected body;


	-- procedure randomUniformDistibutedValue(Seed : inout T_SIM_SEED; Value : inout REAL; Minimum : in REAL; Maximum : in REAL) is
	-- begin
		-- randUniformDistibutedValue(Seed, Value, Minimum, Maximum);
	-- end procedure ;

	-- procedure randomNormalDistibutedValue(Seed : inout T_SIM_SEED; Value : inout REAL; StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0) is
	-- begin
		-- randNormalDistibutedValue(Seed, Value, StandardDeviation, Mean);
	-- end procedure;

	-- procedure randomNormalDistibutedValue(Seed : inout T_SIM_SEED; Value : inout REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
	-- begin
		-- randNormalDistibutedValue(Seed, Value, StandardDeviation, Mean, Minimum, Maximum);
	-- end procedure;
	
	-- procedure randomPoissonDistibutedValue(Seed : inout T_SIM_SEED; Value : inout REAL; Mean : in REAL) is
	-- begin
		-- randPoissonDistibutedValue(Seed, Value, Mean);
	-- end procedure;
	
	-- procedure randomPoissonDistibutedValue(Seed : inout T_SIM_SEED; Value : inout REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
	-- begin
		-- randPoissonDistibutedValue(Seed, Value, Mean, Minimum, Maximum);
	-- end procedure;
end package body;
