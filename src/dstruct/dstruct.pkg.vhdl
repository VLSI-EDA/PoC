-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:     Jens Voss
--
-- Package:     dstruct
--
-- Description
-- -----------
--   Package for component declarations, types and functions within the
--   namespace PoC.dstruct.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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

package dstruct is

  component dstruct_stack is
    generic (
      D_BITS    : positive;  						-- Data Width
      MIN_DEPTH : positive  						-- Minimum Stack Depth
    );
    port (
      -- INPUTS
      clk, rst : in std_logic;

      -- Write Ports
      din  : in  std_logic_vector(D_BITS-1 downto 0);  -- Data Input
      put  : in  std_logic;  -- 0 -> pop, 1 -> push
      full : out std_logic;

      -- Read Ports
      got   : in  std_logic;
      dout  : out std_logic_vector(D_BITS-1 downto 0);
      valid : out std_logic
    );
	end component dstruct_stack;

  component dstruct_deque is
    generic (
      D_BITS    : positive;  						-- Data Width
      MIN_DEPTH : positive  						-- Minimum Deque Depth
    );
    port (
      -- Shared Ports
      clk, rst : in std_logic;

      -- Port A
      dinA   : in  std_logic_vector(D_BITS-1 downto 0);  -- DataA Input
      putA   : in  std_logic;
      gotA   : in  std_logic;
      doutA  : out std_logic_vector(D_BITS-1 downto 0);  -- DataA Output
      validA : out std_logic;
      fullA  : out std_logic;

      -- Port B
      dinB   : in  std_logic_vector(D_BITS-1 downto 0);  -- DataB Input
      putB   : in  std_logic;
      gotB   : in  std_logic;
      doutB  : out std_logic_vector(D_BITS-1 downto 0);
      validB : out std_logic;
      fullB  : out std_logic
    );
  end component dstruct_deque;

end package;
