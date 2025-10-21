----------------------------------------------------------------------
-- FILE:        BYTECODE_MEM.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 22/03/2025 - File created.
-- DESCRIPTION: BYTECODE_MEM Memory using BRAMS.
-- COMMENTS:    
--------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity BYTECODE_MEM is
    generic(
        MEM_WIDTH  : natural := 8;       -- 8-bit words
        MEM_DEPTH  : natural := 32768;    -- 32K memory depth
        ADRR_WIDTH : natural := 16
    );
    port(
        toBYTCD   : in std_logic_vector(MEM_WIDTH - 1 downto 0); -- 256 bytes input
        wrtBYTCD  : in std_logic; -- Write Enable
        pc        : in std_logic_vector(ADRR_WIDTH - 1 downto 0); -- Base write address (15-bit for 32K depth)
        cnt2PC    : in std_logic_vector(ADRR_WIDTH - 1 downto 0); -- Address
        clk       : in std_logic;
        outBYTCD8 : out std_logic_vector(MEM_WIDTH - 1 downto 0);
        bytOutPC  : out std_logic_vector(MEM_WIDTH - 1 downto 0)
    );
end entity;

architecture rtl of BYTECODE_MEM is
    -- BRAM Instantiation (Using RAMB36E1)
    type ram_type is array (0 to MEM_DEPTH-1) of std_logic_vector(MEM_WIDTH-1 downto 0);
    signal RAM : ram_type := (others => (others => '0'));
    attribute ram_style : string;
    attribute ram_style of RAM : signal is "block";  -- Forces Block RAM Usage

begin
    -- Synchronous Memory Write (256 Words at a Time)
    process(clk)
    begin
        if rising_edge(clk) then
            if wrtBYTCD = '1' then
                RAM(to_integer(unsigned(pc))) <= toBYTCD;
            end if;
            -- Read Process
            outBYTCD8 <= RAM(to_integer(unsigned(pc)));
            bytOutPC <= RAM(to_integer(unsigned(cnt2PC)));
        end if;
    end process;

end architecture;
