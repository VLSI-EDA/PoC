-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:					TRNG - True Random Number Generator.
--
-- Description:
-- ------------
-- This module implements a true random number generator based on sampling
-- combinational loops of interleaved X(N)OR gates.
--
-- Always verify the randomness of this TRNG implementation for your concrete
-- target platform, for instance, using the dieharder test by Robert G. Brown
-- [http://www.phy.duke.edu/~rgb/General/dieharder.php], which is also
-- directly available for many GNU/Linux distributions, e.g. Debian. Ideally,
-- randomness would be verified for varying operating conditions.
--
-- This design involves fast-switching combinational loops on purpose so as
-- to serve as sources of entropoy. This implies a relevant local power
-- consumption. Do not cramp large parts of a chip with these TRNGs without
-- ensuring appropriate heat dissipation. It often requires special
-- constraints or directives to enforce the proper synthesis of these
-- combinational loops by the tools.
--
-- License:
-- =============================================================================
-- Copyright 2007-2017 Technische Universitaet Dresden - Germany
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
use	IEEE.std_logic_1164.all;

entity arith_trng is
  generic (
    BITS : positive  														 -- Width: Number of Oscillators
	);
  port (
    clk : in  std_logic;				  							 -- Clock
    rnd : out std_logic_vector(BITS-1 downto 0)  -- Random Oscillator Samples
	);
end entity;


library PoC;
use PoC.utils.all;
use PoC.sync.sync_Bits;

architecture rtl of arith_trng is
  signal osc : std_logic_vector(BITS-1 downto 0) := (others => '-');  -- Oscillators
  attribute KEEP : boolean;
  attribute KEEP of osc : signal is true;
begin

  -- Oscillator Leaves
  genOscillate : for i in 0 to BITS-1 generate
	  osc(i) <= ite(i<3, '1', '0') xor osc((i-1)mod BITS) xor osc(i) xor osc((i+1)mod BITS);
  end generate;

	sync_i : sync_Bits
		generic map (
			BITS => BITS
		)
		port map (
			Clock  => clk,
			Input  => osc,
			Output => rnd
		);

end rtl;
