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

entity TB_BOOTH_MULTIPLIER is
end entity;

architecture test of TB_BOOTH_MULTIPLIER is
    constant WIDTH : integer := 8;

    signal multiplicant : std_logic_vector(WIDTH-1 downto 0);
    signal multiplier   : std_logic_vector(WIDTH-1 downto 0);
    signal clk          : std_logic := '0';
    signal rst          : std_logic := '0';
    signal start        : std_logic := '0';
    signal done         : std_logic;
    signal product      : std_logic_vector((2*WIDTH)-1 downto 0);
    signal done_sim : boolean := false;

    -- Clock generation
    constant CLK_PERIOD : time := 1000 ns;

begin

    -- Instantiate the DUT
    UUT : entity work.BOOTH_MULTIPLIER(rtl)
        generic map(WIDTH => WIDTH)
        port map (
            multiplicant => multiplicant,
            multiplier   => multiplier,
            clk          => clk,
            rst          => rst,
            start        => start,
            done         => done,
            product      => product
        );

    -- Clock process
    clk <= not clk after CLK_PERIOD / 2 when done_sim = false else '0';

    -- Stimulus process
    stim_proc : process
        variable expected : std_logic_vector((2*WIDTH)-1 downto 0);
    begin
        
        -- Test cases
        for i in 10 to 20 loop
            for j in 10 to 20 loop

                -- Reset
                rst <= '0';
                wait for 2*CLK_PERIOD;

                rst <= '1';
                start <= '1';
                multiplicant <= std_logic_vector(to_signed(i, WIDTH));
                multiplier   <= std_logic_vector(to_signed(j, WIDTH));
                

                -- Wait for done signal
                wait until done = '1';

                -- Expected result
                expected := std_logic_vector(to_signed(i * j, 2*WIDTH));

                -- Self-check
                if product = expected then
                    report "PASS: " & integer'image(i) & " * " & integer'image(j)
                        & " = " & integer'image(to_integer(unsigned(product)));
                else
                    report "FAIL: " & integer'image(i) & " * " & integer'image(j)
                        & " /= " & integer'image(to_integer(unsigned(product)))
                        severity error;
                end if;

            end loop;
        end loop;
        
        done_sim <= true;
        report "All tests finished.";
        wait;
    end process;

end architecture;
