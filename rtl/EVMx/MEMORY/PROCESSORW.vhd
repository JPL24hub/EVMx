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
-- FILE:        MEMORY.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 28/11/2024 - File created.
-- DESCRIPTION: 
-- COMMENTS:    
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
-- Entity
entity PROCESSORW is
    generic(
        SIZE_COPY   : integer := 10;
        WIDTH_CNTR  : integer := 256;
        WIDTH_MEMORY_ADDR : integer := 256
    );
    port(
        clk       : in std_logic;
        rst       : in std_logic;
        start_wrt_mem : in std_logic;
        size      : in std_logic_vector(SIZE_COPY - 1 downto 0); 
        offDestOff: in std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0);
        cntr_out0 : in std_logic_vector(WIDTH_CNTR - 1 downto 0);
        done_wt   : out std_logic
    );
end entity;
architecture rtl of PROCESSORW is

    constant ONES  : unsigned(WIDTH_MEMORY_ADDR-1 downto 0) := (others => '1');

    type MEM_STATES is (IDLE, WRITE);
    signal reg_state, next_state : MEM_STATES := IDLE;
    signal diff : unsigned(WIDTH_MEMORY_ADDR-1 downto 0) := (others => '0');

begin
    FSM: process(clk) is
        begin
            if rising_edge(clk) then
                if rst = '0' then
                    reg_state <= IDLE;
                else
                    reg_state <= next_state;
                end if;
            end if;
        end process;

        diff <= unsigned(offDestOff) + unsigned(size) - 1;
    
        PROCESSOR0: process(reg_state, start_wrt_mem, offDestOff, size, cntr_out0, diff) is
        begin
            done_wt     <= '0';
            case reg_state is
                when IDLE =>
                    if start_wrt_mem = '1' then -- If we are writing or reading mem
                        next_state <= WRITE;
                    else
                        next_state <= IDLE;
                    end if;
                when WRITE =>
                    if unsigned(cntr_out0) = diff OR unsigned(cntr_out0) > diff  OR  diff = ONES then -- If we have written all the bytes. counter can only have 32 bytes
                        done_wt    <= '1';
                        next_state <= IDLE;
                    else
                        next_state <= WRITE;
                    end if;
                when others =>
                    next_state <= IDLE;
                end case;
        end process;
end architecture;