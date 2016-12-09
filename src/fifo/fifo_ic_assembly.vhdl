-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Thomas B. Preusser
--
-- Entity:					Address-based FIFO stream assembly, independent clocks (ic)
--
-- Description:
-- -------------------------------------
-- This module assembles a FIFO stream from data blocks that may arrive
-- slightly out of order. The arriving data is ordered according to their
-- address. The streamed output starts with the data word written to
-- address zero (0) and may proceed all the way to just before the first yet
-- missing data. The association of data with addresses is used on the input
-- side for the sole purpose of reconstructing the correct order of the data.
-- It is assumed to wrap so as to allow an infinite input sequence. Addresses
-- are not actively exposed to the purely stream-based FIFO output.
--
-- The implemented functionality enables the reconstruction of streams that
-- are tunnelled across address-based transports that are allowed to reorder
-- the transmission of data blocks. This applies to many DMA implementations.
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
--		http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library	IEEE;
use	IEEE.std_logic_1164.all;

entity fifo_ic_assembly is
  generic (
    D_BITS : positive;  								-- Data Width
    A_BITS : positive;  								-- Address Bits
    G_BITS : positive  									-- Generation Guard Bits
  );
  port (
    -- Write Interface
    clk_wr : in std_logic;
    rst_wr : in std_logic;

		-- Only write addresses in the range [base, base+2**(A_BITS-G_BITS)) are
		-- acceptable. This is equivalent to the test
		--   tmp(A_BITS-1 downto A_BITS-G_BITS) = 0 where tmp = addr - base.
		-- Writes performed outside the allowable range will assert the failure
		-- indicator, which will stick until the next reset.
		-- No write is to be performed before base turns zero (0) for the first
		-- time.
		base   : out std_logic_vector(A_BITS-1 downto 0);
		failed : out std_logic;

    addr : in  std_logic_vector(A_BITS-1 downto 0);
    din  : in  std_logic_vector(D_BITS-1 downto 0);
    put  : in  std_logic;

    -- Read Interface
    clk_rd : in std_logic;
    rst_rd : in std_logic;

    dout : out std_logic_vector(D_BITS-1 downto 0);
    vld  : out std_logic;
    got  : in  std_logic
  );
end entity fifo_ic_assembly;


library IEEE;
use	IEEE.numeric_std.all;

library	PoC;
use PoC.utils.all;
use PoC.ocram.all;

architecture rtl of fifo_ic_assembly is

	-----------------------------------------------------------------------------
	-- Memory Dimensioning
	--  The leading guard bits from the provided address serve to distinguish
	--  the data generations. A generation is the amount of data that fills the
	--  internal assembly memory exactly once. Due to their purpose, the guard
	--  bits tag the data rather than being used for internal addressing.
	constant AN : positive := A_BITS - G_BITS;
	constant DN : positive := G_BITS + D_BITS;

	-- Memory Connectivity
	signal wa : unsigned(AN-1 downto 0);
	signal we : std_logic;
	signal di : std_logic_vector(DN-1 downto 0);

	signal ra : unsigned(AN-1 downto 0);
	signal do : std_logic_vector(DN-1 downto 0);

	-- Cross-clock
	signal OPgray : std_logic_vector(A_BITS-1 downto 0) := (others => '0');

begin

  -----------------------------------------------------------------------------
  -- Write clock domain
  blkWrite : block
    signal InitCnt : unsigned(AN downto 0)               := (others => '0');
    signal OPmeta  : std_logic_vector(A_BITS-1 downto 0) := (others => '0');
    signal OPsync  : std_logic_vector(A_BITS-1 downto 0) := (others => '0');
    signal OPbin   : std_logic_vector(A_BITS-1 downto 0) := '1' & (A_BITS-2 downto 0 => '0');
    signal Fail    : std_logic                           := '0';
  begin
    process(clk_wr)
			variable tmp : unsigned(A_BITS-1 downto 0);
    begin
      if rising_edge(clk_wr) then
        if rst_wr = '1' then
          InitCnt <= (others => '0');
          OPmeta  <= (others => '0');
          OPsync  <= (others => '0');
          OPbin   <= '1' & (A_BITS-2 downto 0 => '0');
          Fail    <= '0';
        else
          OPmeta  <= OPgray;
          OPsync  <= OPmeta;

					if InitCnt(InitCnt'left) = '0' then
						InitCnt <= InitCnt + 1;
					else
						OPbin   <= gray2bin(OPsync);
					end if;

					if put = '1' then
						tmp := unsigned(addr) - unsigned(OPbin);
						if tmp(A_BITS-1 downto AN) /= 0 then
							Fail <= '1';
						end if;
					end if;
        end if;
      end if;
    end process;
    wa <= InitCnt(AN-1 downto 0) when InitCnt(InitCnt'left) = '0' else
          unsigned(addr(AN-1 downto 0));
    di <= (1 to G_BITS => '1') & (1 to D_BITS => '-') when InitCnt(InitCnt'left) = '0' else
          (genmask_alternate(A_BITS-AN) xor (A_BITS-1 downto AN => addr(AN))) & din;
    we <= put or not InitCnt(InitCnt'left);

    -- Module Outputs
    base   <= OPbin;
    failed <= Fail;

  end block blkWrite;

  blkRead : block

    -- Init Delay to allow writer to invalidate memory contents
    signal InitDelay : unsigned(1 downto 0) := (others => '0');

    -- Output Pointer for Reading
    signal OP    : unsigned(A_BITS-1 downto 0) := (others => '0');
    signal OPnxt : unsigned(A_BITS-1 downto 0);

		-- Internal check result
		signal vldi : std_logic;

  begin
    process(clk_rd)
    begin
      if rising_edge(clk_rd) then
        if rst_rd = '1' then
					InitDelay <= (others => '0');
          OP				<= (others => '0');
          OPgray		<= (others => '0');
        else
					if InitDelay(InitDelay'left) = '0' then
						InitDelay <= InitDelay + 1;
					end if;
          OP     <= OPnxt;
          OPgray <= bin2gray(std_logic_vector(OP));
        end if;
      end if;
    end process;
    OPnxt <= OP+1 when vldi = '1' and got = '1' else OP;
    ra    <= OPnxt(AN-1 downto 0);
    vldi  <= '0' when InitDelay(InitDelay'left) = '0' else
             'X' when Is_X(do(DN-1 downto D_BITS)) else
             '1' when do(DN-1 downto D_BITS) = (genmask_alternate(A_BITS-AN) xor (A_BITS-1 downto AN => OP(AN))) else
             '0';

		-- Module Outputs
		dout <= do(D_BITS-1 downto 0);
    vld  <= vldi;

  end block blkRead;

	-- Backing internal assembly memory
	ram : ocram_sdp
		generic map (
			A_BITS => AN,
			D_BITS => DN
		)
		port map (
			wclk   => clk_wr,
			rclk   => clk_rd,

			wa     => wa,
			wce    => '1',
			we     => we,
			d      => di,

			ra     => ra,
			rce    => '1',
			q      => do
		);

end rtl;
