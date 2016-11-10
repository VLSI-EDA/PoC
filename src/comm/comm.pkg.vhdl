-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Thomas B. Preusser
--
-- Entity:				 	VHDL package for component declarations, types and
--									functions associated to the PoC.comm namespace
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
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


package comm is
	-- Calculates the Remainder of the Division by the Generator Polynomial GEN.
	component comm_crc is
		generic (
			GEN	: bit_vector;																			-- Generator Polynom
			BITS : positive																				-- Number of Bits to be processed in parallel
		);
		port (
			clk	: in	std_logic;																	-- Clock

			set	: in std_logic;																		-- Parallel Preload of Remainder
			init : in std_logic_vector(GEN'length-2 downto 0);		--
			step : in std_logic;																	-- Process Input Data (MSB first)
			din	: in std_logic_vector(BITS-1 downto 0);						--

			rmd	: out std_logic_vector(GEN'length-2 downto 0);		-- Remainder
			zero : out std_logic																	-- Remainder is Zero
		);
	end component;

	-- Computes XOR masks for stream scrambling from an LFSR generator.
	component comm_scramble is
		generic (
			GEN	: bit_vector;																			-- Generator Polynomial (little endian)
			BITS : positive																				-- Width of Mask Bits to be computed in parallel
		);
		port (
			clk	: in	std_logic;																	-- Clock

			set	: in	std_logic;																	-- Set LFSR to provided Value
			din	: in	std_logic_vector(GEN'length-2 downto 0);		--

			step : in	std_logic;																	-- Compute a Mask Output
			mask : out std_logic_vector(BITS-1 downto 0)					--
		);
	end component;

end package;
