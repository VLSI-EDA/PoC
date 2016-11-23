-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Martin Zabel
--									Patrick Lehmann
--
-- Entity:				 	Single-port memory.
--
-- Description:
-- -------------------------------------
-- Inferring / instantiating single port memory, with:
--
-- * single clock, clock enable,
-- * 1 read/write port.
--
-- Command Truth Table:
--
-- == == ================
-- ce we Command
-- == == ================
-- 0  X  No operation
-- 1  0  Read from memory
-- 1  1  Write to memory
-- == == ================
--
-- Both reading and writing are synchronous to the rising-edge of the clock.
-- Thus, when reading, the memory data will be outputted after the
-- clock edge, i.e, in the following clock cycle.
--
-- When writing data, the read output will output the new data (in the
-- following clock cycle) which is aka. "write-first behavior". This behavior
-- also applies to Altera M20K memory blocks as described in the Altera:
-- "Stratix 5 Device Handbook" (S5-5V1). The documentation in the Altera:
-- "Embedded Memory User Guide" (UG-01068) is wrong.
--
-- License:
-- =============================================================================
-- Copyright 2008-2015 Technische Universitaet Dresden - Germany
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
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.strings.all;
use			PoC.vectors.all;
use			PoC.mem.all;


entity ocram_sp is
	generic (
		A_BITS		: positive;															-- number of address bits
		D_BITS		: positive;															-- number of data bits
		FILENAME	: string		:= ""												-- file-name for RAM initialization
	);
	port (
		clk : in	std_logic;															-- clock
		ce	: in	std_logic;															-- clock enable
		we	: in	std_logic;															-- write enable
		a	 : in	unsigned(A_BITS-1 downto 0);							-- address
		d	 : in	std_logic_vector(D_BITS-1 downto 0);			-- write data
		q	 : out std_logic_vector(D_BITS-1 downto 0) 			-- read output
	);
end entity;


architecture rtl of ocram_sp is
	constant DEPTH			: positive := 2**A_BITS;

begin

	gInfer : if (VENDOR = VENDOR_GENERIC) or (VENDOR = VENDOR_LATTICE) or (VENDOR = VENDOR_XILINX) generate
		-- RAM can be inferred correctly
		-- XST Advanced HDL Synthesis generates single-port memory as expected.
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

		signal ram		: ram_t		:= ocram_InitMemory(FILENAME);
		signal a_reg	: unsigned(A_BITS-1 downto 0);

	begin
		process (clk)
		begin
			if rising_edge(clk) then
				if ce = '1' then
					if we = '1' then
						ram(to_integer(a)) <= d;
					end if;

					a_reg <= a;
				end if;
			end if;
		end process;

		q <= (others => 'X') when SIMULATION and is_x(std_logic_vector(a_reg)) else
				 ram(to_integer(a_reg));					-- gets new data
	end generate gInfer;

	gAltera: if VENDOR = VENDOR_ALTERA generate
		component ocram_sp_altera
			generic (
				A_BITS		: positive;
				D_BITS		: positive;
				FILENAME	: string		:= ""
			);
			port (
				clk : in	std_logic;
				ce	: in	std_logic;
				we	: in	std_logic;
				a	 : in	unsigned(A_BITS-1 downto 0);
				d	 : in	std_logic_vector(D_BITS-1 downto 0);
				q	 : out std_logic_vector(D_BITS-1 downto 0));
		end component;
	begin
		-- Direct instantiation of altsyncram (including component
		-- declaration above) is not sufficient for ModelSim.
		-- That requires also usage of altera_mf library.
		ram_altera: ocram_sp_altera
			generic map (
				A_BITS		=> A_BITS,
				D_BITS		=> D_BITS,
				FILENAME	=> FILENAME
			)
			port map (
				clk => clk,
				ce	=> ce,
				we	=> we,
				a	 => a,
				d	 => d,
				q	 => q
			);
	end generate gAltera;

	assert ((VENDOR = VENDOR_ALTERA) or (VENDOR = VENDOR_GENERIC) or (VENDOR = VENDOR_LATTICE) or (VENDOR = VENDOR_XILINX))
		report "Vendor '" & T_VENDOR'image(VENDOR) & "' not yet supported."
		severity failure;
end architecture;
