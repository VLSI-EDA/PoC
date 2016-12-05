-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Martin Zabel
--
-- Entity:					Generic controller for SDRAM memory.
--
-- Description:
-- -------------------------------------
-- This file contains the FSM as well as parts of the datapath.
-- The board specific physical layer is defined in another file.
--
-- Configuration
-- *************
--
-- SDRAM_TYPE activates some special cases:
--
-- - 0 for SDR-SDRAM
-- - 1 for DDR-SDRAM
-- - 2 for DDR2-SDRAM (no special support yet like ODT)
--
-- 2**A_BITS specifies the number of memory cells in the SDRAM. This is the
-- size of th memory in bits divided by the native data-path width of the SDRAM
-- (also in bits).
--
-- D_BITS is the native data-path width of the SDRAM. The width might be doubled
-- by the physical interface for DDR interfaces.
--
-- Furthermore, the memory array is divided into
-- 2**R_BITS rows, 2**C_BITS columns and 2**B_BITS banks.
--
-- .. NOTE::
--    For example, the MT46V32M16 has 512 Mbit = 8M x 4 banks x 16 bit =
--    32M cells x 16 bit, with 8K rows and 1K columns. Thus, the configuration
--    is:
--
--    - A_BITS = :math:`\log_2(32\,\mbox{M}) = 25`
--    - D_BITS = 16
--    - data-path width of phy on user side: 32-bit because of DDR
--    - R_BITS = :math:`\log_2(8\,\mbox{K})  = 13`
--    - C_BITS = :math:`\log_2(1\,\mbox{K})  = 10`
--    - B_BITS = :math:`\log_2(4)   =  2`
--
-- Set CAS latency (CL, MR_CL) and  burst length (BL, MR_BL) according to
-- your needs.
--
-- If you have a DDR-SDRAM then set INIT_DLL = true, otherwise false.
--
-- The definition and values of generics T_* can be calculated from the
-- datasheets of the specific SDRAM (e.g. MT46V). Just divide the
-- minimum/maximum times by clock period.
-- Auto refreshs are applied periodically, the datasheet either specifies the
-- average refresh interval (T_REFI) or the total refresh cycle time (T_REF).
-- In the latter case, divide the total time by the row count to get the
-- average refresh interval. Substract about 50 clock cycles to
-- account for pending read/writes.
--
-- INIT_WAIT specifies the time period to wait after the SDRAM is powered up.
-- It is typically 100--200 us long, see datasheet. The waiting time is
-- specified in number of average refresh periods (specified by T_REFI):
-- INIT_WAIT = ceil(wait_time / clock_period / T_REFI)
-- e.g. INIT_WAIT = ceil(200 us / 10 ns / 700) = 29
--
-- Operation
-- *********
--
-- After user_cmd_valid is asserted high, the command (user_write) and address
-- (user_addr) must be hold until user_got_cmd is asserted.
--
-- The FSM automatically waits for user_wdata_valid on writes. The data should
-- be available soon. Otherwise the auto refresh might fail. The FSM only waits
-- for the first word to write. All successive words of a burst must be valid
-- in the following cycles. (A burst can't be stalled.) ATTENTION: During
-- writes, user_cmd_got is asserted only if user_wdata_valid is set.
--
-- The write data must directly connected to the physical layer.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany,
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

library poc;
use poc.utils.all;

entity sdram_ctrl_fsm is
  generic (
    SDRAM_TYPE : natural;               -- SDRAM type

    A_BITS       : positive;            -- log2ceil(memory cell count)
    D_BITS       : positive;            -- native data width
    R_BITS       : positive;            -- log2ceil(rows)
    C_BITS       : positive;            -- log2ceil(columns)
    B_BITS       : positive;            -- log2ceil(banks)

    CL : positive;  -- CAS Latency in clock cycles
    BL : positive;  -- Burst Length

    T_MRD     : integer;                -- in clock cycles
    T_RAS     : integer;                -- in clock cycles
    T_RCD     : integer;                -- in clock cycles
    T_RFC     : integer;                -- (or T_RC) in clock cycles
    T_RP      : integer;                -- in clock cycles
    T_WR      : integer;                -- in clock cycles
    T_WTR     : integer;                -- in clock cycles
    T_REFI    : integer;                -- in clock cycles
    INIT_WAIT : integer);               -- in T_REFI periods
  port (
    clk : in std_logic;
    rst : in std_logic;

    user_cmd_valid   : in  std_logic;
    user_wdata_valid : in  std_logic;
    user_write       : in  std_logic;
    user_addr        : in  std_logic_vector(A_BITS-1 downto 0);
    user_got_cmd     : out std_logic;
    user_got_wdata   : out std_logic;

    sd_cke_nxt : out std_logic;
    sd_cs_nxt  : out std_logic;
    sd_ras_nxt : out std_logic;
    sd_cas_nxt : out std_logic;
    sd_we_nxt  : out std_logic;
    sd_a_nxt   : out std_logic_vector(imax(R_BITS,C_BITS+1)-1 downto 0);
    sd_ba_nxt  : out std_logic_vector(B_BITS-1 downto 0);
    rden_nxt   : out std_logic;
    wren_nxt   : out std_logic);


end sdram_ctrl_fsm;

architecture rtl of sdram_ctrl_fsm is

  -- length of burst in clock cycles of "clk"
  function burst_clock_cycles return positive is
  begin
    if SDRAM_TYPE > 0 then return BL/2; end if;
    return BL;
  end;

  constant BCC : natural := burst_clock_cycles;

  -- FSM
  type FSM_TYPE is (INIT1, INIT2, INIT3, INIT4, INIT5, INIT6, INIT7, INIT8,
                    INIT9, INIT10, INIT11,
                    DO_ACTIVATE,
                    DO_READ1, DO_READ2,
                    DO_WRITE1, DO_WRITE2,
                    CHECKNXT,
                    DO_PRECHARGE, DO_AUTO_REFRESH);
  signal fsm_cs : FSM_TYPE;
  signal fsm_ns : FSM_TYPE;

  -- SDRAM Commands
  subtype  SD_CMD_TYPE is std_logic_vector(3 downto 0);
  constant SD_CMD_DESELECT        : SD_CMD_TYPE := "1---";
  constant SD_CMD_NOP             : SD_CMD_TYPE := "0111";
  constant SD_CMD_ACTIVE          : SD_CMD_TYPE := "0011";
  constant SD_CMD_READ            : SD_CMD_TYPE := "0101";
  constant SD_CMD_WRITE           : SD_CMD_TYPE := "0100";
  constant SD_CMD_BURST_TERMINATE : SD_CMD_TYPE := "0110";
  constant SD_CMD_PRECHARGE       : SD_CMD_TYPE := "0010";
  constant SD_CMD_AUTO_REFRESH    : SD_CMD_TYPE := "0001";
  constant SD_CMD_LOAD_MODE_REG   : SD_CMD_TYPE := "0000";
  signal   sd_cmd_nxt             : SD_CMD_TYPE;

  -- SDRAM address
  signal bank_addr     : std_logic_vector(B_BITS-1 downto 0);
  signal row_addr      : std_logic_vector(R_BITS-1 downto 0);
  signal col_addr      : std_logic_vector(C_BITS-1 downto 0);
  signal precharge_all : std_logic;
  signal reset_dll     : std_logic;

  type SD_A_SEL_TYPE is (SD_A_SEL_EXT_MODE_REG,
                         SD_A_SEL_MODE_REG,
                         SD_A_SEL_ROW_ADDR,
                         SD_A_SEL_COL_ADDR);
  signal sd_a_sel : SD_A_SEL_TYPE;

  type SD_BA_SEL_TYPE is (SD_BA_SEL_EXT_MODE_REG,
                         SD_BA_SEL_MODE_REG,
                         SD_BA_SEL_ADDR);
  signal sd_ba_sel : SD_BA_SEL_TYPE;

  -- Value for Extended Mode Register:
  --   bit 1--0: normal drive strength, enable DLL
  constant EXT_MODE_REG : std_logic_vector(1 downto 0) :=
    (others => '0');

  -- Value for Mode Register
  --   bit 6--0: CL, sequential burst, BL
  --   bit 8: reset DLL
  constant MODE_REG : std_logic_vector(8 downto 0) :=
    "00" & std_logic_vector(to_unsigned(CL, 3)) &
    "0"  & std_logic_vector(to_unsigned(BL-1, 3));

  --------
  -- Timer
  --------

  -- Timer for average periodic refresh interval.
  -- Timer counts from T_REFI-2 downto -1 for easy detection of
  -- "timer done". MSB is sign bit.
  signal   timer_tREFI       : signed(log2ceil(T_REFI-2) downto 0);
  constant TIMER_TREFI_INIT  : signed(log2ceil(T_REFI-2) downto 0)
    := to_signed(T_REFI-2, timer_tREFI'length);
  signal   timer_tREFI_start : std_logic;
  signal   timer_tREFI_done  : std_logic;

  -- Timer for SDRAM commands. To wait for n clock cycles, the timer must be
  -- initiated to the value n-2. The minimum allowed initial value is -1. In
  -- this case the timer is done in the next clock cycles.
  signal timer_cmd       : signed(5 downto 0);
  signal timer_cmd_init  : signed(5 downto 0);
  signal timer_cmd_start : std_logic;
  signal timer_cmd_done  : std_logic;

  -- Timer for ACTIVE-to-PRECHARGE.
  --   Timer counts from T_RAS-2 downto -1 for easy detection of
  --   "timer done". MSB is sign bit.
  --   Substract 1, because timer is checked one cycle before DO_PRECHARGE.
  signal   timer_tRAS       : signed(log2ceil(T_RAS-2) downto 0);
  constant TIMER_TRAS_INIT  : signed(log2ceil(T_RAS-2) downto 0)
    := to_signed(T_RAS-1 -2, timer_tRAS'length);
  signal   timer_tRAS_start : std_logic;
  signal   timer_tRAS_done  : std_logic;

  --------
  -- Counter
  --------

  -- Misc down counter. Counter is "done", when value == -1.
  -- Thus, if counter is inited to n, then counter is done n+2 decrements
  -- later.
  signal downcnt      : signed(log2ceil(INIT_WAIT-2) downto 0);
  signal downcnt_init : signed(downcnt'range);
  signal downcnt_set  : std_logic;
  signal downcnt_dec  : std_logic;
  signal downcnt_done : std_logic;

  --------
  -- Last address
  --------
  signal last_bank_addr_r   : std_logic_vector(bank_addr'range);
  signal last_bank_addr_nxt : std_logic_vector(bank_addr'range);
  signal last_row_addr_r    : std_logic_vector(row_addr'range);
  signal last_row_addr_nxt  : std_logic_vector(row_addr'range);
  signal last_write_r       : std_logic;
  signal last_write_nxt     : std_logic;
  signal save_cmd_addr      : std_logic;
  signal same_bank_row      : std_logic;

begin  -- rtl

  -----------------------------------------------------------------------------
  -- Configuration check
  -----------------------------------------------------------------------------

  assert (D_BITS = 16) or (D_BITS = 8) or (D_BITS = 4)
    report "Data width not yet supported."
    severity failure;

  -----------------------------------------------------------------------------
  -- Datapath not depending on FSM
  -----------------------------------------------------------------------------

  -- address mapping
  col_addr  <= user_addr(              C_BITS-1 downto             0);
  row_addr  <= user_addr(       R_BITS+C_BITS-1 downto        C_BITS);
  bank_addr <= user_addr(B_BITS+R_BITS+C_BITS-1 downto R_BITS+C_BITS);

  timer_tREFI_done <= timer_tREFI(timer_tREFI'left);
  timer_cmd_done   <= timer_cmd(timer_cmd'left);
  timer_tRAS_done  <= timer_tRAS(timer_tRAS'left);
  downcnt_done     <= downcnt(downcnt'left);

  same_bank_row <= '1' when (last_bank_addr_r & last_row_addr_r) =
                            (bank_addr & row_addr) else '0';

  last_bank_addr_nxt <= bank_addr;
  last_row_addr_nxt  <= row_addr;
  last_write_nxt     <= user_write;

  -----------------------------------------------------------------------------
  -- FSM
  -----------------------------------------------------------------------------
  process (fsm_cs,
           timer_tREFI_done, timer_cmd_done, timer_tRAS_done,
           downcnt_done,
           same_bank_row, last_write_r,
           user_cmd_valid, user_write, user_wdata_valid)
  begin  -- process
    fsm_ns        <= fsm_cs;
    sd_cke_nxt    <= '1';
    sd_cmd_nxt    <= SD_CMD_DESELECT;
    sd_a_sel      <= SD_A_SEL_COL_ADDR;
    sd_ba_sel     <= SD_BA_SEL_ADDR;
    precharge_all <= '0';
    reset_dll     <= '-';               -- only when load_mode_reg
    rden_nxt      <= '0';
    wren_nxt      <= '0';

    timer_tREFI_start <= '0';
    timer_tRAS_start  <= '0';

    timer_cmd_init <= (others => '-');
    timer_cmd_start <= '0';

    downcnt_init <= (others => '-');
    downcnt_set  <= '0';
    downcnt_dec  <= '0';

    user_got_cmd   <= '0';
    user_got_wdata <= '0';

    save_cmd_addr <= '0';

    case fsm_cs is
      when INIT1 =>
        -- Wait for SDRAM power up. See description for INIT_WAIT in header.
        -- Hold sd_cke low.
        sd_cke_nxt        <= '0';
        downcnt_init      <= to_signed(INIT_WAIT-2, downcnt_init'length);
        downcnt_set       <= '1';
        timer_tREFI_start <= '1';
        fsm_ns            <= INIT2;

      when INIT2 =>
        sd_cke_nxt <= '0';

        if timer_tREFI_done = '1' then
          if downcnt_done = '1' then
            fsm_ns <= INIT3;
          else
            timer_tREFI_start <= '1';
            downcnt_dec       <= '1';
          end if;
        end if;

      when INIT3 =>
        -- Bring up sd_cke with a NOP command.
        sd_cmd_nxt <= SD_CMD_NOP;
        fsm_ns     <= INIT4;

      when INIT4 =>
        -- Precharge all.
        sd_cmd_nxt      <= SD_CMD_PRECHARGE;
        sd_a_sel        <= SD_A_SEL_COL_ADDR;
        precharge_all   <= '1';
        timer_cmd_init  <= to_signed(T_RP-2, timer_cmd_init'length);
        timer_cmd_start <= '1';

        if SDRAM_TYPE >= 1 then
          fsm_ns <= INIT5;
        else
          -- skip if SDR-SDRAM
          fsm_ns <= INIT8;
        end if;

      when INIT5 =>
        sd_a_sel       <= SD_A_SEL_EXT_MODE_REG;
        sd_ba_sel      <= SD_BA_SEL_EXT_MODE_REG;
        timer_cmd_init <= to_signed(T_MRD-2, timer_cmd_init'length);

        if timer_cmd_done = '1' then
          -- Load extended mode register
          sd_cmd_nxt      <= SD_CMD_LOAD_MODE_REG;
          timer_cmd_start <= '1';
          fsm_ns          <= INIT6;
        end if;

      when INIT6 =>
        reset_dll      <= '1';
        sd_a_sel       <= SD_A_SEL_MODE_REG;
        sd_ba_sel      <= SD_BA_SEL_MODE_REG;
        timer_cmd_init <= to_signed(T_MRD-2, timer_cmd_init'length);

        if timer_cmd_done = '1' then
          -- Load mode register
          sd_cmd_nxt            <= SD_CMD_LOAD_MODE_REG;
          timer_cmd_start <= '1';

          -- Wait for 200 cycles, by waiting for T_REFI.
          -- This is juzst for reuse.
          timer_tREFI_start <= '1';
          fsm_ns            <= INIT7;
        end if;

      when INIT7 =>
        sd_a_sel       <= SD_A_SEL_COL_ADDR;
        precharge_all  <= '1';
        timer_cmd_init <= to_signed(T_RP-2, timer_cmd_init'length);

        if timer_cmd_done = '1' then
          -- Precharge all.
          sd_cmd_nxt      <= SD_CMD_PRECHARGE;
          timer_cmd_start <= '1';
          fsm_ns          <= INIT8;
        end if;

      when INIT8 =>
        timer_cmd_init <= to_signed(T_RFC-2, timer_cmd_init'length);

        if timer_cmd_done = '1' then
          -- First auto refresh.
          sd_cmd_nxt      <= SD_CMD_AUTO_REFRESH;
          timer_cmd_start <= '1';
          fsm_ns          <= INIT9;
        end if;

      when INIT9 =>
        timer_cmd_init <= to_signed(T_RFC-2, timer_cmd_init'length);

        if timer_cmd_done = '1' then
          -- Second auto refresh.
          sd_cmd_nxt      <= SD_CMD_AUTO_REFRESH;
          timer_cmd_start <= '1';
          fsm_ns          <= INIT10;
        end if;

      when INIT10 =>
        reset_dll      <= '0';
        sd_a_sel       <= SD_A_SEL_MODE_REG;
        sd_ba_sel      <= SD_BA_SEL_MODE_REG;
        timer_cmd_init <= to_signed(T_MRD-2, timer_cmd_init'length);

        if (timer_cmd_done = '1') and (timer_tREFI_done = '1') then
          -- Now, we have waited for at least 200 cycles.
          -- Load mode register, with "reset DLL" cleared.
          sd_cmd_nxt      <= SD_CMD_LOAD_MODE_REG;
          timer_cmd_start <= '1';
          fsm_ns          <= INIT11;
        end if;

      when INIT11 =>
        timer_cmd_init <= to_signed(T_RFC-2, timer_cmd_init'length);

        if timer_cmd_done = '1' then
          -- Schedule another auto refresh and restart T_REFI timer.
          sd_cmd_nxt        <= SD_CMD_AUTO_REFRESH;
          timer_cmd_start   <= '1';
          timer_tREFI_start <= '1';
          fsm_ns            <= DO_ACTIVATE;
        end if;


      when DO_ACTIVATE =>
        -- For activate row.
        sd_a_sel  <= SD_A_SEL_ROW_ADDR;
        sd_ba_sel <= SD_BA_SEL_ADDR;

        -- wait for finish of last command, before executing new one
        if timer_cmd_done = '1' then
          if user_cmd_valid = '1' then
            -- Activate Row
            sd_cmd_nxt      <= SD_CMD_ACTIVE;
            timer_cmd_init  <= to_signed(T_RCD-2, timer_cmd_init'length);
            timer_cmd_start <= '1';
            timer_tRAS_start<= '1';

            if user_write = '1' then
              fsm_ns <= DO_WRITE1;
            else
              fsm_ns <= DO_READ1;
            end if;

          elsif timer_tREFI_done = '1' then
            -- Auto Refresh
            sd_cmd_nxt        <= SD_CMD_AUTO_REFRESH;
            timer_cmd_init    <= to_signed(T_RFC-2, timer_cmd_init'length);
            timer_cmd_start   <= '1';
            timer_tREFI_start <= '1';
            --fsm_ns <= DO_ACTIVATE;
          end if;
        end if;

      when DO_READ1 =>
        -- wait for CL cycles.
        -- Substract 1 because CHECKNXT is entered before
        -- DO_PRECHARGE.
        timer_cmd_init  <= to_signed(CL-1 -2,
                                     timer_cmd_init'length);

        -- Additional burst cycles: BCC-1
        downcnt_init <= to_signed(BCC-1-2, downcnt_init'length);

        sd_a_sel  <= SD_A_SEL_COL_ADDR;
        sd_ba_sel <= SD_BA_SEL_ADDR;

        if timer_cmd_done = '1' then
          -- Read first
          sd_cmd_nxt      <= SD_CMD_READ;
          rden_nxt        <= '1';
          timer_cmd_start <= '1';
          downcnt_set     <= '1';
          user_got_cmd    <= '1';
          save_cmd_addr   <= '1';

          if (SDRAM_TYPE = 0 and BL = 1) or
             (SDRAM_TYPE > 0 and BL = 2) then
            fsm_ns <= CHECKNXT;
          else
            fsm_ns <= DO_READ2;
          end if;
        end if;

      when DO_READ2 =>
        if (SDRAM_TYPE = 0 and BL > 1) or
           (SDRAM_TYPE > 0 and BL > 2)
        then
          -- Read more
          downcnt_dec <= '1';
          rden_nxt    <= '1';

          if downcnt_done = '1' then
            fsm_ns <= CHECKNXT;
          end if;
        end if;

      when DO_WRITE1 =>
        -- wait for 1 + BCC + T_WR cycles
        -- Substract 1 because CHECKNXT is entered before
        -- DO_PRECHARGE.
        timer_cmd_init  <= to_signed(1+BCC+T_WR-1 -2,
                                     timer_cmd_init'length);

        -- Additional burst cycles: BCC-1
        downcnt_init <= to_signed(BCC-1-2, downcnt_init'length);

        sd_a_sel  <= SD_A_SEL_COL_ADDR;
        sd_ba_sel <= SD_BA_SEL_ADDR;

        if (timer_cmd_done and user_wdata_valid) = '1' then
          -- Write first
          sd_cmd_nxt      <= SD_CMD_WRITE;
          wren_nxt        <= '1';
          timer_cmd_start <= '1';
          downcnt_set     <= '1';
          user_got_cmd    <= '1';
          user_got_wdata  <= '1';
          save_cmd_addr   <= '1';

          if (SDRAM_TYPE = 0 and BL = 1) or
             (SDRAM_TYPE > 0 and BL = 2) then
            fsm_ns <= CHECKNXT;
          else
            fsm_ns <= DO_WRITE2;
          end if;
        end if;

      when DO_WRITE2 =>
        if (SDRAM_TYPE = 0 and BL > 1) or
           (SDRAM_TYPE > 0 and BL > 2) then
          -- Write more
          downcnt_dec    <= '1';
          wren_nxt       <= '1';
          user_got_wdata <= '1';

          if downcnt_done = '1' then
            fsm_ns <= CHECKNXT;
          end if;
        end if;

      when CHECKNXT =>
        if last_write_r = '1' then
          -- last was write
          if user_write = '1' then
            -- write-to-write to same bank and row
            -- Set timer to zero.
            timer_cmd_init <= to_signed(-2, timer_cmd_init'length);
          else
            -- write-to-read to same bank and row
            -- We must wait for 1+BCC+T_WTR cycles since start of write.
            -- We already waited for BCC due to execution of burst.
            timer_cmd_init <= to_signed(1+T_WTR -2, timer_cmd_init'length);
          end if;
        else
          -- last was read
          if user_write = '1' then
            -- read-to-write to same bank and row
            -- We must wait for BCC+CL cycles since start of read.
            -- We already waited for BCC due to execution of burst.
            timer_cmd_init <= to_signed(CL -2, timer_cmd_init'length);
          else
            -- read-to-read to same bank and row
            -- Set timer to zero.
            timer_cmd_init <= to_signed(-2, timer_cmd_init'length);
          end if;

        end if;

        if timer_tREFI_done = '1' then
          -- A refresh is pending.
          -- Wait here until timer_tRAS is done.
          if timer_tRAS_done = '1' then
            fsm_ns <= DO_PRECHARGE;
          end if;

        elsif (user_cmd_valid and same_bank_row) = '1' then
          -- Access to same bank and row.
          -- Wait timer is initiated above.
          timer_cmd_start <= '1';
          if user_write = '1' then
            fsm_ns <= DO_WRITE1;
          else
            fsm_ns <= DO_READ1;
          end if;

        elsif timer_cmd_done = '1' then
          -- Execute a precharge now for minimum latency of next access to
          -- another bank/row.
          -- Wait here until timer_tRAS is done.
          if timer_tRAS_done = '1' then
            fsm_ns <= DO_PRECHARGE;
          end if;

        --else: check again
        end if;

      when DO_PRECHARGE =>
        timer_cmd_init  <= to_signed(T_RP-2, timer_cmd_init'length);

        if timer_cmd_done = '1' then
          -- Precharge
          -- NOTE: It is sufficient to precharge the bank in use.
          -- But, because the address isn't saved, the bank is unknown.
          -- Thus, precharge ALL.
          sd_cmd_nxt      <= SD_CMD_PRECHARGE;
          precharge_all   <= '1';
          timer_cmd_start <= '1';
          if timer_tREFI_done = '1' then
            fsm_ns <= DO_AUTO_REFRESH;
          else
            fsm_ns <= DO_ACTIVATE;
          end if;
        end if;

      when DO_AUTO_REFRESH =>
        timer_cmd_init  <= to_signed(T_RFC-2, timer_cmd_init'length);

        if timer_cmd_done = '1' then
          -- Auto refresh
          sd_cmd_nxt        <= SD_CMD_AUTO_REFRESH;
          timer_cmd_start   <= '1';
          timer_tREFI_start <= '1';
          fsm_ns            <= DO_ACTIVATE;
        end if;

    end case;
  end process;

  -----------------------------------------------------------------------------
  -- Datapath depending on FSM output
  --
  -- Command and address are registered again in the physical layer.
  -----------------------------------------------------------------------------

  sd_cs_nxt  <= sd_cmd_nxt(3);
  sd_ras_nxt <= sd_cmd_nxt(2);
  sd_cas_nxt <= sd_cmd_nxt(1);
  sd_we_nxt  <= sd_cmd_nxt(0);

  process (sd_a_sel, reset_dll, row_addr, col_addr, precharge_all)
  begin  -- process
    sd_a_nxt <= (others => '0');

    case sd_a_sel is
      when SD_A_SEL_EXT_MODE_REG =>
        sd_a_nxt(EXT_MODE_REG'range) <= EXT_MODE_REG;

      when SD_A_SEL_MODE_REG =>
        sd_a_nxt(MODE_REG'range) <= MODE_REG;
        sd_a_nxt(MODE_REG'left)  <= reset_dll;

      when SD_A_SEL_ROW_ADDR =>
        sd_a_nxt(R_BITS-1 downto 0) <= row_addr;

      when SD_A_SEL_COL_ADDR =>
        sd_a_nxt  (imin(10, C_BITS)-1 downto 0)
                                     <= col_addr(imin(10, C_BITS)-1 downto 0);
        sd_a_nxt(10) <= precharge_all;
        if C_BITS > 10 then
          sd_a_nxt(C_BITS downto 11) <= col_addr(C_BITS-1 downto 10);
        end if;
    end case;
  end process;

  with sd_ba_sel select
    sd_ba_nxt <=
    "01"      when SD_BA_SEL_EXT_MODE_REG,
    "00"      when SD_BA_SEL_MODE_REG,
    bank_addr when others;              -- SD_BA_SEL_ADDR

  -----------------------------------------------------------------------------
  -- Registers
  -----------------------------------------------------------------------------

  process (clk)
  begin  -- process
    if rising_edge(clk) then
      if rst = '1' then
        fsm_cs <= INIT1;
      else
        fsm_cs <= fsm_ns;
      end if;

      if timer_tREFI_start = '1' then
        timer_tREFI <= TIMER_TREFI_INIT;
      elsif timer_tREFI_done = '0' then
        -- auto decrement
        timer_tREFI <= timer_tREFI - 1;
      end if;

      if timer_cmd_start = '1' then
        timer_cmd <= timer_cmd_init;
      elsif timer_cmd_done = '0' then
        -- auto decrement
        timer_cmd <= timer_cmd - 1;
      end if;

      if timer_tRAS_start = '1' then
        timer_tRAS <= TIMER_TRAS_INIT;
      elsif timer_tRAS_done = '0' then
        -- auto decrement
        timer_tRAS <= timer_tRAS - 1;
      end if;

      if downcnt_set = '1' then
        downcnt <= downcnt_init;
      elsif downcnt_dec = '1' then
        downcnt <= downcnt - 1;
      end if;

      if save_cmd_addr = '1' then
        last_write_r     <= last_write_nxt;
        last_bank_addr_r <= last_bank_addr_nxt;
        last_row_addr_r  <= last_row_addr_nxt;
      end if;
    end if;
  end process;
end rtl;
