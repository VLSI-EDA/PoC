-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:					Minimal FIFO, common clock (cc), pipelined interface, first-word-fall-through mode
--
-- Description:
-- -------------------------------------
-- Its primary use is the decoupling of enable domains in a processing
-- pipeline. Data storage is limited to two words only so as to allow both
-- the ``ful``  and the ``vld`` indicators to be driven by registers.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
--                     Chair of VLSI-Design, Diagnostics and Architecture
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

library	IEEE;
use			IEEE.std_logic_1164.all;

entity fifo_glue is
  generic (
    D_BITS : positive              							     -- Data Width
  );
  port (
    -- Control
    clk : in std_logic;           						      -- Clock
    rst : in std_logic;           						      -- Synchronous Reset

    -- Input
    put : in  std_logic;                            -- Put Value
    di  : in  std_logic_vector(D_BITS-1 downto 0);  -- Data Input
    ful : out std_logic;                            -- Full

    -- Output
    vld : out std_logic;                            -- Data Available
    do  : out std_logic_vector(D_BITS-1 downto 0);  -- Data Output
    got : in  std_logic                             -- Data Consumed
  );
end entity fifo_glue;


architecture rtl of fifo_glue is

  -- Data Buffer Registers
  signal A, B : std_logic_vector(D_BITS-1 downto 0);

  -- State Registers
  signal Full, Avail : std_logic := '0';

begin

  process(clk)
  begin
    if rising_edge(clk) then
      if rst = '1' then
        A <= (others => '-');
        B <= (others => '-');

        Full  <= '0';
        Avail <= '0';
      else

        if Avail = '0' then
          if put = '1' then
            B     <= di;
            Avail <= '1';
          end if;
        elsif Full = '0' then
          if got = '1' then
            if put = '1' then
              B <= di;
            else
              Avail <= '0';
            end if;
          else
            if put = '1' then
              A    <= di;
              Full <= '1';
            end if;
          end if;
        else
          if got = '1' then
            B    <= A;
            Full <= '0';
          end if;
        end if;

      end if;
    end if;
  end process;

  ful <= Full;
  vld <= Avail;
  do  <= B;

end architecture;
