----------------------------------------------------------------------
-- FILE:        STORAGE.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 08/01/2025 - File created.
-- DESCRIPTION: EVM KEY-VALUE Persistent STORAGE.
-- COMMENTS:    The key rage is up to 2^32-1 as opposed to 2^256-1 in the actual EVM
--------------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity STORAGE is
    generic (
        WIDTH_KEY    : integer := 10;  
        STORAGE_DEPTH : integer := 1024; --2**31-1; -- Number of keys (Storage Slots)
        STORAGE_WIDTH : integer := 256  -- 256-bit wide values
    );
    port (
        clk      : in  std_logic;
        write_en : in  std_logic;
        key      : in  std_logic_vector(WIDTH_KEY-1 downto 0); -- Storage key (address)
        value    : in  std_logic_vector(STORAGE_WIDTH-1 downto 0); -- Input data
        value_out : out std_logic_vector(STORAGE_WIDTH-1 downto 0) -- Output data
    );
end entity;

architecture rtl of STORAGE is
    type Storage_Array is array (0 to STORAGE_DEPTH-1) of std_logic_vector(STORAGE_WIDTH-1 downto 0);
    signal RAM : Storage_Array := (others => (others => '0'));  -- Initialize to zero
    attribute ram_style : string;
    attribute ram_style of RAM : signal is "block";  -- Instructs Vivado to use BRAM

begin

    process (clk)
    begin
        if rising_edge(clk) then
            if write_en = '0' then
                RAM(to_integer(unsigned(key))) <= value;
            end if;
            value_out <= RAM(to_integer(unsigned(key)));
        end if;
    end process;
    

end architecture;
