----------------------------------------------------------------------
-- FILE:        FSM_EXPO.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 09/04/2025 - File created.
-- DESCRIPTION: FSM of a Shift and Add Multiplier
-- COMMENTS: 
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FSM_EXPO is
    generic(
        WIDTH2 : natural := 2;
        WIDTH  : natural := 256;
        WIDTH_CNTRL : natural := 7
    );
    port(
        clk : in std_logic;
        reset : in std_logic;
        baseIs2 : in std_logic;
        counter  : in unsigned(WIDTH - 1 downto 0);
        start    : in std_logic;
        reg_base : in unsigned(WIDTH - 1 downto 0);
        reg_expo : in unsigned(WIDTH - 1 downto 0); 
        doneSAMA : in std_logic;  
        doneSAMB : in std_logic;  
        selB       : out std_logic_vector(WIDTH2 - 1 downto 0); 
        selE       : out std_logic_vector(WIDTH2 - 1 downto 0); 
        fsmControl : out std_logic_vector(WIDTH_CNTRL - 1 downto 0) 

    );
end entity;
architecture rtl of FSM_EXPO is

    signal selR, enCntr, enR0, enR1, startSAMA, startSAMB, done, regA, regAnext, regB, regBnext, doneMult, rstMULT, rstDoneMult : std_logic;

    type states is (IDLE, WHAT_IS_E0, CHK_COUNTER, LDR0R1, RUN_MULT, STATE_DONE);
    signal reg_state, next_state : states;

begin

    fsmControl <= rstMULT & regB & regA & selR & enCntr & done & enR0 & enR1 & startSAMA & startSAMB;

    process(clk) is
        begin
            if rising_edge(clk) then
                if reset = '0' then
                    reg_state <= IDLE;
                elsif start = '1' then
                    reg_state <= next_state;
                end if;
            end if;
        end process;

        process(clk) is
        begin
            if rising_edge(clk) then
                if rstDoneMult = '0' then
                    regA <= '0';
                    regB <= '0';
                elsif start = '1' then
                    regA <= regAnext;
                    regB <= regBnext;
                end if;
            end if;
        end process;

        regAnext <= '1' when doneSAMA = '1' else regA; 
        regBnext <= '1' when doneSAMB = '1' else regB;  
        doneMult <= regA AND regB;

        process(reg_state, counter, start, counter, reg_base, reg_expo, doneMult, baseIs2) is
        begin
            selR <= '0';
            selB <= "00";
            selE <= "00";
            enCntr <= '0';
            done <= '0';
            enR0 <= '0';
            enR1 <= '0';
            startSAMA <= '0';
            startSAMB <= '0';
            rstMULT <= '0';
            rstDoneMult <= '0';            

            case reg_state is
                when IDLE =>
                    if start = '1' then -- Load base and exponent
                        selB <= "01";
                        selE <= "01";
                        enCntr <= '1';
                        if baseIs2 = '1' then
                            next_state <= STATE_DONE;
                        else
                            next_state <= RUN_MULT;
                        end if;
                    else
                        next_state <= IDLE;
                    end if;
                when RUN_MULT =>
                    rstMULT <= '1';
                    rstDoneMult <= '1';
                    startSAMA <= '1';
                    startSAMB <= '1';
                    if doneMult = '1' then
                        startSAMA <= '0';
                        next_state <= WHAT_IS_E0;
                    else
                        next_state <= RUN_MULT;
                    end if;
                when WHAT_IS_E0 =>
                    if reg_expo(0) = '1' then
                        enR0 <= '1';
                    end if;
                    enR1 <= '1';
                    enCntr <= '1';
                    next_state <= LDR0R1;
                when LDR0R1 => -- Load R0 and R1
                    if reg_expo(0) = '1' then
                        selR <= '1';
                    end if;
                    selB <= "10";
                    selE <= "10"; -- Shift right
                    next_state <= CHK_COUNTER;
                when CHK_COUNTER => -- Load results and base and check counter
                    if counter = WIDTH OR reg_base = 1 OR reg_expo = 0 then
                        done <= '1';
                        next_state <= STATE_DONE;
                    else
                        next_state <= RUN_MULT;
                    end if;
                when STATE_DONE =>
                    done <= '1';
                    next_state <= STATE_DONE;
                when others =>
                    next_state <= IDLE;
            end case;
        end process;
end architecture;