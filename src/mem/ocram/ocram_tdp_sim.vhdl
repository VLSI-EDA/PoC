-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Martin Zabel
--
-- Entity:				 	Simulation model for true dual-port memory.
--
-- Description:
-- -------------------------------------
-- Simulation model for true dual-port memory, with:
--
-- * dual clock, clock enable,
-- * 2 read/write ports.
--
-- The interface matches that of the IP core PoC.mem.ocram.tdp.
-- But the implementation there is restricted to the description supported by
-- various synthesis compilers. The implementation here also simulates the
-- correct Mixed-Port Read-During-Write Behavior and handles X propagation.
--
-- License:
-- =============================================================================
-- Copyright 2016-2016 Technische Universitaet Dresden - Germany
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
use			PoC.utils.all;
use			PoC.strings.all;
use			PoC.vectors.all;
use			PoC.mem.all;


entity ocram_tdp_sim is
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
		we2	: in	std_logic;															-- write-enable for 2nd port
		a1	 : in	unsigned(A_BITS-1 downto 0);						-- address for 1st port
		a2	 : in	unsigned(A_BITS-1 downto 0);						-- address for 2nd port
		d1	 : in	std_logic_vector(D_BITS-1 downto 0);		-- write-data for 1st port
		d2	 : in	std_logic_vector(D_BITS-1 downto 0);		-- write-data for 2nd port
		q1	 : out std_logic_vector(D_BITS-1 downto 0);		-- read-data from 1st port
		q2	 : out std_logic_vector(D_BITS-1 downto 0) 		-- read-data from 2nd port
	);
end entity;


architecture sim of ocram_tdp_sim is
	constant DEPTH : positive := 2**A_BITS;
		subtype word_t	is std_logic_vector(D_BITS - 1 downto 0);
		type		ram_t		is array(0 to DEPTH - 1) of word_t;

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

	-- write to memory, 'X' means maybe write
	signal write1 : X01;
	signal write2 : X01;

	-- read only from memory, 'X' means maybe read
	signal read1  : X01;
	signal read2  : X01;
