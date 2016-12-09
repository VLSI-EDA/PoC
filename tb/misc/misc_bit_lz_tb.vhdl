-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ===========================================================================
-- Testbench:   Basic testbench for LZ-based bitstream compressor misc_bit_lz.
--
-- Authors:     Thomas B. Preusser
--
-- Description:
-- ------------
--              Basic testbench for PoC.misc_bit_lz.
--
-- License:
-- ===========================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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

entity misc_bit_lz_tb is
end entity;


use std.textio.all;

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

architecture tb of misc_bit_lz_tb is
  constant COUNT_BITS  : positive := 7;
  constant OFFSET_BITS : positive := 8;

  constant DATA : std_logic_vector := x"72B6C9B5_25D92DCA_DB26DFFF";

  component misc_bit_lz is
    generic(
      COUNT_BITS  : positive;
      OFFSET_BITS : positive
    );
    port(
      -- Global Control
      clk : in std_logic;
      rst : in std_logic;

      -- Data Input
      din   : in std_logic;
      put   : in std_logic;
      flush : in std_logic;

      -- Data Output
      odat : out std_logic_vector(COUNT_BITS+OFFSET_BITS downto 0);
      ostb : out std_logic
    );
  end component;

  signal clk : std_logic;
  signal rst : std_logic;

  signal din : std_logic;
  signal put : std_logic;
  signal flush : std_logic;

  signal odat : std_logic_vector(COUNT_BITS+OFFSET_BITS downto 0);
  signal ostb : std_logic;

begin

  DUT: misc_bit_lz
    generic map (
      COUNT_BITS  => COUNT_BITS,
      OFFSET_BITS => OFFSET_BITS
    )
    port map (
      clk   => clk,
      rst   => rst,
      din   => din,
      put   => put,
      flush => flush,
      odat  => odat,
      ostb  => ostb
    );

  -- Stimuli
  process
    procedure cycle is
    begin
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
    end procedure cycle;
  begin
    rst   <= '1';
    cycle;
    rst   <= '0';
    put   <= '0';
    flush <= '0';
    cycle;

    put <= '1';
    for i in DATA'range loop
      din <= DATA(i);
      cycle;
    end loop;

    put   <= '0';
    flush <= '1';
    cycle;

    flush <= '0';
    cycle;
    cycle;

    wait;  -- forever
  end process;

  -- Output Parsing
  process
    variable l : line;
  begin
    wait until rising_edge(clk);
    assert rst = '1' or not Is_X(ostb)
      report "Unknown ostb output."
      severity error;

    if ostb = '1' then
      if odat(odat'left) = '1' then
        -- Literal
        write(l, string'("L: "));
        for i in odat'left-1 downto 0 loop
          write(l, to_bit(odat(i)));
        end loop;
      elsif odat(odat'left-1 downto OFFSET_BITS) /= (1 to COUNT_BITS => '1') then
        -- Repetition
        write(l, string'("R: "));
        write(l, to_integer(unsigned(odat(odat'left-1 downto OFFSET_BITS)))+COUNT_BITS+OFFSET_BITS);
        write(l, string'(" @"));
        write(l, to_integer(unsigned(odat(OFFSET_BITS-1 downto 0))));
      else
        -- End Marker
        write(l, string'("E: "));
        if odat(OFFSET_BITS-1) = '0' then
          write(l, std_logic'image(odat(0)));
        else
	  write(l, '<');
          write(l, to_integer(unsigned(not odat(OFFSET_BITS-1 downto 0))));
        end if;
      end if;
      writeline(output, l);
    end if;
  end process;

end architecture tb;
