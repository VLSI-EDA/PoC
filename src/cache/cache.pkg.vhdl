-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Package:					Cache functions and types
--
-- Description:
-- -------------------------------------
--		For detailed documentation see below.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library	PoC;


package cache is
	-- cache-lookup Result
	type T_CACHE_RESULT	is (CACHE_RESULT_NONE, CACHE_RESULT_HIT, CACHE_RESULT_MISS);

	function to_Cache_Result(CacheHit : std_logic; CacheMiss : std_logic) return T_CACHE_RESULT;

end package;


package body cache is

	function to_cache_Result(CacheHit : std_logic; CacheMiss : std_logic) return T_CACHE_RESULT is
	begin
		if (CacheMiss = '1') then
			return CACHE_RESULT_MISS;
		elsif (CacheHit = '1') then
			return CACHE_RESULT_HIT;
		else
			return CACHE_RESULT_NONE;
		end if;
	end function;

end package body;
