-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- =============================================================================
-- Authors:     Thomas B. Preusser
--
-- Testbench:	Testbench FIFO stream assembly: module fifo_ic_assembly.
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
--		       Chair for VLSI-Design, Diagnostics and Architecture
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

entity fifo_ic_assembly_hwtb is
	generic (
    D_BITS : positive := 9;                                                                  -- Data Width
    A_BITS : positive := 9;                                                                  -- Address Bits
    G_BITS : positive := 1                                                                 -- Generation Guard Bits
	);
  port (
    clk : in std_logic;
    rst : in std_logic;

    leds : out std_logic_vector(7 downto 0)
  );
end entity fifo_ic_assembly_hwtb;


library IEEE;
use IEEE.numeric_std.all;

library PoC;
use PoC.utils.all;
use PoC.fifo.all;

architecture rtl of fifo_ic_assembly_hwtb is
  constant SEQ : t_intvec := (1, 0, 2, 3, 5, 4, 7, 6, 8, 10, 9, 12, 11, 13, 15, 14);

	-- DUT Connectivity
  signal base   : std_logic_vector(A_BITS-1 downto 0);
  signal failed : std_logic;
  signal addr   : std_logic_vector(A_BITS-1 downto 0);
  signal din    : std_logic_vector(D_BITS-1 downto 0);
  signal put    : std_logic;

  signal dout   : std_logic_vector(D_BITS-1 downto 0);
  signal vld    : std_logic;
  signal got    : std_logic;

  -- Writer State
  signal Ptr : unsigned(A_BITS-1 downto 0) := (others => '0');
  alias Seg  : unsigned(A_BITS-1 downto A_BITS-4) is Ptr(A_BITS-1 downto A_BITS-4);
  alias Ofs  : unsigned(A_BITS-5 downto        0) is Ptr(A_BITS-5 downto        0);

	signal tmp : unsigned(A_BITS-1 downto 0);

	-- Reader State
	signal Count   : unsigned(A_BITS-1 downto 0) := (others => '0');
	signal Failure : std_logic_vector(1 downto 0) := "00";

begin

  DUT: fifo_ic_assembly
    generic map (
      D_BITS => D_BITS,
      A_BITS => A_BITS,
      G_BITS => G_BITS
    )
    port map (
      clk_wr => clk,
      rst_wr => rst,
      base   => base,
			failed => failed,
      addr   => addr,
      din    => din,
      put    => put,

      clk_rd => clk,
      rst_rd => rst,
      dout   => dout,
      vld    => vld,
      got    => got
    );

	-- Writer
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Ptr <= (others => '0');
			elsif put = '1' then
				Ptr <= Ptr + 1;
			end if;
		end if;
	end process;
	addr <= std_logic_vector(to_unsigned(SEQ(to_integer(Seg)), Seg'length) & Ofs);
	din  <= not addr(D_BITS-1 downto 0);

	tmp <= unsigned(addr) - unsigned(base);
	put <= '1' when tmp(A_BITS-1 downto A_BITS-G_BITS) = 0 else '0';

  -- Reading Checker
	got <= '1';
	process(clk)
	begin
		if rising_edge(clk) then
			if rst = '1' then
				Count  <= (others => '0');
				Failure <= "00";
			elsif vld = '1' then
				if Count /= unsigned(not dout) then
					Failure(0) <= '1';
				end if;
				if failed = '1' then
				   Failure(1) <= '1';
				end if;
				Count <= Count + 1;
			end if;
		end if;
	end process;

  -- Outputs
	leds <= Failure & std_logic_vector(base(base'left downto base'left-5));
end rtl;
