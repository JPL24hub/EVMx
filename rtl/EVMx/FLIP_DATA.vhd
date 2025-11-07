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