-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--									Steffen Koehler
--									Martin Zabel
--
-- Entity:					FIFO, independent clocks (ic), first-word-fall-through mode
--
-- Description:
-- -------------------------------------
-- Independent clocks meens that read and write clock are unrelated.
--
-- This implementation uses dedicated block RAM for storing data.
--
-- First-word-fall-through (FWFT) mode is implemented, so data can be read out
-- as soon as ``valid`` goes high. After the data has been captured, then the
-- signal ``got`` must be asserted.
--
-- Synchronous reset is used. Both resets may overlap.
--
-- ``DATA_REG`` (=true) is a hint, that distributed memory or registers should be
-- used as data storage. The actual memory type depends on the device
-- architecture. See implementation for details.
--
-- ``*STATE_*_BITS`` defines the granularity of the fill state indicator
-- ``*state_*``. ``fstate_rd`` is associated with the read clock domain and outputs
-- the guaranteed number of words available in the FIFO. ``estate_wr`` is
-- associated with the write clock domain and outputs the number of words that
-- is guaranteed to be accepted by the FIFO without a capacity overflow. Note
-- that both these indicators cannot replace the ``full`` or ``valid`` outputs as
-- they may be implemented as giving pessimistic bounds that are minimally off
-- the true fill state.
--
-- If a fill state is not of interest, set *STATE_*_BITS = 0.
--
-- ``fstate_rd`` and ``estate_wr`` are combinatorial outputs and include an address
-- comparator (subtractor) in their path.
--
-- Examples:
-- - FSTATE_RD_BITS = 1: fstate_rd == 0 => 0/2 full
--                       fstate_rd == 1 => 1/2 full (half full)
--
-- - FSTATE_RD_BITS = 2: fstate_rd == 0 => 0/4 full
--                       fstate_rd == 1 => 1/4 full
--                       fstate_rd == 2 => 2/4 full
--                       fstate_rd == 3 => 3/4 full
--
-- License:
-- =============================================================================
-- Copyright 2007-2014 Technische Universitaet Dresden - Germany
--                     Chair of VLSI-Design, Diagnostics and Architecture
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


entity fifo_ic_got is
  generic (
    D_BITS         : positive;          -- Data Width
    MIN_DEPTH      : positive;          -- Minimum FIFO Depth
    DATA_REG       : boolean := false;  -- Store Data Content in Registers
    OUTPUT_REG     : boolean := false;  -- Registered FIFO Output
    ESTATE_WR_BITS : natural := 0;      -- Empty State Bits
    FSTATE_RD_BITS : natural := 0       -- Full State Bits
  );
  port (
    -- Write Interface
    clk_wr    : in  std_logic;
    rst_wr    : in  std_logic;
    put       : in  std_logic;
    din       : in  std_logic_vector(D_BITS-1 downto 0);
    full      : out std_logic;
    estate_wr : out std_logic_vector(imax(ESTATE_WR_BITS-1, 0) downto 0);

    -- Read Interface
    clk_rd    : in  std_logic;
    rst_rd    : in  std_logic;
    got       : in  std_logic;
    valid     : out std_logic;
    dout      : out std_logic_vector(D_BITS-1 downto 0);
    fstate_rd : out std_logic_vector(imax(FSTATE_RD_BITS-1, 0) downto 0)
  );
end entity fifo_ic_got;


architecture rtl of fifo_ic_got is

  -- Constants
  constant A_BITS : positive := log2ceilnz(MIN_DEPTH);
  constant AN     : positive := A_BITS + 1;

  -- Registers, clk_wr domain
  signal IP1 : std_logic_vector(AN-1 downto 0);                     -- IP + 1
  signal IP0 : std_logic_vector(AN-1 downto 0) := (others => '0');  -- Write Pointer IP
  signal IPz : std_logic_vector(AN-1 downto 0) := (others => '0');  -- IP delayed by one clock
	signal OPs : std_logic_vector(AN-1 downto 0) := (others => '0');  -- Sync stage: OP0 -> OPc
  signal OPc : std_logic_vector(AN-1 downto 0) := (others => '0');  -- Copy of OP
  signal Ful : std_logic                       := '0';              -- RAM full

  -- Registers, clk_rd domain
  signal OP1 : std_logic_vector(AN-1 downto 0);                     -- OP + 1
  signal OP0 : std_logic_vector(AN-1 downto 0) := (others => '0');  -- Read Pointer OP
  signal IPs : std_logic_vector(AN-1 downto 0) := (others => '0');  -- Sync stage: IPz -> IPc
  signal IPc : std_logic_vector(AN-1 downto 0) := (others => '0');  -- Copy of IP
  signal Avl : std_logic                       := '0';              -- RAM Data available
  signal Vld : std_logic                       := '0';              -- Output Valid

  -- Memory Connectivity
  signal wa   : unsigned(A_BITS-1 downto 0);
  signal di   : std_logic_vector(D_BITS-1 downto 0);
  signal puti : std_logic;

  signal ra   : unsigned(A_BITS-1 downto 0);
  signal do   : std_logic_vector(D_BITS-1 downto 0);
  signal geti : std_logic;

  signal goti : std_logic;              -- Internal Read ACK

