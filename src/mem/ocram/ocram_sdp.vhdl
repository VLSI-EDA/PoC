-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Martin Zabel
--									Thomas B. Preusser
--									Patrick Lehmann
--
-- Entity:				 	Simple dual-port memory.
--
-- Description:
-- -------------------------------------
-- Inferring / instantiating simple dual-port memory, with:
--
-- * dual clock, clock enable,
-- * 1 read port plus 1 write port.
--
-- The generalized behavior across Altera and Xilinx FPGAs since
-- Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:
--
-- Mixed-Port Read During Write
--   When reading at the write address, the read value will be unknown which is
--   aka. "don't care behavior". This applies to all reads (at the same
--   address) which are issued during the write-cycle time, which starts at the
--   rising-edge of the write clock and (in the worst case) extends until the
--   next rising-edge of the write clock.
--
-- .. WARNING::
--    The simulated behavior on RT-level is too optimistic. The
--    mixed-port read-during-write behavior is only valid if the read and write
--    clock are in phase. Otherwise, simulation will always show known data.
--
-- .. TODO:: Implement correct behavior for RT-level simulation.
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

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.strings.all;
use			PoC.vectors.all;
use			PoC.mem.all;


entity ocram_sdp is
	generic (
		A_BITS		: positive;															-- number of address bits
		D_BITS		: positive;															-- number of data bits
		FILENAME	: string		:= ""												-- file-name for RAM initialization
	);
	port (
		rclk	: in	std_logic;														-- read clock
		rce		: in	std_logic;														-- read clock-enable
		wclk	: in	std_logic;														-- write clock
		wce		: in	std_logic;														-- write clock-enable
		we		: in	std_logic;														-- write enable
		ra		: in	unsigned(A_BITS-1 downto 0);					-- read address
		wa		: in	unsigned(A_BITS-1 downto 0);					-- write address
		d			: in	std_logic_vector(D_BITS-1 downto 0);	-- data in
		q			: out std_logic_vector(D_BITS-1 downto 0)		-- data out
	);
end entity;


architecture rtl of ocram_sdp is
  constant DEPTH : positive := 2**A_BITS;

begin

	gInfer : if (VENDOR = VENDOR_ALTERA) or (VENDOR = VENDOR_GENERIC) or (VENDOR = VENDOR_LATTICE) or (VENDOR = VENDOR_XILINX) generate
		-- RAM can be inferred correctly
		-- Xilinx notes:
		--	 WRITE_MODE is set to WRITE_FIRST, but this also means that read data
		--	 is unknown on the opposite port. (As expected.)
		-- Altera notes:
		--	 Setting attribute "ramstyle" to "no_rw_check" suppresses generation of
		--	 bypass logic, when 'clk1'='clk2' and 'ra' is feed from a register.
		--	 This is the expected behaviour.
		--	 With two different clocks, synthesis complains about an undefined
		--	 read-write behaviour, that can be ignored.

    attribute ramstyle : string;

    subtype	word_t	is std_logic_vector(D_BITS - 1 downto 0);
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

		signal ram : ram_t	:= ocram_InitMemory(FILENAME);
		attribute ramstyle of ram : signal is "no_rw_check";

	begin
		process(wclk)
		begin
			if rising_edge(wclk) then
				if (wce and we) = '1' then
					-- Note: Hide plausibility tests from synthesis to ensure
					--       proper RAM inference.
					--synthesis translate_off
					if Is_X(std_logic_vector(wa)) then
						report "ocram_sdp: Writing to ill-defined address."
							severity error;
					else
					--synthesis translate_on
						ram(to_integer(wa)) <= d;
					--synthesis translate_off
					end if;
					--synthesis translate_on
				end if;
			end if;
		end process;

		process(rclk)
		begin
			if rising_edge(rclk) then
				if rce = '1' then
					-- Note: Hide plausibility tests from synthesis to ensure
					--       proper RAM inference.
					--synthesis translate_off
					if Is_X(std_logic_vector(ra)) then
						q <= (others => 'X');
					elsif wce = '1' and we = '1' and ra = wa and rising_edge(wclk) then
						-- read data unknown when reading at write address,
						-- and both clock-edges are at almost the same time
						q <= (others => 'X');
						report "ocram_sdp: Reading from address just writing: Unknown result."
							severity warning;
					else
					--synthesis translate_on
						q <= ram(to_integer(ra));
					--synthesis translate_off
					end if;
					--synthesis translate_on
				end if;
			end if;
		end process;
	end generate gInfer;

	assert ((VENDOR = VENDOR_ALTERA) or (VENDOR = VENDOR_GENERIC) or (VENDOR = VENDOR_LATTICE) or (VENDOR = VENDOR_XILINX))
		report "Vendor '" & T_VENDOR'image(VENDOR) & "' not yet supported."
		severity failure;
end architecture;
