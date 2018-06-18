-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--
-- Entity:					Physical layer of SDRAM-Controller for Altera DE0 Board
--
-- Description:
-- -------------------------------------
-- Physical layer used by module :ref:`sdram_ctrl_de0 <IP:sdram_ctrl_de0>`.
--
-- Instantiates input and output buffer components and adjusts the timing for
-- the Altera DE0 board.
--
-- Clock and Reset Signals
-- ***********************
--
-- +-----------+-----------------------------------------------------------+
-- | Port      | Description                                               |
-- +===========+===========================================================+
-- |clk        | Base clock for command and write data path.               |
-- +-----------+-----------------------------------------------------------+
-- |rst        | Reset for ``clk``.                                        |
-- +-----------+-----------------------------------------------------------+
--
-- Command signals and write data are sampled with ``clk``.
-- Read data is also aligned with ``clk``.
--
-- Write and read enable (wren_nxt, rden_nxt) must be hold for:
--
-- * 1 clock cycle  if BL = 1,
-- * 2 clock cycles if BL = 2, or
-- * 4 clock cycles if BL = 4, or
-- * 8 clock cycles if BL = 8.
--
-- They must be first asserted with the read and write command. Proper delay is
-- included in this unit.
--
-- The first word to write must be asserted with the write command. Proper
-- delay is included in this unit.
--
-- Synchronous resets are used. Reset must be hold for at least two cycles.
--
-- License:
-- =============================================================================
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

-------------------------------------------------------------------------------
-- Naming Conventions:
-- (Based on: Keating and Bricaud: "Reuse Methodology Manual")
--
-- active low signals: "*_n"
-- clock signals: "clk", "clk_div#", "clk_#x"
-- reset signals: "rst", "rst_n"
-- generics: all UPPERCASE
-- user defined types: "*_TYPE"
-- state machine next state: "*_ns"
-- state machine current state: "*_cs"
-- output of a register: "*_r"
-- asynchronous signal: "*_a"
-- pipelined or register delay signals: "*_p#"
-- data before being registered into register with the same name: "*_nxt"
-- clock enable signals: "*_ce"
-- internal version of output port: "*_i"
-- tristate internal signal "*_z"
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

library altera_mf;
use altera_mf.altera_mf_components.all;

entity sdram_ctrl_phy_de0 is
  generic (
    CL : positive);                     -- CAS latency
  port (
    clk     : in std_logic;
    clkout  : in std_logic;
    rst     : in std_logic;

    sd_cke_nxt : in std_logic;
    sd_cs_nxt  : in std_logic;
    sd_ras_nxt : in std_logic;
    sd_cas_nxt : in std_logic;
    sd_we_nxt  : in std_logic;
    sd_ba_nxt  : in std_logic_vector(1 downto 0);
    sd_a_nxt   : in std_logic_vector(11 downto 0);

    wren_nxt  : in std_logic;
    wdata_nxt : in std_logic_vector(15 downto 0);

    rden_nxt : in  std_logic;
    rdata    : out std_logic_vector(15 downto 0);
    rstb     : out std_logic;

    sd_ck   : out   std_logic;
    sd_cke  : out   std_logic;
    sd_cs   : out   std_logic;
    sd_ras  : out   std_logic;
    sd_cas  : out   std_logic;
    sd_we   : out   std_logic;
    sd_ba   : out   std_logic_vector(1 downto 0);
    sd_a    : out   std_logic_vector(11 downto 0);
    sd_dq   : inout std_logic_vector(15 downto 0));

end sdram_ctrl_phy_de0;

architecture rtl of sdram_ctrl_phy_de0 is
  -- memory command: domain clk
  signal sd_cke_r : std_logic := '0';
  signal sd_cs_r  : std_logic := '1';
  signal sd_ras_r : std_logic;
  signal sd_cas_r : std_logic;
  signal sd_we_r  : std_logic;
  signal sd_ba_r  : std_logic_vector(1 downto 0);
  signal sd_a_r   : std_logic_vector(11 downto 0);

  -- control / data signals for write
  signal dq_en_r : std_logic_vector(15 downto 0);
  signal dq_o_r  : std_logic_vector(15 downto 0);

  -- control / data signals for read
  -- adjust read delay through length of vector
  signal dq_i        : std_logic_vector(15 downto 0);
  signal rden_r      : std_logic_vector(CL downto 0);
  signal rstb_r      : std_logic;
  signal rdata_r     : std_logic_vector(15 downto 0);

