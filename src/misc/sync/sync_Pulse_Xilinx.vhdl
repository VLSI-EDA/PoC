-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:          Patrick Lehmann
--
-- Entity:           sync_Pulse_Xilinx
--
-- Description:
-- -------------------------------------
-- This is a multi-bit clock-domain-crossing circuit optimized for Xilinx FPGAs.
-- It synchronizes multiple pulsed bits into the clock-domain ``Clock``.
-- It utilizes two `FD` instances from `UniSim.vComponents`. All bits are
-- independent from each other. If you need a platform independent version of
-- this synchronizer, please use `PoC.misc.sync.Pulse`, which internally
-- instantiates this module if a Xilinx FPGA is detected.
--
-- .. ATTENTION::
--    Use this synchronizer for very short signals (pulse).
--
-- CONSTRAINTS:
--    This relative placement of the internal sites are constrained by RLOCs.
--
--   Xilinx ISE UCF or XCF file:
--    .. code-block:: VHDL
--
--        NET "*_async"    TIG;
--        INST "*FF1_METASTABILITY_FFS" TNM = "METASTABILITY_FFS";
--        TIMESPEC "TS_MetaStability" = FROM FFS TO "METASTABILITY_FFS" TIG;
--
--   Xilinx Vivado xdc file:
--    The XDC file `sync_Pulse_Xilinx.xdc` must be directly applied to all
--    instances of sync_Pulse_Xilinx. To achieve this, set the property
--    `SCOPED_TO_REF` to `sync_Pulse_Xilinx` within the Vivado project.
--    Load the XDC file defining the clocks before that XDC file by using the
--    property `PROCESSING_ORDER`.
--
--    .. literalinclude:: ../../../ucf/misc/sync/sync_Pulse_Xilinx.xdc
--       :language: xdc
--       :tab-width: 2
--       :linenos:
--       :lines: 4-8
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
--    http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library IEEE;
use     IEEE.STD_LOGIC_1164.all;

library PoC;
use     PoC.utils.all;
use     PoC.sync.all;

library UniSim;
use     UniSim.VComponents.all;


entity sync_Pulse_Xilinx is
  generic (
    BITS          : positive            := 1;                 -- number of bit to be synchronized
    SYNC_DEPTH    : T_MISC_SYNC_DEPTH   := 2                  -- generate SYNC_DEPTH many stages, at least 2
  );
  port (
    Clock         : in  std_logic;                            -- Clock to be synchronized to
    Input         : in  std_logic_vector(BITS - 1 downto 0);  -- Data to be synchronized
    Output        : out  std_logic_vector(BITS - 1 downto 0)  -- synchronised data
  );
end entity;


architecture rtl of sync_Pulse_Xilinx is
  constant INIT_I           : bit_vector    := (0 to BITS - 1 => '0');

  signal Captured_async     : std_logic_vector(BITS - 1 downto 0);
  signal Input_sync         : std_logic_vector(BITS - 1 downto 0);
  
begin
  gen : for i in 0 to BITS - 1 generate
    signal Clear            : std_logic;
  begin
    capture : FDCE
      generic map (
        INIT => '0'
      )
      port map (
        C =>    Input(i),
        CE =>    '1',
        CLR =>  Clear,
        D =>    '1',
        Q =>    Captured_async(i)
      );

    Clear <= not Input(i) and Input_sync(i);
  end generate;

  Sync : entity PoC.sync_Bits_Xilinx
    generic map (
      BITS        => BITS,
      SYNC_DEPTH  => SYNC_DEPTH
    )
    port map (
      Clock   => Clock,
      Input   => Captured_async,
      Output  => Input_sync
    );

  Output <= Input_sync;
end architecture;
