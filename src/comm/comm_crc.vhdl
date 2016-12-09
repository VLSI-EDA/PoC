-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--									Patrick Lehmann
--
-- Entity:					Computes the Cyclic Redundancy Check (CRC)
--
-- Description:
-- -------------------------------------
-- Computes the Cyclic Redundancy Check (CRC) for a data packet as remainder
-- of the polynomial division of the message by the given generator
-- polynomial (GEN).
--
-- The computation is unrolled so as to process an arbitrary number of
-- message bits per step. The generated CRC is independent from the chosen
-- processing width.
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

library	PoC;
use			PoC.utils.all;


entity comm_crc is
	generic (
		GEN		: bit_vector;		 															-- Generator Polynomial
		BITS	: positive;			 															-- Number of Bits to be processed in parallel

		STARTUP_RMD : std_logic_vector	:= "0";
		OUTPUT_REGS : boolean						:= true
	);
	port (
		clk	: in	std_logic;																-- Clock

		set	: in	std_logic;																-- Parallel Preload of Remainder
		init : in	std_logic_vector(abs(mssb_idx(GEN)-GEN'right)-1 downto 0);	--
		step : in	std_logic;																-- Process Input Data (MSB first)
		din	: in	std_logic_vector(BITS-1 downto 0);				--

		rmd	: out std_logic_vector(abs(mssb_idx(GEN)-GEN'right)-1 downto 0);	-- Remainder
		zero : out std_logic																-- Remainder is Zero
	);
end entity comm_crc;


architecture rtl of comm_crc is

	-----------------------------------------------------------------------------
	-- Normalizes the generator representation:
	--	 - into a 'downto 0' index range and
	--	 - truncating it just below the most significant and so hidden '1'.
	function normalize(G : bit_vector) return bit_vector is
		variable GN : bit_vector(G'length-1 downto 0);
	begin
		GN := G;
		for i in GN'left downto 1 loop
			if GN(i) = '1' then
				return	GN(i-1 downto 0);
			end if;
		end loop;
		report "Cannot use absolute constant as generator."
			severity failure;
		return	GN;
	end normalize;

	-- Normalized Generator
	constant GN : std_logic_vector := to_stdlogicvector(normalize(GEN));

	-- LFSR Value
	signal lfsr : std_logic_vector(GN'range) := resize(descend(STARTUP_RMD), GN'length);
	signal lfsn : std_logic_vector(GN'range);	-- Next Value
	signal lfso : std_logic_vector(GN'range);	-- Output

begin

	-- Compute next combinational Value
	process(lfsr, din)
		variable v : std_logic_vector(lfsr'range);
	begin
		v := lfsr;
		for i in BITS-1 downto 0 loop
			v := (v(v'left-1 downto 0) & '0') xor
					 (GN and (GN'range => (din(i) xor v(v'left))));
		end loop;
		lfsn <= v;
	end process;

	-- Remainder Register
	process(clk)
	begin
		if rising_edge(clk) then
			if set = '1' then
				lfsr <= init(lfsr'range);
			elsif step = '1' then
				lfsr <= lfsn;
			end if;
		end if;
	end process;

	-- Provide Outputs
	lfso <= lfsr when OUTPUT_REGS else lfsn;
	rmd	<= lfso;
	zero <= '1' when lfso = (lfso'range => '0') else '0';

end architecture;
