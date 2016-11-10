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
-- Inferring / instantiating single-port read-only memory
--
-- - single clock, clock enable
-- - 1 read port
--
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


library STD;
use			STD.TextIO.all;

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;
use			IEEE.std_logic_textio.all;

library	PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.strings.all;
use			PoC.vectors.all;
use			PoC.mem.all;


entity ocrom_sp is
	generic (
		A_BITS		: positive;
		D_BITS		: positive;
		FILENAME	: string		:= ""
	);
	port (
		clk	: in	std_logic;
		ce	: in	std_logic;
		a		: in	unsigned(A_BITS-1 downto 0);
		q		: out	std_logic_vector(D_BITS-1 downto 0)
	);
end entity;


architecture rtl of ocrom_sp is
	constant DEPTH				: positive := 2**A_BITS;

begin
	assert (str_length(FILENAME) /= 0) report "Do you really want to generate a block of zeros?" severity FAILURE;

	gInfer: if (VENDOR = VENDOR_GENERIC) or (VENDOR = VENDOR_XILINX) generate
		-- RAM can be inferred correctly
		-- XST Advanced HDL Synthesis generates single-port memory as expected.
		subtype word_t	is std_logic_vector(D_BITS - 1 downto 0);
		type		rom_t		is array(0 to DEPTH - 1) of word_t;

		-- Compute the initialization of a RAM array, if specified, from the passed file.
		impure function ocrom_InitMemory(FilePath : string) return rom_t is
			variable Memory		: T_SLM(DEPTH - 1 downto 0, word_t'range);
			variable res			: rom_t;
		begin
			if str_length(FilePath) = 0 then
        -- shortcut required by Vivado (assert above is ignored)
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

		constant rom	: rom_t		:= ocrom_InitMemory(FILENAME);
		signal a_reg	: unsigned(A_BITS-1 downto 0);
	begin
		process (clk)
		begin
			if rising_edge(clk) then
				if ce = '1' then
					a_reg <= a;
				end if;
			end if;
		end process;

		q <= rom(to_integer(a_reg));					-- gets new data
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
		i: ocram_sp_altera
			generic map (
				A_BITS		=> A_BITS,
				D_BITS		=> D_BITS,
				FILENAME	=> FILENAME
			)
			port map (
				clk => clk,
				ce	=> ce,
				we	=> '0',
				a	 => a,
				d	 => (others => '0'),
				q	 => q
			);
	end generate gAltera;

	assert ((VENDOR = VENDOR_ALTERA) or (VENDOR = VENDOR_GENERIC) or (VENDOR = VENDOR_XILINX))
		report "Vendor '" & T_VENDOR'image(VENDOR) & "' not yet supported."
		severity failure;
end architecture;
