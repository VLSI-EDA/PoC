-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ===========================================================================
-- Module:
--
-- Authors:        Thomas B. Preusser
--
-- Description:    UART (RS232) Transmitter: 1 Start + 8 Data + 1 Stop
-- ------------
--
-- License:
-- ===========================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
--                     Chair for VLSI-Design, Diagnostics and Architecture
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--              http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- ===========================================================================

library	IEEE;
use IEEE.std_logic_1164.all;

entity uart_tx is
  port (
    -- Global Control
    clk : in std_logic;
    rst : in std_logic;

    -- Bit Clock and TX Line
    bclk : in  std_logic;  -- bit clock, one strobe each bit length
    tx   : out std_logic;

    -- Byte Stream Input
    di  : in  std_logic_vector(7 downto 0);
    put : in  std_logic;
    ful : out std_logic
  );
end entity;


library IEEE;
use IEEE.numeric_std.all;

architecture rtl of uart_tx is

  --                Buf           Cnt
  --   Idle     "---------1"    "0----"
  --   Start    "hgfedcba01"     -10
  --   Send     "1111hgfedc"   -10 -> -1
  --   Done     "1111111111"       0

  signal Buf : std_logic_vector(9 downto 0) := (0 => '1', others => '-');
  signal Cnt : signed(4 downto 0)           := "0----";

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        Buf <= (0 => '1', others => '-');
        Cnt <= "0----";
      else
        if Cnt(Cnt'left) = '0' then
          -- Idle
          if put = '1' then
						-- Start Transmission
            Buf <= di & "01";
            Cnt <= to_signed(-10, Cnt'length);
          else
            Buf <= (0 => '1', others => '-');
            Cnt <= "0----";
          end if;
        else
          -- Transmitting
          if bclk = '1' then
            Buf <= '1' & Buf(Buf'left downto 1);
            Cnt <= Cnt + 1;
          end if;
        end if;
      end if;
    end if;
  end process;
	tx  <= Buf(0);
	ful <= Cnt(Cnt'left);
end;
