-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:     Peter Reichel
--              Jan Schirok
--              Steffen Koehler
--
-- Entity:      UART controller for FTDI FT245M UART-over-USB converter.
--
-- Description:
-- ------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2008-2015 Technische Universitaet Dresden - Germany
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


library IEEE;
use IEEE.std_logic_1164.all;

entity uart_ft245 is
   generic (
      CLK_FREQ : positive
   );
   port (
      -- common signals
      clk : in std_logic;
      rst : in std_logic;

      -- send data
      snd_ready  : out std_logic;
      snd_strobe : in  std_logic;
      snd_data   : in  std_logic_vector(7 downto 0);

      -- receive data
      rec_strobe : out std_logic;
      rec_data   : out std_logic_vector(7 downto 0);

      -- connection to ft245
      ft245_data   : inout std_logic_vector(7 downto 0);
      ft245_rdn    : out   std_logic;
      ft245_wrn    : out   std_logic;
      ft245_rxfn   : in    std_logic;
      ft245_txen   : in    std_logic;
      ft245_pwrenn : in    std_logic
   );
end entity;


library IEEE;
use IEEE.numeric_std.all;

library PoC;
use PoC.utils.all;

architecture rtl of uart_ft245 is

   -- clock frequency (MHz)
   constant CLK_FREQ_MHZ : integer := CLK_FREQ / 1000000;

   -- FT245 communication delay cycles (minimum delay is 50 ns = 1/20 us)
   constant DELAY_CYCLES : integer := CLK_FREQ_MHZ / 20;

   -- delay register width
   constant DELAY_WIDTH : integer := log2ceilnz(DELAY_CYCLES + 1);

   -- delay register load value
   constant DELAY_LOAD : unsigned(DELAY_WIDTH-1 downto 0) :=
      to_unsigned(DELAY_CYCLES, DELAY_WIDTH);

   -- delay register
   signal reg_delay    : unsigned(DELAY_WIDTH-1 downto 0);

   -- FSM
   type tState is ( IDLE, RD1, RD2, RD3, RD4, WR1, WR2, WR3, WR4 );
   signal fsm_state : tState := IDLE;
   signal fsm_nextstate : tState;

   -- registers
   signal reg_data_snd  : std_logic_vector(7 downto 0);
   signal reg_data_rec  : std_logic_vector(7 downto 0);
   signal reg_ld_rec    : std_logic;
   signal reg_dto_b     : std_logic := '1';    -- low-active
   signal reg_wr_b      : std_logic := '1';    -- low-active
   signal reg_rd_b      : std_logic := '1';    -- low-active

   signal ff_susp       : std_logic := '1';    -- low-active
   signal ff_rxf        : std_logic := '1';    -- low-active
   signal ff_txe        : std_logic := '1';    -- low-active

   -- control signals
   signal ctrl_ld_rec   : std_logic;
   signal ctrl_delay    : std_logic;
   signal ctrl_rd       : std_logic;
   signal ctrl_wr       : std_logic;
   signal ctrl_dto      : std_logic;

   signal data_in       : std_logic_vector(7 downto 0);

begin
   ----------------------------------------------
   -- Synchronize Inputs
   process(clk)
   begin
      if rising_edge(clk) then
        if rst = '1' then
          -- Neutral PowerUp / Reset
          ff_susp <= '1';
          ff_rxf  <= '1';
          ff_txe  <= '1';
        else
          -- Wait for Initilization to Complete
          ff_susp <= ft245_pwrenn;

          -- Now forward Fill Signals
          ff_rxf  <= ft245_rxfn;
          ff_txe  <= ft245_txen;
        end if;
      end if;
   end process;

   process(fsm_state, snd_strobe, reg_delay, ff_susp, ff_rxf, ff_txe)
   begin
      fsm_nextstate <= fsm_state;
      ctrl_ld_rec <= '0';
      ctrl_rd <= '0';
      ctrl_wr <= '0';
      ctrl_dto <= '0';
      ctrl_delay <= '0';

      case fsm_state is
         when IDLE =>
            if ff_susp = '0' then
               if ff_rxf = '0' then
                  -- receive data
                  fsm_nextstate <= RD1;
               elsif ff_txe = '0' and snd_strobe = '1' then
                  -- ok, send...
                  fsm_nextstate <= WR1;
               end if;
            end if;
         when RD1 =>
            -- load delay counter
            ctrl_rd <= '1';
            ctrl_delay <= '1';
            fsm_nextstate <= RD2;
         when RD2 =>
            -- wait until delay counter has expired
            ctrl_rd <= '1';
            if reg_delay = 0 then
               fsm_nextstate <= RD3;
            end if;
         when RD3 =>
            -- data is valid now => load
            ctrl_rd <= '1';
            ctrl_ld_rec <= '1';
            -- load delay counter again
            ctrl_delay <= '1';
            fsm_nextstate <= RD4;
         when RD4 =>
            -- wait until delay counter has expired
            if reg_delay = 0 then
               fsm_nextstate <= IDLE;
            end if;

         when WR1 =>
            -- load delay counter
            ctrl_dto <= '1';
            ctrl_delay <= '1';
            fsm_nextstate <= WR2;
         when WR2 =>
            -- set wr (active pulse)
            ctrl_dto <= '1';
            ctrl_wr <= '1';
            -- wait until delay counter has expired
            if reg_delay = 0 then
               fsm_nextstate <= WR3;
            end if;
         when WR3 =>
            -- clear wr (pre-charge time)
            ctrl_dto <= '1';
            -- load delay counter again
            ctrl_delay <= '1';
            fsm_nextstate <= WR4;
         when WR4 =>
            -- wait until delay counter has expired
            if reg_delay = 0 then
               fsm_nextstate <= IDLE;
            end if;
      end case;
   end process;

   ----------------------------------------------
   -- registers
   process(clk)
   begin
      if rising_edge(clk) then

         -- control signals
         if rst = '1' then
            fsm_state   <= IDLE;
            reg_rd_b    <= '1';
            reg_wr_b    <= '1';
            reg_dto_b   <= '1';
            reg_ld_rec  <= '0';
         else
            fsm_state   <= fsm_nextstate;
            reg_rd_b    <= not ctrl_rd;
            reg_wr_b    <= not ctrl_wr;
            reg_dto_b   <= not ctrl_dto;
            reg_ld_rec  <= ctrl_ld_rec;
         end if;

         -- delay counter
         if ctrl_delay = '1' then
            reg_delay <= DELAY_LOAD;
         else
            reg_delay <= reg_delay - 1;
         end if;

         -- received data
         if ctrl_ld_rec = '1' then
            reg_data_rec <= data_in;
         end if;

         -- data to send
         if snd_strobe = '1' then
            reg_data_snd <= snd_data;
         end if;

      end if;
   end process;

   ----------------------------------------------
   -- tristate driver and output assignments
   ft245_data <= reg_data_snd when reg_dto_b = '0' else (others => 'Z');
   data_in <= ft245_data;

   ft245_rdn <= reg_rd_b;
   ft245_wrn <= reg_wr_b;

   rec_data   <= reg_data_rec;
   rec_strobe <= reg_ld_rec;
   snd_ready  <= ff_rxf and not ff_txe and not ff_susp
      when fsm_state = IDLE else '0';

end rtl;
