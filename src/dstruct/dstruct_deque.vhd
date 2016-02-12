library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library PoC;
use PoC.config.all;
use PoC.utils.all;
use PoC.ocram.all;

entity dstruct_deque is
    generic(
    D_BITS  : positive := 8; -- Data Width
    MIN_DEPTH : positive := 16 -- Minimum Deque Depth
    );
    port(
    -- Shared Ports
    clk, rst : in std_logic;

    -- Port A
    dinA : in std_logic_vector(D_BITS-1 downto 0); -- DataA Input
    putA : in std_logic;
    gotA : in std_logic;
    doutA : out std_logic_vector(D_BITS-1 downto 0); -- DataA Output
    validA : out std_logic;
    fullA : out std_logic;

    -- Port B
    dinB : in std_logic_vector(D_BITS-1 downto 0); -- DataB Input
    putB: in std_logic;
    gotB : in std_logic;
    doutB : out std_logic_vector(D_BITS-1 downto 0);
    validB : out std_logic;
    fullB : out std_logic
    );
end dstruct_deque;

architecture rtl of dstruct_deque is
    -- Constants
    constant A_BITS : natural := log2ceil(MIN_DEPTH);--INTEGER(CEIL(LOG2(REAL(MIN_DEPTH))));

    -- MEMORY variable
    type memory_t is array ((2**A_BITS)-1 downto 0) of std_logic_vector(D_BITS-1 downto 0);
    signal memory : memory_t := (others => (others => '0'));

    -- Signals
    signal combined : std_logic_vector(3 downto 0) := (others => '0');
    signal ctrl : std_logic_vector(1 downto 0) := (others => '1');
    signal sub : unsigned(A_BITS-1 downto 0) := (others => '0');

    -- last operation flag
    signal last_operation : std_logic := '0'; -- save last operation 0 -> read, 1 -> write
    type last_op_ctrl_t is (IDLE, SET, UNSET);
    signal last_op_ctrl : last_op_ctrl_t := IDLE;

    signal s_validA : std_logic := '0';
    signal s_validB : std_logic := '0';

    -- Stackpointer
    -- A
    signal stackpointerA : unsigned (A_BITS-1 downto 0) := shift_right(to_unsigned(MIN_DEPTH-1,A_BITS),1) ;
    signal rea : std_logic := '0';
    signal wea : std_logic := '0';
    -- B
    signal stackpointerB : unsigned (A_BITS-1 downto 0) := shift_right(to_unsigned(MIN_DEPTH-1,A_BITS),1) + 1;
    signal reb : std_logic := '0';
    signal web : std_logic := '0';


    -- ctrl signal for stackpointer operations
    type ctrl_t is (PUSH, POP, IDLE);
    signal ctrlA : ctrl_t := IDLE;
    signal ctrlB : ctrl_t := IDLE;

    -- RAM Signals
    signal adrA : unsigned(A_BITS-1 downto 0) := (others => '0');
    signal adrB : unsigned(A_BITS-1 downto 0) := (others => '0');

