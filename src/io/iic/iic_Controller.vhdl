-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					I2C Controller
--
-- Description:
-- -------------------------------------
-- The I2C Controller transmitts words over the I2C bus (SerialClock - SCL,
-- SerialData - SDA) and also receives them. This controller utilizes the
-- I2C BusController to send/receive bits over the I2C bus. This controller
-- is compatible to the System Management Bus (SMBus).
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

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.vectors.all;
use			PoC.physical.all;
use			PoC.components.all;
use			PoC.iic.all;


entity iic_Controller is
	generic (
		DEBUG										: boolean												:= FALSE;
		CLOCK_FREQ							: FREQ													:= 100 MHz;
		IIC_BUSMODE							: T_IO_IIC_BUSMODE							:= IO_IIC_BUSMODE_STANDARDMODE;
		IIC_ADDRESS							: std_logic_vector							:= (7 downto 1 => '0') & '-';
		ADDRESS_BITS						: positive											:= 7;
		DATA_BITS								: positive											:= 8;
		ALLOW_MEALY_TRANSITION	: boolean												:= TRUE
	);
	port (
		Clock										: in	std_logic;
		Reset										: in	std_logic;

		-- IICController master interface
		Master_Request					: in	std_logic;
		Master_Grant						: out	std_logic;
		Master_Command					: in	T_IO_IIC_COMMAND;
		Master_Status						: out	T_IO_IIC_STATUS;
		Master_Error						: out	T_IO_IIC_ERROR;

		Master_Address					: in	std_logic_vector(ADDRESS_BITS - 1 downto 0);

		Master_WP_Valid					: in	std_logic;
		Master_WP_Data					: in	std_logic_vector(DATA_BITS - 1 downto 0);
		Master_WP_Last					: in	std_logic;
		Master_WP_Ack						: out	std_logic;
		Master_RP_Valid					: out	std_logic;
		Master_RP_Data					: out	std_logic_vector(DATA_BITS - 1 downto 0);
		Master_RP_Last					: out	std_logic;
		Master_RP_Ack						: in	std_logic;

		-- tristate interface
		Serial									: inout T_IO_IIC_SERIAL
	);
end entity;


architecture rtl of iic_Controller is
	attribute KEEP									: boolean;
	attribute FSM_ENCODING					: string;
	attribute ENUM_ENCODING					: string;

	constant SMBUS_COMPLIANCE				: boolean				:= IIC_BUSMODE = IO_IIC_BUSMODE_SMBUS;

	-- if-then-else (ite)
	function ite(cond : boolean; value1 : T_IO_IIC_STATUS; value2 : T_IO_IIC_STATUS) return T_IO_IIC_STATUS is
	begin
		if cond then
			return value1;
		else
			return value2;
		end if;
	end;

	function to_IICBus_Command(value : std_logic) return T_IO_IICBUS_COMMAND is
	begin
		case value is
			when '0' =>			return IO_IICBUS_CMD_SEND_LOW;
			when '1' =>			return IO_IICBUS_CMD_SEND_HIGH;
			when others =>	return IO_IICBUS_CMD_NONE;
		end case;
	end;

	type T_STATE is (
		ST_IDLE,
		ST_REQUEST,
		ST_SAVE_ADDRESS,
		ST_SEND_START,							ST_SEND_START_WAIT,
		-- device address transmission 0
			ST_SEND_DEVICE_ADDRESS0,		ST_SEND_DEVICE_ADDRESS0_WAIT,
			ST_SEND_READWRITE0,					ST_SEND_READWRITE0_WAIT,
			ST_RECEIVE_ACK0,						ST_RECEIVE_ACK0_WAIT,
		-- send byte(s) operation => continue with data bytes
			ST_SEND_DATA1,							ST_SEND_DATA1_WAIT,
			ST_RECEIVE_ACK1,						ST_RECEIVE_ACK1_WAIT,
		-- receive byte(s) operation => continue with data bytes
			ST_RECEIVE_DATA2,						ST_RECEIVE_DATA2_WAIT,
			ST_SEND_ACK2,								ST_SEND_ACK2_WAIT,
			ST_SEND_NACK2,							ST_SEND_NACK2_WAIT,
		-- call operation => send byte(s), restart bus, resend device address, read byte(s)
		ST_SEND_RESTART3,						ST_SEND_RESTART3_WAIT,
			ST_SEND_DEVICE_ADDRESS3,		ST_SEND_DEVICE_ADDRESS3_WAIT,
			ST_SEND_READWRITE3,					ST_SEND_READWRITE3_WAIT,
			ST_RECEIVE_ACK3,						ST_RECEIVE_ACK3_WAIT,
			ST_RECEIVE_DATA3,						ST_RECEIVE_DATA3_WAIT,
			ST_SEND_ACK3,								ST_SEND_ACK3_WAIT,
			ST_SEND_NACK3,							ST_SEND_NACK3_WAIT,
		ST_SEND_STOP,								ST_SEND_STOP_WAIT,
		ST_COMPLETE,
		ST_ERROR,
			ST_ADDRESS_ERROR,
			ST_ACK_ERROR,
			ST_BUS_ERROR
	);

	signal State												: T_STATE													:= ST_IDLE;
	signal NextState										: T_STATE;
	attribute FSM_ENCODING of State			: signal is ite(DEBUG, "gray", ite((VENDOR = VENDOR_XILINX), "auto", "default"));

	signal Status_i											: T_IO_IIC_STATUS;
	signal Error_i											: T_IO_IIC_ERROR;

	signal Command_en										: std_logic;
	signal Command_d										: T_IO_IIC_COMMAND								:= IO_IIC_CMD_NONE;

	signal IICBC_Request								: std_logic;
	signal IICBC_Grant									: std_logic;
	signal IICBC_Command								: T_IO_IICBUS_COMMAND;
	signal IICBC_Status									: T_IO_IICBUS_STATUS;

	signal BitCounter_rst								: std_logic;
	signal BitCounter_en								: std_logic;
	signal BitCounter_us								: unsigned(3 downto 0)						:= (others => '0');

	signal RegOperation_en							: std_logic;
	signal RegOperation_d								: std_logic												:= '0';

	signal Device_Address_en						: std_logic;
	signal Device_Address_sh						: std_logic;
	signal Device_Address_d							: std_logic_vector(6 downto 0)		:= (others => '0');

	signal DataRegister_en							: std_logic;
	signal DataRegister_sh							: std_logic;
	signal DataRegister_d								: T_SLV_8													:= (others => '0');

	signal LastRegister_en							: std_logic;
	signal LastRegister_d								: std_logic												:= '0';

	signal SerialClock_t_i							: std_logic;
	signal SerialData_t_i								: std_logic;

