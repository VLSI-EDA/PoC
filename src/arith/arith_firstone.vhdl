-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:					TODO
--
-- Description:
-- -------------------------------------
-- Computes from an input word, a word of the same size that has, at most,
-- one bit set. The output contains a set bit at the position of the rightmost
-- set bit of the input if and only if such a set bit exists in the input.
--
-- A typical use case for this computation would be an arbitration over
-- requests with a fixed and strictly ordered priority. The terminology of
-- the interface assumes this use case and provides some useful extras:
--
-- * Set tin <= '0' (no input token) to disallow grants altogether.
-- * Read tout (unused token) to see whether or any grant was issued.
-- * Read bin to obtain the binary index of the rightmost detected one bit.
--   The index starts at zero (0) in the rightmost bit position.
--
-- This implementation uses carry chains for wider implementations.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universität Dresden - Germany
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

library IEEE;
use IEEE.std_logic_1164.all;

library PoC;
use PoC.utils.all;

entity arith_firstone is
  generic (
    N : positive                                -- Length of Token Chain
  );
  port (
    tin  : in  std_logic := '1';                -- Enable:   Fed Token
    rqst : in  std_logic_vector(N-1 downto 0);  -- Request:  Token Requests
    grnt : out std_logic_vector(N-1 downto 0);  -- Grant:    Token Output
    tout : out std_logic;                       -- Inactive: Unused Token
    bin  : out std_logic_vector(log2ceil(N)-1 downto 0)  -- Binary Grant Index
  );
end entity arith_firstone;


library IEEE;
use IEEE.numeric_std.all;

library PoC;
use PoC.config.all;

architecture rtl of arith_firstone is
begin
  -- Generic Carry Chain through Addition
  genGeneric: if VENDOR /= VENDOR_XILINX or N < 6 generate
    process(rqst, tin)
      variable onehot : std_logic_vector(grnt'range);
      variable binary : unsigned(bin'range);
			variable adder : unsigned(N downto 0);
    begin
			adder  := ("0" & unsigned(not rqst)) + (1 to 1 => tin);
      onehot := std_logic_vector(adder(N-1 downto 0)) and rqst;
      binary := (others => '0');
      for i in onehot'range loop
        if onehot(i) = '1' then
          binary := binary or to_unsigned(i, binary'length);
        end if;
      end loop;
			tout <= adder(N);
      grnt <= onehot;
      bin  <= std_logic_vector(binary);
    end process;
  end generate genGeneric;

  -- Optimized Xilinx Carry Chain by MUXCY Instantiation
  genXilinx: if VENDOR = VENDOR_XILINX and N >= 6 generate
    component MUXCY
      port (
        S  : in  std_logic;
        DI : in  std_logic;
        CI : in  std_logic;
        O  : out std_logic
      );
    end component;

    signal p : std_logic_vector(N-1 downto 0);  -- Propagates
    signal q : std_logic_vector(N   downto 0);  -- Carries = Intermediate Tokens
  begin

    -- Propagate if no local Request
    p <= not rqst;

    -- Token Input
    q(0) <= to_X01(tin);

    -- Token Forwarding Chain
    genChain: for i in 0 to N-1 generate
      signal pp, cc : std_logic;
      signal qq     : std_logic_vector(1 downto 0);
    begin

      -- q(i+1) <= q(i) and p(i)

      -- First MUXCY only with switching LUT
      genFirst: if i = 0 generate
        pp <= q(0) and p(0);
        cc <= '1';
      end generate;

      -- Others using Carry Input
      genChain: if i > 0 generate
        pp <= p(i);
        cc <= q(i);
      end generate genChain;

      MUXCY_inst : MUXCY
        port map (
          O  => q(i+1),
          CI => cc,
          DI => '0',
          S  => pp
        );

      -- Compute Grant
      qq <= q(i+1 downto i);
      with qq select grnt(i) <=
        '0' when "00" | "11",
        '1' when "01",
        'X' when others;

    end generate;

    -- Token Output
    tout <= q(N);

    -- Recode to Binary
    process(q)
      variable b : std_logic;
    begin
      for i in 0 to log2ceil(N)-1 loop
        b := '0';
        for j in 0 to (N+(2**i)-1)/(2**(i+1))-1 loop
          b := b or (q((2**i) + j*(2**(i+1))) and not q(imin(N, (2**(i+1)) + j*(2**(i+1)))));
        end loop;
        bin(i) <= b;
      end loop;
    end process;

  end generate genXilinx;

end rtl;
