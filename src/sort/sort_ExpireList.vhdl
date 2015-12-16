-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Module:				 	TODO
--
-- Authors:				 	Patrick Lehmann
-- 
-- Description:
-- ------------------------------------
--		TODO
--
-- License:
-- ============================================================================
-- Copyright 2007-2014 Technische Universitaet Dresden - Germany
--										 Chair for VLSI-Design, Diagnostics and Architecture
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

LIBRARY IEEE;
USE			IEEE.STD_LOGIC_1164.ALL;
USE			IEEE.NUMERIC_STD.ALL;

LIBRARY PoC;
USE			PoC.utils.ALL;

-- list_expire_fixed
--		expire	= list of expireable items
--		fixed		= insert_time := current_time + fixed interval

ENTITY list_expire IS
	GENERIC (
		CLOCK_CYCLE_TICKS					: POSITIVE												:= 1024;
		EXPIRATION_TIME_TICKS			: NATURAL													:= 10;
		ELEMENTS									: POSITIVE												:= 32;
		KEY_BITS									: POSITIVE												:= 4
	);
	PORT (
		Clock											: IN	STD_LOGIC;
		Reset											: IN	STD_LOGIC;
		
		Tick											: IN	STD_LOGIC;
		
		Insert										: IN	STD_LOGIC;
		KeyIn											: IN	STD_LOGIC_VECTOR(KEY_BITS - 1 DOWNTO 0);
		
		Expired										: OUT	STD_LOGIC;
		KeyOut										: OUT	STD_LOGIC_VECTOR(KEY_BITS - 1 DOWNTO 0)
	);
END;


ARCHITECTURE rtl OF list_expire IS
	ATTRIBUTE KEEP										: BOOLEAN;

	CONSTANT CLOCK_BITS								: POSITIVE																								:= log2ceilnz(CLOCK_CYCLE_TICKS);
	
	SIGNAL CurrentTime_us							: UNSIGNED(CLOCK_BITS - 1 DOWNTO 0)												:= (OTHERS => '0');
	SIGNAL KeyTime_us									: UNSIGNED(CLOCK_BITS + KEY_BITS - 1 DOWNTO KEY_BITS);
	
	SIGNAL FIFO_put										: STD_LOGIC;
	SIGNAL FIFO_DataIn								: STD_LOGIC_VECTOR(CLOCK_BITS + KEY_BITS - 1 DOWNTO 0);
	SIGNAL FIFO_Full									: STD_LOGIC;
	SIGNAL FIFO_got										: STD_LOGIC;
	SIGNAL FIFO_DataOut								: STD_LOGIC_VECTOR(CLOCK_BITS + KEY_BITS - 1 DOWNTO 0);
	SIGNAL FIFO_Valid									: STD_LOGIC;
	
	SIGNAL Expired_i									: STD_LOGIC;
	
BEGIN

	PROCESS(Clock)
	BEGIN
		IF rising_edge(Clock) THEN
			IF (Reset = '1') THEN
				CurrentTime_us	<= (OTHERS => '0');
			ELSE
				IF (Tick = '1') THEN
					CurrentTime_us	<= CurrentTime_us + 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	KeyTime_us											<= CurrentTime_us + EXPIRATION_TIME_TICKS;

	FIFO_put												<= Insert;
	FIFO_DataIn(KeyIn'range)				<= KeyIn;
	FIFO_DataIn(KeyTime_us'range)		<= std_logic_vector(KeyTime_us);

	FIFO : ENTITY PoC.fifo_cc_got
		GENERIC MAP (
			D_BITS							=> CLOCK_BITS + KEY_BITS,		-- Data Width
			MIN_DEPTH						=> ELEMENTS,								-- Minimum FIFO Depth
			DATA_REG						=> TRUE,										-- Store Data Content in Registers
			STATE_REG						=> TRUE,										-- Registered Full/Empty Indicators
			OUTPUT_REG					=> FALSE,										-- Registered FIFO Output
			ESTATE_WR_BITS			=> 0,												-- Empty State Bits
			FSTATE_RD_BITS			=> 0												-- Full State Bits
		)
		PORT MAP (
			-- Global Reset and Clock
			clk									=> Clock,
			rst									=> Reset,
			
			-- Writing Interface
			put									=> FIFO_put,
			din									=> FIFO_DataIn,
			full								=> OPEN,--FIFO_Full,
			estate_wr						=> OPEN,

			-- Reading Interface
			got									=> FIFO_got,
			dout								=> FIFO_DataOut,
			valid								=> FIFO_Valid,
			fstate_rd						=> OPEN
		);

	FIFO_got			<= Expired_i;

	Expired_i			<= to_sl(FIFO_DataOut(KeyTime_us'range) = std_logic_vector(CurrentTime_us)) AND FIFO_Valid;

	Expired				<= Expired_i;
	KeyOut				<= FIFO_DataOut(KeyIn'range);
END ARCHITECTURE;
