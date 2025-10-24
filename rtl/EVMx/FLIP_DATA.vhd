----------------------------------------------------------------------
-- FILE:        FLIP_DATA.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 04/01/2025 - File created.
-- DESCRIPTION: Flips input data
-- COMMENTS:   
--------------------------------------------------------------------------------------
-- Library declaration
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

-- Entity declaration
entity FLIP_DATA is
    generic (
        WIDTH_DATA : integer := 256
        );
    port(
        toFLIP : in  std_logic_vector(WIDTH_DATA-1 downto 0); -- Input data
        outFLIP: out std_logic_vector(WIDTH_DATA-1 downto 0) -- Flipped data
    );
end entity;
-- Architecture declaration
architecture rtl of FLIP_DATA is
begin
    -- Flips the input data
   Flip: for i in 0 to WIDTH_DATA-1 generate
        outFLIP(i) <= toFLIP(WIDTH_DATA - 1 - i);
    end generate Flip;
end architecture;