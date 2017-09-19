-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity: A bit slice of a 4-2-adder using the carry chain.
--
-- Description:
-- ------------
--   This implementation of a bit slice of a 4-to-2-adder uses the carry
--   chain of Xilinx devices for one of the carry path. This design decision
--   is valid for composing adders of a width of up to 50 bits or for
--   constructing a 3-to-1 carry-propagate adder by connecting the secondary
--   carry paths gout -> gin through the fabric. 4-to-2 adders that are
--   constructed from these bit slices have a delay that is *not* independent
--   of the adder size.
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

entity add42_cc is
  port (
    a, b, c, gin, cin : in  std_logic;
    gout, cout, s     : out std_logic
  );
end add42_cc;


library UNISIM;
use UNISIM.vcomponents.all;

architecture xil of add42_cc is
  signal p : std_logic;
begin
  lut : LUT6_2
    generic map (
      INIT => x"6996_6996_E8E8_E8E8"
    )
    port map (
      O6 => p,
      O5 => gout,
      I5 => '1',
      I4 => '-',
      I3 => gin,
      I2 => c,
      I1 => b,
      I0 => a
    );
  mux : MUXCY
    port map (
      O  => cout,
      S  => p,
      CI => cin,
      DI => gin
    );
  sum : XORCY
    port map (
      O  => s,
      CI => cin,
      LI => p
    );
end xil;
