-- EMACS settings: -*-  tab-width: 2; indent-tabs-mode: t -*-
-- vim: tabstop=2:shiftwidth=2:noexpandtab
-- kate: tab-width 2; replace-tabs off; indent-width 2;
-- =============================================================================
-- Authors:				 	Patrick Lehmann
--
-- Entity:				 	A generic buffer module for the PoC.Stream protocol.
--
-- Description:
-- -------------------------------------
-- .. TODO:: No documentation available.
--
-- License:
-- =============================================================================
-- Copyright 2007-2015 Technische Universitaet Dresden - Germany
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
-- WITHOUT WARRANTIES OR CONDITIONS of ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.
-- =============================================================================

library IEEE;
use			IEEE.STD_LOGIC_1164.all;
use			ieee.numeric_std.all;

library	PoC;
use			PoC.utils.all;
use			PoC.vectors.all;


entity stream_FrameGenerator is
  generic (
    DATA_BITS					: positive														:= 8;
		WORD_BITS					: positive														:= 16;
		APPEND						: T_FRAMEGEN_APPEND										:= FRAMEGEN_APP_NONE;
		FRAMEGROUPS				: T_FRAMEGEN_FRAMEGROUP_VECTOR_8			:= (0 => C_FRAMEGEN_FRAMEGROUP_EMPTY)
  );
	port (
		Clock							: in	std_logic;
		Reset							: in	std_logic;
		-- CSE interface
		Command						: in	T_FRAMEGEN_COMMAND;
		Status						: out	T_FRAMEGEN_STATUS;
		-- Control interface
		Pause							: in	T_SLV_16;
		FrameGroupIndex		: in	T_SLV_8;
		FrameIndex				: in	T_SLV_8;
		Sequences					: in	T_SLV_16;
		FrameLength				: in	T_SLV_16;
		-- OUT Port
		Out_Valid					: out	std_logic;
		Out_Data					: out	std_logic_vector(DATA_BITS - 1 downto 0);
		Out_SOF						: out	std_logic;
		Out_EOF						: out	std_logic;
		Out_Ack						: in	std_logic
	);
end entity;


architecture rtl of stream_FrameGenerator is
	type T_STATE is (
		ST_IDLE,
			ST_SEQUENCE_SOF,	ST_SEQUENCE_DATA,	ST_SEQUENCE_EOF,
			ST_RANDOM_SOF,		ST_RANDOM_DATA,		ST_RANDOM_EOF,
		ST_ERROR
	);

	signal State											: T_STATE														:= ST_IDLE;
	signal NextState									: T_STATE;

	signal FrameLengthCounter_rst			: std_logic;
	signal FrameLengthCounter_en			: std_logic;
	signal FrameLengthCounter_us			: unsigned(15 downto 0)							:= (others => '0');

	signal SequencesCounter_rst				: std_logic;
	signal SequencesCounter_en				: std_logic;
	signal SequencesCounter_us				: unsigned(15 downto 0)							:= (others => '0');
	signal ContentCounter_rst					: std_logic;
	signal ContentCounter_en					: std_logic;
	signal ContentCounter_us					: unsigned(WORD_BITS - 1 downto 0)	:= (others => '0');

	signal PRNG_rst										: std_logic;
	signal PRNG_got										: std_logic;
	signal PRNG_Data									: std_logic_vector(DATA_BITS - 1 downto 0);
