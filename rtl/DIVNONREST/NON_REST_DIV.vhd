--------------------------------------------------------------------------------------
-- FILE:        NON_REST_DIV.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.2 - 13/02/2025 - File created.
-- DESCRIPTION: Division module using DSP slices
-- COMMENTS:    Implementing a non-restoring division algorithm. Handles edge cases: a/1, a/0, a/a+1, a/a, 0/a .
--------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity NON_REST_DIV is
    generic (WIDTH : natural := 256);
    port (
        clk         : in  std_logic;  -- Clock signal
        rst         : in  std_logic;  -- Reset signal (active low)
        dividend    : in  std_logic_vector(WIDTH - 1 downto 0); -- Numerator
        divisor     : in  std_logic_vector(WIDTH - 1 downto 0); -- Denominator
        start       : in  std_logic;  -- Start signal
        ready       : out std_logic;  -- Ready signal
        remainder   : out std_logic_vector(WIDTH - 1 downto 0);
        quotient    : out std_logic_vector(WIDTH - 1 downto 0) -- Quotient result
    );
end entity;

architecture rtl of NON_REST_DIV is
    constant ZEROS : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    constant ONE : std_logic_vector(WIDTH-1 downto 0) := (0=>'1',others => '0');

    signal regA, regA_nxt, regQ, regQ_nxt, sigALU, sigLS, regM, regM_nxt : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal selM, op, enCntr, selRmr : std_logic;
    signal selA, selQnt : std_logic_vector(1 downto 0);
    signal selQ : std_logic_vector(2 downto 0);
    signal counter, counter_nxt : natural := 0;
    -- 
    type states is (IDLE, LOAD, SHIFT, DONE, ADD_STATE, SUB_STATE, QSTATE, WATISN);
    signal reg_state, next_state : states;

begin
    process (clk) is
    begin
        if rising_edge(clk) then
            if rst = '0' then
                regA <= (others => '0');
                regQ <= (others => '0');
                regM <= (others => '0');
                counter <= 0;
            else
                regA <= regA_nxt;
                regQ <= regQ_nxt;
                regM <= regM_nxt;
                counter <= counter_nxt;
            end if;
        end if;
    end process;
    
    -- Register A
    with selA select
        regA_nxt <= regA when "00", -- Load A
                sigALU when "01", -- ALU operation
                sigLS when others; -- Shift A left

        sigLS <= regA(WIDTH - 2 downto 0) & regQ(WIDTH-1); -- Shift A left
        sigALU <= regA + NOT regM + 1 when op = '1' else regA + regM; -- ALU operation

    -- Register Q
    with selQ select
        regQ_nxt <= regQ when "000", -- Retain Q
                regQ(WIDTH - 2 downto 0) & '0' when "001", -- Shift Q left
                regQ(WIDTH - 1 downto 1) & '0' when "010", -- regQ(0) = 0
                regQ(WIDTH - 1 downto 1) & '1' when "011", -- regQ(0) = 1
                unsigned(dividend) when others; -- Load Q
    
    -- Register M
    regM_nxt <=  unsigned(divisor) when selM = '1' else regM; -- Load M

    -- Counter
    counter_nxt <= counter + 1 when enCntr = '1' else counter; -- Counter

    -- Output signals
    with selQnt select
        quotient <= std_logic_vector(regQ) when "00", -- Quotient
                ZEROS when "01",
                dividend when "10",
                ONE when others;
    
    remainder <= ZEROS when selRmr = '1' else std_logic_vector(regA); -- Remainder

    -- Controler
    process(clk, rst) is
        begin
            if rising_edge(clk) then
                if(rst='0') then
                    reg_state <= idle;
                else
                    reg_state <= next_state;
                end if;
            end if;
        end process;


        process(reg_state, start, counter, regA, divisor, dividend) is
            begin
                op <= '0';
                ready <= '0';
                selA <= "00";
                selQ <= "000";
                selM <= '0';
                enCntr <= '0';
                selRmr <= '0';
                selQnt <= "00";

                case reg_state is
                    when IDLE =>
                        if start = '1' then
                            next_state <= LOAD;
                        else
                            next_state <= IDLE;
                        end if;
                    when LOAD =>
                        selM <= '1'; -- Load M
                        selQ <= "100"; -- Load Q
                        if unsigned(divisor) = 1 then
                            selRmr <= '1'; -- Remainder = 0
                            selQnt <= "10"; -- Quotient = dividend
                            ready <= '1';
                            next_state <= IDLE;
                        elsif(unsigned(dividend) < unsigned(divisor) OR  unsigned(divisor) = 0 OR  unsigned(dividend) = 0) then
                            selRmr <= '1'; -- Remainder = 0
                            selQnt <= "01"; -- Quotient = 0
                            ready <= '1';
                            next_state <= IDLE;
                        elsif(unsigned(dividend) = unsigned(divisor)) then
                            selRmr <= '1'; -- Remainder = 0
                            selQnt <= "11"; -- Quotient = 1
                            ready <= '1';
                            next_state <= IDLE;
                        else
                            next_state <= SHIFT;
                        end if;
                    when SHIFT => -- Shift left AQ
                        selA <= "10"; -- Shift A
                        selQ <= "001"; -- Shift Q
                        if regA(WIDTH - 1) = '1' then
                            next_state <= ADD_STATE;
                        else
                            op <= '0'; -- A = A + M
                            next_state <= SUB_STATE;
                        end if;
                    when ADD_STATE =>
                        selA <= "01"; -- A = A + M
                        next_state <= QSTATE;
                    when SUB_STATE =>
                        op <= '1'; -- A = A - M
                        selA <= "01"; -- A = A - M
                        next_state <= QSTATE;
                    when QSTATE =>
                        enCntr <= '1'; -- Enable counter
                        if regA(WIDTH - 1) = '1' then
                            selQ <= "010"; -- Q(0) = 0
                            next_state <= WATISN;
                        else
                            selQ <= "011"; -- Q(0) = 1
                            next_state <= WATISN;
                        end if;
                    when WATISN =>
                        if counter = WIDTH then
                            if regA(WIDTH - 1) = '1' then
                                selA <= "01"; -- A = A + M
                            end if;
                            next_state <= DONE;
                        else
                            next_state <= SHIFT;
                        end if;
                    when DONE =>
                        ready <= '1';
                        next_state <= IDLE;
                    when others =>
                        next_state <= IDLE;
                end case;
            end process;



end architecture;
