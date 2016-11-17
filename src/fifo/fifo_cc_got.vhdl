-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--									Steffen Koehler
--									Martin Zabel
--									Patrick Lehmann
--
-- Entity:					FIFO, Common Clock (cc), Pipelined Interface
--
-- Description:
-- -------------------------------------
-- This module implements a regular FIFO with common clock (cc), pipelined
-- interface. Common clock means read and write port use the same clock. The
-- FIFO size can be configured in word width (``D_BITS``) and minimum word count
-- ``MIN_DEPTH``. The specified depth is rounded up to the next suitable value.
--
-- ``DATA_REG`` (=true) is a hint, that distributed memory or registers should
-- be used as data storage. The actual memory type depends on the device
-- architecture. See implementation for details.
--
-- ``*STATE_*_BITS`` defines the granularity of the fill state indicator
-- ``*state_*``. If a fill state is not of interest, set ``*STATE_*_BITS = 0``.
-- ``fstate_rd`` is associated with the read clock domain and outputs the
-- guaranteed number of words available in the FIFO. ``estate_wr`` is associated
-- with the write clock domain and outputs the number of words that is
-- guaranteed to be accepted by the FIFO without a capacity overflow. Note that
-- both these indicators cannot replace the ``full`` or ``valid`` outputs as
-- they may be implemented as giving pessimistic bounds that are minimally off
-- the true fill state.
--
-- ``fstate_rd`` and ``estate_wr`` are combinatorial outputs and include an address
-- comparator (subtractor) in their path.
--
-- .. rubric:: Examples:
--
-- * FSTATE_RD_BITS = 1:
--
--   +-----------+----------------------+
--   | fstate_rd | filled (at least)    |
--   +===========+======================+
--   |    0      | 0/2 full             |
--   +-----------+----------------------+
--   |    1      | 1/2 full (half full) |
--   +-----------+----------------------+
--
-- * FSTATE_RD_BITS = 2:
--
--   +-----------+----------------------+
--   | fstate_rd | filled (at least)    |
--   +===========+======================+
--   |    0      | 0/4 full             |
--   +-----------+----------------------+
--   |    1      | 1/4 full             |
--   +-----------+----------------------+
--   |    2      | 2/4 full (half full) |
--   +-----------+----------------------+
--   |    3      | 3/4 full             |
--   +-----------+----------------------+
--
-- SeeAlso:
-- :ref:`IP:fifo_dc_got`
--   For a FIFO with dependent clocks.
-- :ref:`IP:fifo_ic_got`
--   For a FIFO with independent clocks (cross-clock FIFO).
-- :ref:`IP:fifo_glue`
--   For a minimal FIFO / pipeline decoupling.
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

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library	poc;
use			poc.config.all;
use			poc.utils.all;
use			poc.ocram.all;


entity fifo_cc_got is
  generic (
    D_BITS         : positive;          -- Data Width
    MIN_DEPTH      : positive;          -- Minimum FIFO Depth
    DATA_REG       : boolean := false;  -- Store Data Content in Registers
    STATE_REG      : boolean := false;  -- Registered Full/Empty Indicators
    OUTPUT_REG     : boolean := false;  -- Registered FIFO Output
    ESTATE_WR_BITS : natural := 0;      -- Empty State Bits
    FSTATE_RD_BITS : natural := 0       -- Full State Bits
  );
  port (
    -- Global Reset and Clock
    rst, clk : in  std_logic;

    -- Writing Interface
    put       : in  std_logic;                            -- Write Request
    din       : in  std_logic_vector(D_BITS-1 downto 0);  -- Input Data
    full      : out std_logic;
    estate_wr : out std_logic_vector(imax(0, ESTATE_WR_BITS-1) downto 0);

    -- Reading Interface
    got       : in  std_logic;                            -- Read Completed
    dout      : out std_logic_vector(D_BITS-1 downto 0);  -- Output Data
    valid     : out std_logic;
    fstate_rd : out std_logic_vector(imax(0, FSTATE_RD_BITS-1) downto 0)
  );
end entity fifo_cc_got;


