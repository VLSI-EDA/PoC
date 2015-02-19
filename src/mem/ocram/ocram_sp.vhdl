-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Module:				 	Single-port memory.
--
-- Authors:				 	Martin Zabel
-- 
-- Description:
-- ------------------------------------
-- Inferring / instantiating single-port RAM
--
-- - single clock, clock enable
-- - 1 read/write port
-- 
-- Written data is passed through the memory and output again as read-data 'q'.
-- This is the normal behaviour of a single-port RAM and also known as
-- write-first mode or read-through-write behaviour.
-- 
-- License:
-- ============================================================================
-- Copyright 2008-2015 Technische Universitaet Dresden - Germany
--										 Chair for VLSI-Design, Diagnostics and Architecture
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
-- ============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library poc;
use poc.config.all;

entity ocram_sp is
  
  generic (
    A_BITS : positive;-- := 10;
    D_BITS : positive--  := 32
  );

  port (
    clk : in  std_logic;
    ce  : in  std_logic;
    we  : in  std_logic;
    a   : in  unsigned(A_BITS-1 downto 0);
    d   : in  std_logic_vector(D_BITS-1 downto 0);
    q   : out std_logic_vector(D_BITS-1 downto 0)
  );

end ocram_sp;

architecture rtl of ocram_sp is
  
  component ocram_sp_altera
    generic (
      A_BITS : positive;
      D_BITS : positive);
    port (
      clk : in  std_logic;
      ce  : in  std_logic;
      we  : in  std_logic;
      a   : in  unsigned(A_BITS-1 downto 0);
      d   : in  std_logic_vector(D_BITS-1 downto 0);
      q   : out std_logic_vector(D_BITS-1 downto 0));
  end component;

  constant DEPTH : positive := 2**A_BITS;

begin  -- rtl

  gInfer: if VENDOR = VENDOR_XILINX generate
    -- RAM can be infered correctly
    -- XST Advanced HDL Synthesis generates single-port memory as expected.
    type ram_t is array(0 to DEPTH-1) of std_logic_vector(D_BITS-1 downto 0);
    signal ram : ram_t;

    signal a_reg : unsigned(A_BITS-1 downto 0);
  
  begin
    process (clk)
    begin
      if rising_edge(clk) then
        if ce = '1' then
          if we = '1' then
            ram(to_integer(a)) <= d;
          end if;

          a_reg <= a;
        end if;
      end if;
    end process;

    q <= ram(to_integer(a_reg));          -- gets new data
  end generate gInfer;

  gAltera: if VENDOR = VENDOR_ALTERA generate
    -- Direct instantiation of altsyncram (including component
    -- declaration above) is not sufficient for ModelSim.
    -- That requires also usage of altera_mf library.
    i: ocram_sp_altera
      generic map (
        A_BITS => A_BITS,
        D_BITS => D_BITS)
      port map (
        clk => clk,
        ce  => ce,
        we  => we,
        a   => a,
        d   => d,
        q   => q);
    
  end generate gAltera;
  
  assert VENDOR = VENDOR_XILINX or VENDOR = VENDOR_ALTERA
    report "Device not yet supported."
    severity failure;
end rtl;
