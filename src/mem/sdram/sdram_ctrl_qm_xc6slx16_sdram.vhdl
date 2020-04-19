-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--
-- Entity:					Controller for Micron SDR-SDRAM on QM XC6SLX16 SDRAM.
--
-- Description:
-- -------------------------------------
-- Controller for Micron SDR-SDRAM on QM XC6SLX16 SDRAM.
--
-- SDRAM Device: MT48LC16M16A2-75
--
-- Configuration
-- *************
--
-- +------------+----------------------------------------------------+
-- | Parameter  | Description                                        |
-- +============+====================================================+
-- | CLK_PERIOD | Clock period in nano seconds. All SDRAM timings are|
-- |            | calculated for the device stated above.            |
-- +------------+----------------------------------------------------+
-- | CL         | CAS latency, choose according to clock frequency.  |
-- +------------+----------------------------------------------------+
-- | BL         | Burst length. Choose BL=1 for single cycle memory  |
-- |            | transactions as required for the PoC.Mem interface.|
-- +------------+----------------------------------------------------+
--
-- Tested with: CLK_PERIOD = 10.0, CL=2, BL=1.
--
-- Operation
-- *********
--
-- Command, address and write data is sampled with ``clk``.
-- Read data is also aligned with ``clk``.
--
-- For description of ``clkout`` and datapath signals see
-- :ref:`sdram_ctrl_phy_qm_xc6slx16_sdram <IP:sdram_ctrl_phy_qm_xc6slx16_sdram>`.
--
-- Synchronous resets are used.
--
-- License:
-- =============================================================================
-- Copyright 2020      Martin Zabel, Berlin, Germany
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany,
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
--
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library poc;

entity sdram_ctrl_qm_xc6slx16_sdram is

  generic (
    CLK_PERIOD  : real;
    CL          : positive;
    BL          : positive);

  port (
    clk      : in std_logic;
    clkout   : in std_logic;
    clkout_n : in std_logic;
    rst      : in std_logic;

    user_cmd_valid   : in  std_logic;
    user_wdata_valid : in  std_logic;
    user_write       : in  std_logic;
    user_addr        : in  std_logic_vector(23 downto 0);
    user_wdata       : in  std_logic_vector(15 downto 0);
    user_wmask       : in  std_logic_vector(1 downto 0) := (others => '0');
    user_got_cmd     : out std_logic;
    user_got_wdata   : out std_logic;
    user_rdata       : out std_logic_vector(15 downto 0);
    user_rstb        : out std_logic;

    sd_ck  : out   std_logic;
    sd_cke : out   std_logic;
    sd_cs  : out   std_logic;
    sd_ras : out   std_logic;
    sd_cas : out   std_logic;
    sd_we  : out   std_logic;
    sd_ba  : out   std_logic_vector(1 downto 0);
    sd_a   : out   std_logic_vector(12 downto 0);
    sd_dqm : out   std_logic_vector(1 downto 0);
    sd_dq  : inout std_logic_vector(15 downto 0));

end sdram_ctrl_qm_xc6slx16_sdram;

architecture rtl of sdram_ctrl_qm_xc6slx16_sdram is

  --
  -- Configuration
  --
  constant A_BITS : positive := 24;     -- 16M
  constant D_BITS : positive := 16;     -- x16
  constant R_BITS : positive := 13;     -- 8192 rows
  constant C_BITS : positive := 9;      -- 512 columns
  constant B_BITS : positive := 2;      -- 4 banks

  -- Divide timings from datasheet by clock period.
  -- SDRAM device: MT48LC16M16A2-75
  constant T_MRD     : integer := integer(ceil(2.0/CLK_PERIOD));
  constant T_RAS     : integer := integer(ceil(44.0/CLK_PERIOD));
  constant T_RCD     : integer := integer(ceil(20.0/CLK_PERIOD));
  constant T_RFC     : integer := integer(ceil(66.0/CLK_PERIOD));
  constant T_RP      : integer := integer(ceil(20.0/CLK_PERIOD));
  constant T_WR      : integer := integer(ceil(15.0/CLK_PERIOD));
  constant T_WTR     : integer := 1;
  constant T_REFI    : integer := integer(ceil((7812.0)/CLK_PERIOD))-50; -- 64 ms / 8192 rows
  constant INIT_WAIT : integer := integer(ceil(100000.0/  -- 100 us
                                               (real(T_REFI)*CLK_PERIOD)));

  --
  -- Signals
  --
  signal sd_cke_nxt       : std_logic;
  signal sd_cs_nxt        : std_logic;
  signal sd_ras_nxt       : std_logic;
  signal sd_cas_nxt       : std_logic;
  signal sd_we_nxt        : std_logic;
  signal sd_a_nxt         : std_logic_vector(12 downto 0);
  signal sd_ba_nxt        : std_logic_vector(1 downto 0);
  signal rden_nxt         : std_logic;
  signal wren_nxt         : std_logic;

begin  -- rtl

  fsm: entity poc.sdram_ctrl_fsm
    generic map (
      SDRAM_TYPE   => 0,                -- SDR-SDRAM
      A_BITS       => A_BITS,
      D_BITS       => D_BITS,
      R_BITS       => R_BITS,
      C_BITS       => C_BITS,
      B_BITS       => B_BITS,
      CL           => CL,
      BL           => BL,
      T_MRD        => T_MRD,
      T_RAS        => T_RAS,
      T_RCD        => T_RCD,
      T_RFC        => T_RFC,
      T_RP         => T_RP,
      T_WR         => T_WR,
      T_WTR        => T_WTR,
      T_REFI       => T_REFI,
      INIT_WAIT    => INIT_WAIT)
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

  phy: entity poc.sdram_ctrl_phy_qm_xc6slx16_sdram
    generic map (
      CL => CL)
    port map (
      clk        => clk,
      clkout     => clkout,
      clkout_n   => clkout_n,
      rst        => rst,
      sd_cke_nxt => sd_cke_nxt,
      sd_cs_nxt  => sd_cs_nxt,
      sd_ras_nxt => sd_ras_nxt,
      sd_cas_nxt => sd_cas_nxt,
      sd_we_nxt  => sd_we_nxt,
      sd_ba_nxt  => sd_ba_nxt,
      sd_a_nxt   => sd_a_nxt,
      wren_nxt   => wren_nxt,
      wdata_nxt  => user_wdata,
      wmask_nxt  => user_wmask,
      rden_nxt   => rden_nxt,
      rdata      => user_rdata,
      rstb       => user_rstb,
      sd_ck      => sd_ck,
      sd_cke     => sd_cke,
      sd_cs      => sd_cs,
      sd_ras     => sd_ras,
      sd_cas     => sd_cas,
      sd_we      => sd_we,
      sd_ba      => sd_ba,
      sd_a       => sd_a,
			sd_dqm     => sd_dqm,
      sd_dq      => sd_dq);

end rtl;