architecture rtl of fifo_cc_got is
  -- Address Width
  constant A_BITS : natural := log2ceil(MIN_DEPTH);

  -----------------------------------------------------------------------------
  -- Memory Pointers

  -- Actual Input and Output Pointers
  signal IP0 : unsigned(A_BITS-1 downto 0) := (others => '0');
  signal OP0 : unsigned(A_BITS-1 downto 0) := (others => '0');

  -- Incremented Input and Output Pointers
  signal IP1 : unsigned(A_BITS-1 downto 0);
  signal OP1 : unsigned(A_BITS-1 downto 0);

  -----------------------------------------------------------------------------
  -- Backing Memory Connectivity

  -- Write Port
  signal wa : unsigned(A_BITS-1 downto 0);
  signal we : std_logic;

  -- Read Port
  signal ra : unsigned(A_BITS-1 downto 0);
  signal re : std_logic;

  -- Internal full and empty indicators
  signal fulli : std_logic;
  signal empti : std_logic;

begin
  -----------------------------------------------------------------------------
  -- Pointer Logic
	blkPointer : block
		signal IP0_slv		: std_logic_vector(IP0'range);
		signal IP1_slv		: std_logic_vector(IP0'range);
		signal OP0_slv		: std_logic_vector(IP0'range);
		signal OP1_slv		: std_logic_vector(IP0'range);
	begin
		IP0_slv	<= std_logic_vector(IP0);
		OP0_slv	<= std_logic_vector(OP0);

		incIP : entity PoC.arith_carrychain_inc
			generic map (
				BITS		=> A_BITS
			)
			port map (
				X				=> IP0_slv,
				Y				=> IP1_slv
			);

		incOP : entity PoC.arith_carrychain_inc
			generic map (
				BITS		=> A_BITS
			)
			port map (
				X				=> OP0_slv,
				Y				=> OP1_slv
			);

		IP1			<= unsigned(IP1_slv);
		OP1			<= unsigned(OP1_slv);
	end block;

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        IP0 <= (others => '0');
        OP0 <= (others => '0');
      else
        -- Update Input Pointer upon Write
        if we = '1' then
          IP0 <= IP1;
        end if;

        -- Update Output Pointer upon Read
        if re = '1' then
          OP0 <= OP1;
        end if;

      end if;
    end if;
  end process;
  wa <= IP0;
  ra <= OP0;

  -- Fill State Computation (soft indicators)
  process(IP0, OP0, fulli)
    variable  d : std_logic_vector(A_BITS-1 downto 0);
  begin
    estate_wr <= (others => 'X');
    fstate_rd <= (others => 'X');

    -- Compute Pointer Difference
    if fulli = '1' then
      d := (others => '1');              -- true number minus one when full
    else
      d := std_logic_vector(IP0 - OP0);  -- true number of valid entries
    end if;

    -- Fix assignment to outputs
    if ESTATE_WR_BITS > 0 then
      -- one's complement is pessimistically low by one but
      -- benefits optimization by synthesis
      estate_wr <= not d(d'left downto d'left-ESTATE_WR_BITS+1);
    end if;
    if FSTATE_RD_BITS > 0 then
      fstate_rd <= d(d'left downto d'left-FSTATE_RD_BITS+1);
    end if;
  end process;

  -----------------------------------------------------------------------------
  -- Computation of full and empty indications.

  -- Cheapest implementation using a direction flag DF to determine
  -- full or empty condition on equal input and output pointers.
  -- Both conditions are derived combinationally involving a comparison
  -- of the two pointers.
  genStateCmb: if not STATE_REG generate
    signal DF    : std_logic := '0';    -- Direction Flag
    signal Peq   : std_logic;           -- Pointer Comparison
  begin

    -- Direction Flag remembering the last Operation
    process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          DF <= '0';                    -- get => empty
        elsif we /= re then
          DF <= we;
        end if;
      end if;
    end process;

    -- Fill Conditions
    Peq   <= '1' when IP0 = OP0 else '0';
    fulli <= Peq and     DF;
    empti <= Peq and not DF;
  end generate genStateCmb;

  -- Implementation investing another comparator so as to provide both full and
  -- empty indications from registers.
  genStateReg: if STATE_REG generate
    signal Ful : std_logic := '0';
    signal Avl : std_logic := '0';
  begin
    process(clk)
    begin
      if rising_edge(clk) then
        if rst = '1' then
          Ful <= '0';
          Avl <= '0';
        elsif we /= re then

          -- Update Full Indicator
          if we = '0' or IP1 /= OP0 then
            Ful <= '0';
          else
            Ful <= '1';
          end if;

          -- Update Empty Indicator
          if re = '0' or OP1 /= IP0 then
            Avl <= '1';
          else
            Avl <= '0';
          end if;

        end if;
      end if;
    end process;
    fulli <= Ful;
    empti <= not Avl;
  end generate genStateReg;

  -----------------------------------------------------------------------------
  -- Memory Access

  -- Write Interface => Input
  full <= fulli;
  we   <= put and not fulli;

  -- Backing Memory and Read Interface => Output
  genLarge: if not DATA_REG generate
    signal do : std_logic_vector(D_BITS-1 downto 0);
  begin

    -- Backing Memory
    ram : entity PoC.ocram_sdp
      generic map (
        A_BITS => A_BITS,
        D_BITS => D_BITS
      )
      port map (
        wclk   => clk,
        rclk   => clk,
        wce    => '1',

        wa     => wa,
        we     => we,
        d      => din,

        ra     => ra,
        rce    => re,
        q      => do
      );

    -- Read Interface => Output
    genOutputCmb : if not OUTPUT_REG generate
      signal Vld : std_logic := '0';      -- valid output of RAM module
    begin
      process(clk)
      begin
        if rising_edge(clk) then
          if rst = '1' then
            Vld <= '0';
          else
            Vld <= (Vld and not got) or not empti;
          end if;
        end if;
      end process;
      re    <= (not Vld or got) and not empti;
      dout  <= do;
      valid <= Vld;
    end generate genOutputCmb;

    genOutputReg: if OUTPUT_REG generate
      -- Extra Buffer Register for Output Data
      signal Buf : std_logic_vector(D_BITS-1 downto 0) := (others => '-');
      signal Vld : std_logic_vector(0 to 1)            := (others => '0');
      -- Vld(0)   -- valid output of RAM module
      -- Vld(1)   -- valid word in Buf
    begin
      process(clk)
      begin
        if rising_edge(clk) then
          if rst = '1' then
            Buf <= (others => '-');
            Vld <= (others => '0');
          else
            Vld(0) <= (Vld(0) and Vld(1) and not got) or not empti;
            Vld(1) <= (Vld(1) and not got) or Vld(0);
            if Vld(1) = '0' or got = '1' then
              Buf <= do;
            end if;
          end if;
        end if;
      end process;
      re    <= (not Vld(0) or not Vld(1) or got) and not empti;
      dout  <= Buf;
      valid <= Vld(1);
    end generate genOutputReg;

  end generate genLarge;

  genSmall: if DATA_REG generate

    -- Memory modelled as Array
    type regfile_t is array(0 to 2**A_BITS-1) of std_logic_vector(D_BITS-1 downto 0);
    signal regfile : regfile_t;
    attribute ram_style            : string;  -- XST specific
    attribute ram_style of regfile : signal is "distributed";

    -- Altera Quartus II: Allow automatic RAM type selection.
    -- For small RAMs, registers are used on Cyclone devices and the M512 type
    -- is used on Stratix devices. Pass-through logic is automatically added
    -- if required. (Warning can be ignored.)

  begin

    -- Memory State
    process(clk)
    begin
      if rising_edge(clk) then
        --synthesis translate_off
        if SIMULATION and (rst = '1') then
          regfile <= (others => (others => '-'));
        else
        --synthesis translate_on
          if we = '1' then
            regfile(to_integer(wa)) <= din;
          end if;
        --synthesis translate_off
        end if;
        --synthesis translate_on
      end if;
    end process;

    -- Memory Output
    re    <= got and not empti;
    dout  <= (others => 'X') when Is_X(std_logic_vector(ra)) else
             regfile(to_integer(ra));
    valid <= not empti;

  end generate genSmall;

end rtl;