begin
	assert SIMULATION report "This model is only for simulation." severity error;

	-- handle 'U' as 'X'
  write1 <= to_x01(ce1 and we1);
  read1  <= to_x01(ce1 and not we1);
  write2 <= to_x01(ce2 and we2);
  read2  <= to_x01(ce2 and not we2);

  process (clk1, clk2)
    -- Flag and address indicating whether a write occurs in the current clock
		-- cycle. Set and cleared at the rising_edge of the port's clock.
		-- The write address is set to don't care when the write location is
		-- undefined, to match all addresses in collision checks from other port.
    variable writing1 : boolean;
    variable writing2 : boolean;
    variable waddr1   : unsigned(A_BITS-1 downto 0);
    variable waddr2   : unsigned(A_BITS-1 downto 0);

		-- Check for write-collision check on port 1. Only set during one execution
		-- of the process.
		variable check_wr1 : boolean;

    -- Flag and address indicating whether a read occurs in the current clock
		-- cycle. Set and cleared at the rising_edge of the port's clock.
		-- In opposition to the writing flag, the reading flag is only set if the
		-- address is well known and the read succeeded at the rising clock edge.
		-- A read fails afterwards if a write happens during the read clock cycle.
    variable reading1 : boolean;
    variable reading2 : boolean;
    variable raddr1   : unsigned(A_BITS-1 downto 0);
    variable raddr2   : unsigned(A_BITS-1 downto 0);

	begin	-- process
		check_wr1 := false;

		-- Writing to Memory
		-- =========================================================================
		if rising_edge(clk1) then
			writing1 := false;
			waddr1   := (others => '-');

			if write1 = '1' then
				-- RAM is definitely written ...
				writing1 := true;
				if is_x(std_logic_vector(a1)) then
					-- ... but address is unknown
					ram <= (others => (others => 'X'));
				else
					--- ... and address is well known
					waddr1 := a1;
					ram(to_integer(a1)) <= to_ux01(d1);
					-- writing2 and waddr2 are not yet up-to-date, check for
					-- write-collision below
					check_wr1 := true;
				end if;
				-- same-port read during write: return new data
				q1 <= to_ux01(d1);

			elsif write1 = 'X' then
				-- RAM may be written ...
				writing1 := true;
				if is_x(std_logic_vector(a1)) then
					-- ... but address is unknown
					ram <= (others => (others => 'X'));
				else
					--- ... and address is well known
					waddr1 := a1;
					ram(to_integer(a1)) <= (others => 'X');
				end if;
				-- same-port read during write: unknown data
				q1 <= (others => 'X');
			end if;
		end if;

		-- Must be executed after write to port 1 due to write-collsion check
		if rising_edge(clk2) then
			writing2 := false;
			waddr2   := (others => '-');

			if write2 = '1' then
				-- RAM is definitely written ...
				writing2 := true;
				if is_x(std_logic_vector(a2)) then
					-- ... but address is unknown
					ram <= (others => (others => 'X'));
				else
					--- ... and address is well known
					waddr2 := a2;
					-- writing1 and waddr1 are up-to-date, check for write-collision
					if writing1 and std_match(waddr1, a2) then
						ram(to_integer(a2)) <= (others => 'X');
					else
						ram(to_integer(a2)) <= to_ux01(d2);
					end if;
				end if;
				-- same-port read during write: return new data
				q2 <= to_ux01(d2);

			elsif write2 = 'X' then
				-- RAM may be written ...
				writing2 := true;
				if is_x(std_logic_vector(a2)) then
					-- ... but address is unknown
					ram <= (others => (others => 'X'));
				else
					--- ... and address is well known
					waddr2 := a2;
					ram(to_integer(a2)) <= (others => 'X');
				end if;
				-- same-port read during write: unknown data
				q1 <= (others => 'X');
			end if;
		end if;

		-- writing1 and waddr1 are up-to-date, check for write-collision
		if check_wr1 then
			if writing2 and std_match(waddr2, a1) then
				ram(to_integer(a1)) <= (others => 'X');
			end if;
		end if;

		-- Reading (only) from Memory
		-- =========================================================================
		if rising_edge(clk1) then
			reading1 := false;
			raddr1   := (others => '-');

			if read1 = '1' then
				-- Definitely read only from RAM ...
				if is_x(std_logic_vector(a1)) then
					-- ... but address is unknown
					q1 <= (others => 'X');
				else
					-- check for mixed-port read-during-write
					if writing2 and std_match(a1,waddr2) then
						q1 <= (others => 'X');
					else
						-- further checks are only required if address is well known
						reading1 := true;
						raddr1   := a1;
						q1 <= ram(to_integer(a1));
					end if;
				end if;
			elsif read1 = 'X' then
				-- Maybe read only from RAM
				q1 <= (others => 'X');
			end if;
		end if;

		if rising_edge(clk2) then
			reading2 := false;
			raddr2   := (others => '-');

			if read2 = '1' then
				-- Definitely read only from RAM ...
				if is_x(std_logic_vector(a2)) then
					-- ... but address is unknown
					q2 <= (others => 'X');
				else
					-- check for mixed-port read-during-write
					if writing1 and std_match(a2,waddr1) then
						q2 <= (others => 'X');
					else
						-- further checks are only required if address is well known
						reading2 := true;
						raddr2   := a2;
						q2 <= ram(to_integer(a2));
					end if;
				end if;
			elsif read2 = 'X' then
				-- Maybe read only from RAM
				q2 <= (others => 'X');
			end if;
		end if;

    -- Write-during-read check
    -- =========================================================================
		-- cannot be included in read part above, because check is performed on a
		-- following rising edge of the write clock (not read clock!).
		if rising_edge(clk1) and writing1 then
			if reading2 and std_match(raddr2, waddr1) then
				-- read is disturbed by a write during the read clock cycle
				q2 <= (others => 'X');
			end if;
		end if;

		if rising_edge(clk2) and writing2 then
			if reading1 and std_match(raddr1, waddr2) then
				-- read is disturbed by a write during the read clock cycle
				q1 <= (others => 'X');
			end if;
		end if;
	end process;

end architecture;
