-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity: A floating LUT implementation for a (2,5:1,2,1] counter.
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

entity comp25 is
  port (
    x0 : in  std_logic_vector(4 downto 0);
    x1 : in  std_logic_vector(1 downto 0);
    o0 : out std_logic_vector(1 downto 0);
    o1 : out std_logic_vector(1 downto 0)
  );
end entity comp25;


library UNISIM;
use UNISIM.vcomponents.all;

architecture xil of comp25 is
begin

  lut0: LUT6_2
    generic map (
      INIT => x"9669_6996" & x"E88E_8EE8"
    )
    port map (
      O6 => o0(0),
      O5 => o0(1),
      I5 => '1',
      I4 => x0(4),
      I3 => x0(3),
      I2 => x0(2),
      I1 => x0(1),
      I0 => x0(0)
    );

  lut1: LUT6_2
    generic map (
      INIT => x"E817_17E8" & x"FFE8_E800"
    )
    port map (
      O6 => o1(0),
      O5 => o1(1),
      I5 => '1',
      I4 => x1(1),
      I3 => x1(0),
      I2 => x0(4),
      I1 => x0(3),
      I0 => x0(2)
    );

end xil;
