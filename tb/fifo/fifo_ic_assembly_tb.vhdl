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

entity fifo_ic_assembly_tb is
end entity fifo_ic_assembly_tb;


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

library PoC;
use			PoC.utils.all;
use			PoC.physical.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


architecture tb of fifo_ic_assembly_tb is
	constant CLOCK_FREQ							: FREQ					:= 100 MHz;

  -- component generics
  constant D_BITS : positive := 8;
  constant A_BITS : positive := 8;
  constant G_BITS : positive := 2;

  constant SEQ : t_intvec := (1, 0, 2, 3, 5, 4, 7, 6, 8, 10, 9, 12, 11, 13, 15, 14);

  -- component ports
  signal clk : std_logic;
  signal rst : std_logic;

  signal base   : std_logic_vector(A_BITS-1 downto 0);
  signal addr   : std_logic_vector(A_BITS-1 downto 0);
  signal din    : std_logic_vector(D_BITS-1 downto 0);
  signal put    : std_logic;

  signal dout   : std_logic_vector(D_BITS-1 downto 0);
  signal vld    : std_logic;
  signal got    : std_logic;

begin
	-- initialize global simulation status
	simInitialize;
	-- generate global testbench clock and reset
	simGenerateClock(clk, 		CLOCK_FREQ);
	-- simGenerateWaveform(rst,	simGenerateWaveform_Reset(Pause => 10 ns, ResetPulse => 10 ns));
	rst		<= '0';

  DUT: entity PoC.fifo_ic_assembly
    generic map (
      D_BITS => D_BITS,
      A_BITS => A_BITS,
      G_BITS => G_BITS
    )
    port map (
      clk_wr => clk,
      rst_wr => rst,
      base   => base,
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
	procWriter : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Writer");

    variable t : integer;
  begin
    put <= '0';
    wait until base = (base'range => '0');
    put <= '1';
    for i in SEQ'range loop
      for j in 0 to 15 loop
        t := 16*SEQ(i) + j;
        addr <= std_logic_vector(to_unsigned(t, addr'length));
        din  <= std_logic_vector(to_unsigned(t, din 'length));
        wait until rising_edge(clk);
      end loop;
    end loop;
    put <= '0';

   -- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
  end process;

  -- Reading Checker
	procReader : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Reader");
  begin
    got <= '1';
    for i in 0 to SEQ'length*16-1 loop
      wait until rising_edge(clk) and vld = '1';
      simAssertion(dout = std_logic_vector(to_unsigned(i, dout'length)),
									 "Unexpected output: "&integer'image(to_integer(unsigned(dout)))&
									 " instead of "&integer'image(i mod 2**dout'length));
    end loop;
    got <= '0';

    -- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
  end process;

end tb;
