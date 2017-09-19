-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:  Generic bit matrix compressor.
--
-- Description:
-- ------------
--   This module implements a generic bit matrix compression. It computes the
--   numeric total across all input bits in a conventional 2-complement
--   encoding. Each input bit contributes to this sum the weight that
--   corresponds to its containing matrix column if and only if it is asserted.
--   The rightmost matrix column has a weight of 2^0, the adjacent one 2^1, and
--   so on. The individual heights of the input columns are specified by the
--   generic INPUT_LAYOUT, an array of naturals, in which the rightmost element
--   refers to the rightmost column. The input signals are extracted from the
--   flattened input vector again using the rightmost inputs for the rightmost
--   matrix bits having weight 1.
--
--   This implementation is based on the following paper:
--
--   Thomas B. Preußer: "Generic and Universal Parallel Matrix Summation
--     									 with a Flexible Compression Goal for Xilinx FPGAs",
--     International Conference on Field Programmable Logic and Applications
--     (FPL 2017), Sep, 2017.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universität Dresden - Germany,
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

use work.utils.all;

entity arith_matrixsum is
  generic (
    INPUT_LAYOUT : natural_vector
  );
  port (
    x : in  std_logic_vector(sum(INPUT_LAYOUT)-1 downto 0);
    y : out std_logic_vector(clog2_maxweight(INPUT_LAYOUT)-1 downto 0)
  );
end entity arith_matrixsum;


library UNISIM;
use UNISIM.vcomponents.all;

library PoC;
use PoC.arith_counters.all;

architecture xil of arith_matrixsum is

  -- Compression Schedule
  constant S : integer_vector := schedule(INPUT_LAYOUT);
  signal nn  : std_logic_vector(MAXIMUM(S) downto 0);  -- used bit signals

