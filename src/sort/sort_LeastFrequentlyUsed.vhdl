
library IEEE;
use			IEEE.std_logic_1164.all;
use			IEEE.numeric_std.all;


entity sort_LeastFrequentlyUsed is
	generic (
		ELEMENTS			: POSITIVE		:= 1024;
		KEY_BITS			: POSITIVE		:= 16;
		DATA_BITS			: POSITIVE		:= 16;
		COUNTER_BITS	: POSITIVE		:= 8
	);
	port (
		Clock					: in	STD_LOGIC;
		Reset					: in	STD_LOGIC;
		
		Access				: in	STD_LOGIC;
		Key						: in	STD_LOGIC_VECTOR(KEY_BITS - 1 downto 0);
		
		LFU_Valid			: out	STD_LOGIC;
		LFU_Key				: out	STD_LOGIC_VECTOR(KEY_BITS - 1 downto 0)
	);
end entity;


architecture rtl of sort_LeastFrequentlyUsed is
	type T_ELEMENT is record
		Data				: STD_LOGIC_VECTOR(DATA_BITS - 1 downto 0);
		Counter_us	: UNSIGNED(COUNTER_BITS - 1 downto 0);
		Valid				: STD_LOGIC;
	end record;
	
	type T_ELEMENT_VECTOR is array(NATURAL range <>) of T_ELEMENT;
	
	constant C_ELEMENT_EMPTY	: T_ELEMENT		:= (Data => (others => '0'), Counter_us => (others => '0'), Valid => '0');
	
	signal List_d					: T_ELEMENT_VECTOR(ELEMENTS - 1 downto 0)		:= (others => C_ELEMENT_EMPTY);
	signal List_AddSub		: T_ELEMENT_VECTOR(ELEMENTS - 1 downto 0);
	signal List_OddSort		: T_ELEMENT_VECTOR(ELEMENTS - 1 downto 0);
	signal List_EvenSort	: T_ELEMENT_VECTOR(ELEMENTS - 1 downto 0);
begin
	
	genAddSub : for i in 0 to ELEMENTS - 1 generate
		process(List_d, Data, Access, New)
		begin
			List_AddSub(i)		<= List_d(i);
			if ((Access = '1') and (List_d(i).Data(KEY_BITS - 1 downto 0) = Data(KEY_BITS - 1 downto 0)) and (List_d(i).Counter_us /= (others => '1')) then
				List_AddSub(i).Counter_us		:= List_d(i).Counter_us + 1;
			elsif (New = '1') then		-- ((New = '1') and (List_d(i).Counter_us /= (others => '0')) then
				if (i = 0) then
					List_AddSub(i).Data					:= Data;
					List_AddSub(i).Counter_us		:= (others => '0');
					List_AddSub(i).Valid				:= '1';
				else
					List_AddSub(i).Counter_us		:= List_d(i).Counter_us - List_d(0).Counter_us;
				end loop;
			end if;
		end process;
	end generate;
	genOddSort : for i in 0 to ELEMENTS - 2 generate
		process(List_AddSub)
		begin
			if ((i mod 2 = 0) and (List_AddSub(i).Counter_us <= List_AddSub(i + 1).Counter_us)) then
				List_OddSort(i)				<= List_AddSub(i);
				List_OddSort(i + 1)		<= List_AddSub(i + 1);
			else
				List_OddSort(i)				<= List_AddSub(i + 1);
				List_OddSort(i + 1)		<= List_AddSub(i);
			end if;
		end process;
	end generate;
	genEvenSort : for i in 1 to ELEMENTS - 3 generate
		process(List_OddSort)
		begin
			if ((i mod 2 = 0) and (List_OddSort(i).Counter_us <= List_OddSort(i + 1).Counter_us)) then
				List_EvenSort(i)				<= List_OddSort(i);
				List_EvenSort(i + 1)		<= List_OddSort(i + 1);
			else
				List_EvenSort(i)				<= List_OddSort(i + 1);
				List_EvenSort(i + 1)		<= List_OddSort(i);
			end if;
		end process;
	end generate;
	genReg : for i in 0 to ELEMENTS - 1 generate
		process(Clock)
		begin
			if rising_edge(Clock) then
				if (Reset = '1') then
					List_d	<= (others => C_ELEMENT_EMPTY);
				else
					List_d	<= List_EvenSort;
				end if;
			end if;
		end process;
	end generate;
	
	LFU_Valid		<= List_d(0).Valid;
	LFU_Key			<= List_d(0).Key;
	LFU_Data		<= List_d(0).Data;
	
end architecture;
		