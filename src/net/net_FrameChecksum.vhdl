-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- 
-- ============================================================================
-- Authors:				 	Patrick Lehmann
-- 
-- Module:				 	TODO
--
-- Description:
-- ------------------------------------
--		TODO
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
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
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


entity net_FrameChecksum is
	generic (
		MAX_FRAMES										: POSITIVE				:= 8;
		MAX_FRAME_LENGTH							: POSITIVE				:= 2048;
		META_BITS											: T_POSVEC				:= (0 => 8);
		META_FIFO_DEPTH								: T_POSVEC				:= (0 => 16)
	);
	port (
		Clock													: in	STD_LOGIC;
		Reset													: in	STD_LOGIC;
		-- IN port
		In_Valid											: in	STD_LOGIC;
		In_Data												: in	T_SLV_8;
		In_SOF												: in	STD_LOGIC;
		In_EOF												: in	STD_LOGIC;
		In_Ack												: out	STD_LOGIC;
		In_Meta_rst										: out	STD_LOGIC;
		In_Meta_nxt										: out	STD_LOGIC_VECTOR(META_BITS'length - 1 downto 0);
		In_Meta_Data									: in	STD_LOGIC_VECTOR(isum(META_BITS) - 1 downto 0);
		-- OUT port
		Out_Valid											: out	STD_LOGIC;
		Out_Data											: out	T_SLV_8;
		Out_SOF												: out	STD_LOGIC;
		Out_EOF												: out	STD_LOGIC;
		Out_Ack												: in	STD_LOGIC;
		Out_Meta_rst									: in	STD_LOGIC;
		Out_Meta_nxt									: in	STD_LOGIC_VECTOR(META_BITS'length - 1 downto 0);
		Out_Meta_Data									: out	STD_LOGIC_VECTOR(isum(META_BITS) - 1 downto 0);
		Out_Meta_Length								: out	T_SLV_16;
		Out_Meta_Checksum							: out	T_SLV_16
	);
end entity;

-- FIXME: review writer-FSM: check full signals => block incoming words/frames if datafifo or metafifo is full

architecture rtl of net_FrameChecksum is
	attribute FSM_ENCODING						: STRING;

	type T_WRITER_STATE IS			(ST_IDLE, ST_FRAME, ST_CARRY_1, ST_CARRY_2);
	type T_METAWRITER_STATE IS	(ST_IDLE, ST_METADATA);
	type T_READER_STATE IS			(ST_IDLE, ST_FRAME);
	
	signal Writer_State						: T_WRITER_STATE																			:= ST_IDLE;
	signal Writer_NextState				: T_WRITER_STATE;
	signal MetaWriter_State				: T_METAWRITER_STATE																	:= ST_IDLE;
	signal MetaWriter_NextState		: T_METAWRITER_STATE;
	signal Reader_State						: T_READER_STATE																			:= ST_IDLE;
	signal Reader_NextState				: T_READER_STATE;
	
	signal Checksum_rst						: STD_LOGIC;
	signal Checksum_en						: STD_LOGIC;
	signal Checksum_Data_us				: UNSIGNED(In_Data'range);
	signal Checksum0_nxt_us				: UNSIGNED(In_Data'length downto 0);
	signal Checksum0_d_us					: UNSIGNED(In_Data'length downto 0)										:= (others => '0');
	signal Checksum0_nxt_cy				: STD_LOGIC;
	signal Checksum1_nxt_us				: UNSIGNED(In_Data'range);
	signal Checksum1_d_us					: UNSIGNED(In_Data'range)															:= (others => '0');
	signal Checksum								: T_SLV_16;
	
	constant WORDCOUNTER_BITS			: POSITIVE																						:= log2ceilnz(MAX_FRAME_LENGTH);
	signal WordCounter_rst				: STD_LOGIC;
	signal WordCounter_en					: STD_LOGIC;
	signal WordCounter_us					: UNSIGNED(WORDCOUNTER_BITS - 1 downto 0)							:= to_unsigned(1, log2ceilnz(MAX_FRAME_LENGTH));
	signal WordCount							: STD_LOGIC_VECTOR(WORDCOUNTER_BITS + 15 downto 16);
	
	signal FrameCommit						: STD_LOGIC;
	
	constant DATA_BITS						: POSITIVE																						:= 8;
	constant EOF_BIT							: NATURAL																							:= DATA_BITS;
	
	signal DataFIFO_put						: STD_LOGIC;
	signal DataFIFO_DataIn				: STD_LOGIC_VECTOR(DATA_BITS downto 0);
	signal DataFIFO_Full					: STD_LOGIC;
	signal DataFIFO_got						: STD_LOGIC;
	signal DataFIFO_DataOut				: STD_LOGIC_VECTOR(DATA_BITS downto 0);
	signal DataFIFO_Valid					: STD_LOGIC;
	
	constant META_MISC_BITS				: POSITIVE																						:= Checksum'length + WordCount'length;
	
	signal MetaFIFO_Misc_put			: STD_LOGIC;
	signal MetaFIFO_Misc_DataIn		: STD_LOGIC_VECTOR(META_MISC_BITS - 1 downto 0);
	signal MetaFIFO_Misc_Full			: STD_LOGIC;
	signal MetaFIFO_Misc_got			: STD_LOGIC;
	signal MetaFIFO_Misc_DataOut	: STD_LOGIC_VECTOR(META_MISC_BITS - 1 downto 0);
	signal MetaFIFO_Misc_Valid		: STD_LOGIC;

	signal Meta_rst								: STD_LOGIC_VECTOR(META_BITS'length - 1 downto 0);
	
begin

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
					In_Valid, In_SOF, In_EOF, In_Data,
					WordCounter_us, Checksum0_nxt_cy,
					DataFIFO_Full, MetaFIFO_Misc_Full)
	begin
		Writer_NextState								<= Writer_State;
		
		DataFIFO_put										<= '0';
		MetaFIFO_Misc_put								<= '0';
		
		In_Ack													<= NOT DataFIFO_Full;
		
		WordCounter_rst									<= '0';
		WordCounter_en									<= '0';
		
		Checksum_rst										<= '0';
		Checksum_en											<= '0';
		Checksum_Data_us								<= unsigned(In_Data);
		
		case Writer_State is
			when ST_IDLE =>
				if ((In_Valid AND In_SOF AND (NOT DataFIFO_Full)) = '1') then
					WordCounter_en						<= '1';
					Checksum_en								<= '1';
					DataFIFO_put							<= In_Valid;
					
					if (In_EOF = '1') then
						MetaFIFO_Misc_put						<= '1';
					
						Writer_NextState				<= ST_IDLE;
					else
						Writer_NextState				<= ST_FRAME;
					end if;
				end if;
	
			when ST_FRAME =>
				DataFIFO_put								<= In_Valid;
				
				if ((In_Valid AND (NOT DataFIFO_Full)) = '1') then
					WordCounter_en						<= '1';
					Checksum_en								<= '1';
					
					if (In_EOF = '1') then
						WordCounter_en					<= '0';
						
						if (Checksum0_nxt_cy = '0') then
							WordCounter_rst			<= '1';
							Checksum_rst				<= '1';
							
							MetaFIFO_Misc_put				<= '1';
							
							Writer_NextState		<= ST_IDLE;
						else
							Writer_NextState		<= ST_CARRY_1;
						end if;
					end if;
				end if;
				
			when ST_CARRY_1 =>			
				In_Ack											<= '0';

				Checksum_Data_us						<= (others => '0');
				
				if (Checksum0_nxt_cy = '0') then
					Checksum_rst							<= '1';
					WordCounter_rst						<= '1';

					MetaFIFO_Misc_put							<= '1';

					Writer_NextState					<= ST_IDLE;
				else
					Checksum_en								<= '1';
					
					Writer_NextState					<= ST_CARRY_2;
				end if;
				
			when ST_CARRY_2 =>			
				In_Ack											<= '0';

				Checksum_Data_us						<= (others => '0');
				Checksum_rst								<= '1';
				WordCounter_rst							<= '1';

				MetaFIFO_Misc_put								<= '1';

				Writer_NextState						<= ST_IDLE;
			
		end case;
	end process;


	process(Reader_State,
					Out_Ack,
					DataFIFO_Valid, DataFIFO_DataOut,
					MetaFIFO_Misc_Valid, MetaFIFO_Misc_DataOut)
	begin
		Reader_NextState								<= Reader_State;
		
		Out_Valid												<= '0';
		Out_Data												<= DataFIFO_DataOut(Out_Data'range);
		Out_SOF													<= '0';
		Out_EOF													<= DataFIFO_DataOut(EOF_BIT);
		Out_Meta_Checksum								<= MetaFIFO_Misc_DataOut(Checksum'range);
		Out_Meta_Length									<= resize(MetaFIFO_Misc_DataOut(WordCount'range), Out_Meta_Length'length);
		
		DataFIFO_got										<= '0';
		
		case Reader_State IS
			when ST_IDLE =>
				Out_SOF											<= '1';
			
				if ((DataFIFO_Valid AND MetaFIFO_Misc_Valid) = '1') then
					Out_Valid									<= '1';
					
					if (Out_Ack	 = '1') then
						DataFIFO_got						<= '1';
					
						if (DataFIFO_DataOut(EOF_BIT) = '0') then
							Reader_NextState			<= ST_FRAME;
						end if;
					end if;
				end if;
			
			when ST_FRAME =>
				Out_Valid										<= DataFIFO_Valid;

				if (Out_Ack	 = '1') then
					DataFIFO_got							<= '1';
					
					if (DataFIFO_DataOut(EOF_BIT) = '1') then
						Reader_NextState				<= ST_IDLE;
					end if;
				end if;

		end case;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (WordCounter_rst = '1') then
				WordCounter_us		<= to_unsigned(1, WordCounter_us'length);
			elsif (WordCounter_en = '1') then
				WordCounter_us		<= WordCounter_us + 1;
			end if;
		end if;
	end process;

	Checksum0_nxt_cy		<= Checksum0_nxt_us(Checksum0_nxt_us'high);
	Checksum0_nxt_us		<= ('0' & Checksum1_d_us) + ('0' & Checksum_Data_us) + ((Checksum1_d_us'range => '0') & Checksum0_d_us(Checksum0_d_us'high));
	Checksum1_nxt_us		<= Checksum0_d_us(Checksum1_d_us'range);
					
	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Checksum_rst = '1') then
				Checksum0_d_us			<= (others => '0');
				Checksum1_d_us			<= (others => '0');
			elsif (Checksum_en = '1') then
				Checksum0_d_us			<= Checksum0_nxt_us;
				Checksum1_d_us			<= Checksum1_nxt_us;
			end if;
		end if;
	end process;
	
	Checksum			<= std_logic_vector(Checksum0_nxt_us(Checksum1_nxt_us'range)) & std_logic_vector(Checksum1_nxt_us);
	WordCount			<= std_logic_vector(WordCounter_us);

	DataFIFO_DataIn(In_Data'range)		<= In_Data;
	DataFIFO_DataIn(EOF_BIT)					<= In_EOF;
	
	DataFIFO : entity PoC.fifo_cc_got
		generic map (
			D_BITS							=> DataFIFO_DataIn'length,			-- Data Width
			MIN_DEPTH						=> MAX_FRAME_LENGTH,						-- Minimum FIFO Depth
			DATA_REG						=> FALSE,												-- Store Data Content in Registers
			STATE_REG						=> TRUE,												-- Registered Full/Empty Indicators
			OUTPUT_REG					=> TRUE,												-- Registered FIFO Output
			ESTATE_WR_BITS			=> 0,														-- Empty State Bits
			FSTATE_RD_BITS			=> 0														-- Full State Bits
		)
		port map (
			clk									=> Clock,
			rst									=> Reset,
			-- Write Interface
			put									=> DataFIFO_put,
			din									=> DataFIFO_DataIn,
			full								=> DataFIFO_Full,
			estate_wr						=> open,
			-- Read Interface
			got									=> DataFIFO_got,
			valid								=> DataFIFO_Valid,
			dout								=> DataFIFO_DataOut,
			fstate_rd						=> open
		);

	MetaFIFO_Misc_DataIn(Checksum'range)		<= ite((WordCounter_us(0) = to_sl(Writer_State /= ST_CARRY_1)), Checksum, swap(Checksum, 8));
	MetaFIFO_Misc_DataIn(WordCount'range)		<= WordCount;
	
	MetaFIFO_Misc : entity PoC.fifo_cc_got
		generic map (
			D_BITS							=> MetaFIFO_Misc_DataIn'length,							-- Data Width
			MIN_DEPTH						=> MAX_FRAMES,															-- Minimum FIFO Depth
			DATA_REG						=> TRUE,																		-- Store Data Content in Registers
			STATE_REG						=> TRUE,																		-- Registered Full/Empty Indicators
			OUTPUT_REG					=> FALSE,																		-- Registered FIFO Output
			ESTATE_WR_BITS			=> 0,																				-- Empty State Bits
			FSTATE_RD_BITS			=> 0																				-- Full State Bits
		)
		port map (
			clk									=> Clock,
			rst									=> Reset,
			-- Write Interface
			put									=> MetaFIFO_Misc_put,
			din									=> MetaFIFO_Misc_DataIn,
			full								=> MetaFIFO_Misc_Full,
			estate_wr						=> open,
			-- Read Interface
			got									=> MetaFIFO_Misc_got,
			valid								=> MetaFIFO_Misc_Valid,
			dout								=> MetaFIFO_Misc_DataOut,
			fstate_rd						=> open
		);
	
	Out_Meta_Length					<= resize(MetaFIFO_Misc_DataOut(WordCount'range), Out_Meta_Length'length);
	Out_Meta_Checksum				<= MetaFIFO_Misc_DataOut(Checksum'range);
	
	FrameCommit							<= DataFIFO_Valid AND DataFIFO_DataOut(EOF_BIT) AND Out_Ack;
	MetaFIFO_Misc_got				<= FrameCommit;
	
	genMeta : for i in 0 to META_BITS'length - 1 generate
		signal MetaFIFO_put						: STD_LOGIC;
		signal MetaFIFO_DataIn				: STD_LOGIC_VECTOR(META_BITS(i) - 1 downto 0);
		signal MetaFIFO_Full					: STD_LOGIC;
		signal MetaFIFO_got						: STD_LOGIC;
		signal MetaFIFO_DataOut				: STD_LOGIC_VECTOR(META_BITS(i) - 1 downto 0);
		signal MetaFIFO_Valid					: STD_LOGIC;
		signal MetaFIFO_Commit				: STD_LOGIC;
		signal MetaFIFO_Rollback			: STD_LOGIC;
		
		signal Writer_CounterControl	: STD_LOGIC																																:= '0';
		
		signal Writer_Counter_rst			: STD_LOGIC;
		signal Writer_Counter_en			: STD_LOGIC;
		signal Writer_Counter_us			: UNSIGNED(log2ceilnz(META_FIFO_DEPTH(i) * MAX_FRAMES) - 1 downto 0)			:= (others => '0');
	begin
		Writer_Counter_rst		<= '0';		-- FIXME: is this correct?
	
		process(Clock)
		begin
			if rising_edge(Clock) then
				if (Reset = '1') then
					Writer_CounterControl			<= '0';
				elsif ((In_Valid AND In_SOF) = '1') then
					Writer_CounterControl		<= '1';
				elsif (Writer_Counter_us = (META_FIFO_DEPTH(i) - 1)) then
					Writer_CounterControl		<= '0';
				end if;
			end if;
		end process;
	
		Writer_Counter_en		<= (In_Valid AND In_SOF) OR Writer_CounterControl;
		
		process(Clock)
		begin
			if rising_edge(Clock) then
				if ((Reset OR Writer_Counter_rst) = '1') then
					Writer_Counter_us					<= (others => '0');
				elsif (Writer_Counter_en = '1') then
					Writer_Counter_us				<= Writer_Counter_us + 1;
				end if;
			end if;
		end process;
		
		Meta_rst(i)					<= NOT Writer_Counter_en;
		In_Meta_nxt(i)			<= Writer_Counter_en;
		
		MetaFIFO_put				<= Writer_Counter_en;
		MetaFIFO_DataIn			<= In_Meta_Data(high(META_BITS, i) downto low(META_BITS, i));
	
		MetaFIFO : entity PoC.fifo_cc_got_tempgot
			generic map (
				D_BITS							=> MetaFIFO_DataIn'length,							-- Data Width
				MIN_DEPTH						=> (META_FIFO_DEPTH(i) * MAX_FRAMES),		-- Minimum FIFO Depth
				DATA_REG						=> TRUE,																-- Store Data Content in Registers
				STATE_REG						=> TRUE,																-- Registered Full/Empty Indicators
				OUTPUT_REG					=> FALSE,																-- Registered FIFO Output
				ESTATE_WR_BITS			=> 0,																		-- Empty State Bits
				FSTATE_RD_BITS			=> 0																		-- Full State Bits
			)
			port map (
				clk									=> Clock,
				rst									=> Reset,
				-- Write Interface
				put									=> MetaFIFO_put,
				din									=> MetaFIFO_DataIn,
				full								=> MetaFIFO_Full,
				estate_wr						=> open,
				-- Read Interface
				got									=> MetaFIFO_got,
				valid								=> MetaFIFO_Valid,
				dout								=> MetaFIFO_DataOut,
				fstate_rd						=> open,
				
				commit							=> MetaFIFO_Commit,
				rollback						=> MetaFIFO_Rollback
			);
		
		MetaFIFO_got				<= Out_Meta_nxt(i);
		MetaFIFO_Commit			<= FrameCommit;
		MetaFIFO_Rollback		<= Out_Meta_rst;
	
		Out_Meta_Data(high(META_BITS, i) downto low(META_BITS, i))	<= MetaFIFO_DataOut;
	end generate;

	In_Meta_rst						<= slv_and(Meta_rst);

end architecture;
