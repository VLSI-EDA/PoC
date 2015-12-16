-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:				 	Martin Zabel
--									Thomas B. Preusser
--									Patrick Lehmann
--
-- Module:				 	Simple dual-port memory.
--
-- Description:
-- ------------------------------------
-- Inferring / instantiating simple dual-port memory, with:
--	* dual clock, clock enable,
--	* 1 read port plus 1 write port.
--
-- The generalized behavior across Altera and Xilinx FPGAs since
-- Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:
--
--   The Altera M512/M4K TriMatrix memory (as found e.g. in Stratix and
--   Stratix II FPGAs) defines the minimum time after which the written data at
--   the write port can be read-out at read port again. As stated in the Stratix
--   Handbook, Volume 2, page 2-13, data is actually written with the falling
--   (instead of the rising) edge of the clock into the memory array. The write
--   itself takes the write-cycle time which is less or equal to the minimum
--   clock-period time. After this, the data can be read-out at the other port.
--   Consequently, data "d" written at the rising-edge of "wclk" at address
--   "wa" can be read-out at the read port from the same address with the
--   2nd rising-edge of "rclk" following the falling-edge of "wclk".
--   If the rising-edge of "rclk" coincides with the falling-edge of "wclk"
--   (e.g. same clock signal), then it is counted as the 1st rising-edge of
--   "rclk" in this timing.
--
-- WARNING: The simulated behavior on RT-level is not correct.
--
-- TODO: add timing diagram
-- TODO: implement correct behavior for RT-level simulation
--
-- License:
-- ============================================================================
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
-- ============================================================================

library std;
use			std.TextIO.all;

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;
use			IEEE.std_logic_textio.all;

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.strings.all;


entity ocram_sdp is
	generic (
		A_BITS		: positive;
		D_BITS		: positive;
		FILENAME	: STRING		:= ""
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

	gInfer: if VENDOR = VENDOR_XILINX or VENDOR = VENDOR_ALTERA generate
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
		
    subtype word_t is std_logic_vector(D_BITS - 1 downto 0);
    type ram_t is array(0 to DEPTH - 1) of word_t;

		-- Compute the initialization of a RAM array, if specified, from the passed file.
    impure function ocram_InitMemory(FileName : string) return ram_t is
			-- Read the specified file name into the RAM array.
			procedure ReadMemFile(FileName : in string; variable mem : inout ram_t) is
				file FileHandle      : TEXT open READ_MODE is FileName;
				variable CurrentLine : LINE;
				variable TempWord    : STD_LOGIC_VECTOR((div_ceil(word_t'length, 4) * 4) - 1 downto 0);
			begin
				-- discard the first line of a mem file
				if (str_toLower(FileName(FileName'length - 3 to FileName'length)) = ".mem") then
					readline(FileHandle, CurrentLine);
				end if;

				for i in 0 to DEPTH - 1 loop
					exit when endfile(FileHandle);

					readline(FileHandle, CurrentLine);
					hread(CurrentLine, TempWord);
					mem(i) := TempWord(word_t'range);
				end loop;
			end procedure;

			variable res : ram_t;
		begin
			res		:= (others => (others => 'U'));
			
			if str_length(FileName) > 0 then
				ReadMemFile(FileName, res);
			end if;
			return  res;
		end function;

    signal ram : ram_t := ocram_InitMemory(FILENAME);
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
          elsif ra = wa then
            -- read data unknown when reading at write address
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

	assert VENDOR = VENDOR_XILINX or VENDOR = VENDOR_ALTERA
		report "Vendor not yet supported."
		severity failure;
end architecture;
