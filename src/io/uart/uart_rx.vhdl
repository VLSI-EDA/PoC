-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:        Thomas B. Preusser
--
-- Entity:				 Universal Asynchronous Receiver Transmitter (UART) - Receiver
--
-- Description:
-- -------------------------------------
-- :abbr:`UART (Universal Asynchronous Receiver Transmitter)` Receiver:
-- 1 Start + 8 Data + 1 Stop
--
-- License:
-- =============================================================================
-- Copyright 2008-2016 Technische Universitaet Dresden - Germany
--                     Chair of VLSI-Design, Diagnostics and Architecture
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
-- =============================================================================

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library	PoC;


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
end entity;


architecture rtl of uart_rx is
  -- RX Synchronization
  signal rxs : std_logic;

  --                Buf        Cnt  Vld
  --   Idle     "---------0"    X    0
  --   Start    "0111111111"  5->16  0   -- 1.5 bit length after start of start bit
  --   Recv     "dcba011111"  9->16  0   -- shifting left to right (LSB first)
  --   Done     "1hgfedcba0"    X    1   -- Output strobe

	-- Data buffer
  signal Buf : std_logic_vector(9 downto 0) := (0      => '0', others => '-');
	-- Bit clock counter: 8 ticks per bit
  signal Cnt : unsigned(4 downto 0)         := (others => '-');
	-- Output strobe
  signal Vld : std_logic                    := '0';

begin
  -- Input synchronization
	sync :  entity PoC.sync_Bits
		generic map (
			INIT					=> (SYNC_DEPTH - 1 downto 0 => '1'),	-- initialitation bits
			SYNC_DEPTH		=> SYNC_DEPTH													-- generate SYNC_DEPTH many stages, at least 2
		)
		port map (
			Clock					=> clk,		-- <Clock>	output clock domain
			Input(0)			=> rx,		-- @async:	input bits
			Output(0)			=> rxs		-- @Clock:	output bits
		);

  -- Reception state
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
					if rxs = '0' then
						-- Start bit -> receive byte
						Buf <= (Buf'left => '0', others => '1');
						Cnt <= to_unsigned(5, Cnt'length);
					else
						Buf <= (0 => '0', others => '-');
						Cnt <= (others => '-');
					end if;
				elsif bclk_x8 = '1' then
					if Cnt(Cnt'left) = '1' then
						Buf <= rxs & Buf(Buf'left downto 1);
						Vld <= rxs and not Buf(1);
					end if;
					Cnt <= Cnt + (Cnt(4) & Cnt(4) & "001");
				end if;
      end if;
    end if;
  end process;

  -- Outputs
  do  <= Buf(8 downto 1);
  stb <= Vld;

end architecture;
