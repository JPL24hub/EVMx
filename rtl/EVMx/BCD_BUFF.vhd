----------------------------------------------------------------------
-- FILE:        BCD_BUFF.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 25/03/2025 - File created.
-- DESCRIPTION: BUFFER to hold SC bytecode.
-- COMMENTS:    
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity BCD_BUFF is
    generic(
        WIDTH_8  : integer := 8;
        WIDTH_PC : integer := 10;
        BYTCD_LEN : integer := 1024
    );
    port(
        toBYTCD     : in std_logic_vector(BYTCD_LEN-1 downto 0); -- Input data
        wrtBYTCD    : in std_logic; -- EN writing
        pc          : in std_logic_vector(WIDTH_PC-1 downto 0); -- stackPC counts upto 256
        cnt2PC      : in std_logic_vector(WIDTH_PC-1 downto 0); -- stackPC counts upto 256
        clk         : in std_logic;
        outBYTCD8   : out std_logic_vector(WIDTH_8-1 downto 0);
        bytOutPC    : out std_logic_vector(WIDTH_8-1 downto 0)
  );
end entity;
architecture rtl of BCD_BUFF is
    constant MEM_WIDTH : natural := 8;
    constant MEM_DEPTH : natural := 128;
    type ram_type is array(0 to MEM_DEPTH-1) of std_logic_vector(MEM_WIDTH-1 downto 0);
    signal RAM : ram_type := (others => (others => '0')); 
begin

    process(clk) is
    begin
        if rising_edge(clk) then
            if (wrtBYTCD='1') then
                --RAM(to_integer(unsigned(pc))) <= toBYTCD;
                for i in 0 to MEM_DEPTH-1 loop
                    RAM(i) <= toBYTCD(BYTCD_LEN - MEM_WIDTH*i - 1 downto BYTCD_LEN - MEM_WIDTH - MEM_WIDTH*i);  
                end loop;
            end if;
        end if;
    end process;

    -- stackPC always points at data shown at ouput
    outBYTCD8 <= RAM(to_integer(unsigned(pc))) when  to_integer(unsigned(pc)) < MEM_DEPTH else RAM(MEM_DEPTH - 1);
    bytOutPC <= RAM(to_integer(unsigned(cnt2PC))) when  to_integer(unsigned(cnt2PC)) < MEM_DEPTH else RAM(MEM_DEPTH - 1);

end architecture;