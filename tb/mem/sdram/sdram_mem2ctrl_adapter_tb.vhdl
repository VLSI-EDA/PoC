-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Martin Zabel
--
-- Testbench:			 	Testbench for sdram_mem2ctrl_adapter.
--
-- Description:
-- -------------------------------------
--
-- License:
-- =============================================================================
-- Copyright 2020      Martin Zabel, Berlin, Germany
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

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library PoC;
use 		PoC.physical.all;
-- simulation specific packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;

use			PoC.utils.all;

library test;

entity sdram_mem2ctrl_adapter_tb is
end entity sdram_mem2ctrl_adapter_tb;

architecture sim of sdram_mem2ctrl_adapter_tb is
  constant RATIO      : positive := 8; -- configurable
  constant MEM_A_BITS : positive := 8-log2ceil(RATIO); -- fixed
  constant MEM_D_BITS : positive := 8*RATIO; -- fixed

  signal clk_sys          : std_logic := '1';
  signal clk_ctrl         : std_logic := '1';
  signal rst_sys          : std_logic;
  signal rst_ctrl         : std_logic;
  signal mem_req          : std_logic;
  signal mem_write        : std_logic;
  signal mem_addr         : unsigned(MEM_A_BITS-1 downto 0);
  signal mem_wdata        : std_logic_vector(MEM_D_BITS-1 downto 0);
  signal mem_wmask        : std_logic_vector(MEM_D_BITS/8-1 downto 0) := (others => '0');
  signal mem_rdy          : std_logic;
  signal mem_rstb         : std_logic;
  signal mem_rdata        : std_logic_vector(MEM_D_BITS-1 downto 0);
  signal user_cmd_valid   : std_logic;
  signal user_wdata_valid : std_logic;
  signal user_write       : std_logic;
  signal user_addr        : std_logic_vector(MEM_A_BITS+log2ceil(RATIO)-1 downto 0);
  signal user_wdata       : std_logic_vector(MEM_D_BITS/RATIO-1 downto 0);
  signal user_wmask       : std_logic_vector(MEM_D_BITS/RATIO/8-1 downto 0);
  signal user_got_cmd     : std_logic;
  signal user_got_wdata   : std_logic;
  signal user_rdata       : std_logic_vector(MEM_D_BITS/RATIO-1 downto 0);
  signal user_rstb        : std_logic;

	function byte_data(addr: natural; i: natural) return std_logic_vector is
	begin
		-- Byte order has been chosen for beautiful simulation.
		return std_logic_vector(to_unsigned(addr*RATIO+(RATIO-1-i), 8));
	end function;
	
