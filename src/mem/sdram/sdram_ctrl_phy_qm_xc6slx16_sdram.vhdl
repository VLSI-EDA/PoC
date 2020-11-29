-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--
-- Entity:					Physical layer of SDR-SDRAM-Controller for QM XC6SLX16 SDRAM.
--
-- Description:
-- -------------------------------------
-- Physical layer used by module :ref:`sdram_ctrl_qm_xc6slx16_sdram <IP:sdram_ctrl_qm_xc6slx16_sdram>`.
--
-- Instantiates input and output buffer components and adjusts the timing for
-- the QM XC6SLX16 SDRAM board.
--
-- Clock and Reset Signals
-- ***********************
--
-- +-----------+-----------------------------------------------------------+
-- | Port      | Description                                               |
-- +===========+===========================================================+
-- |clk        | Base clock for command and write data path.               |
-- +-----------+-----------------------------------------------------------+
-- |clkout     | Clock to be mirrored on sd_ck. This clock must have the   |
-- |           | same frequence as clk. The phase can be different, so     |
-- |           | that input timings for sd_dq on the FPGA side can be met. |
-- +-----------+-----------------------------------------------------------+
-- |clkout_n   | clkout phase-shifted by 180 degrees.                      |
-- +-----------+-----------------------------------------------------------+
-- |rst        | Reset for ``clk``.                                        |
-- +-----------+-----------------------------------------------------------+
--
-- Datapath Signals
-- ****************
--
-- +--------------------+------------------------------------------------+
-- + wr_en_nxt          | Write enable, see below.                       |
-- +--------------------+------------------------------------------------+
-- | wdata_nxt          | The data to be written to the memory.          |
-- +--------------------+------------------------------------------------+
-- | wmask_nxt          | Write-mask, for each byte: '0' = write byte,   |
-- |                    | '1' = mask byte from write.                    |
-- +--------------------+------------------------------------------------+
-- + rd_en_nxt          | Write enable, see below.                       |
-- +--------------------+------------------------------------------------+
-- | rstb               | High-active read-strobe.                       |
-- +--------------------+------------------------------------------------+
-- | rdata              | The read-data returned from the memory.        |
-- +--------------------+------------------------------------------------+
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
-- XST options: Disable equivalent register removal.
--
-- Synchronous resets are used. Reset must be hold for at least two cycles.
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

library unisim;
use unisim.VComponents.all;

entity sdram_ctrl_phy_qm_xc6slx16_sdram is
  generic (
    CL : positive);  										-- CAS latency
  port (
    clk      : in std_logic;
    clkout   : in std_logic;
    clkout_n : in std_logic;
    rst      : in std_logic;

    sd_cke_nxt : in std_logic;
    sd_cs_nxt  : in std_logic;
    sd_ras_nxt : in std_logic;
    sd_cas_nxt : in std_logic;
    sd_we_nxt  : in std_logic;
    sd_ba_nxt  : in std_logic_vector(1 downto 0);
    sd_a_nxt   : in std_logic_vector(12 downto 0);

    wren_nxt  : in std_logic;
    wdata_nxt : in std_logic_vector(15 downto 0);
    wmask_nxt : in std_logic_vector(1 downto 0);

    rden_nxt : in  std_logic;
    rdata    : out std_logic_vector(15 downto 0);
    rstb     : out std_logic;

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

end sdram_ctrl_phy_qm_xc6slx16_sdram;

architecture rtl of sdram_ctrl_phy_qm_xc6slx16_sdram is
  -- memory command: domain clk
  signal sd_cke_r : std_logic := '0';
  signal sd_cs_r  : std_logic := '1';
  signal sd_ras_r : std_logic;
  signal sd_cas_r : std_logic;
  signal sd_we_r  : std_logic;
  signal sd_ba_r  : std_logic_vector(1 downto 0);
  signal sd_a_r   : std_logic_vector(12 downto 0);

  -- control / data signals for write
  signal dq_hz_r : std_logic_vector(15 downto 0); -- high-impedance
  signal dq_o_r  : std_logic_vector(15 downto 0);
  signal dqm_r   : std_logic_vector(1 downto 0);

  -- control / data signals for read
  -- adjust read delay through length of vector
  signal sd_dq_in    : std_logic_vector(15 downto 0);
  signal rden_r      : std_logic_vector(CL downto 0);
  signal rstb_r      : std_logic;
  signal rdata_r     : std_logic_vector(15 downto 0);

  attribute keep : string;
  attribute keep of rden_r : signal is "true";

	-- Force one tri-state control register per DQ pin to have a short critical
	-- path between the control register and the output, so that, FFs in IOBs can
	-- be used.
	attribute keep of dq_hz_r : signal is "true";

  -- Force Command, DQ and DQ-control signals into IOBs
  attribute iob : string;
  attribute iob of sd_cke_r : signal is "true";
  attribute iob of sd_cs_r  : signal is "true";
  attribute iob of sd_ras_r : signal is "true";
  attribute iob of sd_cas_r : signal is "true";
  attribute iob of sd_we_r  : signal is "true";
  attribute iob of sd_ba_r  : signal is "true";
  attribute iob of sd_a_r   : signal is "true";
  attribute iob of dq_o_r   : signal is "true";
  attribute iob of dq_hz_r  : signal is "true";
  attribute iob of dqm_r    : signal is "true";
  attribute iob of rdata_r  : signal is "true";
begin  -- rtl

  -----------------------------------------------------------------------------
  -- SDRAM clock generation
  -----------------------------------------------------------------------------

  sd_ck_off : ODDR2
    generic map (
			DDR_ALIGNMENT => "C0",
      INIT   => '0',
      SRTYPE => "ASYNC")
    port map (
      C0 => clkout,
      C1 => clkout_n,
      CE => '1',
      D0 => '1',
      D1 => '0',
      Q  => sd_ck,
      R  => '0',
      S  => '0');

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
				dqm_r  <= wmask_nxt;
      end if;

      if rst = '1' then
				-- disable output upon reset
        dq_hz_r <= (others => '1');
      else
				-- disable output when not writing
        dq_hz_r <= (others => not wren_nxt);
      end if;
    end if;
  end process;

  dq_obuf: for i in 0 to 15 generate
		buf: OBUFT port map(
			I => dq_o_r(i),
			T => dq_hz_r(i),
			O => sd_dq(i)
		);
  end generate dq_obuf;

	sd_dqm <= dqm_r;

  -----------------------------------------------------------------------------
  -- Read data capture
  -----------------------------------------------------------------------------

  dq_ibuf: for i in 0 to 15 generate
		buf: IBUF port map(
			I => sd_dq(i),
			O => sd_dq_in(i)
		);
  end generate dq_ibuf;

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
        rdata_r <= sd_dq_in;
      end if;
    end if;
  end process;

  rdata <= rdata_r;
  rstb  <= rstb_r;

end rtl;
