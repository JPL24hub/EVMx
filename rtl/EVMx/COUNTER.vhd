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
----------------------------------------------------------------------
-- FILE:        COUNTER.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 18/12/2024 - File created.
-- DESCRIPTION: Counts the number of bytes in the bytecode.
-- COMMENTS:    
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

-- Entity
entity COUNTER is
    generic(
        WIDTH_OUT   : integer := 256
    );
    port(
        clk         : in  std_logic;   -- Clock input
        rst         : in  std_logic;   -- Reset input
        en          : in  std_logic;
        cnt         : out std_logic_vector(WIDTH_OUT - 1 downto 0)
    );
end entity;

-- Architecture
architecture rtl of COUNTER is

    signal reg, nxt_reg : unsigned(WIDTH_OUT - 1 downto 0) := (others => '0'); -- Internal register

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
    nxt_reg <= reg + 1 when en = '1' else reg;

    -- Assign the internal data to the output
    cnt <= std_logic_vector(reg);

end architecture;