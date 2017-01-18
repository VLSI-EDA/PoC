-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--
-- Entity:					Physical layer of SDRAM-Controller for Spartan-3E Starter Kit
--
-- Description:
-- -------------------------------------
-- Physical layer used by module :ref:`sdram_ctrl_s3esk <IP:sdram_ctrl_s3esk>`.
--
-- Instantiates input and output buffer components and adjusts the timing for
-- the Spartan-3E Starter Kit Board.
--
-- Clock and Reset Signals
-- ***********************
--
-- +-----------+-----------------------------------------------------------+
-- | Port      | Description                                               |
-- +===========+===========================================================+
-- |clk        | Base clock for command and write data path.               |
-- +-----------+-----------------------------------------------------------+
-- |clk_n      | ``clk`` phase shifted by 180 degrees.                     |
-- +-----------+-----------------------------------------------------------+
-- |clk90      | ``clk`` phase shifted by  90 degrees.                     |
-- +-----------+-----------------------------------------------------------+
-- |clk90_n    | ``clk`` phase shifted by 270 degrees.                     |
-- +-----------+-----------------------------------------------------------+
-- |clk_fb     | Driven by external feedback (sd_ck_fb) of DDR-SDRAM clock |
-- |(on PCB)   | (sd_ck_p). Actually unused, just referenced below.        |
-- +-----------+-----------------------------------------------------------+
-- |clk_fb90   | ``clk_fb`` phase shifted by 90 degrees.                   |
-- +-----------+-----------------------------------------------------------+
-- |clk_fb90_n | ``clk_fb`` phase shifted by 270 degrees.                  |
-- +-----------+-----------------------------------------------------------+
-- |rst        | Reset for ``clk``.                                        |
-- +-----------+-----------------------------------------------------------+
-- |rst180     | Reset for ``clk_n``                                       |
-- +-----------+-----------------------------------------------------------+
-- |rst90      | Reset for ``clk90``.                                      |
-- +-----------+-----------------------------------------------------------+
-- |rst270     | Reset for ``clk270``.                                     |
-- +-----------+-----------------------------------------------------------+
-- |rst_fb90   | Reset for ``clk_fb90``.                                   |
-- +-----------+-----------------------------------------------------------+
-- |rst_fb90_n | Reset for ``clk_fb90_n``.                                 |
-- +-----------+-----------------------------------------------------------+
--
--
-- Operation
-- *********
--
-- Command signals and write data are sampled with the rising edge of ``clk``.
--
-- Read data is aligned with ``clk_fb90_n``. Either process data in this clock
-- domain, or connect a FIFO to transfer data into another clock domain of your
-- choice.  This FIFO should capable of storing at least one burst (size BL/2)
-- + start of next burst (size 1).
--
-- Write and read enable (``wren_nxt``, ``rden_nxt``) must be hold for:
--
-- * 1 clock cycle  if BL = 2,
-- * 2 clock cycles if BL = 4, or
-- * 4 clock cycles if BL = 8.
--
-- They must be first asserted with the read and write command. Proper delay is
-- included in this unit.
--
-- The first word to write must be asserted with the write command. Proper
-- delay is included in this unit.
--
-- The SDRAM clock is regenerated in this module. The following timing is
-- chosen for minimum latency (should work up to 100 MHz):
--
-- * ``rising_edge(clk90)``   triggers ``rising_edge(sd_ck_p)``,
-- * ``rising_edge(clk90_n)`` triggers ``falling_edge(sd_ck_p)``.
--
-- XST options: Disable equivalent register removal.
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
--
library ieee;
use ieee.std_logic_1164.all;

library unisim;
use unisim.VComponents.all;

entity sdram_ctrl_phy_s3esk is
  port (
    clk     : in std_logic;
    clk_n   : in std_logic;
    clk90   : in std_logic;
    clk90_n : in std_logic;
    rst     : in std_logic;
    rst90   : in std_logic;
    rst180  : in std_logic;
    rst270  : in std_logic;

    clk_fb90   : in std_logic;
    clk_fb90_n : in std_logic;
    rst_fb90   : in std_logic;
    rst_fb270  : in std_logic;

    sd_cke_nxt : in std_logic;
    sd_cs_nxt  : in std_logic;
    sd_ras_nxt : in std_logic;
    sd_cas_nxt : in std_logic;
    sd_we_nxt  : in std_logic;
    sd_ba_nxt  : in std_logic_vector(1 downto 0);
    sd_a_nxt   : in std_logic_vector(12 downto 0);

    wren_nxt  : in std_logic;
    wdata_nxt : in std_logic_vector(31 downto 0);

    rden_nxt : in  std_logic;
    rdata    : out std_logic_vector(31 downto 0);
    rstb     : out std_logic;

    sd_ck_p : out   std_logic;
    sd_ck_n : out   std_logic;
    sd_cke  : out   std_logic;
    sd_cs   : out   std_logic;
    sd_ras  : out   std_logic;
    sd_cas  : out   std_logic;
    sd_we   : out   std_logic;
    sd_ba   : out   std_logic_vector(1 downto 0);
    sd_a    : out   std_logic_vector(12 downto 0);
    sd_ldqs : out   std_logic;
    sd_udqs : out   std_logic;
    sd_dq   : inout std_logic_vector(15 downto 0));

