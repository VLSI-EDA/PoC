-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- ============================================================================
-- Entity:      dstruct_stack
--
-- Authors:     Jens Voss <jens.voss@mailbox.tu-dresden.de>
--
-- Description:
-- ------------
--   Implements a stack, i.e. a LIFO storage abstraction.
--
-- License:
-- ============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
--                     Chair for VLSI-Design, Diagnostics and Architecture
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
-- ============================================================================

library IEEE;
use IEEE.std_logic_1164.all;

entity dstruct_stack is
  generic (
    D_BITS    : positive;               -- Data Width
    MIN_DEPTH : positive                -- Minimum Stack Depth
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
end dstruct_stack;


library IEEE;
use IEEE.numeric_std.all;

library PoC;
use PoC.config.all;
use PoC.utils.all;
use PoC.ocram.all;

architecture rtl of dstruct_stack is

    -- Constants
    constant A_BITS : natural := log2ceil(MIN_DEPTH); --INTEGER(CEIL(LOG2(REAL(MIN_DEPTH))));

    -- Signals
    signal stackpointer : unsigned(A_BITS-1 downto 0) := (others => '0');
    signal we : std_logic := '0';
    signal re : std_logic := '0';
    signal adr : unsigned(A_BITS-1 downto 0) := (others => '0');
    signal s_adr : unsigned(A_BITS-1 downto 0) := (others => '0');
    signal s_dout : std_logic_vector(D_BITS-1 downto 0) := (others => '0');
    signal last_value : std_logic_vector(D_BITS-1 downto 0) := (others => '0');
    signal reg_re : std_logic := '0';
    signal reg_we : std_logic := '0';
    signal s_valid : std_logic := '0';

    -- ctrl signal for stackpointer operations
    type ctrl_t is (PUSH, POP, IDLE);
    signal ctrl : ctrl_t;

    type state is (SEMPTY, NOTFULL, WAITING, SFULL);
    signal current_state, next_state : state; -- current and next state

begin

    -- Backing Memory
    ram : entity poc.ocram_sp
    generic map(
		A_BITS => A_BITS,
		D_BITS => D_BITS,
        FILENAME => ""
	)
	port map(
		clk => clk,
		ce	=> '1',
		we	=> we,
		a	=> adr,
		d	=> last_value,
		q	=> s_dout
	);

    process(clk)
    begin
        if(rising_edge(clk)) then
            if(rst = '1') then
                current_state <= SEMPTY;
            else
                current_state <= next_state;
            end if;
        end if;
    end process;

    process(current_state, put, stackpointer, got)
    begin
        ctrl <= IDLE;
        re <= '0';
        we <= '0';
        s_adr <= (others =>'0');
        valid <= '1';
        reg_re <= '0';
        reg_we <= '0';
        full <= '0';
        case( current_state ) is
            when SEMPTY =>
                valid <= '0';
                next_state <= SEMPTY;
                if(put = '1') then
                    -- push to empty stack!
                    next_state <= NOTFULL;
                    ctrl <= PUSH;
                    reg_we <= '1';
                else
                    -- enable is 0 -> do nothing
                    ctrl <= IDLE;
                end if;
            when NOTFULL=>
                next_state <= NOTFULL;
                s_adr <= stackpointer - 1;
                re <= '1';
                if(got = '1' and put = '0') then
                    reg_re <= '1';
                    ctrl <= POP;
                    if stackpointer = 1 then
                        -- last value poped from stack -> empty
                        next_state <= SEMPTY;
                    end if;
                elsif (got = '0' and put = '1') then
                    -- push to Stack
                    -- store new value in last_value
                    -- move current last_value to ram
                    ctrl <= PUSH;
                    s_adr <= stackpointer - 1;
                    we <= '1';
                    reg_we <= '1';
                    if (stackpointer = (MIN_DEPTH - 1)) then
                        next_state <= SFULL;
                    end if;
                elsif (got = '1' and put = '1') then
                    -- output last_value and store din in last_value, dont update Stackpointer, dont write back to memory
                    ctrl <= IDLE;
                    reg_we <= '1';
                else
                    -- do nothing
                    ctrl <= IDLE;
                end if;
            when SFULL=>
                next_state <= SFULL;
                full <= '1';
                s_adr <= stackpointer-2;
                re <= '1';
                if(got = '1') then
                    -- pop from Stack
                    ctrl <= POP;
                    next_state <= NOTFULL;
                    reg_re <= '1';
                else
                    -- got is 0 -> do nothnig
                    ctrl <= IDLE;
                end if;
            when others =>
                ctrl <= IDLE;
                next_state <= SEMPTY;
        end case;
    end process;

    process(clk)
    begin
        if (rising_edge(clk)) then
            case( ctrl ) is
                when IDLE =>
                    stackpointer <= stackpointer;
                when PUSH =>
                    stackpointer <= stackpointer + 1;
                when POP =>
                    stackpointer <= stackpointer - 1;
                when others =>
                    stackpointer <= stackpointer;
            end case;
        end if;
    end process;

    process(clk)
    begin
        if (rising_edge(clk)) then
            if(reg_we = '1') then
                last_value <= din;
            elsif (reg_re = '1') then
                last_value <= s_dout;
            else
                last_value <= last_value;
            end if;
        end if;
    end process;

    dout <= last_value;

    -- map local signals to ports
    adr <= s_adr;
end rtl;
