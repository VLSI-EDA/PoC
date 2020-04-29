-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:					Martin Zabel
--
-- Module:					Model of SDRAM controller.
--
-- Description:
-- ------------------------------------
-- Model of an SDRAM controller.
--
-- To be used for simulation as a replacement for a real memory controller.
--
-- .. NOTE::
--    Synchronous reset is required after simulation startup.
--
-- License:
-- ============================================================================
-- Copyright 2020      Martin Zabel, Berlin, Germany
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
-- ============================================================================


-------------------------------------------------------------------------------
-- Naming Conventions:
-- (Based on: Keating and Bricaud: "Reuse Methodology Manual")
--
-- active low signals: "*_n"
-- clock signals: "clk", "clk_div#", "clk_#x"
-- reset signals: "rst", "rst_n"
-- generics: all UPPERCASE
-- user defined types: "*_TYPE"
-- state machine next state: "*_ns"
-- state machine current state: "*_cs"
-- output of a register: "*_r"
-- asynchronous signal: "*_a"
-- pipelined or register delay signals: "*_p#"
-- data before being registered into register with the same name: "*_nxt"
-- clock enable signals: "*_ce"
-- internal version of output port: "*_i"
-- tristate internal signal "*_z"
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity sdram_ctrl_model is

  generic (
    A_BITS : positive;
    D_BITS : positive;
		CL     : positive;  -- CAS Latency
		BL     : positive); -- Burst Length

  port (
    clk         : in  std_logic;
    rst         : in  std_logic;
    user_cmd_valid   : in  std_logic;
    user_wdata_valid : in  std_logic;
    user_write       : in  std_logic;
    user_addr        : in  std_logic_vector(A_BITS-1 downto 0);
    user_wdata       : in  std_logic_vector(D_BITS-1 downto 0);
    user_wmask       : in  std_logic_vector(D_BITS/8-1 downto 0);
    user_got_cmd     : out std_logic;
    user_got_wdata   : out std_logic;
    user_rdata       : out std_logic_vector(D_BITS-1 downto 0);
    user_rstb        : out std_logic);

end entity sdram_ctrl_model;

architecture sim of sdram_ctrl_model is
	-- RAM
	type RAM_T is array(natural range<>) of std_logic_vector(D_BITS-1 downto 0);
	signal ram : RAM_T(0 to 2**A_BITS-1);

	-- address register
	signal addr_r : unsigned(A_BITS-1 downto 0);

	-- write data & mask register
	signal wdata_r : std_logic_vector(D_BITS-1 downto 0);
	signal wmask_r : std_logic_vector(D_BITS/8-1 downto 0);
	
	-- read pipeline
	type RDATA_T is array(natural range<>) of std_logic_vector(D_BITS-1 downto 0);
	signal rdata_p : RDATA_T(1 to CL);
	signal rstb_p : std_logic_vector(1 to CL) := (others => '0');

	-- FSM
	type T_FSM is (RESET, READY, READING, WRITING, UNKNOWN);
	signal fsm_cs : T_FSM := UNKNOWN; -- current state

	signal req_write : X01;
	signal req_read  : X01;

	-- Burst counter
	signal bcnt_r : integer range 0 to BL-1 := 0;

begin  -- architecture sim

	-- Command decoding, handle 'U' as 'X'
	req_write <= to_x01(user_cmd_valid and user_write);
	req_read  <= to_x01(user_cmd_valid and not user_write);

	process(clk)
		variable fsm_ns : T_FSM; -- next state
	begin
		if rising_edge(clk) then
			fsm_ns := fsm_cs;

			case fsm_cs is
				when READY =>
					-- check for valid command
					if is_x(req_read) or is_x(req_write) then
						report "Invalid read/write command." severity error;
						fsm_ns := UNKNOWN;
					elsif req_read = '1' then
						bcnt_r <= BL-1;
						addr_r <= unsigned(user_addr);
						fsm_ns := READING;
					elsif req_write = '1' then
						bcnt_r <= BL-1;
						addr_r <= unsigned(user_addr);
						wdata_r <= user_wdata;
						wmask_r <= user_wmask;
						fsm_ns := WRITING;
					end if;

				when READING =>
					if bcnt_r = 0 then
						fsm_ns := READY;
					else
						addr_r <= addr_r + 1;
						bcnt_r <= bcnt_r - 1;
					end if;

        when WRITING =>
          if bcnt_r = 0 then
            fsm_ns := READY;
          else
            addr_r  <= addr_r + 1;
            wdata_r <= user_wdata;
            wmask_r <= user_wmask;
            bcnt_r  <= bcnt_r - 1;
          end if;

				when RESET   => fsm_ns := READY;
				when UNKNOWN => null;
			end case;

			-- Reset override
			case to_x01(rst) is
				when '1' => fsm_cs <= RESET;
				when '0' => fsm_cs <= fsm_ns;
				when 'X' => fsm_cs <= UNKNOWN;
			end case;
		end if;
	end process;

	-- Memory and Read Pipeline
	process(clk)
	begin
		if rising_edge(clk) then
			rstb_p(1)  <= '0'; -- default

			-- access memory only when ready, ignore requests otherwise
			if fsm_cs = WRITING then
				if Is_X(std_logic_vector(addr_r)) then
					report "Invalid address during write." severity error;
					ram <= (others => (others => 'X'));
				else
					for i in 0 to D_BITS/8-1 loop
						if Is_X(wmask_r(i)) then
							ram(to_integer(addr_r))(i*8+7 downto i*8) <= (others => 'X');
						elsif wmask_r(i) = '0' then
							ram(to_integer(addr_r))(i*8+7 downto i*8) <= to_ux01(wdata_r(i*8+7 downto i*8));
						end if;
					end loop;  -- i
				end if;
			end if;

			if fsm_cs = READING then
				rstb_p(1)  <= '1';
				if Is_X(std_logic_vector(addr_r)) then
					report "Invalid address during read." severity error;
					rdata_p(1) <= (others => 'X');
				else
					rdata_p(1) <= ram(to_integer(addr_r));
				end if;
			end if;

			-- read pipeline
			if CL > 1 then
				rstb_p (2 to CL) <= rstb_p (1 to CL-1);
				rdata_p(2 to CL) <= rdata_p(1 to CL-1);
			end if;

			-- reset only read strobe
			case to_x01(rst) is
				when '1' =>	rstb_p <= (others => '0');
				when '0' => null;
				when 'X' => rstb_p <= (others => 'X');
			end case;
		end if;
	end process;

	-- Outputs
	user_got_cmd <= 'X' when fsm_cs = UNKNOWN else
									'1' when fsm_cs = READY and (req_read = '1' or req_write = '1') else
									'0';
	
	user_got_wdata <= 'X' when fsm_cs = UNKNOWN else
										'1' when fsm_cs = READY and req_write = '1' else
										'1' when fsm_cs = WRITING and bcnt_r > 0 else
										'0';
	
	user_rdata <= rdata_p(CL);
	user_rstb	 <= rstb_p (CL);

end architecture sim;
