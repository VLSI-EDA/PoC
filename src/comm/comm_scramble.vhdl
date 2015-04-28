--
-- Copyright (c) 2011
-- Technische Universitaet Dresden, Dresden, Germany
-- Faculty of Computer Science
-- Institute for Computer Engineering
-- Chair for VLSI-Design, Diagnostics and Architecture
-- 
-- For internal educational use only.
-- The distribution of source code or generated files
-- is prohibited.
--

--
-- Entity: scramble
-- Author(s): Thomas B. Preusser <thomas.preusser@tu-dresden.de>
-- 
-- Computes XOR masks for stream scrambling from an LFSR generator.
-- May be used for SATA scrambling with the polynomial 0x1A011.
--
-- The LFSR computation is unrolled to generate an arbitrary number
-- of mask bits in parallel. The mask are output in little endian.
-- The generated bit sequence is independent from the chosen output
-- width.
--
--
-- Revision:    $Revision: 1.1 $
-- Last change: $Date: 2011-02-24 09:04:46 $
--

library IEEE;
use IEEE.std_logic_1164.all;

entity comm_scramble is
  generic (
    GEN  : bit_vector;       -- Generator Polynomial (little endian)
    BITS : positive          -- Width of Mask Bits to be computed in parallel
  );
  port (
    clk  : in  std_logic;    -- Clock

    set  : in  std_logic;    -- Set LFSR to provided Value
    din  : in  std_logic_vector(GEN'length-2 downto 0);

    step : in  std_logic;    -- Compute a Mask Output
    mask : out std_logic_vector(BITS-1 downto 0)
  );
end comm_scramble;

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

end rtl;
