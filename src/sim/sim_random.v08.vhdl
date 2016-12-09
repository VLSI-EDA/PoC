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

	-- procedure randomNormalDistributedValue(Seed : inout T_SIM_SEED; Value : out REAL; StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0);
	-- procedure randomNormalDistributedValue(Seed : inout T_SIM_SEED; Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);

	-- procedure randomPoissonDistributedValue(Seed : inout T_SIM_SEED; Value : out REAL; Mean : in REAL);
	-- procedure randomPoissonDistributedValue(Seed : inout T_SIM_SEED; Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);

	-- protected type interface
	type T_RANDOM is protected
		procedure				SetSeed;
		procedure				SetSeed(Seed1 : integer; Seed2 : integer);
		procedure				SetSeed(SeedValue : T_SIM_SEED);
		procedure				SetSeed(SeedVector : T_INTVEC);
		procedure				SetSeed(SeedVector : string);
		impure function	GetSeed return T_SIM_SEED;

		procedure				GetUniformDistributedValue(Value : out REAL);
		procedure				GetUniformDistributedValue(Value : out integer; Minimum : in integer; Maximum : in integer);
		procedure				GetUniformDistributedValue(Value : out REAL; Minimum : in REAL; Maximum : in REAL);
		impure function	GetUniformDistributedValue return REAL;
		impure function	GetUniformDistributedValue(Minimum : in integer; Maximum : in integer) return integer;
		impure function	GetUniformDistributedValue(Minimum : in REAL; Maximum : in REAL) return REAL;

		procedure				GetNormalDistributedValue(Value : out REAL; StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0);
		procedure				GetNormalDistributedValue(Value : out integer; StandardDeviation : in REAL; Mean : in REAL; Minimum : in integer; Maximum : in integer);
		procedure				GetNormalDistributedValue(Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);
		impure function	GetNormalDistributedValue(StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0) return REAL;
		impure function	GetNormalDistributedValue(StandardDeviation : in REAL; Mean : in REAL; Minimum : in integer; Maximum : in integer) return integer;
		impure function	GetNormalDistributedValue(StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL;

		procedure				GetPoissonDistributedValue(Value : out REAL; Mean : in REAL);
		procedure				GetPoissonDistributedValue(Value : out integer; Mean : in REAL; Minimum : in integer; Maximum : in integer);
		procedure				GetPoissonDistributedValue(Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);
		impure function	GetPoissonDistributedValue(Mean : in REAL) return REAL;
		impure function	GetPoissonDistributedValue(Mean : in REAL; Minimum : in integer; Maximum : in integer) return integer;
		impure function	GetPoissonDistributedValue(Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL;
	end protected;
end package;


package body sim_random is
	type T_RANDOM is protected body
		variable Local_Seed		: T_SIM_SEED		:= randInitializeSeed;

		-- Seed value handling
		procedure SetSeed is
		begin
			Local_Seed		:= randInitializeSeed;
		end procedure;

		procedure SetSeed(Seed1 : integer; Seed2 : integer) is
		begin
			Local_Seed		:= randInitializeSeed(T_SIM_RAND_SEED'(Seed1, Seed2));
		end procedure;

		procedure SetSeed(SeedValue : T_SIM_SEED) is
		begin
			Local_Seed		:= randInitializeSeed(SeedValue);
		end procedure;

		procedure SetSeed(SeedVector : T_INTVEC) is
		begin
			Local_Seed		:= randInitializeSeed(SeedVector);
		end procedure;

		procedure SetSeed(SeedVector : string) is
		begin
			Local_Seed		:= randInitializeSeed(SeedVector);
		end procedure;

		impure function GetSeed return T_SIM_SEED is
		begin
			return Local_Seed;
		end function;

		-- Uniform distribution
		impure function GetUniformDistributedValue return REAL is
			variable Result		: REAL;
		begin
			randUniformDistributedValue(Local_Seed, Result);
			return Result;
		end function;

		procedure getUniformDistributedValue(Value : out REAL) is
		begin
			randUniformDistributedValue(Local_Seed, Value);
		end procedure;

		impure function GetUniformDistributedValue(Minimum : in integer; Maximum : in integer) return integer is
			variable Result		: integer;
		begin
			randUniformDistributedValue(Local_Seed, Result, Minimum, Maximum);
			return Result;
		end function;

		procedure getUniformDistributedValue(Value : out integer; Minimum : in integer; Maximum : in integer) is
		begin
			randUniformDistributedValue(Local_Seed, Value, Minimum, Maximum);
		end procedure;

		impure function GetUniformDistributedValue(Minimum : in REAL; Maximum : in REAL) return REAL is
			variable Result		: REAL;
		begin
			randUniformDistributedValue(Local_Seed, Result, Minimum, Maximum);
			return Result;
		end function;

		procedure getUniformDistributedValue(Value : out REAL; Minimum : in REAL; Maximum : in REAL) is
		begin
			randUniformDistributedValue(Local_Seed, Value, Minimum, Maximum);
		end procedure;

		-- Normal distribution
		impure function getNormalDistributedValue(StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0) return REAL is
			variable Result		: REAL;
		begin
			randNormalDistributedValue(Local_Seed, Result, StandardDeviation, Mean);
			return Result;
		end function;

		procedure getNormalDistributedValue(Value : out REAL; StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0) is
		begin
			randNormalDistributedValue(Local_Seed, Value, StandardDeviation, Mean);
		end procedure;

		impure function getNormalDistributedValue(StandardDeviation : in REAL; Mean : in REAL; Minimum : in integer; Maximum : in integer) return integer is
			variable Result		: integer;
		begin
			randNormalDistributedValue(Local_Seed, Result, StandardDeviation, Mean, Minimum, Maximum);
			return Result;
		end function;

		procedure getNormalDistributedValue(Value : out integer; StandardDeviation : in REAL; Mean : in REAL; Minimum : in integer; Maximum : in integer) is
		begin
			randNormalDistributedValue(Local_Seed, Value, StandardDeviation, Mean, Minimum, Maximum);
		end procedure;

		impure function getNormalDistributedValue(StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL is
			variable Result		: REAL;
		begin
			randNormalDistributedValue(Local_Seed, Result, StandardDeviation, Mean, Minimum, Maximum);
			return Result;
		end function;

		procedure getNormalDistributedValue(Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
		begin
			randNormalDistributedValue(Local_Seed, Value, StandardDeviation, Mean, Minimum, Maximum);
		end procedure;

		-- Poisson distribution
		impure function getPoissonDistributedValue(Mean : in REAL) return REAL is
			variable Result		: REAL;
		begin
			randPoissonDistributedValue(Local_Seed, Result, Mean);
			return Result;
		end function;

		procedure getPoissonDistributedValue(Value : out REAL; Mean : in REAL) is
		begin
			randPoissonDistributedValue(Local_Seed, Value, Mean);
		end procedure;

		impure function getPoissonDistributedValue(Mean : in REAL; Minimum : in integer; Maximum : in integer) return integer is
			variable Result		: integer;
		begin
			randPoissonDistributedValue(Local_Seed, Result, Mean, Minimum, Maximum);
			return Result;
		end function;

		procedure getPoissonDistributedValue(Value : out integer; Mean : in REAL; Minimum : in integer; Maximum : in integer) is
		begin
			randPoissonDistributedValue(Local_Seed, Value, Mean, Minimum, Maximum);
		end procedure;

		impure function getPoissonDistributedValue(Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL is
			variable Result		: REAL;
		begin
			randPoissonDistributedValue(Local_Seed, Result, Mean, Minimum, Maximum);
			return Result;
		end function;

		procedure getPoissonDistributedValue(Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
		begin
			randPoissonDistributedValue(Local_Seed, Value, Mean, Minimum, Maximum);
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
