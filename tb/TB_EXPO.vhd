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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity TB_EXPO is
end TB_EXPO;

architecture test of TB_EXPO is
    constant CLK_PERIOD : time := 1000 ns;
    constant WIDTH : natural := 256;

    signal clk     : STD_LOGIC := '0';
    signal reset   : STD_LOGIC := '0';
    signal start   : STD_LOGIC := '0';
    signal a       : STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    signal b       : STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    signal result  : STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    signal done    : STD_LOGIC;
    signal done_sim: boolean := false;

begin
    EXPONENTIAL: entity work.EXPONENTIAL(rtl)
        generic map (
            WIDTH => WIDTH
        )
        port map (
            clk     => clk,
            reset   => reset,
            start   => start,
            base    => a,
            exponent=> b,
            expResult  => result,
            done    => done    
        );

        clk <= not clk after CLK_PERIOD / 2 when done_sim = false else '0';

    stim_process: process

        variable expected : STD_LOGIC_VECTOR(WIDTH - 1 downto 0);
    
    begin 

        for i in 0 to 5 loop
            for j in 0 to 5 loop

                reset <= '0';
                wait for 2*CLK_PERIOD;

                reset <= '1';
                start <= '1';
                a <= std_logic_vector(to_unsigned(i, WIDTH));
                b <= std_logic_vector(to_unsigned(j, WIDTH)); -- 13 
                
                wait until done = '1';

                expected := std_logic_vector(to_unsigned(i ** j, WIDTH));

                -- Self-check
                if result = expected then
                    report "PASS: " & integer'image(i) & " pow " & integer'image(j)
                        & " = " & integer'image(to_integer(unsigned(result)));
                else
                    report "FAIL: " & integer'image(i) & " pow " & integer'image(j)
                        & " /= " & integer'image(to_integer(unsigned(result)))
                        severity error;
                end if;

            end loop;
        end loop;

        done_sim <= true;
        report "All tests finished.";
        wait;
    end process;
end test;