begin

	process(Clock)
	begin
		if rising_edge(Clock) then
			if (Reset = '1') then
				State		<= ST_IDLE;
			else
				State		<= NextState;
			end if;
		end if;
	end process;

	process(State, Command, Out_Ack,
					Sequences, FrameLength,
					FrameLengthCounter_us,
					SequencesCounter_us, ContentCounter_us,
					PRNG_Data)
	begin
		NextState													<= State;

		Status														<= FRAMEGEN_STATUS_GENERATING;

		Out_Valid													<= '0';
		Out_Data													<= (others => '0');
		Out_SOF														<= '0';
		Out_EOF														<= '0';

		FrameLengthCounter_rst						<= '0';
		FrameLengthCounter_en							<= '0';
		SequencesCounter_rst							<= '0';
		SequencesCounter_en								<= '0';
		ContentCounter_rst								<= '0';
		ContentCounter_en									<= '0';

		PRNG_rst													<= '0';
		PRNG_got													<= '0';

		case State is
			when ST_IDLE =>
				Status												<= FRAMEGEN_STATUS_IDLE;

				FrameLengthCounter_rst				<= '1';
				SequencesCounter_rst					<= '1';
				ContentCounter_rst						<= '1';
				PRNG_rst											<= '1';

				case Command is
					when FRAMEGEN_CMD_NONE =>
						null;

					when FRAMEGEN_CMD_SEQUENCE =>
						NextState									<= ST_SEQUENCE_SOF;

					when FRAMEGEN_CMD_RANDOM =>
						NextState									<= ST_RANDOM_SOF;

					when FRAMEGEN_CMD_SINGLE_FRAME =>
						NextState									<= ST_ERROR;

					when FRAMEGEN_CMD_SINGLE_FRAMEGROUP =>
						NextState									<= ST_ERROR;

					when FRAMEGEN_CMD_ALL_FRAMES =>
						NextState									<= ST_ERROR;

					when others =>
						NextState									<= ST_ERROR;
				end case;

			-- generate sequential numbers
			-- ----------------------------------------------------------------------
			when ST_SEQUENCE_SOF =>
				Out_Valid											<= '1';
				Out_Data											<= std_logic_vector(ContentCounter_us);
				Out_SOF												<= '1';

				if (Out_Ack	 = '1') then
					FrameLengthCounter_en				<= '1';
					ContentCounter_en						<= '1';

					NextState										<= ST_SEQUENCE_DATA;
				end if;

			when ST_SEQUENCE_DATA =>
				Out_Valid											<= '1';
				Out_Data											<= std_logic_vector(ContentCounter_us);

				if (Out_Ack	 = '1') then
					FrameLengthCounter_en				<= '1';
					ContentCounter_en						<= '1';

					if FrameLengthCounter_us = (unsigned(FrameLength) - 2) then
						NextState									<= ST_SEQUENCE_EOF;
					end if;
				end if;

			when ST_SEQUENCE_EOF =>
				Out_Valid											<= '1';
				Out_Data											<= std_logic_vector(ContentCounter_us);
				Out_EOF												<= '1';

				if (Out_Ack	 = '1') then
					FrameLengthCounter_rst			<= '1';
					ContentCounter_en						<= '1';
					SequencesCounter_en					<= '1';

--					if (Pause = (Pause'range => '0')) then
					if SequencesCounter_us = (unsigned(Sequences) - 1) then
						Status										<= FRAMEGEN_STATUS_COMPLETE;
						NextState									<= ST_IDLE;
					else
						NextState									<= ST_SEQUENCE_SOF;
					end if;
--					end if;
				end if;

			-- generate random numbers
			-- ----------------------------------------------------------------------
			when ST_RANDOM_SOF =>
				Out_Valid									<= '1';
				Out_Data									<= PRNG_Data;
				Out_SOF										<= '1';

				if (Out_Ack	 = '1') then
					FrameLengthCounter_en		<= '1';
					PRNG_got								<= '1';
					NextState								<= ST_RANDOM_DATA;
				end if;

			when ST_RANDOM_DATA =>
				Out_Valid									<= '1';
				Out_Data									<= PRNG_Data;

				if (Out_Ack	 = '1') then
					FrameLengthCounter_en		<= '1';
					PRNG_got								<= '1';

					if FrameLengthCounter_us = (unsigned(FrameLength) - 2) then
						NextState							<= ST_RANDOM_EOF;
					end if;
				end if;

			when ST_RANDOM_EOF =>
				Out_Valid									<= '1';
				Out_Data									<= PRNG_Data;
				Out_EOF										<= '1';

				FrameLengthCounter_rst		<= '1';

				if (Out_Ack	 = '1') then
					PRNG_rst								<= '1';
					NextState								<= ST_IDLE;
				end if;

			when ST_ERROR =>
				Status										<= FRAMEGEN_STATUS_ERROR;
				NextState									<= ST_IDLE;

		end case;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or FrameLengthCounter_rst) = '1') then
				FrameLengthCounter_us			<= (others => '0');
			elsif (FrameLengthCounter_en = '1') then
				FrameLengthCounter_us			<= FrameLengthCounter_us + 1;
			end if;
		end if;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or SequencesCounter_rst) = '1') then
				SequencesCounter_us			<= (others => '0');
			elsif (SequencesCounter_en = '1') then
				SequencesCounter_us			<= SequencesCounter_us + 1;
			end if;
		end if;
	end process;

	process(Clock)
	begin
		if rising_edge(Clock) then
			if ((Reset or ContentCounter_rst) = '1') then
				ContentCounter_us				<= (others => '0');
			elsif (ContentCounter_en = '1') then
				ContentCounter_us				<= ContentCounter_us + 1;
			end if;
		end if;
	end process;

	PRNG : entity PoC.arith_prng
    generic map (
      BITS		=> DATA_BITS
		)
    port map (
      clk			=> Clock,
      rst			=> PRNG_rst,
      got			=> PRNG_got,
      val			=> PRNG_Data
     );

end architecture;
