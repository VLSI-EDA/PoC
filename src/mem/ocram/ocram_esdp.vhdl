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
-- Same-Port Read-During Write
--   When writing data through port 1, the read output of the same port
--   (``q1``) will output the new data (``d1``, in the following clock cycle)
--   which is aka. "write-first behavior". This behavior also applies to Altera
--   M20K memory blocks as described in the Altera: "Stratix 5 Device Handbook"
--   (S5-5V1). The documentation in the Altera: "Embedded Memory User Guide"
--   (UG-01068) is wrong.
--
-- Mixed-Port Read During Write
--   When reading at the write address, the read value will be unknown which is
--   aka. "don't care behavior". This applies to all reads (at the same
--   address) which are issued during the write-cycle time, which starts at the
--   rising-edge of the write clock (``clk1``) and (in the worst case) extends
--   until the next rising-edge of the write clock.
--
-- .. WARNING::
--    The simulated behavior on RT-level is too optimistic. When reading
--    at the write address always the new data will be returned.
--
-- .. TODO::
--    Implement correct behavior for RT-level simulation.
--    Xilinx Vivado synthesizes LUT-RAM, fix it.
--
-- License:
-- =============================================================================
-- Copyright 2008-2015 Technische Universitaet Dresden - Germany
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
	gInfer : if (VENDOR = VENDOR_GENERIC) or (VENDOR = VENDOR_LATTICE) or (VENDOR = VENDOR_XILINX) generate
		-- RAM can be inferred correctly
		-- XST Advanced HDL Synthesis generates extended simple dual-port
		-- memory as expected.
		-- RAM can be inferred correctly only for newer FPGAs!
		subtype word_t	is std_logic_vector(D_BITS - 1 downto 0);
		type		ram_t		is array(0 to DEPTH - 1) of word_t;

		-- Compute the initialization of a RAM array, if specified, from the passed file.
		impure function ocram_InitMemory(FilePath : string) return ram_t is
			variable Memory		: T_SLM(DEPTH - 1 downto 0, word_t'range);
			variable res			: ram_t;
		begin
			if str_length(FilePath) = 0 then
        -- shortcut required by Vivado
				return (others => (others => ite(SIMULATION, 'U', '0')));
			elsif mem_FileExtension(FilePath) = "mem" then
				Memory	:= mem_ReadMemoryFile(FilePath, DEPTH, word_t'length, MEM_FILEFORMAT_XILINX_MEM, MEM_CONTENT_HEX);
			else
				Memory	:= mem_ReadMemoryFile(FilePath, DEPTH, word_t'length, MEM_FILEFORMAT_INTEL_HEX, MEM_CONTENT_HEX);
			end if;

			for i in Memory'range(1) loop
				for j in word_t'range loop
					res(i)(j)		:= Memory(i, j);
				end loop;
			end loop;
			return  res;
		end function;

		signal ram			: ram_t		:= ocram_InitMemory(FILENAME);
		signal a1_reg		: unsigned(A_BITS-1 downto 0);
		signal a2_reg		: unsigned(A_BITS-1 downto 0);

	begin
		process (clk1)
		begin
			if rising_edge(clk1) then
				if ce1 = '1' then
					if we1 = '1' then
						ram(to_integer(a1)) <= d1;
					end if;

					a1_reg <= a1;
				end if;
			end if;
		end process;

		q1 <= (others => 'X') when SIMULATION and is_x(std_logic_vector(a1_reg)) else
					ram(to_integer(a1_reg));				-- gets new data

		process (clk2)
		begin	-- process
			if rising_edge(clk2) then
				if ce2 = '1' then
					a2_reg <= a2;
				end if;
			end if;
		end process;

		-- NOTE: Do not move into clocked process above, otherwise synthesis with
		-- XST will fail.
		-- TODO: read data is unknown, when reading at write address
		-- TODO: Improper synthesis results from Vivado.
		q2 <= (others => 'X') when SIMULATION and is_X(std_logic_vector(a2_reg)) else
					ram(to_integer(a2_reg));
	end generate gInfer;

	gAltera: if VENDOR = VENDOR_ALTERA generate
		component ocram_esdp_altera
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
				a1	 : in	unsigned(A_BITS-1 downto 0);
				a2	 : in	unsigned(A_BITS-1 downto 0);
				d1	 : in	std_logic_vector(D_BITS-1 downto 0);
				q1	 : out std_logic_vector(D_BITS-1 downto 0);
				q2	 : out std_logic_vector(D_BITS-1 downto 0)
			);
		end component;
	begin
		-- Direct instantiation of altsyncram (including component
		-- declaration above) is not sufficient for ModelSim.
		-- That requires also usage of altera_mf library.
		i: ocram_esdp_altera
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
				a1	 => a1,
				a2	 => a2,
				d1	 => d1,
				q1	 => q1,
				q2	 => q2
			);
	end generate gAltera;

	assert ((VENDOR = VENDOR_ALTERA) or (VENDOR = VENDOR_GENERIC) or (VENDOR = VENDOR_LATTICE) or (VENDOR = VENDOR_XILINX))
		report "Vendor '" & T_VENDOR'image(VENDOR) & "' not yet supported."
		severity failure;
end architecture;