begin

  -----------------------------------------------------------------------------
  -- Write clock domain
  -----------------------------------------------------------------------------
  blkIP: block
    signal Cnt : unsigned(AN-1 downto 0) := to_unsigned(1, AN);
  begin
    process(clk_wr)
    begin
      if rising_edge(clk_wr) then
        if rst_wr = '1' then
          Cnt <= to_unsigned(1, AN);
        elsif puti = '1' then
          Cnt <= Cnt + 1;
        end if;
      end if;
    end process;
    IP1 <= std_logic_vector(Cnt(A_BITS) & (Cnt(A_BITS-1 downto 0) xor ('0' & Cnt(A_BITS-1 downto 1))));
  end block blkIP;

  -- Update Write Pointer upon puti
  process(clk_wr)
  begin
    if rising_edge(clk_wr) then
      if rst_wr = '1' then
        IP0 <= (others => '0');
        IPz <= (others => '0');
				OPs <= (others => '0');
        OPc <= (others => '0');
        Ful <= '0';
      else
        IPz <= IP0;
        OPs <= OP0;
        OPc <= OPs;
        if puti = '1' then
          IP0 <= IP1;
          if IP1(A_BITS-1 downto 0) = OPc(A_BITS-1 downto 0) then
            Ful <= '1';
          else
            Ful <= '0';
          end if;
        end if;
        if Ful = '1' then
          if IP0 = (not OPc(A_BITS) & OPc(A_BITS-1 downto 0)) then
            Ful <= '1';
          else
            Ful <= '0';
          end if;
        end if;
      end if;
    end if;
  end process;
  puti <= put and not Ful;
  full <= Ful;

  di <= din;
  wa <= unsigned(IP0(A_BITS-1 downto 0));

  -----------------------------------------------------------------------------
  -- Read clock domain
  -----------------------------------------------------------------------------
  blkOP: block
    signal Cnt : unsigned(AN-1 downto 0) := to_unsigned(1, AN);
  begin
    process(clk_rd)
    begin
      if rising_edge(clk_rd) then
        if rst_rd = '1' then
          Cnt <= to_unsigned(1, AN);
        elsif geti = '1' then
          Cnt <= Cnt + 1;
        end if;
      end if;
    end process;
    OP1 <= std_logic_vector(Cnt(A_BITS) & (Cnt(A_BITS-1 downto 0) xor ('0' & Cnt(A_BITS-1 downto 1))));
  end block blkOP;

  process(clk_rd)
  begin
    if rising_edge(clk_rd) then
      if rst_rd = '1' then
        OP0 <= (others => '0');
				IPs <= (others => '0');
        IPc <= (others => '0');
        Avl <= '0';
        Vld <= '0';
      else
        IPs <= IPz;
        IPc <= IPs;
        if geti = '1' then
          OP0 <= OP1;
          if OP1(A_BITS-1 downto 0) = IPc(A_BITS-1 downto 0) then
            Avl <= '0';
          else
            Avl <= '1';
          end if;
          Vld <= '1';
        elsif goti = '1' then
          Vld <= '0';
        end if;

        if Avl = '0' then
          if OP0 = IPc then
            Avl <= '0';
          else
            Avl <= '1';
          end if;
        end if;

      end if;
    end if;
  end process;
  geti <= (not Vld or goti) and Avl;
  ra   <= unsigned(OP0(A_BITS-1 downto 0));

  -----------------------------------------------------------------------------
  -- Add register to data output
  --
  -- Not needed if DATA_REG = true, because "dout" is already feed from a
  -- register in that case.
  -----------------------------------------------------------------------------
  genRegN: if DATA_REG or not OUTPUT_REG generate
    goti  <= got;
    dout  <= do;
    valid <= Vld;
  end generate genRegN;
  genRegY: if (not DATA_REG) and OUTPUT_REG generate
    signal Buf  : std_logic_vector(D_BITS-1 downto 0) := (others => '-');
    signal VldB : std_logic := '0';
  begin
   process(clk_rd)
   begin
     if rising_edge(clk_rd) then
       if rst_rd = '1' then
         Buf  <= (others => '-');
         VldB <= '0';
       elsif goti = '1' then
         Buf  <= do;
         VldB <= Vld;
       end if;
     end if;
   end process;
   goti  <= not VldB or got;
   dout  <= Buf;
   valid <= VldB;
  end generate genRegY;

  -----------------------------------------------------------------------------
  -- Fill State
  -----------------------------------------------------------------------------
  -- Write Clock Domain
  gEstateWr: if ESTATE_WR_BITS >= 1 generate
    signal  d : unsigned(A_BITS-1 downto 0);
  begin
    d         <= unsigned(gray2bin(OPc(A_BITS-1 downto 0))) + not unsigned(gray2bin(IP0(A_BITS-1 downto 0)));
    estate_wr <= (others => '0') when Ful = '1' else
                 std_logic_vector(d(d'left downto d'left-ESTATE_WR_BITS+1));
  end generate gEstateWr;
  gNoEstateWr: if ESTATE_WR_BITS = 0 generate
    estate_wr <= "X";
  end generate gNoEstateWr;

  -- Read Clock Domain
  gFstateRd: if FSTATE_RD_BITS >= 1 generate
    signal  d : unsigned(A_BITS-1 downto 0);
  begin
    d         <= unsigned(gray2bin(IPc(A_BITS-1 downto 0))) + not unsigned(gray2bin(OP0(A_BITS-1 downto 0)));
    fstate_rd <= (others => '0') when Avl = '0' else
                 std_logic_vector(d(d'left downto d'left-FSTATE_RD_BITS+1));
  end generate gFstateRd;
  gNoFstateRd: if FSTATE_RD_BITS = 0 generate
    fstate_rd <= "X";
  end generate gNoFstateRd;

  -----------------------------------------------------------------------------
  -- Memory Instantiation
  -----------------------------------------------------------------------------
  gLarge: if not DATA_REG generate
    ram : entity PoC.ocram_sdp
      generic map (
        A_BITS => A_BITS,
        D_BITS => D_BITS
        )
      port map (
        wclk   => clk_wr,
        rclk   => clk_rd,
        wce    => '1',
        rce    => geti,
        we     => puti,
        ra     => ra,
        wa     => wa,
        d      => di,
        q      => do
        );
  end generate gLarge;

  gSmall: if DATA_REG generate
    -- Memory modelled as Array
    type regfile_t is array(0 to 2**A_BITS-1) of std_logic_vector(D_BITS-1 downto 0);
    signal regfile : regfile_t;
    attribute ram_style            : string;  -- XST specific
    attribute ram_style of regfile : signal is "distributed";

    -- Altera Quartus II: Allow automatic RAM type selection.
    -- For small RAMs, registers are used on Cyclone devices and the M512 type
    -- is used on Stratix devices. Pass-through logic is not required as
    -- reads do not occur on write addresses.
    -- Warning about undefined read-during-write behaviour can be ignored.
    attribute ramstyle : string;
    attribute ramstyle of regfile : signal is "no_rw_check";
  begin

    -- Memory State
    process(clk_wr)
    begin
      if rising_edge(clk_wr) then
        --synthesis translate_off
        if SIMULATION and (rst_wr = '1') then
          regfile <= (others => (others => '-'));
        else
        --synthesis translate_on
          if puti = '1' then
            regfile(to_integer(wa)) <= di;
          end if;
      --synthesis translate_off
        end if;
      --synthesis translate_on
      end if;
    end process;

    -- Memory Output
    process (clk_rd)
    begin  -- process
      if rising_edge(clk_rd) then
        if SIMULATION and (rst_rd = '1') then
          do <= (others => 'U');
        elsif geti = '1' then
          if Is_X(std_logic_vector(ra)) then
            do <= (others => 'X');
          else
            do <= regfile(to_integer(ra));
          end if;
        end if;
      end if;
    end process;
  end generate gSmall;

end rtl;