begin

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				State			<= ST_IDLE;
			else
				State			<= NextState;
			end if;
		end if;
	end process;

	process(State, Master_Request, Master_Command, Command_d, IICBC_Grant, IICBC_Status, BitCounter_us, Device_Address_d, DataRegister_d, LastRegister_d)
		type T_CMDCAT is (NONE, SENDING, RECEIVING, EXECUTING, CALLING);
		variable CommandCategory	: T_CMDCAT;

	begin
		NextState									<= State;

		Status_i									<= IO_IIC_STATUS_IDLE;
		Error_i										<= IO_IIC_ERROR_NONE;

		Master_Grant							<= '0';

		Master_WP_Ack							<= '0';
		Master_RP_Valid						<= '0';
		Master_RP_Last						<= '0';

		Command_en								<= '0';
		Device_Address_en					<= '0';
		DataRegister_en						<= '0';
		LastRegister_en						<= '0';

		Device_Address_sh					<= '0';
		DataRegister_sh						<= '0';

		BitCounter_rst						<= '0';
		BitCounter_en							<= '0';

		IICBC_Request							<= '0';
		IICBC_Command							<= IO_IICBUS_CMD_NONE;

		-- precalculated command categories
		case Command_d is
			when IO_IIC_CMD_NONE =>									CommandCategory := NONE;
			when IO_IIC_CMD_QUICKCOMMAND_READ =>		CommandCategory := EXECUTING;
			when IO_IIC_CMD_QUICKCOMMAND_WRITE =>		CommandCategory := EXECUTING;
			when IO_IIC_CMD_SEND_BYTES =>						CommandCategory := SENDING;
			when IO_IIC_CMD_RECEIVE_BYTES =>				CommandCategory := RECEIVING;
			when IO_IIC_CMD_PROCESS_CALL =>					CommandCategory := CALLING;
			when others =>													CommandCategory := NONE;
		end case;

		case State is
			when ST_IDLE =>
				Status_i												<= IO_IIC_STATUS_IDLE;

				if (Master_Request = '1') then
					NextState											<= ST_REQUEST;

					if ALLOW_MEALY_TRANSITION then
						IICBC_Request								<= '1';

						if (IICBC_Grant = '1') then
							Master_Grant							<= '1';
							NextState									<= ST_SAVE_ADDRESS;
						end if;
					end if;
				end if;

			when ST_REQUEST =>
				IICBC_Request										<= '1';

				if (IICBC_Grant = '1') then
					Master_Grant									<= '1';
					NextState											<= ST_SAVE_ADDRESS;
				end if;

			when ST_SAVE_ADDRESS =>
				Master_Grant										<= IICBC_Grant;
				Status_i												<= IO_IIC_STATUS_IDLE;
				IICBC_Request										<= '1';

				case Master_Command is
					when IO_IIC_CMD_NONE =>
						null;

					when IO_IIC_CMD_QUICKCOMMAND_READ =>
						Command_en									<= '1';
						Device_Address_en						<= '1';

						NextState										<= ST_SEND_START;

					when IO_IIC_CMD_QUICKCOMMAND_WRITE =>
						Command_en									<= '1';
						Device_Address_en						<= '1';

						NextState										<= ST_SEND_START;

					when IO_IIC_CMD_SEND_BYTES =>
						Command_en									<= '1';
						Device_Address_en						<= '1';
						DataRegister_en							<= '1';
						LastRegister_en							<= '1';
						Master_WP_Ack								<= '1';

						NextState										<= ST_SEND_START;

					when IO_IIC_CMD_RECEIVE_BYTES =>
						Command_en									<= '1';
						Device_Address_en						<= '1';

						NextState										<= ST_SEND_START;

					when IO_IIC_CMD_PROCESS_CALL =>
						Command_en									<= '1';
						Device_Address_en						<= '1';
						DataRegister_en							<= '1';
						LastRegister_en							<= '1';
						Master_WP_Ack								<= '1';

						NextState										<= ST_SEND_START;

					when others =>
						NextState										<= ST_ERROR;

				end case;

			when ST_SEND_START =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when EXECUTING =>		Status_i	<= IO_IIC_STATUS_EXECUTING;
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_SEND_START_CONDITION;

				NextState												<= ST_SEND_START_WAIT;

			when ST_SEND_START_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when EXECUTING =>		Status_i	<= IO_IIC_STATUS_EXECUTING;
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>		NextState			<= ST_SEND_DEVICE_ADDRESS0;
					when IO_IICBUS_STATUS_ERROR =>						NextState			<= ST_BUS_ERROR;
					when others =>														NextState			<= ST_ERROR;
				end case;

			when ST_SEND_DEVICE_ADDRESS0 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when EXECUTING =>		Status_i	<= IO_IIC_STATUS_EXECUTING;
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';
				IICBC_Command										<= to_IICBus_Command(Device_Address_d(Device_Address_d'high));
				Device_Address_sh								<= '1';

				NextState												<= ST_SEND_DEVICE_ADDRESS0_WAIT;

			when ST_SEND_DEVICE_ADDRESS0_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when EXECUTING =>		Status_i	<= IO_IIC_STATUS_EXECUTING;
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>
						BitCounter_en								<= '1';

						if (BitCounter_us = (Device_Address_d'length - 1)) then
							NextState									<= ST_SEND_READWRITE0;
						else
							NextState									<= ST_SEND_DEVICE_ADDRESS0;
						end if;
					when IO_IICBUS_STATUS_ERROR =>		NextState			<= ST_BUS_ERROR;
					when others =>										NextState			<= ST_ERROR;
				end case;

			when ST_SEND_READWRITE0 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when EXECUTING =>		Status_i	<= IO_IIC_STATUS_EXECUTING;
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case Command_d is														-- write = 0; read = 1
					when IO_IIC_CMD_QUICKCOMMAND_READ =>	IICBC_Command		<= IO_IICBUS_CMD_SEND_HIGH;
					when IO_IIC_CMD_QUICKCOMMAND_WRITE =>	IICBC_Command		<= IO_IICBUS_CMD_SEND_LOW;
					when IO_IIC_CMD_SEND_BYTES =>					IICBC_Command		<= IO_IICBUS_CMD_SEND_LOW;
					when IO_IIC_CMD_RECEIVE_BYTES =>			IICBC_Command		<= IO_IICBUS_CMD_SEND_HIGH;
					when IO_IIC_CMD_PROCESS_CALL =>				IICBC_Command		<= IO_IICBUS_CMD_SEND_LOW;
					when others  =>												IICBC_Command		<= IO_IICBUS_CMD_NONE;
				end case;

				NextState												<= ST_SEND_READWRITE0_WAIT;

			when ST_SEND_READWRITE0_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when EXECUTING =>		Status_i	<= IO_IIC_STATUS_EXECUTING;
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>		NextState			<= ST_RECEIVE_ACK0;
					when IO_IICBUS_STATUS_ERROR =>						NextState			<= ST_BUS_ERROR;
					when others =>														NextState			<= ST_ERROR;
				end case;

			when ST_RECEIVE_ACK0 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when EXECUTING =>		Status_i	<= IO_IIC_STATUS_EXECUTING;
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				BitCounter_rst									<= '1';
				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_RECEIVE;

				NextState												<= ST_RECEIVE_ACK0_WAIT;

			when ST_RECEIVE_ACK0_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when EXECUTING =>		Status_i	<= IO_IIC_STATUS_EXECUTING;
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_RECEIVING =>									null;
					when IO_IICBUS_STATUS_RECEIVED_LOW =>								-- ACK
						case Command_d is
							when IO_IIC_CMD_QUICKCOMMAND_WRITE =>						NextState			<= ST_SEND_STOP;
							when IO_IIC_CMD_QUICKCOMMAND_READ =>						NextState			<= ST_SEND_STOP;
							when IO_IIC_CMD_SEND_BYTES =>										NextState			<= ST_SEND_DATA1;
							when IO_IIC_CMD_RECEIVE_BYTES =>								NextState			<= ST_RECEIVE_DATA2;
							when IO_IIC_CMD_PROCESS_CALL =>									NextState			<= ST_SEND_DATA1;
							when others =>																	NextState			<= ST_ERROR;
						end case;
					when IO_IICBUS_STATUS_RECEIVED_HIGH =>							-- NACK
						if SMBUS_COMPLIANCE then
																															NextState			<= ST_ACK_ERROR;			-- TODO: send stop
						else
							case Command_d is
								when IO_IIC_CMD_QUICKCOMMAND_WRITE =>					NextState			<= ST_ADDRESS_ERROR;	-- TODO: send stop
								when IO_IIC_CMD_QUICKCOMMAND_READ =>					NextState			<= ST_ADDRESS_ERROR;	-- TODO: send stop
								when IO_IIC_CMD_SEND_BYTES =>									NextState			<= ST_ADDRESS_ERROR;	-- TODO: send stop
								when IO_IIC_CMD_RECEIVE_BYTES =>							NextState			<= ST_ADDRESS_ERROR;	-- TODO: send stop
								when IO_IIC_CMD_PROCESS_CALL =>								NextState			<= ST_ADDRESS_ERROR;	-- TODO: send stop
								when others =>																NextState			<= ST_ERROR;
							end case;
						end if;
					when IO_IICBUS_STATUS_ERROR =>											NextState			<= ST_BUS_ERROR;
					when others =>																			NextState			<= ST_ERROR;
				end case;

			-- write operation => continue writing
			-- ======================================================================
			when ST_SEND_DATA1 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';
				IICBC_Command										<= to_IICBus_Command(DataRegister_d(DataRegister_d'high));
				DataRegister_sh									<= '1';

				NextState												<= ST_SEND_DATA1_WAIT;

			when ST_SEND_DATA1_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>
						BitCounter_en								<= '1';

						if (BitCounter_us = (DataRegister_d'length - 1)) then
							NextState									<= ST_RECEIVE_ACK1;
						else
							NextState									<= ST_SEND_DATA1;
						end if;
					when IO_IICBUS_STATUS_ERROR =>		NextState			<= ST_BUS_ERROR;
					when others =>										NextState			<= ST_ERROR;
				end case;

			when ST_RECEIVE_ACK1 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				BitCounter_rst									<= '1';
				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_RECEIVE;

				NextState												<= ST_RECEIVE_ACK1_WAIT;

			when ST_RECEIVE_ACK1_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_RECEIVING =>									null;
					when IO_IICBUS_STATUS_RECEIVED_LOW =>								-- ACK
						if (LastRegister_d = '1') then										-- no more byte to be send?
							case Command_d is
								when IO_IIC_CMD_SEND_BYTES =>		NextState	<= ST_SEND_STOP;			-- command complete, free bus
								when IO_IIC_CMD_PROCESS_CALL =>	NextState	<= ST_SEND_RESTART3;	-- bus turnaround
								when others =>									NextState	<= ST_ERROR;
							end case;
						else																							-- register next byte
							DataRegister_en		<= '1';
							LastRegister_en		<= '1';
							Master_WP_Ack			<= '1';

							NextState					<= ST_SEND_DATA1;
						end if;
					when IO_IICBUS_STATUS_RECEIVED_HIGH =>							-- NACK
						case Command_d is
							when IO_IIC_CMD_SEND_BYTES =>										NextState			<= ST_ACK_ERROR;				-- TODO: send stop
							when IO_IIC_CMD_PROCESS_CALL =>									NextState			<= ST_ACK_ERROR;				-- TODO: send stop
							when others =>																	NextState			<= ST_ERROR;
						end case;
					when IO_IICBUS_STATUS_ERROR =>											NextState			<= ST_BUS_ERROR;
					when others =>																			NextState			<= ST_ERROR;
				end case;


			-- read operation => continue with reading without restart
			-- ======================================================================
			when ST_RECEIVE_DATA2 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_RECEIVE;

				NextState												<= ST_RECEIVE_DATA2_WAIT;

			when ST_RECEIVE_DATA2_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_RECEIVING =>									null;
					when IO_IICBUS_STATUS_RECEIVED_LOW | IO_IICBUS_STATUS_RECEIVED_HIGH =>		-- LOW or HIGH
						BitCounter_en								<= '1';
						DataRegister_sh							<= '1';

						if (BitCounter_us = (DataRegister_d'length - 1)) then										-- current byte is full

-- FIXME: if receive abort is wished => send NACK
--
--							if ((Out_LastByte = '1') OR (Command_d = IO_IIC_CMD_READ_BYTE)) then
--								NextState								<= ST_SEND_NACK2;
--							else
								NextState								<= ST_SEND_ACK2;
--							end if;
						else
							NextState									<= ST_RECEIVE_DATA2;
						end if;
					when IO_IICBUS_STATUS_ERROR =>											NextState			<= ST_BUS_ERROR;
					when others =>																			NextState			<= ST_ERROR;
				end case;

			when ST_SEND_ACK2 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				BitCounter_rst									<= '1';
				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_SEND_LOW;			-- ACK

				NextState												<= ST_SEND_ACK2_WAIT;

			when ST_SEND_ACK2_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>		NextState			<= ST_RECEIVE_DATA2;			-- receive more bytes
					when IO_IICBUS_STATUS_ERROR =>						NextState			<= ST_BUS_ERROR;
					when others =>														NextState			<= ST_ERROR;
				end case;

			when ST_SEND_NACK2 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				BitCounter_rst									<= '1';
				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_SEND_HIGH;			-- NACK

				NextState												<= ST_SEND_NACK2_WAIT;

			when ST_SEND_NACK2_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>		NextState			<= ST_SEND_STOP;			-- receiving complete, free bus
					when IO_IICBUS_STATUS_ERROR =>						NextState			<= ST_BUS_ERROR;
					when others =>														NextState			<= ST_ERROR;
				end case;


			-- read operation after restart => continue with reading
			-- ======================================================================
			when ST_SEND_RESTART3 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_SEND_RESTART_CONDITION;

				NextState												<= ST_SEND_RESTART3_WAIT;

			when ST_SEND_RESTART3_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>		NextState			<= ST_SEND_DEVICE_ADDRESS3;
					when IO_IICBUS_STATUS_ERROR =>						NextState			<= ST_BUS_ERROR;
					when others =>														NextState			<= ST_ERROR;
				end case;

			when ST_SEND_DEVICE_ADDRESS3 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';
				IICBC_Command										<= to_IICBus_Command(Device_Address_d(Device_Address_d'high));
				Device_Address_sh								<= '1';

				NextState												<= ST_SEND_DEVICE_ADDRESS3_WAIT;

			when ST_SEND_DEVICE_ADDRESS3_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>
						BitCounter_en								<= '1';

						if (BitCounter_us = (Device_Address_d'length - 1)) then
							NextState									<= ST_SEND_READWRITE3;
						else
							NextState									<= ST_SEND_DEVICE_ADDRESS3;
						end if;
					when IO_IICBUS_STATUS_ERROR =>		NextState			<= ST_BUS_ERROR;
					when others =>										NextState			<= ST_ERROR;
				end case;

			when ST_SEND_READWRITE3 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_SEND_HIGH;			-- 1 = read

				NextState												<= ST_SEND_READWRITE3_WAIT;

			when ST_SEND_READWRITE3_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>		NextState			<= ST_RECEIVE_ACK3;
					when IO_IICBUS_STATUS_ERROR =>						NextState			<= ST_BUS_ERROR;
					when others =>														NextState			<= ST_ERROR;
				end case;

			when ST_RECEIVE_ACK3 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				BitCounter_rst									<= '1';
				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_RECEIVE;

				NextState												<= ST_RECEIVE_ACK3_WAIT;

			when ST_RECEIVE_ACK3_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_RECEIVING =>									null;
					when IO_IICBUS_STATUS_RECEIVED_LOW =>								-- ACK
						case Command_d is
							when IO_IIC_CMD_PROCESS_CALL =>									NextState			<= ST_RECEIVE_DATA3;
							when others =>																	NextState			<= ST_ERROR;
						end case;
					when IO_IICBUS_STATUS_RECEIVED_HIGH =>							-- NACK
						if SMBUS_COMPLIANCE then
																															NextState			<= ST_ACK_ERROR;			-- TODO: send stop
						else
							case Command_d is
								when IO_IIC_CMD_PROCESS_CALL =>								NextState			<= ST_ADDRESS_ERROR;	-- TODO: send stop
								when others =>																NextState			<= ST_ERROR;
							end case;
						end if;
					when IO_IICBUS_STATUS_ERROR =>											NextState			<= ST_BUS_ERROR;
					when others =>																			NextState			<= ST_ERROR;
				end case;

			when ST_RECEIVE_DATA3 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_RECEIVE;

				NextState												<= ST_RECEIVE_DATA3_WAIT;

			when ST_RECEIVE_DATA3_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_RECEIVING =>									null;
					when IO_IICBUS_STATUS_RECEIVED_LOW | IO_IICBUS_STATUS_RECEIVED_HIGH =>		-- LOW or HIGH
						BitCounter_en								<= '1';
						DataRegister_sh							<= '1';

						if (BitCounter_us = (DataRegister_d'length - 1)) then										-- current byte is full

-- FIXME: if receive abort is wished => send NACK
--
--							if ((Out_LastByte = '1') OR (Command_d = IO_IIC_CMD_READ_BYTE)) then
--								NextState								<= ST_SEND_NACK3;
--							else
								NextState								<= ST_SEND_ACK3;
--							end if;
						else
							NextState									<= ST_RECEIVE_DATA3;
						end if;
					when IO_IICBUS_STATUS_ERROR =>											NextState			<= ST_BUS_ERROR;
					when others =>																			NextState			<= ST_ERROR;
				end case;

			when ST_SEND_ACK3 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				BitCounter_rst									<= '1';
				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_SEND_LOW;			-- ACK

				NextState												<= ST_SEND_ACK3_WAIT;

			when ST_SEND_ACK3_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>		NextState			<= ST_RECEIVE_DATA3;			-- receive more bytes
					when IO_IICBUS_STATUS_ERROR =>						NextState			<= ST_BUS_ERROR;
					when others =>														NextState			<= ST_ERROR;
				end case;

			when ST_SEND_NACK3 =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				BitCounter_rst									<= '1';
				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_SEND_HIGH;			-- NACK

				NextState												<= ST_SEND_NACK3_WAIT;

			when ST_SEND_NACK3_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>		NextState			<= ST_SEND_STOP;			-- receiving complete, free bus
					when IO_IICBUS_STATUS_ERROR =>						NextState			<= ST_BUS_ERROR;
					when others =>														NextState			<= ST_ERROR;
				end case;

			when ST_SEND_STOP =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when EXECUTING =>		Status_i	<= IO_IIC_STATUS_EXECUTING;
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';
				IICBC_Command										<= IO_IICBUS_CMD_SEND_STOP_CONDITION;

				NextState												<= ST_SEND_STOP_WAIT;

			when ST_SEND_STOP_WAIT =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when EXECUTING =>		Status_i	<= IO_IIC_STATUS_EXECUTING;
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SENDING;
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVING;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALLING;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				case IICBC_Status is
					when IO_IICBUS_STATUS_SENDING =>					null;
					when IO_IICBUS_STATUS_SEND_COMPLETE =>		NextState			<= ST_COMPLETE;
					when IO_IICBUS_STATUS_ERROR =>						NextState			<= ST_BUS_ERROR;
					when others =>														NextState			<= ST_ERROR;
				end case;

-- ======================================================================

			when ST_COMPLETE =>
				Master_Grant										<= IICBC_Grant;
				case CommandCategory is
					when EXECUTING =>		Status_i	<= IO_IIC_STATUS_EXECUTE_OK;		-- TODO: IO_IIC_STATUS_EXECUTE_ERROR
					when SENDING =>			Status_i	<= IO_IIC_STATUS_SEND_COMPLETE;
					when RECEIVING =>		Status_i	<= IO_IIC_STATUS_RECEIVE_COMPLETE;
					when CALLING =>			Status_i	<= IO_IIC_STATUS_CALL_COMPLETE;
					when others =>			Status_i	<= ite(SIMULATION, IO_IIC_STATUS_ERROR, IO_IIC_STATUS_IDLE);
				end case;

				IICBC_Request										<= '1';

				NextState												<= ST_IDLE;

			when ST_BUS_ERROR =>
				Status_i												<= IO_IIC_STATUS_ERROR;
				Error_i													<= IO_IIC_ERROR_BUS_ERROR;

				-- FIXME: free bus ???

				NextState												<= ST_IDLE;

			when ST_ACK_ERROR =>
				Status_i												<= IO_IIC_STATUS_ERROR;
				Error_i													<= IO_IIC_ERROR_ACK_ERROR;

				-- FIXME: free bus !

				NextState												<= ST_IDLE;

			when ST_ADDRESS_ERROR =>
				Status_i												<= IO_IIC_STATUS_ERROR;
				Error_i													<= IO_IIC_ERROR_ADDRESS_ERROR;

				-- FIXME: free bus !

				NextState												<= ST_IDLE;

			when ST_ERROR =>
				Status_i												<= IO_IIC_STATUS_ERROR;
				Error_i													<= IO_IIC_ERROR_FSM;
				NextState												<= ST_IDLE;

		end case;
	end process;


	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or BitCounter_rst) = '1') then
				BitCounter_us						<= (others => '0');
			elsif (BitCounter_en	= '1') then
				BitCounter_us					<= BitCounter_us + 1;
			end if;
		end if;
	end process;

	process(Clock, IICBC_Status)
		variable DataRegister_si		: std_logic;
	begin
		case IICBC_Status is
			when IO_IICBUS_STATUS_RECEIVED_LOW =>			DataRegister_si	:= '0';
			when IO_IICBUS_STATUS_RECEIVED_HIGH =>		DataRegister_si	:= '1';
			when others =>														DataRegister_si	:= 'X';
		end case;

		if rising_edge(Clock) then
			if (Reset = '1') then
				Command_d							<= IO_IIC_CMD_NONE;
				Device_Address_d			<= (others => '0');
				DataRegister_d				<= (others => '0');
			else
				if (Command_en	= '1') then
					Command_d						<= Master_Command;
				end if;

				if (Device_Address_en	= '1') then
					Device_Address_d		<= Master_Address;
				elsif (Device_Address_sh = '1') then
					Device_Address_d		<= Device_Address_d(Device_Address_d'high - 1 downto 0) & Device_Address_d(Device_Address_d'high);
				end if;

				if (DataRegister_en	= '1') then
					DataRegister_d			<= Master_WP_Data;
				elsif (DataRegister_sh = '1') then
					DataRegister_d			<= DataRegister_d(DataRegister_d'high - 1 downto 0) & DataRegister_si;
				end if;

				if (LastRegister_en	= '1') then
					LastRegister_d			<= Master_WP_Last;
				end if;
			end if;
		end if;
	end process;

	Master_Status		<= Status_i;
	Master_Error		<= Error_i;

	Master_RP_Data	<= DataRegister_d;

	IICBC : entity PoC.iic_BusController
		generic map (
			CLOCK_FREQ							=> CLOCK_FREQ,
			IIC_BUSMODE							=> IIC_BUSMODE,
			ALLOW_MEALY_TRANSITION	=> ALLOW_MEALY_TRANSITION
		)
		port map (
			Clock										=> Clock,
			Reset										=> Reset,

			Request									=> IICBC_Request,
			Grant										=> IICBC_Grant,

			Command									=> IICBC_Command,
			Status									=> IICBC_Status,

			Serial									=> Serial
		);


	genDBG : if DEBUG generate
		-- Configuration
		constant DBG_TRIGGER_DELAY		: positive		:= 4;
		constant DBG_TRIGGER_WINDOWS	: positive		:= 6;

--		constant STATES		: POSITIVE		:= T_STATE'pos(ST_ERROR) + 1;
--		constant BITS			: POSITIVE		:= log2ceilnz(STATES);
		constant BITS			: positive		:= log2ceil(T_STATE'pos(T_STATE'high));

		function to_slv(State : T_STATE) return std_logic_vector is
		begin
			return to_slv(T_STATE'pos(State), BITS);
		end function;

		-- debugging signals
		type T_DBG_CHIPSCOPE is record
			Command						: T_IO_IIC_COMMAND;
			Status						: T_IO_IIC_STATUS;
			Device_Address		: std_logic_vector(6 downto 0);
			DataIn						: T_SLV_8;
			DataOut						: T_SLV_8;
			State							: std_logic_vector(BITS - 1 downto 0);
			IICBC_Command			: T_IO_IICBUS_COMMAND;
			IICBC_Status			: T_IO_IICBUS_STATUS;
			Clock_i						: std_logic;
			Clock_t						: std_logic;
			Data_i						: std_logic;
			Data_t						: std_logic;
		end record;

		type T_DBG_CHIPSCOPE_VECTOR	is array(natural range <>) of T_DBG_CHIPSCOPE;

		signal DBG_DebugVector_d		: T_DBG_CHIPSCOPE_VECTOR(DBG_TRIGGER_DELAY downto 0);

		-- edge detection FFs
		signal SerialClock_t_d			: std_logic																					:= '0';
		signal SerialData_t_d				: std_logic																					:= '0';

		-- trigger delay FFs / trigger valid-window FF
		signal Trigger_d						: std_logic_vector(DBG_TRIGGER_WINDOWS downto 0)		:= (others => '0');
		signal Valid_r							: std_logic																					:= '0';

		-- ChipScope trigger signals
		signal DBG_Trigger					: std_logic;
		signal DBG_Valid						: std_logic;

		-- ChipScope data signals
		signal DBG_Command					: T_IO_IIC_COMMAND;
		signal DBG_Status						: T_IO_IIC_STATUS;
		signal DBG_Device_Address		: std_logic_vector(ADDRESS_BITS - 1 downto 0);
		signal DBG_DataIn						: T_SLV_8;
		signal DBG_DataOut					: T_SLV_8;
		signal DBG_State						: std_logic_vector(BITS - 1 downto 0);
		signal DBG_IICBC_Command		: T_IO_IICBUS_COMMAND;
		signal DBG_IICBC_Status			: T_IO_IICBUS_STATUS;
		signal DBG_Clock_i					: std_logic;
		signal DBG_Clock_t					: std_logic;
		signal DBG_Data_i						: std_logic;
		signal DBG_Data_t						: std_logic;

--		constant DBG_temp						: STD_LOGIC_VECTOR		:= to_slv(ST_SEND_REGisTER_ADDRESS_WAIT);

		attribute KEEP of DBG_Command					: signal is TRUE;
		attribute KEEP of DBG_Status					: signal is TRUE;
		attribute KEEP of DBG_Device_Address	: signal is TRUE;
		attribute KEEP of DBG_DataIn					: signal is TRUE;
		attribute KEEP of DBG_DataOut					: signal is TRUE;
		attribute KEEP of DBG_State						: signal is TRUE;
		attribute KEEP of DBG_IICBC_Command		: signal is TRUE;
		attribute KEEP of DBG_IICBC_Status		: signal is TRUE;
		attribute KEEP of DBG_Clock_i					: signal is TRUE;
		attribute KEEP of DBG_Clock_t					: signal is TRUE;
		attribute KEEP of DBG_Data_i					: signal is TRUE;
		attribute KEEP of DBG_Data_t					: signal is TRUE;

		attribute KEEP of DBG_Trigger					: signal is TRUE;
		attribute KEEP of DBG_Valid						: signal is TRUE;

	begin
		DBG_DebugVector_d(0).Command					<= Master_Command;
		DBG_DebugVector_d(0).Status						<= Status_i;
		DBG_DebugVector_d(0).Device_Address		<= Master_Address;
		DBG_DebugVector_d(0).DataIn						<= Master_WP_Data;
		DBG_DebugVector_d(0).DataOut					<= DataRegister_d;
		DBG_DebugVector_d(0).State						<= to_slv(State);
		DBG_DebugVector_d(0).IICBC_Command		<= IICBC_Command;
		DBG_DebugVector_d(0).IICBC_Status			<= IICBC_Status;
		DBG_DebugVector_d(0).Clock_i					<= Serial.Clock.I;
		DBG_DebugVector_d(0).Clock_t					<= Serial.Clock.T;
		DBG_DebugVector_d(0).Data_i						<= Serial.Data.I;
		DBG_DebugVector_d(0).Data_t						<= Serial.Data.T;

		genDataDelay : for i in 0 to DBG_DebugVector_d'high - 1 generate
			DBG_DebugVector_d(i + 1)	<= DBG_DebugVector_d(i) when rising_edge(Clock);
		end generate;

		DBG_Command						<= DBG_DebugVector_d(DBG_DebugVector_d'high).Command;
		DBG_Status						<= DBG_DebugVector_d(DBG_DebugVector_d'high).Status;
		DBG_Device_Address		<= DBG_DebugVector_d(DBG_DebugVector_d'high).Device_Address;
		DBG_DataIn						<= DBG_DebugVector_d(DBG_DebugVector_d'high).DataIn;
		DBG_DataOut						<= DBG_DebugVector_d(DBG_DebugVector_d'high).DataOut;
		DBG_State							<= DBG_DebugVector_d(DBG_DebugVector_d'high).State;
		DBG_IICBC_Command			<= DBG_DebugVector_d(DBG_DebugVector_d'high).IICBC_Command;
		DBG_IICBC_Status			<= DBG_DebugVector_d(DBG_DebugVector_d'high).IICBC_Status;
		DBG_Clock_i						<= DBG_DebugVector_d(DBG_DebugVector_d'high).Clock_i;
		DBG_Clock_t						<= DBG_DebugVector_d(DBG_DebugVector_d'high).Clock_t;
		DBG_Data_i						<= DBG_DebugVector_d(DBG_DebugVector_d'high).Data_i;
		DBG_Data_t						<= DBG_DebugVector_d(DBG_DebugVector_d'high).Data_t;

		SerialClock_t_d				<= SerialClock_t_i		when rising_edge(Clock);
		SerialData_t_d				<= SerialData_t_i			when rising_edge(Clock);

		-- trigger on all edges and on all signal lines
		Trigger_d(0)					<= (SerialClock_t_i xor SerialClock_t_d) or
														 (SerialData_t_i	xor SerialData_t_d);

		genTriggerDelay : for i in 0 to Trigger_d'high - 1 generate
			Trigger_d(i + 1)		<= Trigger_d(i) when rising_edge(Clock);
		end generate;

		DBG_Trigger						<= Trigger_d(DBG_TRIGGER_DELAY);
		DBG_Valid							<= Trigger_d(0) or Valid_r;

		--											RS-FF:	Q					RST						SET								CLOCK
		Valid_r								<= ffrs(Valid_r, DBG_Trigger, Trigger_d(0)) when rising_edge(Clock);
	end generate;
end architecture;
