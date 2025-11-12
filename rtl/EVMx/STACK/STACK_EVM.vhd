
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
-- FILE:        STACK_PNTR.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 26/09/2024 - File created.
-- DESCRIPTION: This module implements STACK with push and pop mechanism.
-- COMMENTS:    
--------------------------------------------------------------------------------------
-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity
entity STACK_EVM is
    generic (
        DEPTH_STACK : integer := 1024; -- Define depth of stack
        WIDTH_STACK : integer := 256;  -- Define the size of word the stack
        DUP_OFFSET  : integer := 10    -- Defines the address size of stack
    );
    port(
        clk         : in  std_logic;   -- Clock input
        reset       : in  std_logic;   -- Reset input
        we          : in  std_logic;   -- Only needed when pushing, should 0 when not writing
        push        : in  std_logic;   -- Push operation control input
        pop         : in  std_logic;   -- Pop operation control input
        data_in     : in  std_logic_vector(WIDTH_STACK-1 downto 0); -- Input data to be pushed
        wrt         : in  std_logic; -- Write STACK at a particular address
        addr_offset : in  std_logic_vector(DUP_OFFSET-1 downto 0);
        data_out    : out std_logic_vector(WIDTH_STACK-1 downto 0) := (others=>'0') -- Output data popped from the stack
    );
end entity;

-- Architecture
architecture rtl of STACK_EVM is

    signal pointer, pointer_next, sig_addr  : unsigned(DUP_OFFSET-1 downto 0);
    signal cntl_stack : std_logic_vector(1 downto 0) := "00"; -- push, pop, wrt
    signal cntl_pntr : std_logic_vector(1 downto 0) := "00"; -- push, pop, wrt

begin

    PROC_PNTER : process(clk) is
    begin
        if rising_edge(clk) then
            if reset = '0' then
                pointer <= (others=>'0');
            else
                pointer <= pointer_next;
            end if;
        end if;
    end process;

    cntl_stack <= push & pop;

    PROC_CNTRL: process(cntl_stack, pointer, pointer_next) is
    begin
        case cntl_stack is
            when "10" => -- push
                if pointer < DEPTH_STACK then
                    pointer_next <= pointer + 1;
                end if;
            when "01" => -- pop
                if pointer > 0 then
                    pointer_next <= pointer - 1;
                end if;
            when others =>
                pointer_next <= pointer;
            end case;
    end process;

    cntl_pntr <= pop & wrt;

    PROC_PNTR: process(cntl_pntr, pointer_next, pointer, addr_offset) is
    begin
        case cntl_pntr is
            when "10" => -- pop
                sig_addr <= pointer_next;
            when "01" => -- pop
                sig_addr <= unsigned(addr_offset);
            when others =>
                sig_addr <= pointer;
            end case;
    end process;

    -- Instantiate STACK
    STACK: entity work.STACK(rtl)
    generic map(RAM_DEPTH  => DEPTH_STACK, 
                RAM_WIDTH  => WIDTH_STACK,
                ARRD_WIDTH => DUP_OFFSET)
    port map(
        clk     => clk,
        we      => we,
        addr    => sig_addr,
        di      => data_in,
        do      => data_out
    );

end architecture;

