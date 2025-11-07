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
-- FILE:        CALLDATACOPY.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 21/01/2025 - File created.
-- DESCRIPTION: Used to execute the CALLDATACOPY.
-- COMMENTS:    It copies a given size of data running int the current environment starting from a given offset and writes it to Memory 1 byte at a time.
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

-- Entity
entity CALLDATACOPY is
    generic(
        WIDTH_INPUT : integer := 1024;
        WIDTH_256 : integer := 256;
        WIDTH_CNTR : integer := 10
        );
    port(
        clk      : in std_logic;
        rst      : in std_logic;
        cntlCntr0  : in std_logic_vector(1 downto 0);
        callData : in std_logic_vector(WIDTH_INPUT-1 downto 0);
        offset   : in std_logic_vector(WIDTH_256-1 downto 0);
        outCallData : out std_logic_vector(WIDTH_256-1 downto 0) := (others=>'0')
    );
end entity;
architecture rtl of CALLDATACOPY is
    constant ZEROS248 : std_logic_vector(247 downto 0) := (others=>'0');
    signal cntr_out0, cntr_out1, offsetIN : std_logic_vector(WIDTH_CNTR - 1 downto 0);
begin

    COUNTER_0: entity work.COUNTER_NEW(rtl)
    generic map(WIDTH_CNTR => WIDTH_CNTR)
    port map(
        clk      => clk,     
        rst      => rst,     
        sel_cntr => cntlCntr0,
        data_in  => offsetIN, 
        data_out => cntr_out1);

        -- Assign offsetIN
        offsetIN <= offset(WIDTH_CNTR - 1 downto 0);

        cntr_out0 <= cntr_out1 when unsigned(cntr_out1) < (WIDTH_INPUT / 8) else std_logic_vector(to_unsigned((WIDTH_INPUT / 8) - 1, WIDTH_CNTR));

        -- Read data from callData
        outCallData <= ZEROS248 & callData(WIDTH_INPUT - 1 - to_integer(unsigned(cntr_out0)) * 8 downto WIDTH_INPUT - to_integer(unsigned(cntr_out0)) * 8 - 8);

end architecture;