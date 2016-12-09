-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Martin Zabel
--									Patrick Lehmann
--
-- Entity:				 	Enhanced simple dual-port memory.
--
-- Description:
-- -------------------------------------
-- Inferring / instantiating enhanced simple dual-port memory, with:
--
-- * dual clock, clock enable,
-- * 1 read/write port (1st port) plus 1 read port (2nd port).
--
-- .. deprecated:: 1.1
--
--    **Please use** :ref:`IP:ocram_tdp` **for new designs.
--    This component has been provided because older FPGA compilers where not
--    able to infer true dual-port memory from an RTL description.**
--
-- Command truth table for port 1:
--
-- === === ================
-- ce1 we1 Command
-- === === ================
-- 0   X   No operation
-- 1   0   Read from memory
-- 1   1   Write to memory
-- === === ================
--
-- Command truth table for port 2:
--
-- === ================
-- ce2 Command
-- === ================
-- 0   No operation
-- 1   Read from memory
-- === ================
--
-- Both reading and writing are synchronous to the rising-edge of the clock.
-- Thus, when reading, the memory data will be outputted after the
-- clock edge, i.e, in the following clock cycle.
--
-- The generalized behavior across Altera and Xilinx FPGAs since
-- Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:
--
-- Same-Port Read-During-Write
--   When writing data through port 1, the read output of the same port
--   (``q1``) will output the new data (``d1``, in the following clock cycle)
--   which is aka. "write-first behavior".
--
-- Mixed-Port Read-During-Write
--   When reading at the write address, the read value will be unknown which is
--   aka. "don't care behavior". This applies to all reads (at the same
--   address) which are issued during the write-cycle time, which starts at the
--   rising-edge of the write clock (``clk1``) and (in the worst case) extends
--   until the next rising-edge of the write clock.
--
-- For simulation, always our dedicated simulation model :ref:`IP:ocram_tdp_sim`
-- is used.
--
-- License:
-- =============================================================================
-- Copyright 2008-2016 Technische Universitaet Dresden - Germany
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

library STD;
use			STD.TextIO.all;

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.strings.all;
use			PoC.vectors.all;
use			PoC.mem.all;


entity ocram_esdp is
	generic (
		A_BITS		: positive;															-- number of address bits
		D_BITS		: positive;															-- number of data bits
		FILENAME	: string		:= ""												-- file-name for RAM initialization
	);
	port (
		clk1 : in	std_logic;															-- clock for 1st port
		clk2 : in	std_logic;															-- clock for 2nd port
		ce1	: in	std_logic;															-- clock-enable for 1st port
		ce2	: in	std_logic;															-- clock-enable for 2nd port
		we1	: in	std_logic;															-- write-enable for 1st port
		a1	 : in	unsigned(A_BITS-1 downto 0);						-- address for 1st port
		a2	 : in	unsigned(A_BITS-1 downto 0);						-- address for 2nd port
		d1	 : in	std_logic_vector(D_BITS-1 downto 0);		-- write-data for 1st port
		q1	 : out std_logic_vector(D_BITS-1 downto 0);		-- read-data from 1st port
		q2	 : out std_logic_vector(D_BITS-1 downto 0) 		-- read-data from 2nd port
	);
end entity;


architecture rtl of ocram_esdp is
	constant DEPTH : positive := 2**A_BITS;

