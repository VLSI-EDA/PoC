-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ===========================================================================
--
-- Authors:        Thomas B. Preusser
--
-- Module:				 uart_rx
--
-- Description:    UART (RS232) Receiver: 1 Start + 8 Data + 1 Stop
-- ------------
--
-- License:
-- ===========================================================================
-- Copyright 2008-2015 Technische Universitaet Dresden - Germany
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

library IEEE;
use IEEE.std_logic_1164.all;

entity uart_rx is
  generic (
    SYNC_DEPTH : natural := 2  -- use zero for already clock-synchronous rx
	);
  port (
    -- Global Control
    clk : in std_logic;
    rst : in std_logic;

    -- Bit Clock and RX Line
    bclk_x8 : in std_logic;  	-- bit clock, eight strobes per bit length
    rx      : in std_logic;

    -- Byte Stream Output
    do  : out std_logic_vector(7 downto 0);
    stb : out std_logic
  );
end uart_rx;


library IEEE;
use IEEE.numeric_std.all;

architecture rtl of uart_rx is

  -- RX Synchronization
  signal rxs : std_logic_vector(0 to SYNC_DEPTH) := (0 => 'Z', others => '1');

  --                Buf        Cnt  Vld
  --   Idle     "---------0"    X    0
  --   Start    "0111111111"  5->16  0   -- 1.5 bit length after start of start bit
  --   Recv     "dcba011111"  9->16  0   -- shifting left to right (LSB first)
  --   Done     "1hgfedcba0"    X    1   -- Output Strobe

	-- Data Buffer
  signal Buf : std_logic_vector(9 downto 0) := (0      => '0', others => '-');
	-- Bit Clock Counter: 8 ticks per bit
  signal Cnt : unsigned(4 downto 0)         := (others => '-');
	-- Output Strobe
  signal Vld : std_logic                    := '0';

begin

  -- RX Synchronization, Synchronized Signal on rxs(SYNC_DEPTH)
	rxs(0) <= rx;
	genSyncFF: if SYNC_DEPTH > 0 generate
		process(clk)
		begin
			if rising_edge(clk) then
				if rst = '1' then
					rxs(1 to SYNC_DEPTH) <= (others => '1');
				else
					rxs(1 to SYNC_DEPTH) <= rxs(0 to SYNC_DEPTH-1);
				end if;
			end if;
		end process;
	end generate genSyncFF;

  -- Reception State
  process(clk)
  begin
    if rising_edge(clk) then
			Vld <= '0';
      if rst = '1' then
        Buf <= (0      => '0', others => '-');
        Cnt <= (others => '-');
      else
				if Buf(0) = '0' then
					-- Idle
					if rxs(SYNC_DEPTH) = '0' then
						-- Start Bit -> Receive Byte
						Buf <= (Buf'left => '0', others => '1');
						Cnt <= to_unsigned(5, Cnt'length);
					else
						Buf <= (0 => '0', others => '-');
						Cnt <= (others => '-');
					end if;
				elsif bclk_x8 = '1' then
					if Cnt(Cnt'left) = '1' then
						Buf <= rxs(SYNC_DEPTH) & Buf(Buf'left downto 1);
						Vld <= rxs(SYNC_DEPTH) and not Buf(1);
					end if;
					Cnt <= Cnt + (Cnt(4) & Cnt(4) & "001");
				end if;
      end if;
    end if;
  end process;

  -- Outputs
  do  <= Buf(8 downto 1);
  stb <= Vld;

end rtl;
