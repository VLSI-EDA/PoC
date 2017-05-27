-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
--
-- ============================================================================
-- Authors:					Patrick Lehmann
--
-- Testbench:				For PoC.io.iic.Controller
--
-- Description:
-- ------------------------------------
--	TODO
--
-- License:
-- ============================================================================
-- Copyright 2007-2016 Technische Universitaet Dresden - Germany
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
-- ============================================================================

library	IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;

library PoC;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.strings.all;
use			PoC.physical.all;
use			PoC.iic.all;
-- simulation only packages
use			PoC.sim_types.all;
use			PoC.simulation.all;
use			PoC.waveform.all;

library uvvm_util;
use			uvvm_util.types_pkg.all;

library uvvm_vvc_framework;
use			uvvm_vvc_framework.ti_vvc_framework_support_pkg.all;

library bitvis_vip_i2c;
use			bitvis_vip_i2c.i2c_bfm_pkg.all;


entity iic_Controller_th is
end entity;


architecture tb of iic_Controller_th is
	constant CLOCK_FREQ					: FREQ			:= 100 MHz;
	
	constant ADDRESS_BITS				: positive	:= 7;
	constant DATA_BITS					: positive	:= 8;
	
	signal Clock								: std_logic;
	signal Reset								: std_logic;
	
	signal Master_Request				: std_logic;
	signal Master_Grant					: std_logic;
	signal Master_Command				: T_IO_IIC_COMMAND;
	signal Master_Status				: T_IO_IIC_STATUS;
	signal Master_Error					: T_IO_IIC_ERROR;
	
	signal Master_Address				: std_logic_vector(ADDRESS_BITS - 1 downto 0);
	
	signal Master_WP_Valid			: std_logic;
	signal Master_WP_Data				: std_logic_vector(DATA_BITS - 1 downto 0);
	signal Master_WP_Last				: std_logic;
	signal Master_WP_Ack				: std_logic;
	signal Master_RP_Valid			: std_logic;
	signal Master_RP_Data				: std_logic_vector(DATA_BITS - 1 downto 0);
	signal Master_RP_Last				: std_logic;
	signal Master_RP_Ack				: std_logic;
	
	-- tristate interface: STD_LOGIC;
	signal Master_Serial				: T_IO_IIC_SERIAL;
	
	signal Slave1_Serial				: T_IO_IIC_SERIAL;
	signal Slave2_Serial				: T_IO_IIC_SERIAL;
	signal i2c_vvc_if						: T_I2C_IF;
	