begin

    ram : entity poc.ocram_tdp
	generic map(
		A_BITS => A_BITS,
		D_BITS => D_BITS,
		FILENAME =>  ""
	)
	port map(
		clk1 => clk,
		clk2 => clk,
		ce1	=> '1',
		ce2	=> '1',
		we1	=> weA,
		we2	=> weB,
		a1	=> adrA,
		a2	=> adrB,
		d1	=> dinA,
		d2	=> dinB,
		q1	=> doutA,
		q2	=> doutB
	);

    sub <= stackpointerB - StackpointerA;

    combined <= putA & gotA & putB & gotB;

    process(combined, stackpointerA, stackpointerB, last_operation, ctrl)
    begin
        ctrlA <= IDLE;
        ctrlB <= IDLE;
        reA <= '1';
        reB <= '1';
        adrA <= stackpointerA + 1;
        adrB <= stackpointerB - 1;
        weA <= '0';
        weB <= '0';
        last_op_ctrl <= IDLE;
        case(combined) is
            when x"0" =>    --nothing
                -- nothing happend/happens
                -- dont update stackpointers
                ctrlA <= IDLE;
                ctrlB <= IDLE;
            when x"1" =>    --readB
                -- B read a valid value
                -- update stackpiunter
                ctrlB <= POP;
                reB <= '1';
                adrB <= stackpointerB - 2;
                last_op_ctrl <= UNSET;
                if (ctrl = "01") then
                    if(last_operation = '0') then
                        --> deque is empty!
                        -- B couldn't read a valid value => dont update SP!
                        ctrlB <= IDLE;
                        adrB <= stackpointerB - 1;
                        last_op_ctrl <= UNSET;
                    end if;
                elsif (ctrl = "10") then
                    --> only one element left
                    -- side B saw empty signal
                    -- so B couldnt read a valid value
                    ctrlB <= IDLE;
                    adrB <= stackpointerB - 1;
                    last_op_ctrl <= IDLE;
                end if;
            when x"2" =>    --writeB
                ctrlB <= PUSH;
                weB <= '1';
                adrB <= stackpointerB;
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if(last_operation = '1') then
                        --> deque is full!
                        -- B cant write => dont update SP!
                        ctrlB <= IDLE;
                        weB <= '0';
                        adrB <= stackpointerB - 1;
                    end if;
                elsif (ctrl = "00") then
                    --> only one spot left
                    -- B isnt allowed to write
                    -- B sees full signal atm
                    weB <= '0';
                    adrB <= stackpointerB - 1;
                    ctrlB <= IDLE;
                end if;
            when x"3" =>    --readB, writeB
                -- B read a valid value and writes a new value at the same spot
                -- dont update stackpointer
                reB <= '1';
                adrB <= stackpointerB - 1;
                weB <= '1';
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if (last_operation = '1') then
                        --> deque is full!
                        -- B read a valid value but new value cant be pushed!
                        ctrlB <= POP;
                        weB <= '0';
                        adrB <= stackpointerB - 2;
                        last_op_ctrl <= UNSET;
                    else
                        --> deque is empty!
                        -- B couldn't read a valid value, but new value can be written!
                        ctrlB <= PUSH;
                        weB <= '1';
                        adrB <= stackpointerB;
                        last_op_ctrl <= SET;
                    end if;
                elsif (ctrl = "10") then
                    --> only one element left
                    -- B couldnt read it, but can write new value
                    ctrlB <= PUSH;
                    weB <= '1';
                    adrB <= stackpointerB;
                    last_op_ctrl <= SET;
                elsif (ctrl = "00") then
                    -- only one spot left
                    -- B read a valid value but cant write new value
                    ctrlB <= POP;
                    weB <= '0';
                    adrB <= stackpointerB - 2;
                    last_op_ctrl <= UNSET;
                end if;
            when x"4" =>    --readA
                -- A read a valid values
                -- update stackpiunter
                ctrlA <= POP;
                reA <= '1';
                adrA <= stackpointerA + 2;
                last_op_ctrl <= UNSET;
                if (ctrl = "01" and last_operation = '0') then
                    --> deque is empty!
                    -- A couldn't read a valid value => dont update SP!
                    ctrlA <= IDLE;
                    adrA <= stackpointerA + 1;
                end if;
            when x"5" =>    --readA, readB
                -- A and B read both valid values
                -- update both stackpiunters
                ctrlA <= POP;
                ctrlB <= POP;
                reB <= '1';
                adrB <= stackpointerB - 2;
                reA <= '1';
                adrA <= stackpointerA + 2;
                last_op_ctrl <= UNSET;
                if (ctrl = "01") then
                    if (last_operation = '1') then
                        --> deque is full
                        -- A and B read a valid value!
                        last_op_ctrl <= UNSET;
                    else
                        --> deque is empty!
                        -- A and B couldn't a valid value => dont update SP!
                        ctrlB <= IDLE;
                        ctrlA <= IDLE;
                        adrA <= stackpointerA + 1;
                        adrB <= stackpointerB - 1;
                    end if;
                elsif (ctrl = "10") then
                    -- A and B both tried to read last value!
                    -- but only A was allowed to read value so only update stackpointerA
                    ctrlA <= POP;
                    ctrlB <= IDLE;
                end if;
            when x"6" =>   --readA, writeB
                -- A read a valid value and B writes a new value
                -- update both stackpointers
                ctrlA <= POP;
                ctrlB <= PUSH;
                reA <= '1';
                adrA <= stackpointerA + 2;
                weB <= '1';
                adrB <= stackpointerB;
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if(last_operation = '1') then
                        --> deque is full!
                        -- A read a valid value, but B cant push!
                        ctrlB <= IDLE;
                        weB <= '0';
                        last_op_ctrl <= UNSET;
                        adrB <= stackpointerB - 1;
                    else
                        --> deque is empty!
                        -- A couldnt read a valid value, but B can push!
                        ctrlA <= IDLE;
                        adrA <= stackpointerA + 1;
                        last_op_ctrl <= SET;
                    end if;
                elsif (ctrl = "00") then
                    --> only one spot left
                    -- A read valid value, but B isnt allowed to write last value
                    ctrlB <= IDLE;
                    weB <= '0';
                    last_op_ctrl <= UNSET;
                    adrB <= stackpointerB - 1;
                end if;
            when x"7" =>   --readA, readB, writeB
                -- A and B read valid values and B writes a new value at the same spot
                -- Update stackpointerA and dont update stackpointer B
                ctrlA <= POP;
                adrB <= stackpointerB - 1;
                reB <= '1';
                weB <= '1';
                adrA <= stackpointerA + 2;
                reA <= '1';
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if last_operation = '1' then
                        --> deque is full!
                        -- A and B read a valid value, but B cant push!
                        ctrlB <= POP;
                        weB <= '0';
                        adrB <= stackpointerB - 2;
                        last_op_ctrl <= UNSET;
                    else
                        --> deque is empty!
                        -- A and B couldnt have read a valid value, but B can push!
                        adrA <= stackpointerA + 1;
                        ctrlA <= IDLE;
                        ctrlB <= PUSH;
                        weB <= '1';
                        adrB <= stackpointerB;
                        last_op_ctrl <= SET;
                    end if;
                elsif (ctrl = "00") then
                    --> only one spot left
                    -- A and B read valid values, but B isnt allowed to write new value
                    -- B sees full signl atm
                    ctrlB <= POP;
                    weB <= '0';
                    adrB <= stackpointerB - 2;
                    last_op_ctrl <= UNSET;
                elsif (ctrl = "10") then
                    --> only one element in deque
                    -- only A read a valid value, but B can write a new value
                    ctrlB <= PUSH;
                    weB <= '1';
                    adrB <= stackpointerB;
                    last_op_ctrl <= SET;
                end if;
            when x"8" =>   --writeA
                -- A writes a new value
                -- update stackpointer
                ctrlA <= PUSH;
                weA <= '1';
                adrA <= StackpointerA;
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if (last_operation = '1') then
                        --> deque is full
                        -- A cant write!
                        ctrla <= IDLE;
                        weA <= '0';
                        adrA <= stackpointerA + 1;
                    end if;
                end if;
            when x"9" =>   --writeA, readB
                -- A writes new value and B reada a valid value
                -- update both stackpointers
                ctrlA <= PUSH;
                ctrlB <= POP;
                reB <= '1';
                weA <= '1';
                adrA <= stackpointerA;
                adrB <= stackpointerB - 2;
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if (last_operation = '1') then
                        --> deque is full!
                        -- A cant write, but B read a valid value!
                        weA <= '0';
                        ctrlA <= IDLE;
                        adrA <= stackpointerA + 1;
                        last_op_ctrl <= SET;
                    else
                        --> deque is empty!
                        -- A can write, but B couldnt read a valid value!
                        ctrlB <= IDLE;
                        adrB <= stackpointerB - 1;
                        last_op_ctrl <= SET;
                    end if;
                elsif (ctrl = "10") then
                    --> only one element left
                    -- A can write new value, but B couldnt read a valid value
                    -- B sees empty signal atm
                    ctrlB <= IDLE;
                    adrB <= stackpointerB - 1;
                    last_op_ctrl <= SET;
                end if;
            when x"A" =>   --writeA, writeB
                -- A and B write new values
                -- update both Stackpointers
                ctrlA <= PUSH;
                ctrlB <= PUSH;
                weA <= '1';
                adrA <= stackpointerA;
                weB <= '1';
                adrB <= stackpointerB;
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if (last_operation = '1') then
                        --> deque is full!
                        -- A and B cant write!
                        ctrlA <= IDLE;
                        ctrlB <= IDLE;
                        weA <= '0';
                        weB <= '0';
                        adrB <= stackpointerB - 1;
                        adrA <= stackpointerA + 1;
                        last_op_ctrl <= UNSET;
                    else
                        --> deque is empty!
                        --> A and B can write!
                        last_op_ctrl <= SET;
                    end if;
                elsif (ctrl = "00") then
                    --> only one spot left.
                    -- only A is allowed to write
                    -- B got full signal
                    weB <= '0';
                    ctrlB <= IDLE;
                    adrB <= stackpointerB - 1;
                end if;
            when x"B" =>   --writeA, readB, writeB
                --> A writes a value and B read a valid value and writes a new value at the same spot!
                -- update stackpointerA and dont update stackpointerB
                ctrlA <= PUSH;
                weA <= '1';
                adrA <= stackpointerA;
                reB <= '1';
                weB <= '1';
                adrB <= stackpointerB - 1;
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if (last_operation = '1') then
                        --> deque is full!
                        -- A and B cant write, but B read a valid value!
                        ctrlB <= POP;
                        ctrlA <= IDLE;
                        weA <= '0';
                        weB <= '0';
                        adrA <= stackpointerA + 1;
                        adrB <= stackpointerB - 2;
                        last_op_ctrl <= UNSET;
                    else
                        --> deque is empty
                        --> A and B can write, but B couldnt read a valid value!
                        ctrlB <= PUSH;
                        adrB <= stackpointerB;
                        last_op_ctrl <= SET;
                    end if;
                elsif (ctrl = "00") then
                    --> only one spot left
                    -- only A can write last value
                    -- B only read a valid value
                    ctrlB <= POP;
                    weB <= '0';
                    adrB <= stackpointerB - 2;
                elsif (ctrl = "10") then
                    --> only one elemen left
                    --> B couldnt read value but A and B are allowed to write new values
                    ctrlB <= PUSH;
                    adrB <= stackpointerB;
                    last_op_ctrl <= SET;
                end if;
            when x"C" =>   --readA, writeA
                --> A read a valid value and writes a new value at the same spot!
                -- => dont update stackpointer!
                ctrlA <= IDLE;
                reA <= '1';
                weA <= '1';
                adrA <= stackpointerA + 1;
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if (last_operation = '1') then
                        --> deque is full!
                        -- A cant write, but read a valid value!
                        ctrlA <= POP;
                        weA <= '0';
                        adrA <= stackpointerA + 2;
                        last_op_ctrl <= UNSET;
                    else
                        --> deque is empty!
                        -- A can write, but couldnt read a valid value!
                        ctrlA <= PUSH;
                        adrA <= stackpointerA;
                        last_op_ctrl <= SET;
                    end if;
                end if;
            when x"D" =>   --readA, writeA, readB
                -- A and B read valid values and A writes a new value at the same spot
                -- dont update stackpointerA and update stackpointerB
                ctrlB <= POP;
                ctrlA <= IDLE;
                reA <= '1';
                weA <= '1';
                adrA <= stackpointerA + 1;
                reB <= '1';
                adrB <= stackpointerB - 2;
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if (last_operation = '1') then
                        --> deque is full!
                        -- A cant write new values, but A and B could read a valid value
                        ctrlA <= POP;
                        ctrlB <= POP;
                        adrA <= stackpointerA + 2;
                        weA <= '0';
                        last_op_ctrl <= UNSET;
                    else
                        --> deque is empty!
                        -- A and B couldnt read a valid value, but A can write a new value
                        ctrlA <= PUSH;
                        adrB <= stackpointerB - 1;
                        ctrlB <= IDLE;
                        adrA <= stackpointerA;
                        last_op_ctrl <= SET;
                    end if;
                elsif (ctrl = "10") then
                    --> only one element in deque
                    -- only A read valid value and can write a new value
                    adrB <= stackpointerB - 1;
                    ctrlB <= IDLE;
                    ctrlA <= IDLE;
                    adrA <= stackpointerA + 1;
                    last_op_ctrl <= SET;
                end if;
            when x"E" =>   --readA, writeA, writeB
                -- B writes a new value, A read a valid value and writes a new value at the same spot
                -- update stackpiunterB and dont update stackpointerA
                ctrlB <= PUSH;
                ctrlA <= IDLE;
                reA <= '1';
                weA <= '1';
                adrA <= stackpointerA + 1;
                weB <= '1';
                adrB <= stackpointerB;
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if (last_operation = '1') then
                        --> deque is full!
                        -- A and B cant write, but A could read valid value
                        weA <= '0';
                        weB <= '0';
                        ctrlA <= POP;
                        ctrlB <= IDLE;
                        adrB <= stackpointerB - 1;
                        adrA <= stackpointerA + 2;
                        last_op_ctrl <= UNSET;
                    else
                        --> deque is empty!
                        -- A couldnt read a valid value, but A and B can write new values
                        ctrlA <= PUSH;
                        ctrlB <= PUSH;
                        adrA <= stackpointerA;
                        last_op_ctrl <= SET;
                    end if;
                elsif (ctrl = "00") then
                    --> only one spot left
                    -- B cant write new value
                    ctrlB <= IDLE;
                    weB <= '0';
                    adrB <= stackpointerB - 1;
                end if;
            when x"F" =>   --readA, writeA,readB, writeB
                -- A and B read valid values and write new values at the same stackpointers
                -- dont update both stackpointers
                ctrlA <= IDLE;
                ctrlB <= IDLE;
                reA <= '1';
                weA <= '1';
                adrA <= stackpointerA + 1;
                weB <= '1';
                reB <= '1';
                adrB <= stackpointerB - 1;
                last_op_ctrl <= SET;
                if (ctrl = "01") then
                    if last_operation = '1' then
                        --> deque is full
                        -- A and B could read valid values but cant write new values
                        ctrlA <= POP;
                        ctrlB <= POP;
                        weA <= '0';
                        weB <= '0';
                        adrA <= stackpointerA + 2;
                        adrB <= stackpointerB - 2;
                        last_op_ctrl <= UNSET;
                    else
                        --> deque is empty
                        -- A and B couldnt read valid values but can both write new values
                        ctrlA <= PUSH;
                        ctrlB <= PUSH;
                        adrA <= stackpointerA;
                        adrB <= stackpointerB;
                        last_op_ctrl <= SET;
                    end if;
                elsif (ctrl = "10") then
                    --> only one elemet left
                    -- only A read last value, A replaces the last element
                    -- B just writes new value
                    -- B sees empty signal atm
                    ctrlB <= PUSH;
                    adrB <= stackpointerB;
                elsif (ctrl = "00") then
                    --> only one spot left
                    -- B read a valid value, but isnt allowed to write
                    -- B sees full signal atm
                    ctrlB <= POP;
                    adrB <= stackpointerB - 2;
                    weB <= '0';
                end if;
            when others =>  --nothing
                -- nothing happend/happens
                -- dont update stackpointers
                last_op_ctrl <= IDLE;
        end case;
    end process;

    process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                last_operation <= '0';
            else
                case( last_op_ctrl ) is
                    when IDLE =>
                        last_operation <= last_operation;
                    when SET =>
                        last_operation <= '1';
                    when UNSET =>
                        last_operation <= '0';
                    when others =>
                        last_operation <= last_operation;
                end case;
            end if;
        end if;
    end process;

    --stackpointerA operations
    process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                stackpointerA <= shift_right(to_unsigned(MIN_DEPTH-1,A_BITS),1);
            else
                case( ctrlA ) is
                    when IDLE =>
                        stackpointerA <= stackpointerA;
                    when PUSH =>
                        stackpointerA <= stackpointerA - 1;
                    when POP =>
                        stackpointerA <= stackpointerA + 1;
                    when others =>
                        stackpointerA <= stackpointerA;
                end case;
            end if;
        end if;
    end process;

    -- stackpointerB operations
    process(clk)
    begin
        if (rising_edge(clk)) then
            if (rst = '1') then
                stackpointerB <= shift_right(to_unsigned(MIN_DEPTH-1,A_BITS),1) + 1;
            else
                case( ctrlB ) is
                    when IDLE =>
                        stackpointerB <= stackpointerB;
                    when PUSH =>
                        stackpointerB <= stackpointerB + 1;
                    when POP =>
                        stackpointerB <= stackpointerB - 1;
                    when others =>
                        stackpointerB <= stackpointerB;
                end case;
            end if;
        end if;
    end process;

    -- sub of B and A
    process(sub, last_operation)
    begin
        fullA <= '0';
        fullB <= '0';
        validA <= '1';
        validB <= '1';
        case(to_integer(sub)) is
            when 0 =>
                ctrl <= "00"; -- let a or b write?
                    -- only one spot left
                    -- set one side to full!
                    -- at the moment A has higher priority
                    fullB <= '1';
            when 1 =>
                ctrl <= "01"; -- empty or full?
                if (last_operation = '1') then
                    fullA <= '1';
                    fullB <= '1';
                else
                    validA <= '0';
                    validB <= '0';
                end if;
            when 2 =>
                ctrl <= "10"; -- let a or b read?
                    -- onyl one element left
                    -- set one side to empty!
                    -- at the moment A has higher priority
                    validB <= '0';
            when 3 =>
                ctrl <= "11"; -- both can write/read
            when others =>
                ctrl <= "11";
        end case;
    end process;

end architecture;
