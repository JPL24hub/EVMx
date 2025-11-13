-- SPDX-License-Identifier: CERN-OHL-W-2.0
--
-- This source describes Open Hardware and is licensed under the CERN-OHL-W v2.
-- 
-- You may redistribute and modify this source and make products using it under
-- the terms of the CERN-OHL-W v2 (Weakly Reciprocal).
--
-- You should have received a copy of the CERN-OHL-W v2 license with this source.
-- If not, see: https://cern-ohl.web.cern.ch/
--
-- The Documentation and source code for this project are available at:
-- https://github.com/JPL24hub/EVMx
--
-- COPYRIGHT (C) 2025 Joel Poncha Lemayian
----------------------------------------------------------------------
-- FILE:        EXPONENTIAL.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 26/09/2024 - File created.
-- DESCRIPTION: The Binary exponential algorithm.
-- COMMENTS:    It handles a^0, a^1, 1^b, 0^b, 2^b. You need to utilize booth mult in the process
--------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity EXPONENTIAL is
    generic (
        WIDTH : natural := 256
    );
    Port (
        clk      : in  STD_LOGIC;
        reset    : in  STD_LOGIC;
        start    : in  STD_LOGIC;
        base     : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
        exponent : in  STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
        expResult   : out STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
        done     : out STD_LOGIC
    );
end EXPONENTIAL;

architecture rtl of EXPONENTIAL is
    constant WIDTH_CNTRL : natural := 10;
    constant WIDTH2 : natural := 2;
    constant WIDTH3 : natural := 3;

    signal results, sigResults, res_nxt, reg_base, base_nxt, reg_expo, expo_nxt, counter, counter_nxt, base2  : unsigned(WIDTH - 1 downto 0);
    signal prod0, prod0_nxt, prod1, prod1_nxt : unsigned(2*WIDTH - 1 downto 0);
    signal productSAMA, productSAMB, saveA, saveAnext, saveB, saveBnext : std_logic_vector(2*WIDTH - 1 downto 0);
    signal selE, selB : std_logic_vector(1 downto 0);
    signal selR, enCntr, enR0, enR1, doneSAMA, startSAMA, doneSAMB, startSAMB, regA, regB, enSaveA, enSaveB, rstMULT, baseIs2 : std_logic;
    signal fsmControl : std_logic_vector(WIDTH_CNTRL - 1 downto 0);
    signal selRes : std_logic_vector(WIDTH3 - 1 downto 0) := (others=>'0');

