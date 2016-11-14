-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:					Patrick Lehmann
--
-- Entity:					I2C BusController
--
-- Description:
-- -------------------------------------
-- The I2C BusController transmitts bits over the I2C bus (SerialClock - SCL,
-- SerialData - SDA) and also receives them.	To send/receive words over the
-- I2C bus, use the I2C Controller, which utilizes this controller. This
-- controller is compatible to the System Management Bus (SMBus).
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
use			PoC.utils.all;
--use			PoC.strings.all;
--use			PoC.vectors.all;
use			PoC.physical.all;
use			PoC.components.all;
use			PoC.iic.all;


entity iic_BusController is
	generic (
		CLOCK_FREQ							: FREQ													:= 100 MHz;
		ADD_INPUT_SYNCHRONIZER	: boolean												:= FALSE;
		IIC_BUSMODE							: T_IO_IIC_BUSMODE							:= IO_IIC_BUSMODE_STANDARDMODE;			-- 100 kHz
		ALLOW_MEALY_TRANSITION	: boolean												:= TRUE
	);
	port (
		Clock										: in	std_logic;
		Reset										: in	std_logic;

		Request									: in	std_logic;
		Grant										: out	std_logic;
		Command									: in	T_IO_IICBUS_COMMAND;
		Status									: out	T_IO_IICBUS_STATUS;

		Serial									: inout T_IO_IIC_SERIAL
	);
end entity;

-- TODOs:
--	value read back and compare with written data => raise error, arbitration, multi-master?
--	multi-master support
--	receive START, RESTART, STOP
--	"clock stretching", clock synchronization
--	bus-state tracking / request/grant generation

