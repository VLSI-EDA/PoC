-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:         Martin Zabel
--
-- Testbench:       Testbench for fifo_ic_mem.
--
-- Description:
-- ------------------------------------
-- Test fifo_ic_mem using two memories. One connected behind the FIFO, and one
-- directly attached to the CPU. The CPU compares the result of read requests
-- issued to the FIFO with the result from the direct attached memory.
--
-- CPU  ---+--- FIFO (UUT) ---- 1st memory
--         |
--         +--- 2nd memory with FIFO for read replies
--
-- License:
-- ============================================================================
-- Copyright 2019 Martin Zabel, Berlin, Germany
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library poc;
use poc.utils.all;
use poc.physical.all;
-- simulation only packages
use poc.sim_types.all;
use poc.simulation.all;
use poc.waveform.all;

entity fifo_ic_mem_tb is
end entity fifo_ic_mem_tb;

architecture sim of fifo_ic_mem_tb is
	constant CLOCK_FREQ : FREQ := 100 MHz;

	-- Memory configuration
  constant MEM_ADDR_BITS      : positive := 6;
  constant MEM_DATA_BITS      : positive := 128;

	constant MEMORY_WORDS       : positive := 2**MEM_ADDR_BITS;
	constant BYTES_PER_WORD     : positive := MEM_DATA_BITS/8;
	constant OUTSTANDING_REQ    : positive := 16;

	-- Global signals
  signal clk : std_logic := '1';
  signal rst : std_logic;

	-- Request from CPU
  signal cpu_req   : std_logic;
  signal cpu_write : std_logic;
  signal cpu_addr  : unsigned(MEM_ADDR_BITS-1 downto 0);
  signal cpu_wdata : std_logic_vector(MEM_DATA_BITS-1 downto 0);
  signal cpu_wmask : std_logic_vector(MEM_DATA_BITS/8-1 downto 0);

	-- Bus between CPU and FIFO
	-- write / addr / wdata are directly connected to the CPU
  signal fifo_req   : std_logic;
  signal fifo_rdy   : std_logic;
  signal fifo_rstb  : std_logic;
  signal fifo_rdata : std_logic_vector(MEM_DATA_BITS-1 downto 0);

	-- Bus between Cache and 1st Memory
  signal mem1_req   : std_logic;
  signal mem1_write : std_logic;
  signal mem1_addr  : unsigned(MEM_ADDR_BITS-1 downto 0);
  signal mem1_wdata : std_logic_vector(MEM_DATA_BITS-1 downto 0);
  signal mem1_wmask : std_logic_vector(MEM_DATA_BITS/8-1 downto 0);
  signal mem1_rdy   : std_logic;
  signal mem1_rstb  : std_logic;
  signal mem1_rdata : std_logic_vector(MEM_DATA_BITS-1 downto 0);

	-- Bus between CPU and 2nd Memory
	-- write / addr / wdata are directly connected to the CPU
  signal mem2_req   : std_logic;
  signal mem2_rdy   : std_logic;
  signal mem2_rstb  : std_logic;
  signal mem2_rdata : std_logic_vector(MEM_DATA_BITS-1 downto 0);

  signal rply2_valid : std_logic;
  signal rply2_rdata : std_logic_vector(MEM_DATA_BITS-1 downto 0);

	-- Write-Data Generator
	signal wdata_got : std_logic;
	signal wdata_val : std_logic_vector(MEM_DATA_BITS-1 downto 0);

	-- Control signals between Request Generator and Checker of CPU
	signal finished : boolean := false;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock
	simGenerateClock(clk, CLOCK_FREQ);

	-- The Cache
	UUT: entity poc.fifo_ic_mem
    generic map (
      MEM_ADDR_BITS      => MEM_ADDR_BITS,
      MEM_DATA_BITS      => MEM_DATA_BITS)
    port map (
      clk_1       => clk,
      rst_1       => rst,
      mem_req_1   => fifo_req,
      mem_write_1 => cpu_write,
      mem_addr_1  => cpu_addr,
      mem_wdata_1 => cpu_wdata,
      mem_wmask_1 => cpu_wmask,
      mem_rdy_1   => fifo_rdy,
      mem_rstb_1  => fifo_rstb,
      mem_rdata_1 => fifo_rdata,
      clk_2       => clk,
      rst_2       => rst,
      mem_req_2   => mem1_req,
      mem_write_2 => mem1_write,
      mem_addr_2  => mem1_addr,
      mem_wdata_2 => mem1_wdata,
      mem_wmask_2 => mem1_wmask,
      mem_rdy_2   => mem1_rdy,
      mem_rstb_2  => mem1_rstb,
      mem_rdata_2 => mem1_rdata);

	-- request only if also 2nd memory is ready
	fifo_req <= cpu_req and mem2_rdy;

	-- The 1st Memory
	memory1: entity work.mem_model
		generic map (
			A_BITS	=> MEM_ADDR_BITS,
			D_BITS	=> MEM_DATA_BITS)
		port map (
			clk       => clk,
			rst       => rst,
			mem_req   => mem1_req,
			mem_write => mem1_write,
			mem_addr  => mem1_addr,
			mem_wdata => mem1_wdata,
			mem_wmask => mem1_wmask,
			mem_rdy   => mem1_rdy,
			mem_rstb  => mem1_rstb,
			mem_rdata => mem1_rdata);

	-- The 2nd Memory
	memory2: entity work.mem_model
		generic map (
			A_BITS	=> MEM_ADDR_BITS,
			D_BITS	=> MEM_DATA_BITS)
		port map (
			clk       => clk,
			rst       => rst,
			mem_req   => mem2_req,
			mem_write => cpu_write,
			mem_addr  => cpu_addr,
			mem_wdata => cpu_wdata,
			mem_wmask => cpu_wmask,
			mem_rdy   => mem2_rdy,
			mem_rstb  => mem2_rstb,
			mem_rdata => mem2_rdata);

	-- request only if also cache is ready
	mem2_req <= cpu_req and fifo_rdy;

	-- Buffer the replies from 2nd memory for later comparison
	rply2_fifo: entity poc.fifo_cc_got
    generic map (
      D_BITS         => MEM_DATA_BITS,
      MIN_DEPTH      => imax(OUTSTANDING_REQ, 2),
      DATA_REG       => true, -- matches fifo_ic_mem implementation
      OUTPUT_REG     => true)  -- matches fifo_ic_mem implementation
    port map (
      rst       => rst,
      clk       => clk,
      put       => mem2_rstb,
      din       => mem2_rdata,
      full      => open, -- should not overflow
      estate_wr => open,
      got       => fifo_rstb,
      dout      => rply2_rdata,
      valid     => rply2_valid,
      fstate_rd => open);

	-- The Write-Data Generator of the CPU
	wdata_prng: entity poc.arith_prng
    generic map (BITS => MEM_DATA_BITS)
    port map (
      clk => clk,
      rst => rst,
      got => wdata_got,
      val => wdata_val);

	cpu_wdata <= wdata_val when cpu_write = '1' else (others => '-');
	wdata_got <= cpu_write and fifo_rdy and mem2_rdy;

	-- The Request Generator of the CPU
  CPU_RequestGen: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("CPU RequestGen");

		-- no operation
		procedure nop is
		begin
			cpu_req   <= '0';
			cpu_write <= '-';
			cpu_addr  <= (others => '-');
			cpu_wmask <= (others => '-');
			wait until rising_edge(clk);
		end procedure;

		-- Write random data at given word address.
		-- Waits until cache and 2nd memory are ready.
		procedure write(
			addr       : in natural;
			wmask      : in std_logic_vector(BYTES_PER_WORD-1 downto 0) := (others => '0')
		) is
		begin
			-- apply request (will be ignored if not ready)
			cpu_req   <= '1';
			cpu_write <= '1';
			cpu_addr  <= to_unsigned(addr, MEM_ADDR_BITS);
			cpu_wmask <= wmask;
			while true loop
				wait until rising_edge(clk);
				exit when (fifo_rdy and mem2_rdy) = '1';
			end loop;
		end procedure;

		-- Write single byte of random data at given word address.
		-- Waits until cache and 2nd memory are ready.
		procedure write_byte(
			word_addr  : in natural;
			byte_addr  : in natural range 0 to BYTES_PER_WORD-1
		) is
			variable mask : std_logic_vector(BYTES_PER_WORD-1 downto 0);
		begin
			mask := (others => '1');
			mask(byte_addr) := '0';
			write(word_addr, mask);
		end procedure;

		-- Read at given word address.
		-- Waits until cache and 2nd memory are ready.
		procedure read(addr : in natural) is
		begin
			-- apply request (will be ignored if not ready)
			cpu_req   <= '1';
			cpu_write <= '0';
			cpu_addr  <= to_unsigned(addr, MEM_ADDR_BITS);
			cpu_wmask <= (others => '-');
			while true loop
				wait until rising_edge(clk);
				exit when (fifo_rdy and mem2_rdy) = '1';
			end loop;
		end procedure;

		-- Seeds for random request generation
		variable seed1 : positive := 1;
		variable seed2 : positive := 1;

		variable temp_r : real;
		variable temp_r2: real;

  begin
		-- Reset is mandatory
    rst <= '1';
    wait until rising_edge(clk);
    rst <= '0';

		-- Check No Operation
		-- --------------------------------------------
		for i in 0 to 3 loop nop; end loop;

		-- Fill memory with valid data and read it back
		-- --------------------------------------------
		-- Due to the No-Write-Allocate policy no cache hit occurs.

		-- Write / read whole word
		-- ***********************
		for addr in 0 to MEMORY_WORDS-1 loop
			write(addr);
		end loop;  -- addr
		for addr in 0 to MEMORY_WORDS-1 loop
			read(addr);
		end loop;  -- addr
		for i in 0 to 3 loop nop; end loop;

		-- Write single bytes, read whole word
		-- ***********************************
		for word_addr in 0 to MEMORY_WORDS-1 loop
			for byte_addr in 0 to BYTES_PER_WORD-1 loop
				write_byte(word_addr, byte_addr);
			end loop;
		end loop;  -- addr
		for addr in 0 to MEMORY_WORDS-1 loop
			read(addr);
		end loop;  -- addr
		for i in 0 to 3 loop nop; end loop;

		-- Linear access, read/write/read at every address
		-- -----------------------------------------------

		-- Write / read whole word
		-- ***********************
		for addr in 0 to MEMORY_WORDS-1 loop
			read(addr);  -- cache hit only if cache size equals memory size.
			write(addr); -- cache hit, write-through
			read(addr);  -- cache hit
			nop;
		end loop;
		for i in 0 to 3 loop nop; end loop;

		-- Write single bytes, read whole word
		-- ***********************************
		for word_addr in 0 to MEMORY_WORDS-1 loop
			read(word_addr);  -- cache hit only if cache size equals memory size.
			for byte_addr in 0 to BYTES_PER_WORD-1 loop
				write_byte(word_addr, byte_addr);
				-- cache hit, write-through
			end loop;
			read(word_addr);  -- cache hit
			nop;
		end loop;  -- word_addr
		for i in 0 to 3 loop nop; end loop;

		-- Finished
		-- --------
		nop;
		finished  <= true;
		simDeactivateProcess(simProcessID);
    wait;
  end process CPU_RequestGen;

	-- The Checker of the CPU
	CPU_Checker: process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("CPU Checker");
	begin
		-- wait until reset completes
		wait until rising_edge(clk) and rst = '0';

		-- wait until all requests have been applied
		while not finished loop
			wait until rising_edge(clk);
			simAssertion(not is_x(fifo_rstb) and not is_x(rply2_valid), "Meta-value on rstb or valid.");
			if fifo_rstb = '1' then
				simAssertion(rply2_valid = '1', "No read data expected.");
				if rply2_valid = '1' then
					simAssertion(fifo_rdata = rply2_rdata, "Read data differs.");
				end if;
			end if;
		end loop;

		simDeactivateProcess(simProcessID);
		simFinalize;
		wait;
	end process CPU_Checker;

end architecture sim;
