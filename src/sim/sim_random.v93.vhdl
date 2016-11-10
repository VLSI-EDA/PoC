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
	procedure				randomInitializeSeed;
	procedure				randomInitializeSeed(Seed : T_SIM_SEED);
	procedure				randomInitializeSeed(Seed1 : integer; Seed2 : integer);
	procedure				randomInitializeSeed(SeedVector : T_INTVEC);
	procedure				randomInitializeSeed(SeedVector : string);

	-- Uniform distributed random values
	-- ===========================================================================
	procedure				randomUniformDistributedValue(Value : out REAL);
	procedure				randomUniformDistributedValue(Value : out integer; Minimum : in integer; Maximum : in integer);
	procedure				randomUniformDistributedValue(Value : out REAL; Minimum : in REAL; Maximum : in REAL);

	impure function	randomUniformDistributedValue return REAL;
	impure function	randomUniformDistributedValue(Minimum : in integer; Maximum : in integer) return integer;
	impure function	randomUniformDistributedValue(Minimum : in REAL; Maximum : in REAL) return REAL;

	-- Normal / Gaussian distributed random values
	-- ===========================================================================
	procedure				randomNormalDistributedValue(Value : out REAL; StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0);
	procedure				randomNormalDistributedValue(Value : out integer; StandardDeviation : in REAL; Mean : in REAL; Minimum : in integer; Maximum : in integer);
	procedure				randomNormalDistributedValue(Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);

	impure function	randomNormalDistributedValue(StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0) return REAL;
	impure function	randomNormalDistributedValue(StandardDeviation : in REAL; Mean : in REAL; Minimum : in integer; Maximum : in integer) return integer;
	impure function	randomNormalDistributedValue(StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL;

	-- Poisson distributed random values
	-- ===========================================================================
	procedure				randomPoissonDistributedValue(Value : out REAL; Mean : in REAL);
	procedure				randomPoissonDistributedValue(Value : out integer; Mean : in REAL; Minimum : in integer; Maximum : in integer);
	procedure				randomPoissonDistributedValue(Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);

	impure function	randomPoissonDistributedValue(Mean : in REAL) return REAL;
	impure function	randomPoissonDistributedValue(Mean : in REAL; Minimum : in integer; Maximum : in integer) return integer;
	impure function	randomPoissonDistributedValue(Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL;
end package;


package body sim_random is
	shared variable SeedValue		: T_SIM_SEED	:= randInitializeSeed;

	procedure randomInitializeSeed is
	begin
		randInitializeSeed(SeedValue);
	end procedure;

	procedure randomInitializeSeed(Seed : T_SIM_SEED) is
	begin
		randInitializeSeed(SeedValue, Seed);
	end procedure;

	procedure randomInitializeSeed(Seed1 : integer; Seed2 : integer) is
	begin
		randInitializeSeed(SeedValue, T_SIM_RAND_SEED'(Seed1, Seed2));
	end procedure;

	procedure randomInitializeSeed(SeedVector : T_INTVEC) is
	begin
		randInitializeSeed(SeedValue, SeedVector);
	end procedure;

	procedure randomInitializeSeed(SeedVector : string) is
	begin
		randInitializeSeed(SeedValue, SeedVector);
	end procedure;

	-- ===========================================================================
	-- Uniform distributed random values
	-- ===========================================================================
	procedure randomUniformDistributedValue(Value : out REAL) is
	begin
		randUniformDistributedValue(SeedValue, Value);
	end procedure;

	procedure randomUniformDistributedValue(Value : out integer; Minimum : in integer; Maximum : in integer) is
	begin
		randUniformDistributedValue(SeedValue, Value, Minimum, Maximum);
	end procedure;

	procedure randomUniformDistributedValue(Value : out REAL; Minimum : in REAL; Maximum : in REAL) is
	begin
		randUniformDistributedValue(SeedValue, Value, Minimum, Maximum);
	end procedure;

	impure function randomUniformDistributedValue return REAL is
		variable Result		: REAL;
	begin
		randUniformDistributedValue(SeedValue, Result);
		return Result;
	end function;

	impure function randomUniformDistributedValue(Minimum : in integer; Maximum : in integer) return integer is
		variable Result		: integer;
	begin
		randUniformDistributedValue(SeedValue, Result, Minimum, Maximum);
		return Result;
	end function;

	impure function randomUniformDistributedValue(Minimum : in REAL; Maximum : in REAL) return REAL is
		variable Result		: REAL;
	begin
		randUniformDistributedValue(SeedValue, Result, Minimum, Maximum);
		return Result;
	end function;

	-- ===========================================================================
	-- Normal / Gaussian distributed random values
	-- ===========================================================================
	procedure randomNormalDistributedValue(Value : out REAL; StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0) is
	begin
		randNormalDistributedValue(SeedValue, Value, StandardDeviation, Mean);
	end procedure;

	procedure randomNormalDistributedValue(Value : out integer; StandardDeviation : in REAL; Mean : in REAL; Minimum : in integer; Maximum : in integer) is
	begin
		randNormalDistributedValue(SeedValue, Value, StandardDeviation, Mean, Minimum, Maximum);
	end procedure;

	procedure randomNormalDistributedValue(Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
	begin
		randNormalDistributedValue(SeedValue, Value, StandardDeviation, Mean, Minimum, Maximum);
	end procedure;

	impure function randomNormalDistributedValue(StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0) return REAL is
		variable Result		: REAL;
	begin
		randNormalDistributedValue(SeedValue, Result, StandardDeviation, Mean);
		return Result;
	end function;

	impure function randomNormalDistributedValue(StandardDeviation : in REAL; Mean : in REAL; Minimum : in integer; Maximum : in integer) return integer is
		variable Result		: integer;
	begin
		randNormalDistributedValue(SeedValue, Result, StandardDeviation, Mean, Minimum, Maximum);
		return Result;
	end function;

	impure function randomNormalDistributedValue(StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL is
		variable Result		: REAL;
	begin
		randNormalDistributedValue(SeedValue, Result, StandardDeviation, Mean, Minimum, Maximum);
		return Result;
	end function;

	-- ===========================================================================
	-- Poisson distributed random values
	-- ===========================================================================
	procedure randomPoissonDistributedValue(Value : out REAL; Mean : in REAL) is
	begin
		randPoissonDistributedValue(SeedValue, Value, Mean);
	end procedure;

	procedure randomPoissonDistributedValue(Value : out integer; Mean : in REAL; Minimum : in integer; Maximum : in integer) is
	begin
		randPoissonDistributedValue(SeedValue, Value, Mean, Minimum, Maximum);
	end procedure;

	procedure randomPoissonDistributedValue(Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
	begin
		randPoissonDistributedValue(SeedValue, Value, Mean, Minimum, Maximum);
	end procedure;

	impure function randomPoissonDistributedValue(Mean : in REAL) return REAL is
		variable Result		: REAL;
	begin
		randPoissonDistributedValue(SeedValue, Result, Mean);
		return Result;
	end function;

	impure function randomPoissonDistributedValue(Mean : in REAL; Minimum : in integer; Maximum : in integer) return integer is
		variable Result		: integer;
	begin
		randPoissonDistributedValue(SeedValue, Result, Mean, Minimum, Maximum);
		return Result;
	end function;

	impure function randomPoissonDistributedValue(Mean : in REAL; Minimum : in REAL; Maximum : in REAL) return REAL is
		variable Result		: REAL;
	begin
		randPoissonDistributedValue(SeedValue,Result, Mean, Minimum, Maximum);
		return Result;
	end function;
end package body;
