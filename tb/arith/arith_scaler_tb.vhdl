-- EMACS settings: -*-  tab-width:2  -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-------------------------------------------------------------------------------
-- Authors:      Thomas B. Preusser
--
-- Description:  Testbench for arith_scaler.
--
-------------------------------------------------------------------------------
-- Copyright 2007-2016 Technische Universität Dresden - Germany
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
-------------------------------------------------------------------------------

library IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library	PoC;
use			PoC.utils.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;


entity arith_scaler_tb is
end entity;


architecture tb of arith_scaler_tb is
  -- component generics
  constant MULS : T_POSVEC := (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
  constant DIVS : T_POSVEC := (1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);
  constant ARGS : T_NATVEC := (0, 1, 2, 3, 4, 31, 32, 33, 63, 64, 65, 95, 96, 97, 127, 128, 129, 196, 254, 255);

  -- component ports
  signal clk   : std_logic		:= '0';
  signal rst   : std_logic		:= '0';

  signal start : std_logic;
  signal arg   : std_logic_vector(7 downto 0);
  signal msel  : std_logic_vector(log2ceil(MULS'length)-1 downto 0);
  signal dsel  : std_logic_vector(log2ceil(DIVS'length)-1 downto 0);

  signal done  : std_logic;
  signal res   : std_logic_vector(7 downto 0);

begin
	-- initialize global simulation status
	simInitialize;

  -- component instantiation
  DUT: entity PoC.arith_scaler
    generic map (
      MULS => MULS,
      DIVS => DIVS
    )
    port map (
      clk   => clk,
      rst   => rst,
      start => start,
      arg   => arg,
      msel  => msel,
      dsel  => dsel,
      done  => done,
      res   => res
    );

  process
    procedure cycle is
    begin
      clk <= '0';
      wait for 5 ns;
      clk <= '1';
      wait for 5 ns;
    end cycle;

		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Checker");
  begin
    cycle;
    rst <= '1';
    cycle;
    rst <= '0';

    for i in MULS'range loop
      for j in DIVS'range loop
        for k in ARGS'range loop
          arg <= std_logic_vector(to_unsigned(ARGS(k), arg'length));
          msel <= std_logic_vector(to_unsigned(i, msel'length));
          dsel <= std_logic_vector(to_unsigned(j, dsel'length));
          start <= '1';
          cycle;

          arg   <= (others => '-');
          msel  <= (others => '-');
          dsel  <= (others => '-');
          start <= '0';

          while done /= '1' loop
            cycle;
          end loop;

					simAssertion(res = to_slv(((ARGS(k)*MULS(i)+DIVS(j)/2)/DIVS(j)) mod 2**res'length, res'length),
											 "Computation error: "&
											 integer'image(ARGS(k))&'*'&integer'image(MULS(i))&'/'&integer'image(DIVS(j))&
											 " -> "&integer'image(to_integer(unsigned(res))));
        end loop;
      end loop;
    end loop;

    -- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
  end process;

end architecture;