architecture rtl of iic_BusController is
	attribute KEEP														: boolean;
	attribute FSM_ENCODING										: string;

	function getSpikeSupressionTime(IIC_BUSMODE : T_IO_IIC_BUSMODE) return time is
	begin
		if SIMULATION then											return 50 ns;	end if;
		case IIC_BUSMODE is
			when IO_IIC_BUSMODE_SMBUS =>					return 50 ns;
			when IO_IIC_BUSMODE_STANDARDMODE =>		return 50 ns;		-- Changed to 50 ns; original value from NXP UM 10204: 0 ns
			when IO_IIC_BUSMODE_FASTMODE =>				return 50 ns;
			when IO_IIC_BUSMODE_FASTMODEPLUS =>		return 50 ns;
			when IO_IIC_BUSMODE_HIGHSPEEDMODE =>	return 50 ns;
			when others =>												return 50 ns;
		end case;
	end function;

	function getBusFreeTime(IIC_BUSMODE : T_IO_IIC_BUSMODE) return time is
	begin
		if SIMULATION then											return 500 ns;	end if;
		case IIC_BUSMODE is
			when IO_IIC_BUSMODE_SMBUS =>					return 4700 ns;
			when IO_IIC_BUSMODE_STANDARDMODE =>		return 4700 ns;
			when IO_IIC_BUSMODE_FASTMODE =>				return 1300 ns;
			when IO_IIC_BUSMODE_FASTMODEPLUS =>		return 500 ns;
			when IO_IIC_BUSMODE_HIGHSPEEDMODE =>	return 0 ns;
			when others =>												return 0 ns;
		end case;
	end function;

	function getClockHighTime(IIC_BUSMODE : T_IO_IIC_BUSMODE) return time is
	begin
		if SIMULATION then											return 260 ns;	end if;
		case IIC_BUSMODE is
			when IO_IIC_BUSMODE_SMBUS =>					return 4000 ns;
			when IO_IIC_BUSMODE_STANDARDMODE =>		return 4000 ns;
			when IO_IIC_BUSMODE_FASTMODE =>				return 600 ns;
			when IO_IIC_BUSMODE_FASTMODEPLUS =>		return 260 ns;
			when IO_IIC_BUSMODE_HIGHSPEEDMODE =>	return 0 ns;
			when others =>												return 0 ns;
		end case;
	end function;

	function getClockLowTime(IIC_BUSMODE : T_IO_IIC_BUSMODE) return time is
	begin
		if SIMULATION then											return 500 ns;	end if;
		case IIC_BUSMODE is
			when IO_IIC_BUSMODE_SMBUS =>					return 4700 ns;
			when IO_IIC_BUSMODE_STANDARDMODE =>		return 4700 ns;
			when IO_IIC_BUSMODE_FASTMODE =>				return 1300 ns;
			when IO_IIC_BUSMODE_FASTMODEPLUS =>		return 500 ns;
			when IO_IIC_BUSMODE_HIGHSPEEDMODE =>	return 0 ns;
			when others =>												return 0 ns;
		end case;
	end function;

	function getSetupRepeatedStartTime(IIC_BUSMODE : T_IO_IIC_BUSMODE) return time is
	begin
		if SIMULATION then											return 260 ns;	end if;
		case IIC_BUSMODE is
			when IO_IIC_BUSMODE_SMBUS =>					return 4700 ns;
			when IO_IIC_BUSMODE_STANDARDMODE =>		return 4700 ns;
			when IO_IIC_BUSMODE_FASTMODE =>				return 600 ns;
			when IO_IIC_BUSMODE_FASTMODEPLUS =>		return 260 ns;
			when IO_IIC_BUSMODE_HIGHSPEEDMODE =>	return 0 ns;
			when others =>												return 0 ns;
		end case;
	end function;

	function getSetupStopTime(IIC_BUSMODE : T_IO_IIC_BUSMODE) return time is
	begin
		if SIMULATION then											return 260 ns;	end if;
		case IIC_BUSMODE is
			when IO_IIC_BUSMODE_SMBUS =>					return 4000 ns;
			when IO_IIC_BUSMODE_STANDARDMODE =>		return 4000 ns;
			when IO_IIC_BUSMODE_FASTMODE =>				return 600 ns;
			when IO_IIC_BUSMODE_FASTMODEPLUS =>		return 260 ns;
			when IO_IIC_BUSMODE_HIGHSPEEDMODE =>	return 0 ns;
			when others =>												return 0 ns;
		end case;
	end function;

	function getSetupDataTime(IIC_BUSMODE : T_IO_IIC_BUSMODE) return time is
	begin
		if SIMULATION then											return 50 ns;	end if;
		case IIC_BUSMODE is
			when IO_IIC_BUSMODE_SMBUS =>					return 250 ns;
			when IO_IIC_BUSMODE_STANDARDMODE =>		return 250 ns;
			when IO_IIC_BUSMODE_FASTMODE =>				return 100 ns;
			when IO_IIC_BUSMODE_FASTMODEPLUS =>		return 50 ns;
			when IO_IIC_BUSMODE_HIGHSPEEDMODE =>	return 0 ns;
			when others =>												return 0 ns;
		end case;
	end function;

	function getHoldDataTime(IIC_BUSMODE : T_IO_IIC_BUSMODE) return time is
	begin
		if SIMULATION then											return 0 ns;	end if;
		case IIC_BUSMODE is
			when IO_IIC_BUSMODE_SMBUS =>					return 300 ns;
			when IO_IIC_BUSMODE_STANDARDMODE =>		return 0 ns;
			when IO_IIC_BUSMODE_FASTMODE =>				return 0 ns;
			when IO_IIC_BUSMODE_FASTMODEPLUS =>		return 0 ns;
			when IO_IIC_BUSMODE_HIGHSPEEDMODE =>	return 0 ns;
			when others =>												return 0 ns;
		end case;
	end function;

	function getValidDataTime(IIC_BUSMODE : T_IO_IIC_BUSMODE) return time is
	begin
		if SIMULATION then											return 450 ns;	end if;
		case IIC_BUSMODE is
			when IO_IIC_BUSMODE_SMBUS =>					return 0 ns;
			when IO_IIC_BUSMODE_STANDARDMODE =>		return 3450 ns;
			when IO_IIC_BUSMODE_FASTMODE =>				return 900 ns;
			when IO_IIC_BUSMODE_FASTMODEPLUS =>		return 450 ns;
			when IO_IIC_BUSMODE_HIGHSPEEDMODE =>	return 0 ns;
			when others =>												return 0 ns;
		end case;
	end function;

	function getHoldClockAfterStartTime(IIC_BUSMODE : T_IO_IIC_BUSMODE) return time is
	begin
		if SIMULATION then											return 260 ns;	end if;
		case IIC_BUSMODE is
			when IO_IIC_BUSMODE_SMBUS =>					return 4000 ns;
			when IO_IIC_BUSMODE_STANDARDMODE =>		return 4000 ns;
			when IO_IIC_BUSMODE_FASTMODE =>				return 600 ns;
			when IO_IIC_BUSMODE_FASTMODEPLUS =>		return 260 ns;
			when IO_IIC_BUSMODE_HIGHSPEEDMODE =>	return 0 ns;
			when others =>												return 0 ns;
		end case;
	end function;

	-- Timing definitions
	constant TIME_SPIKE_SUPPRESSION						: time			:= getSpikeSupressionTime(IIC_BUSMODE);
	constant TIME_BUS_FREE										: time			:= getBusFreeTime(IIC_BUSMODE);
	constant TIME_CLOCK_HIGH									: time			:= getClockHighTime(IIC_BUSMODE);
	constant TIME_CLOCK_LOW										: time			:= getClockLowTime(IIC_BUSMODE);
	constant TIME_SETUP_REPEAT_START					: time			:= getSetupRepeatedStartTime(IIC_BUSMODE);
	constant TIME_SETUP_STOP									: time			:= getSetupStopTime(IIC_BUSMODE);
	constant TIME_SETUP_DATA									: time			:= getSetupDataTime(IIC_BUSMODE);
	constant TIME_HOLD_CLOCK_AFTER_START			: time			:= getHoldClockAfterStartTime(IIC_BUSMODE);
	constant TIME_HOLD_DATA										: time			:= getHoldDataTime(IIC_BUSMODE);
	constant TIME_VALID_DATA									: time			:= getValidDataTime(IIC_BUSMODE);

	-- Timing table ID
	constant TTID_BUS_FREE_TIME								: natural		:= 0;
	constant TTID_HOLD_CLOCK_AFTER_START			: natural		:= 1;
	constant TTID_CLOCK_LOW										: natural		:= 2;
	constant TTID_CLOCK_HIGH									: natural		:= 3;
	constant TTID_SETUP_REPEAT_START					: natural		:= 4;
	constant TTID_SETUP_STOP									: natural		:= 5;
	constant TTID_SETUP_DATA									: natural		:= 6;

	-- Timing table
	constant TIMING_TABLE											: T_NATVEC	:= (
		TTID_BUS_FREE_TIME						=> TimingToCycles(TIME_BUS_FREE,								CLOCK_FREQ),
		TTID_HOLD_CLOCK_AFTER_START		=> TimingToCycles(TIME_HOLD_CLOCK_AFTER_START,	CLOCK_FREQ),
		TTID_CLOCK_LOW								=> TimingToCycles(TIME_CLOCK_LOW,								CLOCK_FREQ),
		TTID_CLOCK_HIGH								=> TimingToCycles(TIME_CLOCK_HIGH,							CLOCK_FREQ),
		TTID_SETUP_REPEAT_START				=> TimingToCycles(TIME_SETUP_REPEAT_START,			CLOCK_FREQ),
		TTID_SETUP_STOP								=> TimingToCycles(TIME_SETUP_STOP,							CLOCK_FREQ)
	);

	-- Bus TimingCounter (BusTC)
	subtype T_BUSTC_SLOT_INDEX								is integer range 0 to TIMING_TABLE'length - 1;

	signal BusTC_en														: std_logic;
	signal BusTC_Load													: std_logic;
	signal BusTC_Slot													: T_BUSTC_SLOT_INDEX;
	signal BusTC_Timeout											: std_logic;

	constant SMBUS_COMPLIANCE									: boolean				:= IIC_BUSMODE = IO_IIC_BUSMODE_SMBUS;

	type T_BUS_STATE is (
		ST_BUS_IDLE,				-- allow start condition
		ST_BUS_NOT_FREE,		-- wait until free => and start
		ST_BUS_SLAVE,				-- receive
		ST_BUS_MASTER				-- low, high, restart, stop, receive
	);

	type T_STATE is (
		ST_RESET,
		ST_IDLE,
			ST_WAIT_BUS_FREE,
			ST_SEND_START_WAIT_BUS_FREE,
			ST_SEND_START,
				ST_SEND_START_WAIT_HOLD_CLOCK_AFTER_START,
			ST_SEND_RESTART_PULLDOWN_CLOCK,
				ST_SEND_RESTART_PULLDOWN_CLOCK_WAIT,
				ST_SEND_RESTART_RELEASE_CLOCK,
				ST_SEND_RESTART_CLOCK_RELEASED,
				ST_SEND_RESTART_CLOCK_HIGH_WAIT,
				ST_SEND_RESTART_PULLDOWN_DATA,
				ST_SEND_RESTART_WAIT_HOLD_CLOCK_AFTER_RESTART,
			ST_SEND_STOP_PULLDOWN_CLOCK,
				ST_SEND_STOP_PULLDOWN_CLOCK_WAIT,
				ST_SEND_STOP_RELEASE_CLOCK,
				ST_SEND_STOP_CLOCK_RELEASED,
				ST_SEND_STOP_CLOCK_HIGH_WAIT,
				ST_SEND_STOP_RELEASE_DATA,
			ST_SEND_HIGH_PULLDOWN_CLOCK,
				ST_SEND_HIGH_PULLDOWN_CLOCK_WAIT,
				ST_SEND_HIGH_RELEASE_CLOCK,
				ST_SEND_HIGH_CLOCK_RELEASED,
				ST_SEND_HIGH_CLOCK_HIGH_WAIT,
				ST_SEND_HIGH_READBACK_DATA,
			ST_SEND_LOW_PULLDOWN_CLOCK,
				ST_SEND_LOW_PULLDOWN_CLOCK_WAIT,
				ST_SEND_LOW_RELEASE_CLOCK,
				ST_SEND_LOW_CLOCK_RELEASED,
				ST_SEND_LOW_CLOCK_HIGH_WAIT,
				ST_SEND_LOW_READBACK_DATA,
		ST_SEND_COMPLETE,
			ST_RECEIVE_0,				ST_RECEIVE_1,				ST_RECEIVE_2,				ST_RECEIVE_3,
		ST_RECEIVE_COMPLETE,
		ST_ERROR,
			ST_BUS_ERROR
	);
	signal Bus_State										: T_BUS_STATE								:= ST_BUS_NOT_FREE;
	signal Bus_NextState								: T_BUS_STATE;

	signal State												: T_STATE										:= ST_RESET;
	signal NextState										: T_STATE;
	attribute FSM_ENCODING of State			: signal is "gray";

	signal SerialClock_t_r_set					: std_logic;
	signal SerialClock_t_r_rst					: std_logic;
	signal SerialData_t_r_set						: std_logic;
	signal SerialData_t_r_rst						: std_logic;

	signal Status_en										: std_logic;
	signal Status_nxt										: T_IO_IICBUS_STATUS;
	signal Status_d											: T_IO_IICBUS_STATUS				:= IO_IICBUS_STATUS_ERROR;

	signal SerialClock_raw							: std_logic;
	signal SerialClockIn								: std_logic;
	signal SerialClock_o_r							: std_logic									:= '0';
	signal SerialClock_t_r							: std_logic									:= '1';
	signal SerialClock_t_d							: std_logic									:= '1';

	signal SerialData_raw								: std_logic;
	signal SerialDataIn									: std_logic;
	signal SerialData_o_r								: std_logic									:= '0';
	signal SerialData_t_r								: std_logic									:= '1';
	signal SerialData_t_d								: std_logic									:= '1';

	attribute KEEP of SerialClockIn			: signal is TRUE;
	attribute KEEP of SerialDataIn			: signal is TRUE;

