----------------------------------------------------------------------
-- FILE:        MEMORY.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 10/11/2024 - File created.
-- DESCRIPTION: This module uses BRAMs to implement the MEMORY.
-- COMMENTS:    
--------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity MEMORY is
    generic(RAM_DEPTH : integer := 1024;
            RAM_WIDTH : integer := 8;
            ARRD_WIDTH : integer := 256);
    port(
        clk     : in std_logic;
        we      : in std_logic;
        wt_addr : in unsigned(ARRD_WIDTH-1 downto 0);
        rd_addr : in unsigned(ARRD_WIDTH-1 downto 0);
        di      : in std_logic_vector(RAM_WIDTH-1 downto 0);
        do      : out std_logic_vector(RAM_WIDTH-1 downto 0)
    );
end MEMORY;

architecture rtl of MEMORY is
type ram_type is array (0 to RAM_DEPTH-1) of std_logic_vector(0 to RAM_WIDTH-1);
signal RAM : ram_type := (others=>(others=>'0'));
attribute ram_style : string;
attribute ram_style of RAM : signal is "block";  -- Instructs Vivado to use BRAM

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                RAM(to_integer(wt_addr)) <= di;
            end if;
            do <= RAM(to_integer(rd_addr));
        end if;
    end process;

end rtl;