end sdram_ctrl_phy_s3esk;

architecture rtl of sdram_ctrl_phy_s3esk is
  -- memory command: domain clk
  signal sd_cke_r : std_logic := '0';
  signal sd_cs_r  : std_logic := '1';
  signal sd_ras_r : std_logic;
  signal sd_cas_r : std_logic;
  signal sd_we_r  : std_logic;
  signal sd_ba_r  : std_logic_vector(1 downto 0);
  signal sd_a_r   : std_logic_vector(12 downto 0);

  -- control / data signals for write
  signal wren_r_n : std_logic := '1';

  signal dqs_en0_nxt_n : std_logic;
  signal dqs_en0_r_n   : std_logic_vector(1 downto 0) := (others => '1');
  signal dqs_en1_r_n   : std_logic_vector(1 downto 0);  -- inited below
  signal dqs_o_r       : std_logic_vector(1 downto 0);

  signal dq_en0_n   : std_logic;
  signal dq_en1_r_n : std_logic_vector(15 downto 0);  -- inited below
  signal dq_o_r     : std_logic_vector(15 downto 0);
  signal dq_i       : std_logic_vector(15 downto 0);

  signal wdata_r        : std_logic_vector(31 downto 0);
  signal wdata_fal_r    : std_logic_vector(15 downto 0);

  -- control / data signals for read
  signal rden_r  : std_logic := '0';
  signal rden1_r : std_logic := '0';
  signal rden2_r : std_logic := '0';
  signal rden3_r : std_logic := '0';
  signal rstb_r  : std_logic := '0';

  signal rdata_ris_r : std_logic_vector(15 downto 0);
  signal rdata_r     : std_logic_vector(31 downto 0);

  attribute keep : string;
  attribute keep of rden1_r : signal is "true";