begin  -- rtl

  -----------------------------------------------------------------------------
  -- SDRAM clock generation
  -----------------------------------------------------------------------------

  sd_ck_obuf : altiobuf_out generic map (
    NUMBER_OF_CHANNELS => 1)
    port map (
      datain(0)    => clkout,
      dataout(0)   => sd_ck);

  -- Output clock 180 deg phase-shifted with respect to control/data signals
  --sd_ck_off : altddio_out
  --  generic map (
  --    WIDTH => 1)
  --  port map (
  --    datain_h   => "0",
  --    datain_l   => "1",
  --    dataout(0) => sd_ck,
  --    outclock   => clk);

  -----------------------------------------------------------------------------
  -- SDRAM command & address
  --
  -- These registers should be placed in the I/O blocks.
  -- Use appriopate timing constraints.
  -----------------------------------------------------------------------------

  process (clk)
  begin  -- process
    if rising_edge(clk) then
      if rst = '1' then
        sd_cke_r <= '0';
        sd_cs_r  <= '1';                -- Deselect
      else
        sd_cke_r <= sd_cke_nxt;
        sd_cs_r  <= sd_cs_nxt;
      end if;

      sd_ras_r <= sd_ras_nxt;
      sd_cas_r <= sd_cas_nxt;
      sd_we_r  <= sd_we_nxt;
      sd_ba_r  <= sd_ba_nxt;
      sd_a_r   <= sd_a_nxt;
    end if;
  end process;

  sd_cke <= sd_cke_r;
  sd_cs  <= sd_cs_r;
  sd_ras <= sd_ras_r;
  sd_cas <= sd_cas_r;
  sd_we  <= sd_we_r;
  sd_ba  <= sd_ba_r;
  sd_a   <= sd_a_r;

  -----------------------------------------------------------------------------
  -- Write data
  --
  -- These registers should be placed in the I/O blocks.
  -- Use appriopate timing constraints.
  -----------------------------------------------------------------------------

  process (clk)
  begin  -- process
    if rising_edge(clk) then
      -- prevent unnecessary toggling
      if wren_nxt = '1' then
        dq_o_r <= wdata_nxt;
      end if;

      if rst = '1' then
        dq_en_r <= (others => '0');
      else
        dq_en_r <= (others => wren_nxt);
      end if;
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- DQ I/O Buffers
  -----------------------------------------------------------------------------

	-- Explicit instantiation of I/O buffers. May be required if entity is part
	-- of a netlist, which is used in another design.
	-- If altiobuf_bidir is used instead, then meaningless warnings are issued by
	-- Quartus.
  dq_obuf : altiobuf_out generic map (
    NUMBER_OF_CHANNELS => 16, USE_OE => "TRUE")
    port map (
      datain    => dq_o_r,
      oe        => dq_en_r,
      dataout   => sd_dq);

  dq_ibuf : altiobuf_in generic map (
    NUMBER_OF_CHANNELS => 16)
    port map (
      datain    => sd_dq,
      dataout   => dq_i);

  -----------------------------------------------------------------------------
  -- Read data capture
  -----------------------------------------------------------------------------

  process (clk)
  begin  -- process
    if rising_edge(clk) then
      -- Read enable pipeline
      if rst = '1' then
        rden_r <= (others => '0');
        rstb_r <= '0';
      else
        rden_r <= rden_r(rden_r'left-1 downto 0) & rden_nxt;
        rstb_r <= rden_r(rden_r'left);  -- aligned with rdata_r
      end if;

      -- Data capture
      if rden_r(rden_r'left) = '1' then
        rdata_r <= dq_i;
      end if;
    end if;
  end process;

  rdata <= rdata_r;
  rstb  <= rstb_r;

end rtl;
