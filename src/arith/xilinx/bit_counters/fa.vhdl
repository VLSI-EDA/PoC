-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:  A floating LUT implementation of a full adder.
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

entity fa is
  port (
    x : in  std_logic_vector(2 downto 0);
    o : out std_logic_vector(1 downto 0)
  );
end entity fa;


library UNISIM;
use UNISIM.vcomponents.all;

architecture xil of fa is
begin
  lut : LUT6_2
    generic map (
      INIT => x"E8E8_E8E8_9696_9696"
    )
    port map (
      O6 => o(1),
      O5 => o(0),
      I5 => '1',
      I4 => '0',
      I3 => '0',
      I2 => x(2),
      I1 => x(1),
      I0 => x(0)
    );
end xil;
