----------------------------------------------------------------------
-- FILE:        STACK.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 26/09/2024 - File created.
-- DESCRIPTION: This module uses BRAMs to implement the stack.
-- COMMENTS:    
--------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity STACK is
    generic(RAM_DEPTH : integer := 1024;
            RAM_WIDTH : integer := 256;
            ARRD_WIDTH : integer := 10);
    port(
        clk     : in std_logic;
        we      : in std_logic;
        addr    : in unsigned(ARRD_WIDTH-1 downto 0);
        di      : in std_logic_vector(RAM_WIDTH-1 downto 0);
        do      : out std_logic_vector(RAM_WIDTH-1 downto 0)
    );
end STACK;

architecture rtl of STACK is
type ram_type is array (0 to RAM_DEPTH-1) of std_logic_vector(RAM_WIDTH-1 downto 0);
signal RAM : ram_type := (others=>(others=>'0'));
attribute ram_style : string;
attribute ram_style of RAM : signal is "block";  -- Instructs Vivado to use BRAM

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                RAM(to_integer(addr)) <= di;
            end if;
            do <= RAM(to_integer(addr));
        end if;
    end process;

end rtl;