begin

  -- Feed Inputs
  nn(x'length downto 0) <= x & '0';

  -- Implement Schedule
  genSchedule : for i in S'range generate
    constant TAG : integer := -(S(i)+1);
  begin
    genTag : if TAG >= 0 generate
      genCounter : if TAG < COUNTERS'length generate
        constant comp        : counter := COUNTERS(tag);
        constant INPUT_BITS  : positive   := sum(comp.inputs);
        constant OUTPUT_BITS : positive   := sum(comp.outputs);

        signal bits_in  : std_logic_vector(INPUT_BITS-1 downto 0);
        signal bits_out : std_logic_vector(OUTPUT_BITS-1 downto 0);
      begin

        -- Extract Inputs
        genExtrIn: for j in bits_in'range generate
          bits_in(j) <= nn(S(i+INPUT_BITS-j));
        end generate genExtrIn;

        -- Map Outputs
        genMapOut: for j in bits_out'range generate
          nn(S(i+INPUT_BITS+OUTPUT_BITS-j)) <= bits_out(j);
        end generate genMapOut;

        -- Generate Counters that utilize a CARRY4 primitive
        genChain : if TAG < 10 generate

          -- CARRY4 Connectivity
          signal cin  : std_logic;
          signal d, p : std_logic_vector(3 downto 0);

        begin
          genAtoms: if TAG < 9 generate
            constant KIND_HI : natural range 0 to 2 := TAG/3;
            constant KIND_LO : natural range 0 to 2 := TAG mod 3;

            constant HI_BITS : natural := 6 - KIND_HI;
            constant LO_BITS : natural := 6 - KIND_LO/2;

            -- Extracted Signals
            signal bits_hi : std_logic_vector(HI_BITS-1 downto 0);
            signal bits_lo : std_logic_vector(LO_BITS-1 downto 0);

          begin

            -- Extract Inputs
            bits_hi <= bits_in(bits_in'left downto LO_BITS);
            bits_lo <= bits_in(LO_BITS-1 downto 0);

            -- Instantiate HI LUTs
            genHi06: if KIND_HI = 0 generate
              atom: entity work.atom06
                port map (
                  x0 => bits_hi,
                  d  => d(3 downto 2),
                  s  => p(3 downto 2)
                );
            end generate genHi06;
            genHi14: if KIND_HI = 1 generate
              atom: entity work.atom14
                port map (
                  x1 => bits_hi(bits_hi'left),
                  x0 => bits_hi(bits_hi'left-1 downto 0),
                  d  => d(3 downto 2),
                  s  => p(3 downto 2)
                );
            end generate genHi14;
            genHi22: if KIND_HI = 2 generate
              atom: entity work.atom22
                port map (
                  x1 => bits_hi(3 downto 2),
                  x0 => bits_hi(1 downto 0),
                  d  => d(3 downto 2),
                  s  => p(3 downto 2)
                );
            end generate genHi22;

            -- Instantiate LO LUTs
            genLo06: if KIND_LO = 0 generate
              atom: entity work.atom06
                port map (
                  x0 => bits_lo,
                  d  => d(1 downto 0),
                  s  => p(1 downto 0)
                );
              cin <= '0';
            end generate genLo06;
            genLo14: if KIND_LO = 1 generate
              atom: entity work.atom14
                port map (
                  x1 => bits_lo(bits_lo'left),
                  x0 => bits_lo(bits_lo'left-1 downto 1),
                  d  => d(1 downto 0),
                  s  => p(1 downto 0)
                );
              cin <= bits_lo(0);
            end generate genLo14;
            genLo22: if KIND_LO = 2 generate
              atom: entity work.atom22
                port map (
                  x1 => bits_lo(4 downto 3),
                  x0 => bits_lo(2 downto 1),
                  d  => d(1 downto 0),
                  s  => p(1 downto 0)
                );
              cin <= bits_lo(0);
            end generate genLo22;

          end generate genAtoms;

          -- Instantiate full LUT block
          genBlock: if TAG = 9 generate
            block1324_1: entity work.block1324
              port map (
                x0 => bits_in(4 downto 1),
                x1 => bits_in(6 downto 5),
                x2 => bits_in(bits_in'left-1 downto 7),
                x3 => bits_in(bits_in'left),
                d  => d,
                s  => p
              );
            cin <= bits_in(0);
          end generate genBlock;

          -- Instantiate Chain
          genCC: block
            signal co : std_logic_vector(4 downto 1);
          begin
            cc : CARRY4
              port map (
                CO     => co,
                O      => bits_out(3 downto 0),
                CI     => '0',
                CYINIT => cin,
                DI     => d,
                S      => p
              );
            bits_out(4) <= co(4);
          end block genCC;

        end generate genChain;

        -- Generate floating instances
        gen25: if TAG = 10 generate
          comp25_1: entity work.comp25
            port map (
              x0 => bits_in(4 downto 0),
              x1 => bits_in(bits_in'left downto 5),
              o0 => bits_out(1 downto 0),
              o1 => bits_out(bits_out'left downto 2)
            );
        end generate gen25;
        gen63: if TAG = 11 generate
          comp63_1: entity work.comp63
            port map (
              x => bits_in,
              o => bits_out
            );
        end generate gen63;
        genFA: if TAG = 12 generate
          fa_1: entity work.fa
            port map (
              x => bits_in,
              o => bits_out
            );
        end generate genFA;

      end generate genCounter;

      -- Conclusive Chain Construction
      genSumCP : if TAG = TAG_CC_CP generate
				y(S(i+1)) <= nn(S(i+2));
      end generate genSumCP;

      genSumFA : if TAG = TAG_CC_FA generate
        fa : entity work.fa_cc
          port map (
            a    => nn(S(i+2)),
            b    => nn(S(i+3)),
            cin  => nn(S(i+4)),
            cout => nn(S(i+5)),
            s    => y(S(i+1))
          );
      end generate genSumFA;

      genSum42 : if TAG = TAG_CC_42 generate
        a42 : entity work.add42_cc
          port map (
            a    => nn(S(i+2)),
            b    => nn(S(i+3)),
            c    => nn(S(i+4)),
            gin  => nn(S(i+5)),
            cin  => nn(S(i+6)),
            gout => nn(S(i+7)),
            cout => nn(S(i+8)),
            s    => y(S(i+1))
          );
      end generate genSum42;

    end generate genTag;
  end generate genSchedule;

end xil;
