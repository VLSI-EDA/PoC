-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Module:				 	Enhanced simple dual-port memory.
--
-- Authors:				 	Martin Zabel
-- 
-- Description:
-- ------------------------------------
-- Inferring / instantiating enhanced simple dual-port memory, with:
--
-- * dual clock, clock enable,
-- * 1 read/write port (1st port) plus 1 read port (2nd port).
--
-- The generalized behavior across Altera and Xilinx FPGAs since
-- Stratix/Cyclone and Spartan-3/Virtex-5, respectively, is as follows:
--
-- * Same-Port Read-During Write:
--   At rising edge of "clk1", data "d1" written to port 1 (ce1 and we1 = '1')
--   is directly passed to the output "q1". This is also known as write-first
--   mode or read-through write behavior.
--
-- * Mixed-Port Read-During Write:
--   Here, the Altera M512/M4K TriMatrix memory (as found e.g. in Stratix
--   and Stratix II FPGAs) defines the minimum time after which the written data
--   at port 1 can be read-out at port 2 again. As stated in the Stratix
--   Handbook, Volume 2, page 2-13, data is actually written with the falling
--   (instead of the rising) edge of the clock into the memory array. The write
--   itself takes the write-cycle time which is less or equal to the minimum
--   clock-period time. After this, the data can be read-out at the other port.
--   Consequently, data "d1" written at the rising-edge of "clk1" at address
--   "a1" can be read-out at the 2nd port from the same address with the
--   2nd rising-edge of "clk2" following the falling-edge of "clk1".
--   If the rising-edge of "clk2" coincides with the falling-edge of "clk1"
--   (e.g. same clock signal), then it is counted as the 1st rising-edge of
--   "clk2" in this timing.
--
-- WARNING: The simulated behavior on RT-level is not correct.
--
-- TODO: add timing diagram
-- TODO: implement correct behavior for RT-level simulation
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

entity ocram_esdp is
  
  generic (
    A_BITS : positive;-- := 10;
    D_BITS : positive--  := 32
  );

  port (
    clk1 : in  std_logic;
    clk2 : in  std_logic;
    ce1  : in  std_logic;
    ce2  : in  std_logic;
    we1  : in  std_logic;
    a1   : in  unsigned(A_BITS-1 downto 0);
    a2   : in  unsigned(A_BITS-1 downto 0);
    d1   : in  std_logic_vector(D_BITS-1 downto 0);
    q1   : out std_logic_vector(D_BITS-1 downto 0);
    q2   : out std_logic_vector(D_BITS-1 downto 0)
  );

end ocram_esdp;

architecture rtl of ocram_esdp is

  component ocram_esdp_altera
    generic (
      A_BITS : positive;
      D_BITS : positive);
    port (
      clk1 : in  std_logic;
      clk2 : in  std_logic;
      ce1  : in  std_logic;
      ce2  : in  std_logic;
      we1  : in  std_logic;
      a1   : in  unsigned(A_BITS-1 downto 0);
      a2   : in  unsigned(A_BITS-1 downto 0);
      d1   : in  std_logic_vector(D_BITS-1 downto 0);
      q1   : out std_logic_vector(D_BITS-1 downto 0);
      q2   : out std_logic_vector(D_BITS-1 downto 0));
  end component;
  
  constant DEPTH : positive := 2**A_BITS;
  
begin  -- rtl

  gInfer: if VENDOR = VENDOR_XILINX generate
    -- RAM can be infered correctly
    -- XST Advanced HDL Synthesis generates extended simple dual-port
    -- memory as expected.
    type ram_t is array(0 to DEPTH-1) of std_logic_vector(D_BITS-1 downto 0);
    signal ram : ram_t;

    signal a1_reg : unsigned(A_BITS-1 downto 0);
    signal a2_reg : unsigned(A_BITS-1 downto 0);
  
  begin
    process (clk1)
    begin
      if rising_edge(clk1) then
        if ce1 = '1' then
          if we1 = '1' then
            ram(to_integer(a1)) <= d1;
          end if;

          a1_reg <= a1;
        end if;
      end if;
    end process;

    q1 <= ram(to_integer(a1_reg));        -- gets new data

    process (clk2)
    begin  -- process
      if rising_edge(clk2) then
        if ce2 = '1' then
          a2_reg <= a2;
        end if;
      end if;
    end process;
    
    -- read data is unknown, when reading at write address
    q2 <= ram(to_integer(a2_reg));
    
  end generate gInfer;

  gAltera: if VENDOR = VENDOR_ALTERA generate
    -- Direct instantiation of altsyncram (including component
    -- declaration above) is not sufficient for ModelSim.
    -- That requires also usage of altera_mf library.
    i: ocram_esdp_altera
      generic map (
        A_BITS => A_BITS,
        D_BITS => D_BITS)
      port map (
        clk1 => clk1,
        clk2 => clk2,
        ce1  => ce1,
        ce2  => ce2,
        we1  => we1,
        a1   => a1,
        a2   => a2,
        d1   => d1,
        q1   => q1,
        q2   => q2);
    
  end generate gAltera;
  
  assert VENDOR = VENDOR_XILINX or VENDOR = VENDOR_ALTERA
    report "Device not yet supported."
    severity failure;
end rtl;
