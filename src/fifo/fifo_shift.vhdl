-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:					FIFO, common clock, pipelined interface
--
-- Description:
-- -------------------------------------
-- This FIFO implementation is based on an internal shift register. This is
-- especially useful for smaller FIFO sizes, which can be implemented in LUT
-- storage on some devices (e.g. Xilinx' SRLs). Only a single read pointer is
-- maintained, which determines the number of valid entries within the
-- underlying shift register.
--
-- The specified depth (``MIN_DEPTH``) is rounded up to the next suitable value.
--
-- License:
-- =============================================================================
-- Copyright 2007-2014 Technische Universitaet Dresden - Germany,
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

library	PoC;
use			Poc.utils.all;


entity fifo_shift is
  generic (
    D_BITS    : positive;               -- Data Width
    MIN_DEPTH : positive                -- Minimum FIFO Size in Words
  );
  port (
    -- Global Control
    clk : in std_logic;
    rst : in std_logic;

    -- Writing Interface
    put : in  std_logic;                            -- Write Request
    din : in  std_logic_vector(D_BITS-1 downto 0);  -- Input Data
    ful : out std_logic;                            -- Capacity Exhausted

    -- Reading Interface
    got  : in  std_logic;                            -- Read Done Strobe
    dout : out std_logic_vector(D_BITS-1 downto 0);  -- Output Data
    vld  : out std_logic                             -- Data Valid
  );
end entity fifo_shift;

library IEEE;
use IEEE.numeric_std.all;

library poc;
use poc.utils.all;

architecture rtl of fifo_shift is

  -- Data Register
  type tData is array(natural range<>) of std_logic_vector(D_BITS-1 downto 0);
  signal Dat : tData(0 to MIN_DEPTH-1);
  signal Ptr : unsigned(log2ceilnz(MIN_DEPTH) downto 0);

begin

  -- Data anf Pointer Registers
  process(clk)
  begin
    if clk'event and clk = '1' then
      if put = '1' then
        Dat <= din & Dat(0 to MIN_DEPTH-2);
      end if;
    end if;
  end process;
  process(clk)
  begin
    if clk'event and clk = '1' then
      if rst = '1' then
        Ptr <= (others => '0');
      else
        if put /= got then
          if put = '1' then
            Ptr <= Ptr - 1;
          else
            Ptr <= Ptr + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- Outputs
  dout <= Dat(to_integer(not Ptr(Ptr'left-1 downto 0)));
  vld  <= Ptr(Ptr'left);
  ful  <= '1' when ((not Ptr(Ptr'left-1 downto 0)) and to_unsigned(MIN_DEPTH-1, Ptr'length-1)) = MIN_DEPTH-1 else '0';

end rtl;
