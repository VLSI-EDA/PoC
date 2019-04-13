-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:   Martin Zabel
--
-- Entity:    FIFO, independent clocks (ic), PoC.Mem interface
--
-- Description:
-- -------------------------------------
-- Independent clocks meens that read and write clock are unrelated.
-- Synchronous reset is used. Both resets may overlap.
--
-- Inputs & Outputs:
--
--        +------------------------------+
--        |                              |
--     -->| clk_1                  clk_2 |<--
--     -->| rst_1                  rst_2 |<--
--        |                              |
--     -->| mem_req_1          mem_req_2 |-->
--     -->| mem_write_1      mem_write_2 |-->
--     -->| mem_addr_1        mem_addr_2 |-->
--     -->| mem_wdata_1      mem_wdata_2 |-->
--     -->| mem_wmask_1      mem_wmask_2 |-->
--     <--| mem_rdy_1          mem_rdy_2 |<--
--        |                              |
--     <--| mem_rstb_1        mem_rstb_2 |<--
--     <--| mem_rdata_1      mem_rdata_2 |<--
--        |                              |
--        +------------------------------+
--
--
--  The read/write request of the PoC.Mem interface is transfered from the
--  left side (1) to the right side (2). The read reply is transfered from the
--  right side (2) to the left side (1).
--
-- See also dedicated description for PoC.Mem interface.
--
-- ``MEM_ADDR_BITS`` and ``MEM_DATA_BITS`` describe the configuration of the
-- PoC.Mem interface.
--
-- ``MIN_DEPTH`` denotes the minimum number of requests to be stored in the FIFO.
--
-- ``DATA_REG`` (=true) is a hint, that distributed memory or registers should be
-- used as data storage. The actual memory type depends on the device
-- architecture. See implementation for details.
--
-- The suffix ``_1TO2`` means the FIFO for transfering data from left to right.
-- The suffix ``_2TO1`` means the FIFO for transfering data from right to left.
--
-- License:
-- =============================================================================
-- Copyright 2019-2019 Martin Zabel, Berlin, Germany
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

library	poc;
use			PoC.utils.all;
use			poc.ocram.all; -- "all" required by Quartus RTL simulation


entity fifo_ic_mem is
  generic (
    MEM_ADDR_BITS  : positive;
    MEM_DATA_BITS  : positive;
    MIN_DEPTH_1TO2 : positive := 8;
    MIN_DEPTH_2TO1 : positive := 8;
    DATA_REG_1TO2  : boolean  := true;
    DATA_REG_2TO1  : boolean  := true
  );
  port (
    -- Left side (1)
    clk_1       : in  std_logic;
    rst_1       : in  std_logic;
    mem_req_1   : in  std_logic;
    mem_write_1 : in  std_logic;
    mem_addr_1  : in  unsigned(MEM_ADDR_BITS-1 downto 0);
    mem_wdata_1 : in  std_logic_vector(MEM_DATA_BITS-1 downto 0);
    mem_wmask_1 : in  std_logic_vector(MEM_DATA_BITS/8-1 downto 0);
    mem_rdy_1   : out std_logic;
    mem_rstb_1  : out std_logic;
    mem_rdata_1 : out std_logic_vector(MEM_DATA_BITS-1 downto 0);

    -- Right side (2)
    clk_2       : in  std_logic;
    rst_2       : in  std_logic;
    mem_req_2   : out std_logic;
    mem_write_2 : out std_logic;
    mem_addr_2  : out unsigned(MEM_ADDR_BITS-1 downto 0);
    mem_wdata_2 : out std_logic_vector(MEM_DATA_BITS-1 downto 0);
    mem_wmask_2 : out std_logic_vector(MEM_DATA_BITS/8-1 downto 0);
    mem_rdy_2   : in  std_logic;
    mem_rstb_2  : in  std_logic;
    mem_rdata_2 : in  std_logic_vector(MEM_DATA_BITS-1 downto 0)
  );
end entity fifo_ic_mem;


architecture rtl of fifo_ic_mem is
begin

  -----------------------------------------------------------------------------
  -- From left side (1) to right side (2)
  -----------------------------------------------------------------------------

  blk1to2 : block is
    signal put   : std_logic;
    signal din   : std_logic_vector(MEM_DATA_BITS/8+MEM_DATA_BITS+MEM_ADDR_BITS+1-1 downto 0);
    signal full  : std_logic;
    signal got   : std_logic;
    signal dout  : std_logic_vector(MEM_DATA_BITS/8+MEM_DATA_BITS+MEM_ADDR_BITS+1-1 downto 0);
    signal valid : std_logic;
		
	begin  -- block blk1to2
		fifo: entity poc.fifo_ic_got
			generic map (
				D_BITS         => MEM_DATA_BITS/8+MEM_DATA_BITS+MEM_ADDR_BITS+1,
				MIN_DEPTH      => MIN_DEPTH_1TO2,
				DATA_REG       => DATA_REG_1TO2,
				OUTPUT_REG     => true)
			port map (
				clk_wr    => clk_1,
				rst_wr    => rst_1,
				put       => put,
				din       => din,
				full      => full,
				clk_rd    => clk_2,
				rst_rd    => rst_2,
				got       => got,
				valid     => valid,
				dout      => dout);

    put <= mem_req_1;  -- put will already be masked when FIFO is full
    din <= mem_wmask_1 & mem_wdata_1 & std_logic_vector(mem_addr_1) & mem_write_1;
    got <= mem_rdy_2;  -- got is already ignored when FIFO is empty

		mem_rdy_1 <= not full;

    mem_req_2   <= valid;
    mem_write_2 <= dout(0);
    mem_addr_2  <= unsigned(dout(MEM_ADDR_BITS+1-1 downto 1));
    mem_wdata_2 <= dout(MEM_DATA_BITS+MEM_ADDR_BITS+1-1 downto MEM_ADDR_BITS+1);
    mem_wmask_2 <= dout(MEM_DATA_BITS/8+MEM_DATA_BITS+MEM_ADDR_BITS+1-1 downto MEM_DATA_BITS+MEM_ADDR_BITS+1);
  end block blk1to2;
	
  -----------------------------------------------------------------------------
  -- From right side (2) to left side (1)
  -----------------------------------------------------------------------------

  blk2to1 : block is
	begin  -- block blk1to2
		fifo: entity poc.fifo_ic_got
			generic map (
				D_BITS         => MEM_DATA_BITS,
				MIN_DEPTH      => MIN_DEPTH_2TO1,
				DATA_REG       => DATA_REG_2TO1,
				OUTPUT_REG     => true)
			port map (
				clk_wr    => clk_2,
				rst_wr    => rst_2,
				put       => mem_rstb_2,
				din       => mem_rdata_2,
				full      => open,  -- ignored in PoC.Mem interface
				clk_rd    => clk_1,
				rst_rd    => rst_1,
				got       => '1',   -- always acknowledge new data
				valid     => mem_rstb_1,
				dout      => mem_rdata_1);
  end block blk2to1;

end rtl;
