-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Martin Zabel
--
-- Testbench:			 	Testbench for sdram_ctrl_fsm.
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
use ieee.math_real.all;

library PoC;
use 		PoC.physical.all;
-- simulation specific packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;

use			PoC.utils.all;

entity sdram_ctrl_fsm_tb is
end entity sdram_ctrl_fsm_tb;

architecture sim of sdram_ctrl_fsm_tb is

	-- Test Setup
	constant CLK_PERIOD :real := 10.0; -- ns, must match below
	constant SDRAM_TYPE : natural := 0;
	constant CL : positive := 2;
	constant BL : positive := 8;

  --
  -- Example SDRAM Configuration
  --
  constant A_BITS : positive := 24;     -- 16M
  constant D_BITS : positive := 16;     -- x16
  constant R_BITS : positive := 13;     -- 8192 rows
  constant C_BITS : positive := 9;      -- 512 columns
  constant B_BITS : positive := 2;      -- 4 banks

  -- Divide timings from datasheet by clock period.
  -- Example SDRAM device: MT48LC16M16A2-75
  constant T_MRD     : integer := 2; -- fix
  constant T_RAS     : integer := integer(ceil(44.0/CLK_PERIOD));
  constant T_RCD     : integer := integer(ceil(20.0/CLK_PERIOD));
  constant T_RFC     : integer := integer(ceil(66.0/CLK_PERIOD));
  constant T_RP      : integer := integer(ceil(20.0/CLK_PERIOD));
  constant T_WR      : integer := 1 + integer(ceil(7.5/CLK_PERIOD));
  constant T_WTR     : integer := 1;
  constant T_REFI    : integer := integer(ceil((7812.0)/CLK_PERIOD))-50; -- 64 ms / 8192 rows
	constant INIT_WAIT_NS : real := 100000.0; -- 100 us, must match below
  constant INIT_WAIT : integer := integer(ceil(INIT_WAIT_NS/
                                               (real(T_REFI)*CLK_PERIOD)));
	
  signal clk              : std_logic := '1';
  signal rst              : std_logic;
  signal user_cmd_valid   : std_logic;
  signal user_wdata_valid : std_logic;
  signal user_write       : std_logic;
  signal user_addr        : std_logic_vector(A_BITS-1 downto 0);
  signal user_got_cmd     : std_logic;
  signal user_got_wdata   : std_logic;
  signal sd_cke_nxt       : std_logic;
  signal sd_cs_nxt        : std_logic;
  signal sd_ras_nxt       : std_logic;
  signal sd_cas_nxt       : std_logic;
  signal sd_we_nxt        : std_logic;
  signal sd_a_nxt         : std_logic_vector(imax(R_BITS, C_BITS+1)-1 downto 0);
  signal sd_ba_nxt        : std_logic_vector(B_BITS-1 downto 0);
  signal rden_nxt         : std_logic;
  signal wren_nxt         : std_logic;
	