begin  -- architecture sim

	uut: entity PoC.sdram_mem2ctrl_adapter
    generic map (
      MEM_A_BITS => MEM_A_BITS,
      MEM_D_BITS => MEM_D_BITS,
      RATIO      => RATIO)
    port map (
      clk_sys          => clk_sys,
      clk_ctrl         => clk_ctrl,
      rst_sys          => rst_sys,
      rst_ctrl         => rst_ctrl,
      mem_req          => mem_req,
      mem_write        => mem_write,
      mem_addr         => mem_addr,
      mem_wdata        => mem_wdata,
      mem_wmask        => mem_wmask,
      mem_rdy          => mem_rdy,
      mem_rstb         => mem_rstb,
      mem_rdata        => mem_rdata,
      user_cmd_valid   => user_cmd_valid,
      user_wdata_valid => user_wdata_valid,
      user_write       => user_write,
      user_addr        => user_addr,
      user_wdata       => user_wdata,
      user_wmask       => user_wmask,
      user_got_cmd     => user_got_cmd,
      user_got_wdata   => user_got_wdata,
      user_rdata       => user_rdata,
      user_rstb        => user_rstb);

	sdram_ctrl_model_1: entity test.sdram_ctrl_model
    generic map (
      A_BITS => MEM_A_BITS+log2ceil(RATIO),
      D_BITS => MEM_D_BITS/RATIO,
      CL     => 2,
      BL     => RATIO) -- burst length equals RATIO for single data-rate SDRAM
    port map (
      clk              => clk_ctrl,
      rst              => rst_ctrl,
      user_cmd_valid   => user_cmd_valid,
      user_wdata_valid => user_wdata_valid,
      user_write       => user_write,
      user_addr        => user_addr,
      user_wdata       => user_wdata,
      user_wmask       => user_wmask,
      user_got_cmd     => user_got_cmd,
      user_got_wdata   => user_got_wdata,
      user_rdata       => user_rdata,
      user_rstb        => user_rstb);
	
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clocks
	simGenerateClock(clk_sys,   50 MHz);
	simGenerateClock(clk_ctrl, 100 MHz);

  Stimuli : process
    constant simProcessID : T_SIM_PROCESS_ID := simRegisterProcess("Stimuli process");
  begin
    -- 0) Overlapping Reset
    -- ====================
    rst_sys  <= '1';
    rst_ctrl <= '1';
    wait until rising_edge(clk_sys);
    wait until rising_edge(clk_ctrl);
    rst_ctrl <= '0';
    wait until rising_edge(clk_sys);
    rst_sys  <= '0';
		
    -- 1) Fill memory
    -- ==============
    for addr in 0 to 2**MEM_A_BITS-1 loop
      mem_req   <= '1';
      mem_write <= '1';
      mem_addr  <= to_unsigned(addr, mem_addr'length);
			for i in 0 to RATIO-1 loop
				mem_wdata(i*8+7 downto i*8) <= byte_data(addr, i);
			end loop; -- i
			mem_wmask <= (others => '0');
      wait until rising_edge(clk_sys) and mem_rdy = '1';
    end loop;  -- addr

		mem_req   <= '0';
		mem_write <= '-';
		wait until rising_edge(clk_sys) and mem_rdy = '1';

		-- 2) Read back
		-- ============
		for addr in 0 to 2**MEM_A_BITS-1 loop
			mem_req   <= '1';
			mem_write <= '0';
			mem_addr <= to_unsigned(addr, mem_addr'length);
			wait until rising_edge(clk_sys) and mem_rdy = '1';
		end loop;  -- addr
		
		mem_req   <= '0';
		mem_write <= '-';
		wait until rising_edge(clk_sys) and mem_rdy = '1';

		-- 3) Read back in reverse order
		-- =============================
		for addr in 2**MEM_A_BITS-1 downto 0 loop
			mem_req   <= '1';
			mem_write <= '0';
			mem_addr <= to_unsigned(addr, mem_addr'length);
			wait until rising_edge(clk_sys) and mem_rdy = '1';
		end loop;  -- addr
		
		mem_req   <= '0';
		mem_write <= '-';
		wait until rising_edge(clk_sys) and mem_rdy = '1';

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;

	Checker: process
    constant simProcessID : T_SIM_PROCESS_ID := simRegisterProcess("Checker process");
  begin
		-- 2) Check data for Read back
		-- ===========================
		for addr in 0 to 2**MEM_A_BITS-1 loop
			wait until rising_edge(clk_sys) and mem_rstb = '1';
			for i in 0 to RATIO-1 loop
				simAssertion(mem_rdata(i*8+7 downto i*8) = byte_data(addr, i),
									 "Wrong read data from address:" & integer'image(addr));
			end loop; -- i
		end loop;  -- addr
		
		-- 3) Check data for Read back in reverse order
		-- ============================================
		for addr in 2**MEM_A_BITS-1 downto 0 loop
			wait until rising_edge(clk_sys) and mem_rstb = '1';
			for i in 0 to RATIO-1 loop
				-- Must match equation in stimuli process.
				simAssertion(mem_rdata(i*8+7 downto i*8) = byte_data(addr, i),
									 "Wrong read data from address:" & integer'image(addr));
			end loop; -- i
		end loop;  -- addr
		
		-- This process is finished
		simDeactivateProcess(simProcessID);
	end process;

end architecture sim;
