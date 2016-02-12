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

	shared variable SeedValue		: T_SIM_SEED;
	
	-- procedural interface
	procedure randomInitializeSeed;
	
	procedure randomUniformDistibutedValue(Value : out REAL; Minimum : in REAL; Maximum : in REAL);
	
	procedure randomNormalDistibutedValue(Value : out REAL; StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0);
	procedure randomNormalDistibutedValue(Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);
	
	procedure randomPoissonDistibutedValue(Value : out REAL; Mean : in REAL);
	procedure randomPoissonDistibutedValue(Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL);
	
end package;


package body sim_random is
	procedure randomInitializeSeed is
	begin
		randInitializeSeed(SeedValue);
	end procedure;

	procedure randomUniformDistibutedValue(Value : out REAL; Minimum : in REAL; Maximum : in REAL) is
	begin
		randUniformDistibutedValue(SeedValue, Value, Minimum, Maximum);
	end procedure ;

	procedure randomNormalDistibutedValue(Value : out REAL; StandardDeviation : in REAL := 1.0; Mean : in REAL := 0.0) is
	begin
		randNormalDistibutedValue(SeedValue, Value, StandardDeviation, Mean);
	end procedure;

	procedure randomNormalDistibutedValue(Value : out REAL; StandardDeviation : in REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
	begin
		randNormalDistibutedValue(SeedValue, Value, StandardDeviation, Mean, Minimum, Maximum);
	end procedure;
	
	procedure randomPoissonDistibutedValue(Value : out REAL; Mean : in REAL) is
	begin
		randPoissonDistibutedValue(SeedValue, Value, Mean);
	end procedure;
	
	procedure randomPoissonDistibutedValue(Value : out REAL; Mean : in REAL; Minimum : in REAL; Maximum : in REAL) is
	begin
		randPoissonDistibutedValue(SeedValue, Value, Mean, Minimum, Maximum);
	end procedure;
end package body;
