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
--		This module implements a generic buffer (FIFO) for the PoC.Stream protocol.
--		It is generic in DATA_BITS and in META_BITS as well as in FIFO depths for
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


entity stream_Buffer is
	generic (
		FRAMES												: POSITIVE																								:= 2;
		DATA_BITS											: POSITIVE																								:= 8;
		DATA_FIFO_DEPTH								: POSITIVE																								:= 8;
		META_BITS											: T_POSVEC																								:= (0 => 8);
		META_FIFO_DEPTH								: T_POSVEC																								:= (0 => 16)
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
end entity;


architecture rtl of stream_Buffer is
	attribute FSM_ENCODING						: STRING;

	constant META_STREAMS							: POSITIVE																						:= META_BITS'length;

	type T_WRITER_STATE is (ST_IDLE, ST_FRAME);
	type T_READER_STATE is (ST_IDLE, ST_FRAME);

	signal Writer_State								: T_WRITER_STATE																			:= ST_IDLE;
	signal Writer_NextState						: T_WRITER_STATE;
	signal Reader_State								: T_READER_STATE																			:= ST_IDLE;
	signal Reader_NextState						: T_READER_STATE;

	constant EOF_BIT									: NATURAL																							:= DATA_BITS;

	signal DataFIFO_put								: STD_LOGIC;
	signal DataFIFO_DataIn						: STD_LOGIC_VECTOR(DATA_BITS downto 0);
	signal DataFIFO_Full							: STD_LOGIC;

	signal DataFIFO_got								: STD_LOGIC;
	signal DataFIFO_DataOut						: STD_LOGIC_VECTOR(DataFIFO_DataIn'range);
	signal DataFIFO_Valid							: STD_LOGIC;

	signal FrameCommit								: STD_LOGIC;
	signal Meta_rst										: STD_LOGIC_VECTOR(META_BITS'length - 1 downto 0);

begin
	assert (META_BITS'length = META_FIFO_DEPTH'length) report "META_BITS'length /= META_FIFO_DEPTH'length" severity FAILURE;

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
					DataFIFO_Full)
	begin
		Writer_NextState									<= Writer_State;

		In_Ack														<= '0';

		DataFIFO_put											<= '0';
		DataFIFO_DataIn(In_Data'range)		<= In_Data;
		DataFIFO_DataIn(EOF_BIT)					<= In_EOF;

		case Writer_State is
			when ST_IDLE =>
				In_Ack												<= NOT DataFIFO_Full;
				DataFIFO_put									<= In_Valid;

				if ((In_Valid AND In_SOF AND NOT In_EOF) = '1') then

					Writer_NextState						<= ST_FRAME;
				end if;

			when ST_FRAME =>
				In_Ack												<= NOT DataFIFO_Full;
				DataFIFO_put									<= In_Valid;

				if ((In_Valid AND In_EOF AND NOT DataFIFO_Full) = '1') then

					Writer_NextState						<= ST_IDLE;
				end if;
		end case;
	end process;


	process(Reader_State,
					Out_Ack,
					DataFIFO_Valid, DataFIFO_DataOut)
	begin
		Reader_NextState								<= Reader_State;

		Out_Valid												<= '0';
		Out_Data												<= DataFIFO_DataOut(Out_Data'range);
		Out_SOF													<= '0';
		Out_EOF													<= DataFIFO_DataOut(EOF_BIT);

		DataFIFO_got										<= '0';

		case Reader_State is
			when ST_IDLE =>
				Out_Valid										<= DataFIFO_Valid;
				Out_SOF											<= '1';
				DataFIFO_got								<= Out_Ack;

				if ((DataFIFO_Valid AND NOT DataFIFO_DataOut(EOF_BIT) AND Out_Ack) = '1') then
					Reader_NextState					<= ST_FRAME;
				end if;

			when ST_FRAME =>
				Out_Valid										<= DataFIFO_Valid;
				DataFIFO_got								<= Out_Ack;

				if ((DataFIFO_Valid AND DataFIFO_DataOut(EOF_BIT) AND Out_Ack) = '1') then
					Reader_NextState					<= ST_IDLE;
				end if;

		end case;
	end process;

	DataFIFO : entity PoC.fifo_cc_got
		generic map (
			D_BITS							=> DATA_BITS + 1,								-- Data Width
			MIN_DEPTH						=> (DATA_FIFO_DEPTH * FRAMES),	-- Minimum FIFO Depth
			DATA_REG						=> ((DATA_FIFO_DEPTH * FRAMES) <= 128),											-- Store Data Content in Registers
			STATE_REG						=> TRUE,												-- Registered Full/Empty Indicators
			OUTPUT_REG					=> FALSE,												-- Registered FIFO Output
			ESTATE_WR_BITS			=> 0,														-- Empty State Bits
			FSTATE_RD_BITS			=> 0														-- Full State Bits
		)
		port map (
			-- Global Reset and Clock
			clk									=> Clock,
			rst									=> Reset,

			-- Writing Interface
			put									=> DataFIFO_put,
			din									=> DataFIFO_DataIn,
			full								=> DataFIFO_Full,
			estate_wr						=> open,

			-- Reading Interface
			got									=> DataFIFO_got,
			dout								=> DataFIFO_DataOut,
			valid								=> DataFIFO_Valid,
			fstate_rd						=> open
		);

	FrameCommit		<= DataFIFO_Valid AND DataFIFO_DataOut(EOF_BIT) AND Out_Ack;
	In_Meta_rst		<= slv_and(Meta_rst);

	genMeta : for i in 0 to META_BITS'length - 1 generate

	begin
		genReg : if (META_FIFO_DEPTH(i) = 1) generate
			signal MetaReg_DataIn				: STD_LOGIC_VECTOR(META_BITS(i) - 1 downto 0);
			signal MetaReg_d						: STD_LOGIC_VECTOR(META_BITS(i) - 1 downto 0)		:= (others => '0');
			signal MetaReg_DataOut			: STD_LOGIC_VECTOR(META_BITS(i) - 1 downto 0);
		begin
			MetaReg_DataIn		<= In_Meta_Data(high(META_BITS, i) downto low(META_BITS, i));

			process(Clock)
			begin
				if rising_edge(Clock) then
					if (Reset = '1') then
						MetaReg_d			<= (others => '0');
					elsif ((In_Valid AND In_SOF) = '1') then
						MetaReg_d			<= MetaReg_DataIn;
					end if;
				end if;
			end process;

			MetaReg_DataOut		<= MetaReg_d;
			Out_Meta_Data(high(META_BITS, i) downto low(META_BITS, i))	<= MetaReg_DataOut;
		end generate;	-- META_FIFO_DEPTH(i) = 1
		genFIFO : if (META_FIFO_DEPTH(i) > 1) generate
			signal MetaFIFO_put								: STD_LOGIC;
			signal MetaFIFO_DataIn						: STD_LOGIC_VECTOR(META_BITS(i) - 1 downto 0);
			signal MetaFIFO_Full							: STD_LOGIC;

			signal MetaFIFO_Commit						: STD_LOGIC;
			signal MetaFIFO_Rollback					: STD_LOGIC;

			signal MetaFIFO_got								: STD_LOGIC;
			signal MetaFIFO_DataOut						: STD_LOGIC_VECTOR(MetaFIFO_DataIn'range);
			signal MetaFIFO_Valid							: STD_LOGIC;

			signal Writer_CounterControl			: STD_LOGIC																																:= '0';
			signal Writer_Counter_en					: STD_LOGIC;
			signal Writer_Counter_us					: UNSIGNED(log2ceilnz(META_FIFO_DEPTH(i)) - 1 downto 0)										:= (others => '0');
		begin
			process(Clock)
			begin
				if rising_edge(Clock) then
					if (Reset = '1') then
						Writer_CounterControl			<= '0';
					elsif ((In_Valid AND In_SOF) = '1') then
						Writer_CounterControl			<= '1';
					elsif (Writer_Counter_us = (META_FIFO_DEPTH(i) - 1)) then
						Writer_CounterControl			<= '0';
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

			MetaFIFO_put				<= Writer_Counter_en;
			MetaFIFO_DataIn			<= In_Meta_Data(high(META_BITS, i) downto low(META_BITS, i));

			MetaFIFO : entity PoC.fifo_cc_got_tempgot
				generic map (
					D_BITS							=> META_BITS(i),										-- Data Width
					MIN_DEPTH						=> (META_FIFO_DEPTH(i) * FRAMES),		-- Minimum FIFO Depth
					DATA_REG						=> TRUE,														-- Store Data Content in Registers
					STATE_REG						=> FALSE,														-- Registered Full/Empty Indicators
					OUTPUT_REG					=> FALSE,														-- Registered FIFO Output
					ESTATE_WR_BITS			=> 0,																-- Empty State Bits
					FSTATE_RD_BITS			=> 0																-- Full State Bits
				)
				port map (
					-- Global Reset and Clock
					clk									=> Clock,
					rst									=> Reset,

					-- Writing Interface
					put									=> MetaFIFO_put,
					din									=> MetaFIFO_DataIn,
					full								=> MetaFIFO_Full,
					estate_wr						=> open,

					-- Reading Interface
					got									=> MetaFIFO_got,
					dout								=> MetaFIFO_DataOut,
					valid								=> MetaFIFO_Valid,
					fstate_rd						=> open,

					commit							=> MetaFIFO_Commit,
					rollback						=> MetaFIFO_Rollback
				);

			MetaFIFO_got				<= Out_Meta_nxt(i);
			MetaFIFO_Commit			<= FrameCommit;
			MetaFIFO_Rollback		<= Out_Meta_rst;

			Out_Meta_Data(high(META_BITS, i) downto low(META_BITS, i))	<= MetaFIFO_DataOut;
		end generate;	-- (META_FIFO_DEPTH(i) > 1)
	end generate;

end architecture;
