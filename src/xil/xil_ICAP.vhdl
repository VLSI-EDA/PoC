-- EMACS settings: -*-  tab-width: 4; indent-tabs-mode: t -*-
-- vim: tabstop=4:shiftwidth=4:noexpandtab
-- kate: tab-width 4; replace-tabs off; indent-width 4;
-- =============================================================================
-- Authors:					Paul Genssler
--
-- Entity:					ICAP Wrapper
--
-- Description:
-- -------------------------------------
-- This module wraps Xilinx "Internal Configuration Access Port" (ICAP) primitives in a generic
-- module. |br|
-- Supported devices are:
--  * Spartan-6
--  * Virtex-4, Virtex-5, Virtex-6
--  * Series-7 (Artix-7, Kintex-7, Virtex-7, Zynq-7000)
--
-- License:
-- =============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany,
--										 Chair of VLSI-Design, Diagnostics and Architecture
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
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library UniSim;
use			UniSim.vComponents.all;

library PoC;
use			PoC.config.all;


entity xil_ICAP is
	generic (
		ICAP_WIDTH	:	string := "X32";					-- Specifies the input and output data width to be used
															-- Spartan 6: fixed to 16 bit
															-- Virtex 4:  X8 or X32
															-- Rest: X8, X16, X32
		DEVICE_ID	:	bit_vector := X"1234567";				-- pre-programmed Device ID value for simulation
															-- supported by Spartan 6, Virtex 6 and above
		SIM_CFG_FILE_NAME	: string	:= "NONE"			-- Raw Bitstream (RBT) file to be parsed by the simulation model
															-- supported by Spartan 6, Virtex 6 and above
	);
	port (
		clk			:	in std_logic;						-- up to 100 MHz (Virtex-6 and above, Virtex-5??)
		disable		:	in std_logic;						-- low active enable -> high active disable
		rd_wr		:	in std_logic;						-- 0 - write, 1 - read
		busy		:	out std_logic;						-- on Series-7 devices always '0'
		data_in		:	in std_logic_vector(31 downto 0);	-- on Spartan-6 only 15 downto 0
		data_out	:	out std_logic_vector(31 downto 0)	-- on Spartan-6 only 15 downto 0
	);
end entity;


architecture rtl of xil_ICAP is
	constant DEV_INFO		: T_DEVICE_INFO	:= DEVICE_INFO;
begin

	genSpartan6 : if (DEV_INFO.Device = DEVICE_SPARTAN6) generate
	begin
	   icap : ICAP_SPARTAN6
	   generic map (
	      DEVICE_ID => DEVICE_ID,
	      SIM_CFG_FILE_NAME => SIM_CFG_FILE_NAME
	   )
	   port map (
	      BUSY => busy,   				-- 1-bit output: Busy/Ready output
	      O => data_out(15 downto 0),   -- 16-bit output: Configuartion data output bus
	      CE => disable,       			-- 1-bit input: Active-Low ICAP Enable input
	      CLK => clk, 				    -- 1-bit input: Clock input
	      I => data_in(15 downto 0),    -- 16-bit input: Configuration data input bus
	      WRITE => rd_wr				-- 1-bit input: Read/Write control input
	   );
	end generate;

	genVirtex4 : if (DEV_INFO.Device = DEVICE_VIRTEX4) generate
		signal ce : std_logic;
	begin
	   ce <= not disable;
	   icap : ICAP_VIRTEX4
	   generic map (
	      ICAP_WIDTH => ICAP_WIDTH) -- "X8" or "X32"
	   port map (
	      BUSY => busy,   -- Busy output
	      O => data_out,         -- 32-bit data output
	      CE => ce,       -- Clock enable input
	      CLK => clk,     -- Clock input
	      I => data_in,         -- 32-bit data input
	      WRITE => rd_wr  -- Write input
	   );
	end generate;

	genVirtex5 : if (DEV_INFO.Device = DEVICE_VIRTEX5) generate
		signal ce : std_logic;
	begin
	   ce <= not disable;
	   icap : ICAP_VIRTEX5
	   generic map (
	      ICAP_WIDTH => ICAP_WIDTH)
	   port map (
	      BUSY => busy,   -- Busy output
	      O => data_out,         -- 32-bit data output
	      CE => ce,       -- Clock enable input
	      CLK => clk,     -- Clock input
	      I => data_in,         -- 32-bit data input
	      WRITE => rd_wr  -- Write input
	   );
	end generate;

	genVirtex6 : if (DEV_INFO.Device = DEVICE_VIRTEX6) generate
	begin
	   icap : ICAP_VIRTEX6
	   generic map (
	      DEVICE_ID => DEVICE_ID,
	      ICAP_WIDTH => ICAP_WIDTH,
	      SIM_CFG_FILE_NAME => SIM_CFG_FILE_NAME
	   )
	   port map (
	      BUSY => busy,   -- 1-bit output: Busy/Ready output
	      O => data_out,         -- 32-bit output: Configuration data output bus
	      CLK => clk,     -- 1-bit input: Clock Input
	      CSB => disable,     -- 1-bit input: Active-Low ICAP input Enable
	      I => data_in,         -- 32-bit input: Configuration data input bus
	      RDWRB => rd_wr  -- 1-bit input: Read/Write Select input
	   );
	end generate;

	genSeries7 : if (DEV_INFO.DevSeries = DEVICE_SERIES_7_SERIES) generate
	begin
	   icap : ICAPE2
	   generic map (
	      DEVICE_ID => X"0" & DEVICE_ID,
	      ICAP_WIDTH => ICAP_WIDTH,
	      SIM_CFG_FILE_NAME => SIM_CFG_FILE_NAME
	   )
	   port map (
	      O => data_out,         -- 32-bit output: Configuration data output bus
	      CLK => clk,     -- 1-bit input: Clock Input
	      CSIB => disable,   -- 1-bit input: Active-Low ICAP Enable
	      I => data_in,         -- 32-bit input: Configuration data input bus
	      RDWRB => rd_wr  -- 1-bit input: Read/Write Select input
	   );
	   busy <= '0';
	end generate;
end architecture;
