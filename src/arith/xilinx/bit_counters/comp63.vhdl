-- EMACS settings: -*-	tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity: A floating LUT implementation of a (6:1,1,1] counter.
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

entity comp63 is
  port (
    x : in  std_logic_vector(5 downto 0);
    o : out std_logic_vector(2 downto 0)
  );
end entity comp63;


library IEEE;
use IEEE.numeric_bit.all;

library UNISIM;
use UNISIM.vcomponents.all;

architecture xil of comp63 is
  subtype config is bit_vector(63 downto 0);
  type config_vector is array(natural range<>) of config;

  function compute_LUTS return config_vector is
    variable res : config_vector(2 downto 0);
    variable t   : unsigned(5 downto 0);
    variable n   : natural;
  begin
    for i in 0 to 2**t'length-1 loop
      t := to_unsigned(i, t'length);
      n := 0;
      for j in t'range loop
        if t(j) = '1' then
          n := n + 1;
        end if;
      end loop;
      t := to_unsigned(n, t'length);
      for j in res'range loop
        res(j)(i) := t(j);
      end loop;
    end loop;
    return  res;
  end function compute_LUTS;

  constant LUT_INIT : config_vector(2 downto 0) := compute_LUTS;

begin

  genLUTs: for i in o'range generate
    lut0: LUT6_2
      generic map (
        INIT => LUT_INIT(i)
      )
      port map (
        O6 => o(i),
        O5 => open,
        I5 => x(5),
        I4 => x(4),
        I3 => x(3),
        I2 => x(2),
        I1 => x(1),
        I0 => x(0)
      );
  end generate genLUTs;

end xil;
