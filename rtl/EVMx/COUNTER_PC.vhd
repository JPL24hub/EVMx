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

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity COUNTER_PC is
    generic(
        WIDTH_PC  : integer := 10;
        WDTH_enPC : integer := 3
    );
    port(
        pc_inA  : in std_logic_vector(WIDTH_PC - 1 downto 0);
        pc_inB  : in std_logic_vector(WIDTH_PC - 1 downto 0);
        pc_inC  : in std_logic_vector(WIDTH_PC - 1 downto 0);
        clk     : in std_logic;
        rst     : in std_logic;
        enPC    : in std_logic_vector(WDTH_enPC - 1 downto 0);
        out_pc  : out std_logic_vector(WIDTH_PC - 1 downto 0)        
        );
end entity;
architecture rtl of COUNTER_PC is

    signal  pc, pc_next : unsigned(WIDTH_PC-1 downto 0) := (others=>'0');

begin
    -- Sync register
    process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '0' then
                pc <= (others => '0');
            else
                pc <= pc_next;
            end if;
        end if;
    end process;
    
    -- Next state
    with enPC select
    pc_next <= pc when "000",
                pc + 1 when "001",
                unsigned(pc_inA) when "010",
                unsigned(pc_inB) when "011",
                pc + unsigned(pc_inC) when others;
    
    -- Output
    out_pc <= std_logic_vector(pc);

end architecture;