begin

	genSync0 : if not ADD_INPUT_SYNCHRONIZER generate
		SerialClock_raw		<= Serial.Clock.I;
		SerialData_raw		<= Serial.Data.I;
	end generate;
	genSync1 : if ADD_INPUT_SYNCHRONIZER generate
		sync : entity PoC.sync_Bits
			generic map (
				BITS			=> 2
			)
			port map (
				Clock			=> Clock,							-- Clock to be synchronized to
				Input(0)	=> Serial.Clock.I,		-- Data to be synchronized
				Input(1)	=> Serial.Data.I,			-- Data to be synchronized
				Output(0)	=> SerialClock_raw,		-- synchronised data
				Output(1)	=> SerialData_raw			-- synchronised data
			);
	end generate;

	-- Output D-FFs
	SerialClock_t_d		<= SerialClock_t_r		when rising_edge(Clock);
	Serial.Clock.T		<= SerialClock_t_d;
	Serial.Clock.O		<= '0';

	SerialData_t_d		<= SerialData_t_r			when rising_edge(Clock);
	Serial.Data.T			<= SerialData_t_d;
	Serial.Data.O			<= '0';

	genSpikeSupp0 : if (TIME_SPIKE_SUPPRESSION <= to_time(CLOCK_FREQ)) generate
		SerialClockIn	<= SerialClock_raw;
		SerialDataIn	<= SerialData_raw;
	end generate;
	genSpikeSupp1 : if TIME_SPIKE_SUPPRESSION > to_time(CLOCK_FREQ) generate
		constant SPIKE_SUPPRESSION_CYCLES		: natural := TimingToCycles(TIME_SPIKE_SUPPRESSION, CLOCK_FREQ);
	begin
		SerialClockGF : entity PoC.io_GlitchFilter
			generic map (
				HIGH_SPIKE_SUPPRESSION_CYCLES		=> SPIKE_SUPPRESSION_CYCLES,
				LOW_SPIKE_SUPPRESSION_CYCLES		=> SPIKE_SUPPRESSION_CYCLES
			)
			port map (
				Clock		=> Clock,
				Input		=> SerialClock_raw,
				Output	=> SerialClockIn
			);

		SerialDataGF : entity PoC.io_GlitchFilter
			generic map (
				HIGH_SPIKE_SUPPRESSION_CYCLES		=> SPIKE_SUPPRESSION_CYCLES,
				LOW_SPIKE_SUPPRESSION_CYCLES		=> SPIKE_SUPPRESSION_CYCLES
			)
			port map (
				Clock		=> Clock,
				Input		=> SerialData_raw,
				Output	=> SerialDataIn
			);
	end generate;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				State				<= ST_RESET;
				Status_d		<= IO_IICBUS_STATUS_ERROR;
			else
				State				<= NextState;
				if (Status_en = '1') then
					Status_d	<= Status_nxt;
				end if;
			end if;
		end if;
	end process;

	process(State, Request, Command, Status_d, SerialClockIn, SerialDataIn, BusTC_Timeout)
	begin
		NextState									<= State;

		Grant											<= '0';
		Status_en									<= '0';
		Status_nxt								<= IO_IICBUS_STATUS_IDLE;
		Status										<= IO_IICBUS_STATUS_IDLE;

		SerialClock_t_r_set				<= '0';
		SerialClock_t_r_rst				<= '0';
		SerialData_t_r_set				<= '0';
		SerialData_t_r_rst				<= '0';

		BusTC_en									<= '0';
		BusTC_Load								<= '0';
		BusTC_Slot								<= 0;

		case State is
			when ST_RESET =>
				Status								<= IO_IICBUS_STATUS_RESETING;
				BusTC_Load						<= '1';
				BusTC_Slot						<= TTID_BUS_FREE_TIME;

				NextState							<= ST_WAIT_BUS_FREE;

			when ST_WAIT_BUS_FREE =>
				Status								<= IO_IICBUS_STATUS_RESETING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_IDLE;
				end if;

			when ST_IDLE =>
				Status								<= IO_IICBUS_STATUS_IDLE;
				Grant									<= Request;

				BusTC_en							<= '1';				-- run counter for BusFreeTime

				-- test for busmode
				--	idle			=> allow start condition
				--	notfree		=> wait until free => and start
				--	slave			=> receive
				--	master		=> low, high, restart, stop, receive

				case Command is
					when IO_IICBUS_CMD_NONE =>											null;
					when IO_IICBUS_CMD_SEND_START_CONDITION =>			NextState		<= ST_SEND_START_WAIT_BUS_FREE;
					when IO_IICBUS_CMD_SEND_RESTART_CONDITION =>		NextState		<= ST_SEND_RESTART_PULLDOWN_CLOCK;
					when IO_IICBUS_CMD_SEND_STOP_CONDITION =>				NextState		<= ST_SEND_STOP_PULLDOWN_CLOCK;
					when IO_IICBUS_CMD_SEND_LOW =>									NextState		<= ST_SEND_LOW_PULLDOWN_CLOCK;
					when IO_IICBUS_CMD_SEND_HIGH =>									NextState		<= ST_SEND_HIGH_PULLDOWN_CLOCK;
					when IO_IICBUS_CMD_RECEIVE =>										NextState		<= ST_RECEIVE_0;
					when others =>																	NextState		<= ST_ERROR;
				end case;

			when ST_SEND_START_WAIT_BUS_FREE =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_SEND_START;
				end if;

			when ST_SEND_START =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				SerialData_t_r_rst		<= '1';													-- disable data-tristate => data = 0
				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_HOLD_CLOCK_AFTER_START;

				NextState							<= ST_SEND_START_WAIT_HOLD_CLOCK_AFTER_START;

			when ST_SEND_START_WAIT_HOLD_CLOCK_AFTER_START =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