begin  -- architecture sim

	uut: entity PoC.sdram_ctrl_fsm
    generic map (
      SDRAM_TYPE => SDRAM_TYPE,
      A_BITS     => A_BITS,
      D_BITS     => D_BITS,
      R_BITS     => R_BITS,
      C_BITS     => C_BITS,
      B_BITS     => B_BITS,
      CL         => CL,
      BL         => BL,
      T_MRD      => T_MRD,
      T_RAS      => T_RAS,
      T_RCD      => T_RCD,
      T_RFC      => T_RFC,
      T_RP       => T_RP,
      T_WR       => T_WR,
      T_WTR      => T_WTR,
      T_REFI     => T_REFI,
      INIT_WAIT  => INIT_WAIT)
    port map (
      clk              => clk,
      rst              => rst,
      user_cmd_valid   => user_cmd_valid,
      user_wdata_valid => user_wdata_valid,
      user_write       => user_write,
      user_addr        => user_addr,
      user_got_cmd     => user_got_cmd,
      user_got_wdata   => user_got_wdata,
      sd_cke_nxt       => sd_cke_nxt,
      sd_cs_nxt        => sd_cs_nxt,
      sd_ras_nxt       => sd_ras_nxt,
      sd_cas_nxt       => sd_cas_nxt,
      sd_we_nxt        => sd_we_nxt,
      sd_a_nxt         => sd_a_nxt,
      sd_ba_nxt        => sd_ba_nxt,
      rden_nxt         => rden_nxt,
      wren_nxt         => wren_nxt);
	
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clocks
	simGenerateClock(clk, 100 MHz); -- 1/CLK_PERIOD

  Stimuli : process
    constant simProcessID : T_SIM_PROCESS_ID := simRegisterProcess("Stimuli process");
  begin
    -- 0) Reset
    -- ========
    rst  <= '1';
    wait until rising_edge(clk);
    wait until rising_edge(clk);
    rst  <= '0';

    -- 1) Check LOAD MODE REGISTER during initialization
    -- =================================================
		user_cmd_valid   <= '0';
		user_wdata_valid <= '0';
    wait until rising_edge(clk) and	sd_cs_nxt = '0' and
			sd_ras_nxt = '0' and sd_cas_nxt ='0' and sd_we_nxt = '0';
		simAssertion(sd_a_nxt = "000000" &
								 std_logic_vector(to_unsigned(CL, 3)) &
								 "0" &
								 std_logic_vector(to_unsigned(log2ceil(BL), 3)),
								 "Mode register value incorrect!");
		simAssertion(sd_ba_nxt = "00",
								 "Mode register bank address incorrect!");
		

    -- 1) Issue write bursts
    -- =====================
		user_cmd_valid <= '1';
		user_write <= '1';
		user_addr  <= std_logic_vector(to_unsigned(0, user_addr'length));
		user_wdata_valid <= '1';
    wait until rising_edge(clk) and user_got_cmd = '1';
		for i in 0 to BL-1 loop
			simAssertion(user_got_wdata = '1',
									 "Write data not acknowledged @ i=" & integer'image(i));
			simAssertion(wren_nxt = '1',
									 "Write data not enabled @ i=" & integer'image(i));
			user_cmd_valid <= '0';
			wait until rising_edge(clk);
		end loop;

		user_cmd_valid <= '1';
		user_write <= '1';
		user_addr  <= std_logic_vector(to_unsigned(BL, user_addr'length));
		user_wdata_valid <= '1';
    wait until rising_edge(clk) and user_got_cmd = '1';
		for i in 0 to BL-1 loop
			simAssertion(user_got_wdata = '1',
									 "Write data not acknowledged @ i=" & integer'image(i));
			simAssertion(wren_nxt = '1',
									 "Write data not enabled @ i=" & integer'image(i));
			user_cmd_valid <= '0';
			wait until rising_edge(clk);
		end loop;

    -- 2) Issue read bursts
    -- ====================
		user_cmd_valid <= '1';
		user_write <= '0';
		user_addr  <= std_logic_vector(to_unsigned(0, user_addr'length));
    wait until rising_edge(clk) and user_got_cmd = '1';
		for i in 0 to BL-1 loop
			simAssertion(rden_nxt = '1',
									 "Read data not enabled @ i=" & integer'image(i));
			user_cmd_valid <= '0';
			wait until rising_edge(clk);
		end loop;

		user_cmd_valid <= '1';
		user_write <= '0';
		user_addr  <= std_logic_vector(to_unsigned(BL, user_addr'length));
    wait until rising_edge(clk) and user_got_cmd = '1';
		for i in 0 to BL-1 loop
			simAssertion(rden_nxt = '1',
									 "Read data not enabled @ i=" & integer'image(i));
			user_cmd_valid <= '0';
			wait until rising_edge(clk);
		end loop;

		wait until rising_edge(clk);
		wait until rising_edge(clk);
		wait until rising_edge(clk);

		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;
end architecture sim;
