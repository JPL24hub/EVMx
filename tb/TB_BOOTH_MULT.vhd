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
-- FILE:        TB_BOOTH_MULT.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 13/02/2025 - File created.
-- DESCRIPTION: Testbench for the BOOTH_MULTIPLIER module.
-- COMMENTS: It is not working for A = "1001" and B = "0010".
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TB_BOOTH_MULT is
end TB_BOOTH_MULT;

architecture sim of TB_BOOTH_MULT is

    constant WIDTH : natural := 4;
    constant CLK_PERIOD : time := 1000 ns;

    signal multiplicant        : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal multiplier        : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal clk      : std_logic := '1'; 
    signal rst      : std_logic := '0'; 
    signal start    : std_logic := '0';
    signal done     : std_logic;
    signal product  : std_logic_vector(2*WIDTH-1 downto 0);
    signal done_sim : boolean := false;

begin

    UUT : entity work.BOOTH_MULTIPLIER(rtl)
        generic map(WIDTH => WIDTH)
        port map(
            multiplicant => multiplicant,
            multiplier => multiplier,
            clk => clk,
            rst => rst,
            start => start,
            done => done,
            product => product
        );

    clk <= not clk after CLK_PERIOD / 2 when done_sim = false else '0';

    stimulus : process
    begin
        wait for CLK_PERIOD*2;

        rst <= '1';
        multiplicant <= "0010"; -- 2
        multiplier <= "0110"; -- 6
        start <= '1';
        wait until done = '1';
        start <= '0';
        wait for 2*CLK_PERIOD;
        done_sim <= true;

        wait for 2*CLK_PERIOD;

        wait;
    end process;


end architecture sim;