begin
	gInfer : if not SIMULATION and ((VENDOR = VENDOR_LATTICE) or (VENDOR = VENDOR_XILINX)) generate

		-- For Xilinx ISE, Xilinx Vivado and Lattice LSE we can reuse the ocram_tdp.
		--
		-- **Attention**: This encapsulation is mandatory for Xilinx Vivado,
		-- otherwise Vivado synthesizes a lot of LUT-RAM instead of Block-RAM.
		ram_tdp: entity poc.ocram_tdp
			generic map (
				A_BITS	 => A_BITS,
				D_BITS	 => D_BITS,
				FILENAME => FILENAME)
			port map (
				clk1 => clk1,
				clk2 => clk2,
				ce1	 => ce1,
				ce2	 => ce2,
				we1	 => we1,
				we2	 => '0',
				a1	 => a1,
				a2	 => a2,
				d1	 => d1,
				d2	 => (others => '0'),
				q1	 => q1,
				q2	 => q2);
	end generate gInfer;

	gAltera: if not SIMULATION and (VENDOR = VENDOR_ALTERA) generate
		component ocram_tdp_altera
			generic (
				A_BITS		: positive;
				D_BITS		: positive;
				FILENAME	: string		:= ""
			);
			port (
				clk1 : in	std_logic;
				clk2 : in	std_logic;
				ce1	: in	std_logic;
				ce2	: in	std_logic;
				we1	: in	std_logic;
				we2	: in	std_logic;
				a1	 : in	unsigned(A_BITS-1 downto 0);
				a2	 : in	unsigned(A_BITS-1 downto 0);
				d1	 : in	std_logic_vector(D_BITS-1 downto 0);
				d2	 : in	std_logic_vector(D_BITS-1 downto 0);
				q1	 : out std_logic_vector(D_BITS-1 downto 0);
				q2	 : out std_logic_vector(D_BITS-1 downto 0)
			);
		end component;
	begin
		-- Direct instantiation of altsyncram (including component
		-- declaration above) is not sufficient for ModelSim.
		-- That requires also usage of altera_mf library.
		ram_altera: ocram_tdp_altera
			generic map (
				A_BITS		=> A_BITS,
				D_BITS		=> D_BITS,
				FILENAME	=> FILENAME
			)
			port map (
				clk1 => clk1,
				clk2 => clk2,
				ce1	=> ce1,
				ce2	=> ce2,
				we1	=> we1,
				we2 => '0',
				a1	 => a1,
				a2	 => a2,
				d1	 => d1,
				d2   => (others => '0'),
				q1	 => q1,
				q2	 => q2
			);
	end generate gAltera;

	gSim: if SIMULATION generate
		-- Use component instantiation so that simulation model can be excluded
		-- from synthesis.
		component ocram_tdp_sim is
			generic (
				A_BITS	 : positive;
				D_BITS	 : positive;
				FILENAME : string);
			port (
				clk1 : in	 std_logic;
				clk2 : in	 std_logic;
				ce1	 : in	 std_logic;
				ce2	 : in	 std_logic;
				we1	 : in	 std_logic;
				we2	 : in	 std_logic;
				a1	 : in	 unsigned(A_BITS-1 downto 0);
				a2	 : in	 unsigned(A_BITS-1 downto 0);
				d1	 : in	 std_logic_vector(D_BITS-1 downto 0);
				d2	 : in	 std_logic_vector(D_BITS-1 downto 0);
				q1	 : out std_logic_vector(D_BITS-1 downto 0);
				q2	 : out std_logic_vector(D_BITS-1 downto 0));
		end component ocram_tdp_sim;
	begin
		sim_tdp: ocram_tdp_sim
			generic map (
				A_BITS	 => A_BITS,
				D_BITS	 => D_BITS,
				FILENAME => FILENAME)
			port map (
				clk1 => clk1,
				clk2 => clk2,
				ce1	 => ce1,
				ce2	 => ce2,
				we1	 => we1,
				we2	 => '0',
				a1	 => a1,
				a2	 => a2,
				d1	 => d1,
				d2	 => (others => '0'),
				q1	 => q1,
				q2	 => q2);
	end generate gSim;

	assert ((VENDOR = VENDOR_ALTERA) or (VENDOR = VENDOR_GENERIC and SIMULATION) or (VENDOR = VENDOR_LATTICE) or (VENDOR = VENDOR_XILINX))
		report "Vendor '" & T_VENDOR'image(VENDOR) & "' not yet supported."
		severity failure;
end architecture;