begin  -- rtl

  -----------------------------------------------------------------------------
  -- SDRAM clock generation
  --
  -- DO NOT RESET THESE! Reset is hold until clk_fb gets stable which is driven
  -- externally by sd_ck_p.
  -----------------------------------------------------------------------------

  sd_ck_p_off : ODDR2
    generic map (
      INIT   => '0',
      SRTYPE => "SYNC")
    port map (
      C0 => clk90,
      C1 => clk90_n,
      CE => '1',
      D0 => '1',
      D1 => '0',
      Q  => sd_ck_p,
      R  => '0',
      S  => '0');

  sd_ck_n_off : ODDR2
    generic map (
      INIT   => '1',
      SRTYPE => "SYNC")
    port map (
      C0 => clk90,
      C1 => clk90_n,
      CE => '1',
      D0 => '0',
      D1 => '1',
      Q  => sd_ck_n,
      R  => '0',
      S  => '0');

  -----------------------------------------------------------------------------
  -- SDRAM command & address
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
  -----------------------------------------------------------------------------
  --
  -- Write Enable, DQS Enable, DQ Enable
  -- NOTE: Do not optimize too much, otherwise timing constraints can't be met.
  --
  dqs_en0_nxt_n <= not (wren_nxt or (not wren_r_n));

  process (clk)
  begin  -- process
    if rising_edge(clk) then
      if rst = '1' then
        wren_r_n    <= '1';
        dqs_en0_r_n <= (others => '1');
      else
        wren_r_n    <= not wren_nxt;
        dqs_en0_r_n <= (others => dqs_en0_nxt_n);
      end if;
    end if;
  end process;

  dq_en0_n <= wren_r_n;

  --
  -- DQS output
  -- NOTE: clock domain change. Timing is critical because destination clock
  -- is only 90 degrees after source clock.
  --

  dqs_out : for i in 0 to 1 generate
    -- Both "tff" and "off" must be placed in the IOB. Thus, due to placement
    -- constraints, the "off" must be reset with rst90.

    tff : FDRSE
      generic map (
        INIT => '1')                    -- disable output
      port map (
        Q    => dqs_en1_r_n(i),
        C    => clk90,
        CE   => '1',
        D    => dqs_en0_r_n(i),
        R    => '0',
        S    => rst90);                 -- disable output

    off    : ODDR2
      generic map (
        SRTYPE => "SYNC")
      port map (
        Q      => dqs_o_r(i),
        C0     => clk90,
        C1     => clk90_n,
        CE     => '1',
        D0     => '1',                  -- same as sd_ck_p
        D1     => '0',                  -- dito
        R      => rst90,                -- only due to placement constraints
        S      => '0');

  end generate;

	-- Explicit instantiation of I/O buffers. Required if entity is part of a
	-- netlist, which is used in another design.
	ldqs_obuf : OBUFT
		port map (
			I => dqs_o_r(0),
			T => dqs_en1_r_n(0),
			O => sd_ldqs);

	udqs_obuf : OBUFT
		port map (
			I => dqs_o_r(1),
			T => dqs_en1_r_n(1),
			O => sd_udqs);

  --
  -- Write Data
  --
  process (clk)
  begin  -- process
    if rising_edge(clk) then
      -- prevent unnecessary toggling
      if wren_nxt = '1' then
        wdata_r <= wdata_nxt;
      end if;
    end if;
  end process;

  process (clk_n)
  begin  -- process
    if rising_edge(clk_n) then
      wdata_fal_r <= wdata_r(31 downto 16);
    end if;
  end process;

  dq_out: for i in 0 to 15 generate
    -- A reset can't be applied to the "tff" because then it must also be
    -- applied to the "iff" which is driven be another clock domain.
    -- (Applying reset to "off" is not a problem.)
    -- Thus, the "tff" is reset only due to reset of dq_en0_n.

    tff : FDRSE
      generic map (
        INIT => '1')                    -- disable output
      port map (
        Q    => dq_en1_r_n(i),
        C    => clk,
        CE   => '1',
        D    => dq_en0_n,
        R    => '0',
        S    => '0');

    off : ODDR2
      generic map (
        SRTYPE => "SYNC")
      port map (
        Q      => dq_o_r(i),
        C0     => clk,
        C1     => clk_n,
        CE     => '1',
        D0     => wdata_r(i),           -- for rising_edge(dqs)
        D1     => wdata_fal_r(i),       -- for falling_edge(dqs)
        R      => '0',
        S      => '0');

  end generate;

  -----------------------------------------------------------------------------
  -- DQ I/O Buffers
  -----------------------------------------------------------------------------

	-- Explicit instantiation of I/O buffers. Required if entity is part of a
	-- netlist, which is used in another design.
	dq_iobuf : for i in 0 to 15 generate
		b : IOBUF
			port map (
				I => dq_o_r(i),
				T => dq_en1_r_n(i),
				IO => sd_dq(i),
				O  => dq_i(i));
	end generate;

  -----------------------------------------------------------------------------
  -- Read data capture
  -----------------------------------------------------------------------------
  -- Register read enable
  -- rden1_r is a separate signal for simple identification in constraints.
  -- This signal must be kept.
  process (clk)
  begin  -- process
    if rising_edge(clk) then
      if rst = '1' then
        rden_r <= '0';
        rden1_r <= '0';
      else
        rden_r  <= rden_nxt;
        rden1_r <= rden_r;
      end if;
    end if;
  end process;

  -- Register read enable with clk_fb90_n which equals sd_ck_p + 270 degrees
  -- delayed by external feedback.
  -- NOTE: Timing constraints must ensure, that read enable is captured with
  -- the rising edge of clk_fb90_n directly following rising edge of clk.
  process (clk_fb90_n)
  begin  -- process
    if rising_edge(clk_fb90_n) then
      if rst_fb270 = '1' then
        rden2_r <= '0';
      else
        rden2_r <= rden1_r;
      end if;
    end if;
  end process;

  -- Delay once more
  -- If timing is critical, then rden3_r should be duplicated before it used as
  -- clock enable for input FFs.
  process (clk_fb90_n)
  begin
    if rising_edge(clk_fb90_n) then
      if rst_fb270 = '1' then
        rden3_r <= '0';
      else
        rden3_r <= rden2_r;
      end if;
    end if;
  end process;

  dq_in : for i in 0 to 15 generate
    iff   : IDDR2
      generic map (
        SRTYPE => "SYNC")
      port map (
        D      => dq_i(i),
        C0     => clk_fb90,
        C1     => clk_fb90_n,
        CE     => rden3_r,
        Q0     => rdata_ris_r(i),
        Q1     => rdata_r(16+i),
        R      => '0',
        S      => '0');
  end generate;

  process (clk_fb90_n)
  begin  -- process
    if rising_edge(clk_fb90_n) then
      -- align both parts of data word
      rdata_r(15 downto 0) <= rdata_ris_r;

      -- align strobe with data
      if rst_fb270 = '1' then
        rstb_r <= '0';
      else
        rstb_r <= rden3_r;
      end if;
    end if;
  end process;

  rdata <= rdata_r;
  rstb  <= rstb_r;

end rtl;
