-- EMACS settings: -*-  tab-width: 2;indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2;replace-tabs off;indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Package:     		Protected type implementations.
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany,
--  					 				 Chair for VLSI-Design, Diagnostics and Architecture
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
use			IEEE.math_real.all;

library	PoC;
-- use			PoC.my_project.all;
-- use			PoC.utils.all;


package ProtectedTypes is
	-- protected BOOLEAN implementation
	-- ===========================================================================
	type P_BOOLEAN is protected
		procedure				Clear;
		procedure				Set(Value : BOOLEAN := TRUE);
		impure function	Get return BOOLEAN;
		impure function Toggle return BOOLEAN;
	end protected;

	-- protected INTEGER implementation
	-- ===========================================================================
	-- TODO: Mult, Div, Pow, Mod, Rem
	type P_INTEGER is protected
		procedure				Clear;
		procedure				Set(Value : INTEGER);
		impure function	Get return INTEGER;
		procedure				Add(Value : INTEGER);
		impure function Add(Value : INTEGER) return INTEGER;
		procedure				Sub(Value : INTEGER);
		impure function Sub(Value : INTEGER) return INTEGER;
	end protected;

	-- protected NATURAL implementation
	-- ===========================================================================
	-- TODO: Mult, Div, Pow, Mod, Rem
	type P_NATURAL is protected
		procedure				Clear;
		procedure				Set(Value : NATURAL);
		impure function	Get return NATURAL;
		procedure				Add(Value : NATURAL);
		impure function Add(Value : NATURAL) return NATURAL;
		procedure				Sub(Value : NATURAL);
		impure function Sub(Value : NATURAL) return NATURAL;
	end protected;

	-- protected POSITIVE implementation
	-- ===========================================================================
	-- TODO: Mult, Div, Pow, Mod, Rem
	type P_POSITIVE is protected
		procedure				Clear;
		procedure				Set(Value : POSITIVE);
		impure function	Get return POSITIVE;
		procedure				Add(Value : POSITIVE);
		impure function Add(Value : POSITIVE) return POSITIVE;
		procedure				Sub(Value : POSITIVE);
		impure function Sub(Value : POSITIVE) return POSITIVE;
	end protected;

	-- protected REAL implementation
	-- ===========================================================================
	-- TODO: Round, Mult, Div, Pow, Mod
	type P_REAL is protected
		procedure				Clear;
		procedure				Set(Value : REAL);
		impure function	Get return REAL;
		procedure				Add(Value : REAL);
		impure function Add(Value : REAL) return REAL;
		procedure				Sub(Value : REAL);
		impure function Sub(Value : REAL) return REAL;
	end protected;
end package;


package body ProtectedTypes is
	-- protected BOOLEAN implementation
	-- ===========================================================================
	type P_BOOLEAN is protected body
		variable InnerValue		: BOOLEAN		:= FALSE;

		procedure Clear is
		begin
			InnerValue	:= FALSE;
		end procedure;

		procedure Set(Value : BOOLEAN := TRUE) is
		begin
			InnerValue	:= Value;
		end procedure;

		impure function Get return BOOLEAN is
		begin
			return InnerValue;
		end function;

		impure function Toggle return BOOLEAN is
		begin
			InnerValue	:= not InnerValue;
			return InnerValue;
		end function;
	end protected body;

	-- protected INTEGER implementation
	-- ===========================================================================
	type P_INTEGER is protected body
		variable InnerValue		: INTEGER		:= 0;

		procedure Clear is
		begin
			InnerValue	:= 0;
		end procedure;

		procedure Set(Value : INTEGER) is
		begin
			InnerValue	:= Value;
		end procedure;

		impure function Get return INTEGER is
		begin
			return InnerValue;
		end function;

		procedure Add(Value : INTEGER) is
		begin
			InnerValue	:= InnerValue + Value;
		end procedure;

		impure function Add(Value : INTEGER) return INTEGER is
		begin
			Add(Value);
			return InnerValue;
		end function;

		procedure Sub(Value : INTEGER) is
		begin
			InnerValue	:= InnerValue - Value;
		end procedure;

		impure function Sub(Value : INTEGER) return INTEGER is
		begin
			Sub(Value);
			return InnerValue;
		end function;
	end protected body;

	-- protected NATURAL implementation
	-- ===========================================================================
	type P_NATURAL is protected body
		variable InnerValue		: NATURAL		:= 0;

		procedure Clear is
		begin
			InnerValue	:= 0;
		end procedure;

		procedure Set(Value : NATURAL) is
		begin
			InnerValue	:= Value;
		end procedure;

		impure function Get return NATURAL is
		begin
			return InnerValue;
		end function;

		procedure Add(Value : NATURAL) is
		begin
			InnerValue	:= InnerValue + Value;
		end procedure;

		impure function Add(Value : NATURAL) return NATURAL is
		begin
			Add(Value);
			return InnerValue;
		end function;

		procedure Sub(Value : NATURAL) is
		begin
			InnerValue	:= InnerValue - Value;
		end procedure;

		impure function Sub(Value : NATURAL) return NATURAL is
		begin
			Sub(Value);
			return InnerValue;
		end function;
	end protected body;

	-- protected POSITIVE implementation
	-- ===========================================================================
	type P_POSITIVE is protected body
		variable InnerValue		: POSITIVE		:= 1;

		procedure Clear is
		begin
			InnerValue	:= 1;
		end procedure;

		procedure Set(Value : POSITIVE) is
		begin
			InnerValue	:= Value;
		end procedure;

		impure function Get return POSITIVE is
		begin
			return InnerValue;
		end function;

		procedure Add(Value : POSITIVE) is
		begin
			InnerValue	:= InnerValue + Value;
		end procedure;

		impure function Add(Value : POSITIVE) return POSITIVE is
		begin
			Add(Value);
			return InnerValue;
		end function;

		procedure Sub(Value : POSITIVE) is
		begin
			InnerValue	:= InnerValue - Value;
		end procedure;

		impure function Sub(Value : POSITIVE) return POSITIVE is
		begin
			Sub(Value);
			return InnerValue;
		end function;
	end protected body;

	-- protected REAL implementation
	-- ===========================================================================
	type P_REAL is protected body
		variable InnerValue		: REAL		:= 0.0;

		procedure Clear is
		begin
			InnerValue	:= 0.0;
		end procedure;

		procedure Set(Value : REAL) is
		begin
			InnerValue	:= Value;
		end procedure;

		impure function Get return REAL is
		begin
			return InnerValue;
		end function;

		procedure Add(Value : REAL) is
		begin
			InnerValue	:= InnerValue + Value;
		end procedure;

		impure function Add(Value : REAL) return REAL is
		begin
			Add(Value);
			return InnerValue;
		end function;

		procedure Sub(Value : REAL) is
		begin
			InnerValue	:= InnerValue - Value;
		end procedure;

		impure function Sub(Value : REAL) return REAL is
		begin
			Sub(Value);
			return InnerValue;
		end function;
	end protected body;
end package body;
