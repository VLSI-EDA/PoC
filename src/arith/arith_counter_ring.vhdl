-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Module:				 	TODO
--
-- Authors:				 	Patrick Lehmann
-- 
-- Description:
-- ------------------------------------
--		TODO
--
-- License:
-- ============================================================================
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
-- ============================================================================

LIBRARY IEEE;
USE			IEEE.STD_LOGIC_1164.ALL;

LIBRARY PoC;
USE			PoC.utils.ALL;


ENTITY arith_counter_ring IS
	GENERIC (
		BITS						: POSITIVE;
		INVERT_FEEDBACK	: BOOLEAN		:= FALSE																	-- FALSE -> ring counter;		TRUE -> johnson counter
	);
	PORT (
		Clock		: IN	STD_LOGIC;																							-- Clock
		Reset		: IN	STD_LOGIC;																							-- Reset
		seed		: IN	STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0)	:= (OTHERS => '0');	-- initial counter vector / load value
		inc			: IN	STD_LOGIC														:= '0';							-- increment counter
		dec			: IN	STD_LOGIC														:= '0';							-- decrement counter
		value		: OUT STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0)											-- counter value
	);
END;


ARCHITECTURE rtl OF arith_counter_ring IS
	CONSTANT INVERT		: STD_LOGIC			:= to_sl(INVERT_FEEDBACK);

	SIGNAL counter		: STD_LOGIC_VECTOR(BITS - 1 DOWNTO 0)	:= (OTHERS => '0');

BEGIN
	PROCESS(Clock)
	BEGIN
		IF rising_edge(Clock) THEN
			IF (Reset = '1') THEN
				counter			<= seed;
			ELSE
				IF (inc = '1') THEN
					counter		<= counter(counter'high - 1 DOWNTO 0) & (counter(counter'high) XOR INVERT);
				ELSIF (dec = '1') THEN
					counter		<= (counter(0) XOR INVERT) & counter(counter'high DOWNTO 1);
				END IF;
			END IF;
		END IF;
	END PROCESS;

	value		<= counter;
END;