--					SerialClock_t_r_rst	<= '1';													-- disable clock-tristate => clock = 0

					NextState						<= ST_SEND_COMPLETE;
				end if;

			when ST_SEND_RESTART_PULLDOWN_CLOCK =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				SerialClock_t_r_rst		<= '1';													-- disable clock-tristate => clock = 0
				SerialData_t_r_set		<= '1';													-- enable data-tristate => data = 1

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_CLOCK_LOW;

				NextState							<= ST_SEND_RESTART_PULLDOWN_CLOCK_WAIT;

			when ST_SEND_RESTART_PULLDOWN_CLOCK_WAIT =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_SEND_RESTART_RELEASE_CLOCK;
				end if;

			when ST_SEND_RESTART_RELEASE_CLOCK =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				SerialClock_t_r_set		<= '1';													-- enable clock-tristate => clock = 1

				if (SerialClockIn = '1') then
					NextState						<= ST_SEND_RESTART_CLOCK_RELEASED;
				end if;

			when ST_SEND_RESTART_CLOCK_RELEASED =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_SETUP_REPEAT_START;

				NextState							<= ST_SEND_RESTART_CLOCK_HIGH_WAIT;

			when ST_SEND_RESTART_CLOCK_HIGH_WAIT =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_SEND_RESTART_PULLDOWN_DATA;
				end if;

			when ST_SEND_RESTART_PULLDOWN_DATA =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				SerialData_t_r_rst		<= '1';													-- disable data-tristate => data = 0

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_HOLD_CLOCK_AFTER_START;

				NextState							<= ST_SEND_RESTART_WAIT_HOLD_CLOCK_AFTER_RESTART;

			when ST_SEND_RESTART_WAIT_HOLD_CLOCK_AFTER_RESTART =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
