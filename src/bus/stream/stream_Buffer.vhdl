-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Patrick Lehmann
-- 
-- Module:				 	A generic buffer module for the PoC.Stream protocol.
--
-- Description:
-- ------------------------------------
--		This module implements a generic buffer (FifO) for the PoC.Stream protocol.
--		It is generic in DATA_BITS and in META_BITS as well as in FifO depths for
--		data and meta information.
--
-- License:
-- ============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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
-- WITHOUT WARRANTIES OR CONDITIONS of ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- ============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			IEEE.NUMERIC_STD.all;

library PoC;
use			PoC.config.all;
use			PoC.utils.all;
use			PoC.vectors.all;


entity Stream_Buffer is
	generic (
		FRAMES												: POSITIVE																								:= 2;
		DATA_BITS											: POSITIVE																								:= 8;
		DATA_FifO_DEPTH								: POSITIVE																								:= 8;
		META_BITS											: T_POSVEC																								:= (0 => 8);
		META_FifO_DEPTH								: T_POSVEC																								:= (0 => 16)
	);
	port (
		Clock													: in	STD_LOGIC;
		Reset													: in	STD_LOGIC;
		-- IN Port
		In_Valid											: in	STD_LOGIC;
		In_Data												: in	STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);
		In_SOF												: in	STD_LOGIC;
		In_EOF												: in	STD_LOGIC;
		In_Ack												: out	STD_LOGIC;
		In_Meta_rst										: out	STD_LOGIC;
		In_Meta_nxt										: out	STD_LOGIC_VECTOR(META_BITS'length - 1 downto 0);
		In_Meta_Data									: in	STD_LOGIC_VECTOR(isum(META_BITS) - 1 downto 0);
		-- OUT Port
		Out_Valid											: out	STD_LOGIC;
		Out_Data											: out	STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);
		Out_SOF												: out	STD_LOGIC;
		Out_EOF												: out	STD_LOGIC;
		Out_Ack												: in	STD_LOGIC;
		Out_Meta_rst									: in	STD_LOGIC;
		Out_Meta_nxt									: in	STD_LOGIC_VECTOR(META_BITS'length - 1 downto 0);
		Out_Meta_Data									: out	STD_LOGIC_VECTOR(isum(META_BITS) - 1 downto 0)
	);
end;

