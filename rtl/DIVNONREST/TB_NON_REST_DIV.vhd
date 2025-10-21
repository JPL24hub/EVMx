--------------------------------------------------------------------------------------
-- FILE:        TB_DIVISOR.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 13/02/2025 - Testbench for DIVISOR module.
-- DESCRIPTION: Tests division module with various cases
-- COMMENTS:    
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TB_NON_REST_DIV is
end entity;

architecture sim of TB_NON_REST_DIV is

    constant WIDTH  : natural := 256;
    constant CLK_PERIOD : time := 1000 ns;

    signal clk         : std_logic := '0';
    signal rst         : std_logic := '0';
    signal start       : std_logic := '0';
    signal ready       : std_logic;
    signal a           : std_logic_vector(WIDTH - 1 downto 0)  := x"a9059cbb0000000000000000000000008833ed831300bf8fd01ab081c4ea1bab";
    signal b           : std_logic_vector(WIDTH - 1 downto 0) := x"0000000100000000000000000000000000000000000000000000000000000000";
    -- takes 1,027 cc to produce 00000000000000000000000000000000000000000000000000000000a9059cbb
    signal quotientOut, remainder : std_logic_vector(WIDTH - 1 downto 0);
    signal done_sim    : boolean := false;
begin
    -- Clock process
    clk <= not clk after CLK_PERIOD / 2 when done_sim = false else '0';

    -- Device Under Test (DUT)
    DUT : entity work.NON_REST_DIV
        generic map(WIDTH => WIDTH)
        port map(
            clk       => clk,
            rst       => rst,
            dividend  => a,
            divisor   => b,
            start     => start,
            ready     => ready,
            remainder => remainder,
            quotient  => quotientOut
        );

    -- Test Process
    stimulus : process
        variable expected_quotient : std_logic_vector(WIDTH - 1 downto 0);
    begin

        -- Test Cases
        for i in 1 to 5 loop
            -- Reset
            rst <= '0';
            wait for 2 * CLK_PERIOD;
            rst <= '1';

            case i is
                when 1 => 
                    a <= std_logic_vector(to_unsigned(7, WIDTH));
                    b <= std_logic_vector(to_unsigned(6, WIDTH));
                    expected_quotient := std_logic_vector(to_unsigned(1, WIDTH));

                when 2 => 
                    a <= std_logic_vector(to_unsigned(100, WIDTH));
                    b <= std_logic_vector(to_unsigned(10, WIDTH));
                    expected_quotient := std_logic_vector(to_unsigned(10, WIDTH));

                when 3 => 
                    a <= std_logic_vector(to_unsigned(256, WIDTH));
                    b <= std_logic_vector(to_unsigned(16, WIDTH));
                    expected_quotient := std_logic_vector(to_unsigned(16, WIDTH));

                when 4 => 
                    a <= std_logic_vector(to_unsigned(1024, WIDTH));
                    b <= std_logic_vector(to_unsigned(8, WIDTH));
                    expected_quotient := std_logic_vector(to_unsigned(128, WIDTH));

                when 5 => 
                    a <= std_logic_vector(to_unsigned(1, WIDTH));
                    b <= std_logic_vector(to_unsigned(1, WIDTH));
                    expected_quotient := std_logic_vector(to_unsigned(1, WIDTH));

                when others => 
                    a <= (others => '0');
                    b <= (others => '0');
                    expected_quotient := (others => '0');
            end case;

            -- Start the division process
            start <= '1';

            -- Wait for completion
            wait until ready = '1';
            wait for CLK_PERIOD;

            -- Assert result
            assert quotientOut = expected_quotient
                report "Test failed for A=" & integer'image(to_integer(unsigned(a))) &
                " B=" & integer'image(to_integer(unsigned(b))) &
                " Expected=" & integer'image(to_integer(unsigned(expected_quotient))) &
                " Got=" & integer'image(to_integer(unsigned(quotientOut)))
                severity error;

            wait for 2 * CLK_PERIOD;
        end loop;

        --Finish simulation
        report "All tests completed successfully." severity note;
        done_sim <= true;
        wait;
    end process;

end architecture;
