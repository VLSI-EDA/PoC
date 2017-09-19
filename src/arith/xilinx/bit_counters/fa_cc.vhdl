-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:	FA implementation mapped to the Xilinx carry chain architecture.
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

entity fa_cc is
  port (
    a, b, cin : in  std_logic;
    cout, s   : out std_logic
  );
end fa_cc;


library UNISIM;
use UNISIM.vcomponents.all;

architecture xil of fa_cc is
  signal p, d : std_logic;
begin
  p <= a xor b;
  d <= a;
  mux : MUXCY
    port map (
      O  => cout,
      S  => p,
      CI => cin,
      DI => d
    );
  sum : XORCY
    port map (
      O  => s,
      CI => cin,
      LI => p
    );
end xil;