begin
	-- initialize global simulation status
	-- simInitialize;
	simInitialize(MaxSimulationRuntime => 200 us);
	-- generate global testbench clock and reset
	simGenerateClock(Clock, CLOCK_FREQ);
	simGenerateWaveform(Reset, simGenerateWaveform_Reset(Pause => 50 ns));
	
  -- Instantiate the concurrent procedure that initializes UVVM
  uvvm_engine : entity uvvm_vvc_framework.ti_uvvm_engine;
  
	UUT : entity PoC.iic_Controller
		generic map (
			DEBUG										=> FALSE,
			CLOCK_FREQ							=> CLOCK_FREQ,
			IIC_BUSMODE							=> IO_IIC_BUSMODE_FASTMODEPLUS,	--IO_IIC_BUSMODE_STANDARDMODE,
			IIC_ADDRESS							=> (7 downto 1 => '0') & '-',
			ADDRESS_BITS						=> ADDRESS_BITS,
			DATA_BITS								=> DATA_BITS,
			ALLOW_MEALY_TRANSITION	=> TRUE
		)
		port map (
			Clock										=> Clock,
			Reset										=> Reset,
			
			-- IICController master interface
			Master_Request					=> Master_Request,
			Master_Grant						=> Master_Grant,
			Master_Command					=> Master_Command,
			Master_Status						=> Master_Status,
			Master_Error						=> Master_Error,
			
			Master_Address					=> Master_Address,
			
			Master_WP_Valid					=> Master_WP_Valid,
			Master_WP_Data					=> Master_WP_Data,
			Master_WP_Last					=> Master_WP_Last,
			Master_WP_Ack						=> Master_WP_Ack,
			Master_RP_Valid					=> Master_RP_Valid,
			Master_RP_Data					=> Master_RP_Data,
			Master_RP_Last					=> Master_RP_Last,
			Master_RP_Ack						=> Master_RP_Ack,
			
			-- tristate interface
			Serial									=> Master_Serial
		);
		
	blkSerialClock : block
		signal SerialClock_Wire	: std_logic;
		signal Master_Wire			: std_logic		:= 'Z';
		signal Slave1_Wire			: std_logic		:= 'Z';
		signal Slave2_Wire			: std_logic		:= 'Z';
	begin
		-- pullup resistor
		SerialClock_Wire			<= 'H';
		
		Master_Wire						<= 'L', '0' after 20 ns		when (Master_Serial.Clock.T = '0') else 'Z' after 100 ns;
		Slave1_Wire						<= 'L', '0' after 30 ns		when (Slave1_Serial.Clock.T = '0') else 'Z' after 200 ns;
		Slave2_Wire						<= 'L', '0' after 40 ns		when (Slave1_Serial.Clock.T = '0') else 'Z' after 300 ns;
		SerialClock_Wire			<= Master_Wire;
		SerialClock_Wire			<= Slave1_Wire;
		SerialClock_Wire			<= Slave2_Wire;
		
		-- readers
		Master_Serial.Clock.I	<= to_X01(SerialClock_Wire) after 40 ns;
		Slave1_Serial.Clock.I	<= to_X01(SerialClock_Wire) after 50 ns;
		Slave2_Serial.Clock.I	<= to_X01(SerialClock_Wire) after 60 ns;
	end block;
	
	blkSerialData : block
		signal SerialData_Wire	: std_logic;
		signal Master_Wire			: std_logic		:= 'Z';
		signal Slave1_Wire			: std_logic		:= 'Z';
		signal Slave2_Wire			: std_logic		:= 'Z';
	begin
		-- pullup resistor
		SerialData_Wire				<= 'H';
		
		-- drivers
		Master_Wire						<= 'L', '0' after 20 ns		when (Master_Serial.Data.T = '0') else 'Z' after 100 ns;
		Slave1_Wire						<= 'L', '0' after 30 ns		when (Slave1_Serial.Data.T = '0') else 'Z' after 200 ns;
		Slave2_Wire						<= 'L', '0' after 40 ns		when (Slave1_Serial.Data.T = '0') else 'Z' after 300 ns;
		SerialData_Wire				<= Master_Wire;
		SerialData_Wire				<= Slave1_Wire;
		SerialData_Wire				<= Slave2_Wire;
		
		-- readers
		Master_Serial.Data.I	<= to_X01(SerialData_Wire) after 40 ns;
		Slave1_Serial.Data.I	<= to_X01(SerialData_Wire) after 50 ns;
		Slave2_Serial.Data.I	<= to_X01(SerialData_Wire) after 60 ns;
	end block;
	
	procMaster : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Master Port");
	begin
		Master_Request		<= '0';
		Master_Command		<= IO_IIC_CMD_NONE;
		Master_Address		<= (others => '0');
		Master_WP_Valid		<= '0';
		Master_WP_Data		<= (others => '0');
		Master_WP_Last		<= '0';
		Master_RP_Ack			<= '0';
		wait until rising_edge(Clock);
		
		-- Execute Quick Command Write
		Master_Request		<= '1';
		wait until (Master_Grant	= '1') and rising_edge(Clock);
		simAssertion((Master_Status = IO_IIC_STATUS_IDLE), "Master is not idle.");
		simAssertion((Master_Error = IO_IIC_ERROR_NONE), "Master claims an error");
		
		Master_Command		<= IO_IIC_CMD_QUICKCOMMAND_WRITE;
		Master_Address		<= "0101011";
		wait until rising_edge(Clock);
		Master_Command		<= IO_IIC_CMD_NONE;
		Master_Address		<= (others => '0');
		simAssertion((Master_Status	= IO_IIC_STATUS_EXECUTING), "Master should execute the command");
		
		wait until (Master_Status	/= IO_IIC_STATUS_EXECUTING) and rising_edge(Clock);
		simAssertion((Master_Status	= IO_IIC_STATUS_EXECUTE_OK), "Master should execute the command");
		Master_Request		<= '0';
		wait until rising_edge(Clock);
		
		-- Execute Quick Command Read
		Master_Request		<= '1';
		wait until (Master_Grant	= '1') and rising_edge(Clock);
		simAssertion((Master_Status = IO_IIC_STATUS_IDLE), "Master is not idle.");
		simAssertion((Master_Error = IO_IIC_ERROR_NONE), "Master claims an error");
		
		Master_Command		<= IO_IIC_CMD_QUICKCOMMAND_READ;
		Master_Address		<= "0101011";
		wait until rising_edge(Clock);
		Master_Command		<= IO_IIC_CMD_NONE;
		Master_Address		<= (others => '0');
		simAssertion((Master_Status	= IO_IIC_STATUS_EXECUTING), "Master should execute the command");
		
		wait until (Master_Status	/= IO_IIC_STATUS_EXECUTING) and rising_edge(Clock);
		simAssertion((Master_Status	= IO_IIC_STATUS_EXECUTE_OK), "Master should execute the command");
		Master_Request		<= '0';
		wait until rising_edge(Clock);
		
		-- Send Bytes
		Master_Request		<= '1';
		wait until (Master_Grant	= '1') and rising_edge(Clock);
		simAssertion((Master_Status = IO_IIC_STATUS_IDLE), "Master is not idle.");
		simAssertion((Master_Error = IO_IIC_ERROR_NONE), "Master claims an error");
		
		Master_Command		<= IO_IIC_CMD_SEND_BYTES;
		Master_Address		<= "0100011";
		Master_WP_Data		<= x"DE";
		wait until rising_edge(Clock);
		Master_Command		<= IO_IIC_CMD_NONE;
		Master_Address		<= (others => '0');
		simAssertion((Master_Status	= IO_IIC_STATUS_SENDING), "Master should execute the command");
		
		-- Master_WP_Valid		<= '1';
		Master_WP_Data		<= x"AD";
		wait until (Master_WP_Ack = '1') and rising_edge(Clock);
		-- Master_WP_Valid		<= '1';
		Master_WP_Data		<= x"BE";
		wait until (Master_WP_Ack = '1') and rising_edge(Clock);
		-- Master_WP_Valid		<= '1';
		Master_WP_Data		<= x"EF";
		Master_WP_Last		<= '1';
		wait until (Master_WP_Ack = '1') and rising_edge(Clock);
		-- Master_WP_Valid		<= '0';
		Master_WP_Data		<= x"00";
		Master_WP_Last		<= '0';
		
		
		-- wait until (Master_Status	/= IO_IIC_STATUS_SENDING) and rising_edge(Clock);
		-- simAssertion((Master_Status	= IO_IIC_STATUS_EXECUTE_OK), "Master should execute the command");
		-- Master_Request		<= '0';
		-- wait until rising_edge(Clock);
		
		wait for 100 us;
		
		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;
	
	procAck : process
		constant simProcessID	: T_SIM_PROCESS_ID := simRegisterProcess("Acknolegements");
	begin
		Slave1_Serial.Clock.O		<= '0';
		Slave1_Serial.Clock.T		<= '1';
		Slave1_Serial.Data.O		<= '0';
		Slave1_Serial.Data.T		<= '1';
		
		-- ack impulse -> Quick Command Write
		for i in 1 to 9 loop
			wait until falling_edge(Slave1_Serial.Clock.I);
		end loop;
		
		wait for 100 ns;
		Slave1_Serial.Data.T		<= '0';
		wait until rising_edge(Slave1_Serial.Clock.I);
		wait for 50 ns;
		Slave1_Serial.Data.T		<= '1';
		wait until rising_edge(Slave1_Serial.Clock.I);
		
		-- ack impulse -> Quick Command Read
		for i in 1 to 9 loop
			wait until falling_edge(Slave1_Serial.Clock.I);
		end loop;
		
		wait for 100 ns;
		Slave1_Serial.Data.T		<= '0';
		wait until rising_edge(Slave1_Serial.Clock.I);
		wait for 50 ns;
		Slave1_Serial.Data.T		<= '1';
		wait until rising_edge(Slave1_Serial.Clock.I);
		
		-- ack impulse -> Send Bytes
		-- Address ACK
		for i in 1 to 9 loop
			wait until falling_edge(Slave1_Serial.Clock.I);
		end loop;
		
		wait for 100 ns;
		Slave1_Serial.Data.T		<= '0';
		wait until rising_edge(Slave1_Serial.Clock.I);
		wait for 50 ns;
		Slave1_Serial.Data.T		<= '1';
		
		-- Data 0 ACK
		for i in 1 to 9 loop
			wait until falling_edge(Slave1_Serial.Clock.I);
		end loop;
		
		wait for 100 ns;
		Slave1_Serial.Data.T		<= '0';
		wait until rising_edge(Slave1_Serial.Clock.I);
		wait for 50 ns;
		Slave1_Serial.Data.T		<= '1';
		
		-- Data 1 ACK
		for i in 1 to 9 loop
			wait until falling_edge(Slave1_Serial.Clock.I);
		end loop;
		
		wait for 100 ns;
		Slave1_Serial.Data.T		<= '0';
		wait until rising_edge(Slave1_Serial.Clock.I);
		wait for 50 ns;
		Slave1_Serial.Data.T		<= '1';
		
		-- Data 2 ACK
		for i in 1 to 9 loop
			wait until falling_edge(Slave1_Serial.Clock.I);
		end loop;
		
		wait for 100 ns;
		Slave1_Serial.Data.T		<= '0';
		wait until rising_edge(Slave1_Serial.Clock.I);
		wait for 50 ns;
		Slave1_Serial.Data.T		<= '1';
		
		-- Data 3 ACK
		for i in 1 to 9 loop
			wait until falling_edge(Slave1_Serial.Clock.I);
		end loop;
		
		wait for 100 ns;
		Slave1_Serial.Data.T		<= '0';
		wait until rising_edge(Slave1_Serial.Clock.I);
		wait for 50 ns;
		Slave1_Serial.Data.T		<= '1';
		wait until rising_edge(Slave1_Serial.Clock.I);
		
		
		-- disable this slave
		Slave1_Serial.Clock.T		<= '1';
		Slave1_Serial.Data.T		<= '1';
		
		-- This process is finished
		simDeactivateProcess(simProcessID);
		wait;  -- forever
	end process;
	
	
	i2c_vvc_if.scl				<= Slave2_Serial.Clock.I;
	Slave2_Serial.Clock.T	<= not i2c_vvc_if.scl;
	Slave2_Serial.Clock.O	<= '0';
	i2c_vvc_if.sda				<= Slave2_Serial.Clock.I;
	Slave2_Serial.Clock.T	<= not i2c_vvc_if.sda;
	Slave2_Serial.Clock.O	<= '0';
	
	
	IIC_VVC : entity bitvis_vip_i2c.i2c_vvc
		generic map (
			GC_INSTANCE_IDX                       => 1,  -- Instance index for this I2C_VVCT instance
			GC_MASTER_MODE                        => true,
			GC_I2C_CONFIG                         => C_I2C_BFM_CONFIG_DEFAULT,  -- Behavior specification for BFM
			GC_CMD_QUEUE_COUNT_MAX                => 1000,
			GC_CMD_QUEUE_COUNT_THRESHOLD          => 950,
			GC_CMD_QUEUE_COUNT_THRESHOLD_SEVERITY => warning
		)
		port map (
			i2c_vvc_if		=> i2c_vvc_if
		);
end architecture;
