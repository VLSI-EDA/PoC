-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:        Martin Zabel
--                 Thomas B. Preusser
--		   					 Patrick Lehmann
--
-- Package:        UART (RS232) Components for PoC.io.uart
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
--              http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library	IEEE;
use			IEEE.std_logic_1164.all;

library	PoC;
use			PoC.utils.all;
use			PoC.physical.all;


package uart is
	type T_IO_UART_FLOWCONTROL_KIND is (
		UART_FLOWCONTROL_NONE,
		UART_FLOWCONTROL_XON_XOFF,
		UART_FLOWCONTROL_RTS_CTS,
		UART_FLOWCONTROL_RTR_CTS
	);

	constant C_IO_UART_TYPICAL_BAUDRATES : T_BAUDVEC := (
		 0 =>		 300 Bd,	 1 =>		 600 Bd,	 2 =>		1200 Bd,	 3 =>		1800 Bd,	 4 =>		2400 Bd,
		 5 =>		4000 Bd,	 6 =>		4800 Bd,	 7 =>		7200 Bd,	 8 =>		9600 Bd,	 9 =>	 14400 Bd,
		10 =>	 16000 Bd,	11 =>	 19200 Bd,	12 =>	 28800 Bd,	13 =>	 38400 Bd,	14 =>	 51200 Bd,
		15 =>	 56000 Bd,	16 =>	 57600 Bd,	17 =>	 64000 Bd,	18 =>	 76800 Bd,	19 =>	115200 Bd,
		20 =>	128000 Bd,	21 =>	153600 Bd,	22 =>	230400 Bd,	23 =>	250000 Bd,	24 =>	256000 Bd,
		25 =>	460800 Bd,	26 =>	500000 Bd,	27 =>	576000 Bd,	28 =>	921600 Bd
	);

	function io_UART_IsTypicalBaudRate(br : BAUD) return boolean;

  -- Bit Clock Generator: 8 Ticks per Bit
  component uart_bclk
    generic (
      CLK_FREQ : positive;
      BAUDRATE : positive
    );
    port (
      clk     : in  std_logic;
      rst     : in  std_logic;
      bclk    : out std_logic;
      bclk_x8 : out std_logic
    );
  end component;

  -- Receiver
  component uart_rx is
    generic (
      SYNC_DEPTH : natural := 2  -- use zero for already clock-synchronous rx
    );
    port (
      -- Global Control
      clk : in std_logic;
      rst : in std_logic;

      -- Bit Clock and RX Line
      bclk_x8 : in std_logic;  	-- bit clock, eight strobes per bit length
      rx      : in std_logic;

      -- Byte Stream Output
      do  : out std_logic_vector(7 downto 0);
      stb : out std_logic
    );
  end component;

  -- Transmitter
	component uart_tx is
		port (
			-- Global Control
			clk : in std_logic;
			rst : in std_logic;

			-- Bit Clock and TX Line
			bclk : in  std_logic;  -- bit clock, one strobe each bit length
			tx   : out std_logic;

			-- Byte Stream Input
			di  : in  std_logic_vector(7 downto 0);
			put : in  std_logic;
			ful : out std_logic
		);
	end component;

  -- Wrappers
  -- ===========================================================================
  -- UART with FIFOs and optional flow control
  component uart_fifo is
    generic (
      -- Communication Parameters
      CLOCK_FREQ  : FREQ;
      BAUDRATE    : BAUD;

			-- Buffer Dimensioning
      TX_MIN_DEPTH   : positive := 16;
      TX_ESTATE_BITS : natural  :=  0;
      RX_MIN_DEPTH   : positive := 16;
      RX_FSTATE_BITS : natural  :=  0;

      -- Flow Control
      FLOWCONTROL       : T_IO_UART_FLOWCONTROL_KIND   := UART_FLOWCONTROL_NONE;
      SWFC_XON_CHAR     : std_logic_vector(7 downto 0) := x"11";  -- ^Q
      SWFC_XON_TRIGGER  : real                         := 0.0625;
      SWFC_XOFF_CHAR    : std_logic_vector(7 downto 0) := x"13";  -- ^S
      SWFC_XOFF_TRIGGER : real                         := 0.75
    );
    port (
      Clock : in std_logic;
      Reset : in std_logic;

      -- FIFO interface
      TX_put        : in  std_logic;
      TX_Data       : in  std_logic_vector(7 downto 0);
      TX_Full       : out std_logic;
      TX_EmptyState : out std_logic_vector(TX_ESTATE_BITS - 1 downto 0);

      RX_Valid     : out std_logic;
      RX_Data      : out std_logic_vector(7 downto 0);
      RX_got       : in  std_logic;
      RX_FullState : out std_logic_vector(RX_FSTATE_BITS - 1 downto 0);
      RX_Overflow  : out std_logic;

      -- External Pins
      UART_RX : in  std_logic;
      UART_TX : out std_logic
    );
	end component;

	-- USB-UART
	component ft245_uart is
		generic (
      CLK_FREQ : positive
		);
		port (
      -- common signals
      clk         : in  std_logic;
      reset       : in  std_logic;

      -- send data
      snd_ready   : out std_logic;
      snd_strobe  : in  std_logic;
      snd_data    : in  std_logic_vector(7 downto 0);

      -- receive data
      rec_strobe  : out std_logic;
      rec_data    : out std_logic_vector(7 downto 0);

      -- connection to ft245
      ft245_data  : inout std_logic_vector (7 downto 0);
      ft245_rdn   : out std_logic;
      ft245_wrn   : out std_logic;
      ft245_rxfn  : in std_logic;
      ft245_txen  : in std_logic;
      ft245_pwrenn : in std_logic
		);
	end component;

end package;


package body uart is
	function io_UART_IsTypicalBaudRate(br : BAUD) return boolean is
	begin
		for i in C_IO_UART_TYPICAL_BAUDRATES'range loop
			next when (br /= C_IO_UART_TYPICAL_BAUDRATES(i));
			return TRUE;
		end loop;
		return FALSE;
	end function;
end package body;
