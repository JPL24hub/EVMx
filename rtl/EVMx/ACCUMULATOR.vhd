----------------------------------------------------------------------
-- FILE:        ACCUMULATOR.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 18/12/2024 - File created.
-- DESCRIPTION: Accumulates data from bytecode memory using a shift register.
-- COMMENTS:    
--------------------------------------------------------------------------------------
-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity
entity ACCUMULATOR is
    generic (
        WIDTH_IN    : integer := 8;
        WIDTH_OUT   : integer := 256
    );
    port(
        clk         : in  std_logic;   -- Clock input
        rst         : in  std_logic;   -- Reset input
        en          : in  std_logic;
        oneByte_in  : in std_logic_vector(WIDTH_IN - 1 downto 0); 
        accmBytes   : out std_logic_vector(WIDTH_OUT - 1 downto 0)
    );
end entity;

-- Architecture
architecture rtl of ACCUMULATOR is

    signal reg, nxt_reg : STD_LOGIC_VECTOR(WIDTH_OUT - 1 downto 0) := (others => '0'); -- Internal register

begin

    process(clk, rst)
    begin
        if rising_edge(clk) then
            if rst = '0' then
                -- Reset the internal register
                reg <= (others => '0');
            else
                -- Shift left by 8 bits and append the new byte at the least significant end
                reg <= nxt_reg;
            end if;
        end if;
    end process;

    --Next state
    nxt_reg <= reg(WIDTH_OUT - 1 - 8 downto 0) & oneByte_in when en = '1' else reg;

    -- Assign the internal data to the output
    accmBytes <= reg;

end architecture;
