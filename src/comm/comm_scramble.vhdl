-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:					Computes XOR masks for stream scrambling from an LFSR generator.
--
-- Description:
-- -------------------------------------
-- The LFSR computation is unrolled to generate an arbitrary number of mask
-- bits in parallel. The mask are output in little endian. The generated bit
-- sequence is independent from the chosen output width.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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


entity comm_scramble is
  generic (
    GEN  : bit_vector;       -- Generator Polynomial (little endian)
    BITS : positive          -- Width of Mask Bits to be computed in parallel in each step
  );
  port (
    clk  : in  std_logic;    -- Clock

    set  : in  std_logic;    -- Set LFSR to value provided on din
    din  : in  std_logic_vector(GEN'length-2 downto 0) := (others => '0');

    step : in  std_logic;    -- Compute a Mask Output
    mask : out std_logic_vector(BITS-1 downto 0)
  );
end entity comm_scramble;


architecture rtl of comm_scramble is

  -----------------------------------------------------------------------------
  -- Normalizes a generator representation:
  --   - into a 'downto 0' index range and
  --   - truncating it just below the most significant and so hidden '1'.
  function normalize(G : bit_vector) return bit_vector is
    variable GN : bit_vector(G'length-1 downto 0);
  begin
    GN := G;
    for i in GN'left downto 1 loop
      if GN(i) = '1' then
        return  GN(i-1 downto 0);
      end if;
    end loop;
    report "Cannot use absolute constant as generator."
      severity failure;
  end normalize;

  -- Normalized Generator
  constant GN : bit_vector := normalize(GEN);

  -- LFSR Value
  signal lfsr : std_logic_vector(GN'range);

begin
  process(clk)
    -- Intermediate LFSR Values for single-bit Steps
    variable v : std_logic_vector(lfsr'range);
  begin
    if rising_edge(clk) then
      if set = '1' then
        lfsr <= din(lfsr'range);
      elsif step = '1' then
        v := lfsr;
        for i in 0 to BITS-1 loop
          mask(i) <=  v(v'left);
          v := (v(v'left-1 downto 0) & '0') xor
               (to_stdlogicvector(GN) and (GN'range => v(v'left)));
        end loop;
        lfsr <= v;
      end if;
    end if;
  end process;

end architecture;
