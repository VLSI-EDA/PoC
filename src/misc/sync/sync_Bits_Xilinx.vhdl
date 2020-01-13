-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:           Patrick Lehmann
--
-- Entity:           sync_Bits_Xilinx
--
-- Description:
-- -------------------------------------
-- This is a multi-bit clock-domain-crossing circuit optimized for Xilinx FPGAs.
-- It utilizes two `FD` instances from `UniSim.vComponents`. If you need a
-- platform independent version of this synchronizer, please use
-- `PoC.misc.sync.Flag`, which internally instantiates this module if a Xilinx
-- FPGA is detected.
--
-- .. ATTENTION:
--     Use this synchronizer only for long time stable signals (flags).
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
--    The XDC file `sync_Bits_Xilinx.xdc` must be directly applied to all
--    instances of sync_Bits_Xilinx. To achieve this, set the property
--    `SCOPED_TO_REF` to `sync_Bits_Xilinx` within the Vivado project.
--    Load the XDC file defining the clocks before that XDC file by using the
--    property `PROCESSING_ORDER`.
--
--    .. literalinclude:: ../../../ucf/misc/sync/sync_Bits_Xilinx.xdc
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


entity sync_Bits_Xilinx is
  generic (
    BITS          : positive            := 1;                       -- number of bit to be synchronized
    INIT          : std_logic_vector    := x"00000000";             -- initialization bits
    SYNC_DEPTH    : T_MISC_SYNC_DEPTH   := T_MISC_SYNC_DEPTH'low    -- generate SYNC_DEPTH many stages, at least 2
  );
  port (
    Clock         : in  std_logic;                                  -- <Clock>  output clock domain
    Input         : in  std_logic_vector(BITS - 1 downto 0);        -- @async:  input bits
    Output        : out std_logic_vector(BITS - 1 downto 0)         -- @Clock:  output bits
  );
end entity;


library IEEE;
use     IEEE.STD_LOGIC_1164.all;

library UniSim;
use     UniSim.vComponents.all;

library PoC;
use     PoC.sync.all;


entity sync_Bit_Xilinx is
  generic (
    INIT          : bit;                                            -- initialization bits
    SYNC_DEPTH    : T_MISC_SYNC_DEPTH   := T_MISC_SYNC_DEPTH'low    -- generate SYNC_DEPTH many stages, at least 2
  );
  port (
    Clock         : in  std_logic;        -- <Clock>  output clock domain
    Input         : in  std_logic;        -- @async:  input bit
    Output        : out std_logic         -- @Clock:  output bit
  );
end entity;


architecture rtl of sync_Bits_Xilinx is
	constant INIT_I            : bit_vector    := to_bitvector(resize(descend(INIT), BITS));
begin
	gen : for i in 0 to BITS - 1 generate
		Sync : entity PoC.sync_Bit_Xilinx
			generic map (
				INIT        => INIT_I(i),
				SYNC_DEPTH  => SYNC_DEPTH
			)
			port map (
				Clock    => Clock,
				Input    => Input(i),
				Output  => Output(i)
			);
	end generate;
end architecture;


architecture rtl of sync_Bit_Xilinx is
	attribute ASYNC_REG        : string;
	attribute SHREG_EXTRACT    : string;
	attribute RLOC            : string;

	signal Data_async        : std_logic;
	signal Data_meta        : std_logic;
	signal Data_sync        : std_logic;

	-- Mark register Data_async's input as asynchronous
	attribute ASYNC_REG      of Data_meta  : signal is "TRUE";

	-- Prevent XST from translating two FFs into SRL plus FF
	attribute SHREG_EXTRACT of Data_meta  : signal is "NO";
	attribute SHREG_EXTRACT of Data_sync  : signal is "NO";

	-- Assign synchronization FF pairs to the same slice -> minimal routing delay
	attribute RLOC of Data_meta            : signal is "X0Y0";
	attribute RLOC of Data_sync            : signal is "X0Y0";

begin
	assert (SYNC_DEPTH = 2) report "Xilinx synchronizer supports only 2 stages. It could be extended to 4 or 8 on new FPGA series." severity WARNING;

	Data_async  <= Input;

	FF1_METASTABILITY_FFS : FD
		generic map (
			INIT    => INIT
		)
		port map (
			C        => Clock,
			D        => Data_async,
			Q        => Data_meta
		);

	FF2 : FD
		generic map (
			INIT    => INIT
		)
		port map (
			C        => Clock,
			D        => Data_meta,
			Q        => Data_sync
		);

	Output  <= Data_sync;
end architecture;