architecture rtl of Stream_Buffer is
	attribute KEEP										: BOOLEAN;
	attribute FSM_ENCODING						: STRING;

	constant META_STREAMS							: POSITIVE																						:= META_BITS'length;

	type T_WRITER_STATE is (ST_IDLE, ST_FRAME);
	type T_READER_STATE is (ST_IDLE, ST_FRAME);
	
	signal Writer_State								: T_WRITER_STATE																			:= ST_IDLE;
	signal Writer_NextState						: T_WRITER_STATE;
	signal Reader_State								: T_READER_STATE																			:= ST_IDLE;
	signal Reader_NextState						: T_READER_STATE;

	constant EOF_BIT									: NATURAL																							:= DATA_BITS;

	signal DataFifO_put								: STD_LOGIC;
	signal DataFifO_DataIn						: STD_LOGIC_VECTOR(DATA_BITS downto 0);
	signal DataFifO_Full							: STD_LOGIC;
	
	signal DataFifO_got								: STD_LOGIC;
	signal DataFifO_DataOut						: STD_LOGIC_VECTOR(DataFifO_DataIn'range);
	signal DataFifO_Valid							: STD_LOGIC;

	signal FrameCommit								: STD_LOGIC;
	signal Meta_rst										: STD_LOGIC_VECTOR(META_BITS'length - 1 downto 0);

begin
	assert (META_BITS'length = META_FifO_DEPTH'length) report "META_BITS'length /= META_FifO_DEPTH'length" severity FAILURE;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				Writer_State					<= ST_IDLE;
				Reader_State					<= ST_IDLE;
			else
				Writer_State					<= Writer_NextState;
				Reader_State					<= Reader_NextState;
			end if;
		end if;
	end process;

	process(Writer_State,
					In_Valid, In_Data, In_SOF, In_EOF,
					DataFifO_Full)
	begin
		Writer_NextState									<= Writer_State;
		
		In_Ack														<= '0';
		
		DataFifO_put											<= '0';
		DataFifO_DataIn(In_Data'range)		<= In_Data;
		DataFifO_DataIn(EOF_BIT)					<= In_EOF;
		
		case Writer_State is
			when ST_IDLE =>
				In_Ack												<= NOT DataFifO_Full;
				DataFifO_put									<= In_Valid;
						
				if ((In_Valid AND In_SOF AND NOT In_EOF) = '1') then
					
					Writer_NextState						<= ST_FRAME;
				end if;
				
			when ST_FRAME =>
				In_Ack												<= NOT DataFifO_Full;
				DataFifO_put									<= In_Valid;
			
				if ((In_Valid AND In_EOF AND NOT DataFifO_Full) = '1') then
				
					Writer_NextState						<= ST_IDLE;
				end if;
		end case;
	end process;
	

	process(Reader_State,
					Out_Ack,
					DataFifO_Valid, DataFifO_DataOut)
	begin
		Reader_NextState								<= Reader_State;
		
		Out_Valid												<= '0';
		Out_Data												<= DataFifO_DataOut(Out_Data'range);
		Out_SOF													<= '0';
		Out_EOF													<= DataFifO_DataOut(EOF_BIT);
		
		DataFifO_got										<= '0';
	
		case Reader_State is
			when ST_IDLE =>
				Out_Valid										<= DataFifO_Valid;
				Out_SOF											<= '1';
				DataFifO_got								<= Out_Ack;
			
				if ((DataFifO_Valid AND NOT DataFifO_DataOut(EOF_BIT) AND Out_Ack) = '1') then
					Reader_NextState					<= ST_FRAME;
				end if;
			
			when ST_FRAME =>
				Out_Valid										<= DataFifO_Valid;
				DataFifO_got								<= Out_Ack;

				if ((DataFifO_Valid AND DataFifO_DataOut(EOF_BIT) AND Out_Ack) = '1') then
					Reader_NextState					<= ST_IDLE;
				end if;

		end case;
	end process;
	
	DataFifO : entity PoC.fifo_cc_got
		generic map (
			D_BITS							=> DATA_BITS + 1,								-- Data Width
			MIN_DEPTH						=> (DATA_FifO_DEPTH * FRAMES),	-- Minimum FifO Depth
			DATA_REG						=> ((DATA_FifO_DEPTH * FRAMES) <= 128),											-- Store Data Content in Registers
			STATE_REG						=> TRUE,												-- Registered Full/Empty Indicators
			OUTPUT_REG					=> FALSE,												-- Registered FifO Output
			ESTATE_WR_BITS			=> 0,														-- Empty State Bits
			FSTATE_RD_BITS			=> 0														-- Full State Bits
		)
		port map (
			-- Global Reset and Clock
			clk									=> Clock,
			rst									=> Reset,
			
			-- Writing Interface
			put									=> DataFifO_put,
			din									=> DataFifO_DataIn,
			full								=> DataFifO_Full,
			estate_wr						=> OPEN,

			-- Reading Interface
			got									=> DataFifO_got,
			dout								=> DataFifO_DataOut,
			valid								=> DataFifO_Valid,
			fstate_rd						=> OPEN
		);
	
	FrameCommit		<= DataFifO_Valid AND DataFifO_DataOut(EOF_BIT) AND Out_Ack;
	In_Meta_rst		<= slv_and(Meta_rst);
	
	genMeta : for i in 0 to META_BITS'length - 1 generate
		
	begin
		genReg : if (META_FifO_DEPTH(i) = 1) generate
			signal MetaReg_DataIn				: STD_LOGIC_VECTOR(META_BITS(i) - 1 downto 0);
			signal MetaReg_d						: STD_LOGIC_VECTOR(META_BITS(i) - 1 downto 0)		:= (others => '0');
			signal MetaReg_DataOut			: STD_LOGIC_VECTOR(META_BITS(i) - 1 downto 0);
		begin
			MetaReg_DataIn		<= In_Meta_Data(high(META_BITS, I) downto low(META_BITS, I));
		
			process(Clock)
			begin
				if rising_edge(Clock) then
					if (Reset = '1') then
						MetaReg_d			<= (others => '0');
					else
						if ((In_Valid AND In_SOF) = '1') then
							MetaReg_d		<= MetaReg_DataIn;
						end if;
					end if;
				end if;
			end process;
			
			MetaReg_DataOut		<= MetaReg_d;
			Out_Meta_Data(high(META_BITS, I) downto low(META_BITS, I))	<= MetaReg_DataOut;
		end generate;	-- META_FifO_DEPTH(i) = 1
		genFifO : if (META_FifO_DEPTH(i) > 1) generate
			signal MetaFifO_put								: STD_LOGIC;
			signal MetaFifO_DataIn						: STD_LOGIC_VECTOR(META_BITS(i) - 1 downto 0);
			signal MetaFifO_Full							: STD_LOGIC;
			
			signal MetaFifO_Commit						: STD_LOGIC;
			signal MetaFifO_Rollback					: STD_LOGIC;
			
			signal MetaFifO_got								: STD_LOGIC;
			signal MetaFifO_DataOut						: STD_LOGIC_VECTOR(MetaFifO_DataIn'range);
			signal MetaFifO_Valid							: STD_LOGIC;
			
			signal Writer_CounterControl			: STD_LOGIC																																:= '0';
			signal Writer_Counter_en					: STD_LOGIC;
			signal Writer_Counter_us					: UNSIGNED(log2ceilnz(META_FifO_DEPTH(i)) - 1 downto 0)										:= (others => '0');
		begin
			process(Clock)
			begin
				if rising_edge(Clock) then
					if (Reset = '1') then
						Writer_CounterControl			<= '0';
					else
						if ((In_Valid AND In_SOF) = '1') then
							Writer_CounterControl		<= '1';
						ELSif (Writer_Counter_us = (META_FifO_DEPTH(i) - 1)) then
							Writer_CounterControl		<= '0';
						end if;
					end if;
				end if;
			end process;
		
			Writer_Counter_en		<= (In_Valid AND In_SOF) OR Writer_CounterControl;
			
			process(Clock)
			begin
				if rising_edge(Clock) then
					if (Writer_Counter_en = '0') then
						Writer_Counter_us					<= (others => '0');
					else
						Writer_Counter_us					<= Writer_Counter_us + 1;
					end if;
				end if;
			end process;
			
			Meta_rst(i)					<= NOT Writer_Counter_en;
			In_Meta_nxt(i)			<= Writer_Counter_en;
			
			MetaFifO_put				<= Writer_Counter_en;
			MetaFifO_DataIn			<= In_Meta_Data(high(META_BITS, I) downto low(META_BITS, I));
		
			MetaFifO : entity PoC.fifo_cc_got_tempgot
				generic map (
					D_BITS							=> META_BITS(i),										-- Data Width
					MIN_DEPTH						=> (META_FifO_DEPTH(i) * FRAMES),		-- Minimum FifO Depth
					DATA_REG						=> TRUE,														-- Store Data Content in Registers
					STATE_REG						=> FALSE,														-- Registered Full/Empty Indicators
					OUTPUT_REG					=> FALSE,														-- Registered FifO Output
					ESTATE_WR_BITS			=> 0,																-- Empty State Bits
					FSTATE_RD_BITS			=> 0																-- Full State Bits
				)
				port map (
					-- Global Reset and Clock
					clk									=> Clock,
					rst									=> Reset,
					
					-- Writing Interface
					put									=> MetaFifO_put,
					din									=> MetaFifO_DataIn,
					full								=> MetaFifO_Full,
					estate_wr						=> OPEN,

					-- Reading Interface
					got									=> MetaFifO_got,
					dout								=> MetaFifO_DataOut,
					valid								=> MetaFifO_Valid,
					fstate_rd						=> OPEN,

					commit							=> MetaFifO_Commit,
					rollback						=> MetaFifO_Rollback
				);
		
			MetaFifO_got				<= Out_Meta_nxt(i);
			MetaFifO_Commit			<= FrameCommit;
			MetaFifO_Rollback		<= Out_Meta_rst;
		
			Out_Meta_Data(high(META_BITS, I) downto low(META_BITS, I))	<= MetaFifO_DataOut;
		end generate;	-- (META_FifO_DEPTH(i) > 1)
	end generate;
end;
