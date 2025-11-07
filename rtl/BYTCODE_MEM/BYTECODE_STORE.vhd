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
-- FILE:        BYTECODE_STORE.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 25/03/2025 - File created.
-- DESCRIPTION: FSM to control RAM BUF.
-- COMMENTS:    
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity BYTECODE_STORE is
    generic(
        INPUT_WIDTH : natural := 1024;
        OUPUT_WIDTH : natural := 8;
        WIDTH_PC    : natural := 10
    );
    port(
        clk : in std_logic;
        rst : in std_logic;
        start : in std_logic;
        RAMloaded : in std_logic; -- Assert after loading RAM
        ldNext : in std_logic;
        toBYTCD : in std_logic_vector(INPUT_WIDTH - 1 downto 0);
        pc : in std_logic_vector(WIDTH_PC - 1 downto 0);
        cnt2PC : in std_logic_vector(WIDTH_PC - 1 downto 0);
        readBUFF : out std_logic;
        bytOutPC  : out std_logic_vector(OUPUT_WIDTH - 1 downto 0);
        outBYTCD8 : out std_logic_vector(OUPUT_WIDTH - 1 downto 0)
    );
end entity;
architecture rtl of BYTECODE_STORE is
    constant RAM_DEPTH  : natural := 256;
    constant ARRD_WIDTH : natural := 8;
    constant BYTCD_LEN  : natural :=  1024;

    signal we_RAM, en_BUFF, enCntrA, enCntrB : std_logic;
    signal outRAM : std_logic_vector(BYTCD_LEN - 1 downto 0);
    signal counterA, counterA_next, counterB, counterB_next : unsigned(ARRD_WIDTH - 1 downto 0);

    type STATES is (IDLE, LOAD_RAM, READ_BUFF, STATE_DONE);
    signal reg_state, next_state : STATES := IDLE;

begin

    -- BCD_RAM
    BCD_RAM : entity work.BCD_RAM(rtl)
    generic map(
            RAM_DEPTH  => RAM_DEPTH , 
            RAM_WIDTH  => INPUT_WIDTH,
            ARRD_WIDTH => ARRD_WIDTH
    )
    port map(
        clk     => clk,     
        we      => we_RAM,      
        wt_addr => counterA, 
        rd_addr => counterB, 
        di      => toBYTCD,      
        do      => outRAM      
    );

    -- BCD BUFFER
    BCD_BUFF : entity work.BCD_BUFF(rtl)
    generic map(
        WIDTH_8   => OUPUT_WIDTH,  
        WIDTH_PC  => WIDTH_PC, 
        BYTCD_LEN => BYTCD_LEN
    )
    port map(
        toBYTCD   => outRAM,  
        wrtBYTCD  => en_BUFF, 
        pc        => pc,       
        cnt2PC    => cnt2PC,   
        clk       => clk,      
        outBYTCD8 => outBYTCD8,
        bytOutPC  => bytOutPC 
    );

    FSM_R: process(clk) is
        begin
            if rising_edge(clk) then
                if rst = '0' then
                    reg_state <= IDLE;
                    counterA <= (others=>'0');
                    counterB <= (others=>'0');
                else
                    reg_state <= next_state;
                    counterA <= counterA_next;
                    counterB <= counterB_next;
                end if;
            end if;
        end process;

        counterA_next <= counterA + 1 when enCntrA = '1' else counterA;
        counterB_next <= counterB + 1 when enCntrB = '1' else counterB;

    process(reg_state, start, RAMloaded, counterB, ldNext, counterA) is
    begin
        enCntrA <= '0';
        en_BUFF <= '0';
        enCntrB <= '0';
        we_RAM <= '0';
        readBUFF <= '0';

        case reg_state is
            when IDLE =>
                if start = '1' then
                    we_RAM <= '1';
                    enCntrA <= '1';
                    next_state <= LOAD_RAM;
                else
                    next_state <= IDLE;
                end if;
            when LOAD_RAM =>
                enCntrA <= '1';
                we_RAM <= '1';
                if RAMloaded = '1' then
                    en_BUFF <= '1';
                    we_RAM <= '0';
                    enCntrA <= '0';
                    enCntrB <= '1';
                    next_state <= READ_BUFF;
                else
                    next_state <= LOAD_RAM;
                end if;
            when READ_BUFF =>
                readBUFF <= '1';
                if counterB > RAM_DEPTH - 1  then
                    next_state <= STATE_DONE;
                elsif ldNext = '1' then
                    en_BUFF <= '1';
                    enCntrB <= '1';
                    next_state <= READ_BUFF;
                else
                    next_state <= READ_BUFF;
                end if;
            when STATE_DONE =>
                next_state <= STATE_DONE;
            when others =>
                next_state <= IDLE;
        end case;

    end process;


end architecture;