begin

    -- 0x2^0xE0 = 2^224 = 1 << 224 
    base2 <= to_unsigned(1, WIDTH) sll to_integer(unsigned(exponent));
    --baseIs2 <= '1' when unsigned(base) = 2 else '0';
    with selRes select
        sigResults <= results when "000",
                    base2 when "001",
                    (others=>'0') when "010",
                    (0=>'1', others=>'0') when "011",
                    unsigned(base) when others;

    process(clk, base, exponent) is
    begin
        if unsigned(base) = 1 OR unsigned(exponent) = 0 then -- Base 1, Power 0
            selRes <= "011";
            baseIs2 <= '1';
        elsif(unsigned(base) = 0) then -- Base 0
            selRes <= "010";
            baseIs2 <= '1';
        elsif(unsigned(exponent) = 1) then -- Power 1
            selRes <= "100";
            baseIs2 <= '1';
        elsif unsigned(base) = 2 then
            selRes <= "001"; -- Shifting
            baseIs2 <= '1';
        else
            selRes <= "000"; -- Calculate
            baseIs2 <= '0';
        end if;
    end process;


    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '0' then
                reg_base <= (others => '0');
                reg_expo <= (others => '0');
                results <= (0=>'1', others => '0');
                counter <= (others => '0');
                prod0 <= (others => '0');
                prod1 <= (others => '0');
                saveA <= (others => '0');
                saveB <= (others => '0');
            elsif start = '1' then
                reg_base <= base_nxt;
                reg_expo <= expo_nxt;
                results  <= res_nxt;
                counter <= counter_nxt;
                prod0 <= prod0_nxt;
                prod1 <= prod1_nxt;
                saveA <= saveAnext;
                saveB <= saveBnext;
            end if;
        end if;
    end process;

        --prod0_nxt <= results * reg_base when enR0 = '1' else prod0;
        --prod1_nxt <= reg_base * reg_base when enR1 = '1' else prod1;
        prod0_nxt <= unsigned(saveA) when enR0 = '1' else prod0;
        prod1_nxt <= unsigned(saveB) when enR1 = '1' else prod1;
        saveAnext <= productSAMA when enSaveA = '1' else saveA;
        enSaveA <= NOT regA AND doneSAMA;
        saveBnext <= productSAMB when enSaveB = '1' else saveB;
        enSaveB <= NOT regB AND doneSAMB;

        res_nxt <= prod0(WIDTH - 1 downto 0) when selR = '1' else results;

        with selB select
            base_nxt <= reg_base when "00",
                    unsigned(base) when "01",
                    prod1(WIDTH - 1 downto 0) when others;

        with selE select
            expo_nxt <= reg_expo when "00",
                    unsigned(exponent) when "01",
                    '0' & reg_expo(WIDTH-1 downto 1) when others; -- Right shift

        counter_nxt <= counter + 1 when enCntr = '1' else counter;
        expResult <= std_logic_vector(sigResults);

        -- SHIFT_ADD_MULT_A
        --SHIFT_ADD_MULT_A : entity work.SHIFT_ADD_MULT(rtl)
        --generic map(WIDTH => WIDTH)
        --port map(
        --    A => std_logic_vector(results),
        --    B => std_logic_vector(reg_base),
        --    clk => clk,
        --    rst => rstMULT,
        --    start => startSAMA,
        --    done => doneSAMA,
        --    product => productSAMA
        --);
        
        BOOTH_MULTA : entity work.BOOTH_MULTIPLIER(rtl)
        generic map(WIDTH => WIDTH)
        port map (
            multiplicant => std_logic_vector(results),
            multiplier   => std_logic_vector(reg_base),
            clk          => clk,
            rst          => rstMULT,
            start        => startSAMA,
            done         => doneSAMA,
            product      => productSAMA
        );

        -- SHIFT_ADD_MULT_B
        --SHIFT_ADD_MULT_B : entity work.SHIFT_ADD_MULT(rtl)
        --generic map(WIDTH => WIDTH)
        --port map(
        --    A => std_logic_vector(reg_base),
        --    B => std_logic_vector(reg_base),
        --    clk => clk,
        --    rst => rstMULT,
        --    start => startSAMB,
        --    done => doneSAMB,
        --    product => productSAMB
        --);

        BOOTH_MULTB : entity work.BOOTH_MULTIPLIER(rtl)
        generic map(WIDTH => WIDTH)
        port map (
            multiplicant => std_logic_vector(reg_base),
            multiplier   => std_logic_vector(reg_base),
            clk          => clk,
            rst          => rstMULT,
            start        => startSAMB,
            done         => doneSAMB,
            product      => productSAMB
        );
        
        -- FSM
        FSM_EXPO : entity work.FSM_EXPO(rtl)
        generic map(
            WIDTH2 => WIDTH2,
            WIDTH  => WIDTH,
            WIDTH_CNTRL => WIDTH_CNTRL 
        )
        port map(
            clk => clk,
            reset => reset,
            baseIs2 => baseIs2,
            counter    => counter,     
            start      => start,       
            reg_base   => reg_base,
            reg_expo   => reg_expo,     
            doneSAMA   => doneSAMA,   
            doneSAMB   => doneSAMB,   
            selB       => selB,       
            selE       => selE,      
            fsmControl => fsmControl
        );
        rstMULT <= fsmControl(9);
        regB <= fsmControl(8);
        regA <= fsmControl(7);
        selR <= fsmControl(6);
        enCntr <= fsmControl(5);
        done <= fsmControl(4);
        enR0 <= fsmControl(3);
        enR1 <= fsmControl(2);
        startSAMA <= fsmControl(1);
        startSAMB <= fsmControl(0);
end architecture;
