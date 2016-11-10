-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:					TODO
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
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
use			IEEE.std_logic_1164.all;

library UNISIM;
use			UNISIM.vComponents.all;


entity arith_inc_ovcy_xilinx is
  generic (
    N : positive                             -- Bit Width
  );
  port (
    p : in  std_logic_vector(N-1 downto 0);  -- Argument
    g : in  std_logic;                       -- Increment Guard
    v : out std_logic                        -- Overflow Output
  );
end entity;


architecture rtl of arith_inc_ovcy_xilinx is
  signal c : std_logic_vector(N downto 0);  -- Carry Chain Links
begin  -- rtl

  -- Feed Chain with Guard
  c(0) <= g;

  -- Instantiate Carry Chain
  genCC: for i in 0 to N-1 generate
    m : MUXCY
      port map (
        O  => c(i+1),
        CI => c(i),
        DI => '0',
        S  => p(i)
      );
  end generate genCC;

  -- Output from final Carry
  v <= c(N);

end architecture;
