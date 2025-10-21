----------------------------------------------------------------------
-- FILE:        ADD_SUB_CNTR.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 12/11/2024 - File created.
-- DESCRIPTION: ADD SUB counter.
-- COMMENTS:    
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Entity
entity ADD_SUB_CNTR is
    generic(WIDTH_CNTR : integer := 5);
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        sel_cntr    : in std_logic_vector(1 downto 0);
        data_in     : in std_logic_vector(WIDTH_CNTR - 1 downto 0);
        data_out    : out std_logic_vector(WIDTH_CNTR - 1 downto 0)
    );
end entity;

-- Architecture
architecture rtl of ADD_SUB_CNTR is
    signal counter_next, counter, diff : unsigned(WIDTH_CNTR - 1 downto 0);
begin
    process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '0' then
                counter <= (others=>'0');
            else
                counter <= counter_next;
            end if;
        end if;
    end process;

    -- Next state

    diff <= (others=>'0') when  (counter - 1) < 0 else  counter - 1;

    with sel_cntr select
    counter_next <= counter when "00",
    counter + 1 when "01",
    diff when "10",
    unsigned(data_in) when others;

    -- Output
    data_out <= std_logic_vector(counter);

end architecture;