--					SerialClock_t_r_rst	<= '1';													-- disable clock-tristate => clock = 0

					NextState						<= ST_SEND_COMPLETE;
				end if;

			when ST_SEND_STOP_PULLDOWN_CLOCK =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				SerialClock_t_r_rst		<= '1';													-- disable clock-tristate => clock = 0
				SerialData_t_r_rst		<= '1';													-- disable data-tristate => data = 0

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_CLOCK_LOW;

				NextState							<= ST_SEND_STOP_PULLDOWN_CLOCK_WAIT;

			when ST_SEND_STOP_PULLDOWN_CLOCK_WAIT =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_SEND_STOP_RELEASE_CLOCK;
				end if;

			when ST_SEND_STOP_RELEASE_CLOCK =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				SerialClock_t_r_set		<= '1';													-- enable clock-tristate => clock = 1

				if (SerialClockIn = '1') then
					NextState						<= ST_SEND_STOP_CLOCK_RELEASED;
				end if;

			when ST_SEND_STOP_CLOCK_RELEASED =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_SETUP_STOP;

				NextState							<= ST_SEND_STOP_CLOCK_HIGH_WAIT;

			when ST_SEND_STOP_CLOCK_HIGH_WAIT =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_SEND_STOP_RELEASE_DATA;
				end if;

			when ST_SEND_STOP_RELEASE_DATA =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				SerialData_t_r_set		<= '1';													-- enable data-tristate => data = 1

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_BUS_FREE_TIME;

				NextState							<= ST_SEND_COMPLETE;

			when ST_SEND_HIGH_PULLDOWN_CLOCK =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				SerialClock_t_r_rst		<= '1';													-- disable clock-tristate => clock = 0
				SerialData_t_r_set		<= '1';													-- enable data-tristate => data = 1

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_CLOCK_LOW;

				NextState							<= ST_SEND_HIGH_PULLDOWN_CLOCK_WAIT;

			when ST_SEND_HIGH_PULLDOWN_CLOCK_WAIT =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_SEND_HIGH_RELEASE_CLOCK;
				end if;

			when ST_SEND_HIGH_RELEASE_CLOCK =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				SerialClock_t_r_set		<= '1';													-- enable clock-tristate => clock = 1

				if (SerialClockIn = '1') then
					NextState						<= ST_SEND_HIGH_CLOCK_RELEASED;
				end if;

			when ST_SEND_HIGH_CLOCK_RELEASED =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_CLOCK_HIGH;

				NextState							<= ST_SEND_HIGH_CLOCK_HIGH_WAIT;

			when ST_SEND_HIGH_CLOCK_HIGH_WAIT =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_SEND_HIGH_READBACK_DATA;
				end if;

			when ST_SEND_HIGH_READBACK_DATA =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;

				if (SerialDataIn = '1') then
					NextState						<= ST_SEND_COMPLETE;
				else
					NextState						<= ST_BUS_ERROR;
				end if;

			when ST_SEND_LOW_PULLDOWN_CLOCK =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				SerialClock_t_r_rst		<= '1';													-- disable clock-tristate => clock = 0
				SerialData_t_r_rst		<= '1';													-- disable data-tristate => data = 0

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_CLOCK_LOW;

				NextState							<= ST_SEND_LOW_PULLDOWN_CLOCK_WAIT;

			when ST_SEND_LOW_PULLDOWN_CLOCK_WAIT =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_SEND_LOW_RELEASE_CLOCK;
				end if;

			when ST_SEND_LOW_RELEASE_CLOCK =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				SerialClock_t_r_set		<= '1';													-- enable clock-tristate => clock = 1

				if (SerialClockIn = '1') then
					NextState						<= ST_SEND_LOW_CLOCK_RELEASED;
				end if;

			when ST_SEND_LOW_CLOCK_RELEASED =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_CLOCK_HIGH;

				NextState							<= ST_SEND_LOW_CLOCK_HIGH_WAIT;

			when ST_SEND_LOW_CLOCK_HIGH_WAIT =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_SEND_LOW_READBACK_DATA;
				end if;

			when ST_SEND_LOW_READBACK_DATA =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SENDING;

				if (SerialDataIn = '0') then
					NextState						<= ST_SEND_COMPLETE;
				else
					NextState						<= ST_BUS_ERROR;
				end if;

			when ST_SEND_COMPLETE =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_SEND_COMPLETE;
				BusTC_en							<= '1';

				NextState							<= ST_IDLE;

			when ST_RECEIVE_0 =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_RECEIVING;
				SerialClock_t_r_rst		<= '1';													-- disable clock-tristate => clock = 0
				SerialData_t_r_set		<= '1';													-- enable data-tristate => data = Z

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_CLOCK_LOW;

				NextState							<= ST_RECEIVE_1;

			when ST_RECEIVE_1 =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_RECEIVING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_RECEIVE_2;
				end if;

			when ST_RECEIVE_2 =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_RECEIVING;
				Status_en							<= '1';

				SerialClock_t_r_set		<= '1';													-- disable clock-tristate => clock = 1

				if (SerialDataIn = '0') then
					Status_nxt					<= IO_IICBUS_STATUS_RECEIVED_LOW;
				elsif (SerialDataIn = '1') then
					Status_nxt					<= IO_IICBUS_STATUS_RECEIVED_HIGH;
				else
					Status_nxt					<= IO_IICBUS_STATUS_ERROR;
				end if;

				BusTC_Load						<= '1';													-- load timing counter
				BusTC_Slot						<= TTID_CLOCK_HIGH;

				NextState							<= ST_RECEIVE_3;

			when ST_RECEIVE_3 =>
				Grant									<= '1';
				Status								<= IO_IICBUS_STATUS_RECEIVING;
				BusTC_en							<= '1';

				if (BusTC_Timeout = '1') then
					NextState						<= ST_RECEIVE_COMPLETE;
				end if;

			when ST_RECEIVE_COMPLETE =>
				Grant									<= '1';
				Status								<= Status_d;
				NextState							<= ST_IDLE;

			when ST_ERROR =>
				Status								<= IO_IICBUS_STATUS_ERROR;
				NextState							<= ST_IDLE;

			when ST_BUS_ERROR =>
				Status								<= IO_IICBUS_STATUS_BUS_ERROR;
				NextState							<= ST_IDLE;

			when others =>
				Status								<= IO_IICBUS_STATUS_ERROR;
				NextState							<= ST_IDLE;

		end case;
	end process;

	SerialClock_t_r		<= ffrs(q => SerialClock_t_r,	rst => SerialClock_t_r_rst,	set => (Reset or SerialClock_t_r_set))	when rising_edge(Clock);
	SerialData_t_r		<= ffrs(q => SerialData_t_r,	rst => SerialData_t_r_rst,	set => (Reset or SerialData_t_r_set))	when rising_edge(Clock);


	BusTC : entity PoC.io_TimingCounter
		generic map (
			TIMING_TABLE				=> TIMING_TABLE												-- timing table
		)
		port map (
			Clock								=> Clock,															-- clock
			Enable							=> BusTC_en,													-- enable counter
			Load								=> BusTC_Load,												-- load Timing Value from TIMING_TABLE selected by slot
			Slot								=> BusTC_Slot,												--
			Timeout							=> BusTC_Timeout											-- timing reached
		);
end architecture;
