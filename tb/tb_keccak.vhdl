
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
use work.pkg_keccak_types.all;
use work.all;

use ieee.std_logic_textio.all;
library std;
use std.textio.all;


entity tb_keccak is
end entity tb_keccak;

architecture arch of tb_keccak is
    
    constant t : sha3_type := sha256;
    constant input_width : natural := 1600;
    constant data_width : natural := 1024;
    constant WIDTH_SIZE : integer := 10;

    constant clk_frq : natural := 1e6;
    constant clk_prd : time     := 1 sec / clk_frq;

    signal pad_in       : std_logic_vector(data_width-1 downto 0) := x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFFFFFF000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFFFFFF"; --input of pad --resulst = 29045a592007d0c246ef02c2223570da9522d0cf0f73282c79a1bc8f0bb2c238
    signal size         : std_logic_vector(WIDTH_SIZE - 1 downto 0) := "0000000100"; -- 4
    signal pad_out      : std_logic_vector(input_width-1 downto 0); --output of pad
    signal rst          : std_logic := '0'; --active low
    signal clk          : std_logic := '1';
    signal start        : std_logic := '0';
    signal mode         : sha3_mode := init;
    signal output_sha3  : std_logic_vector(getHashSize(t) - 1 downto 0);
    signal ready        : std_logic;

    signal sim_done : boolean := false;
    --constant v_file : string := "in_textFile.txt";
    file open_v_file : text;

    signal  output_data : std_logic_vector(getHashSize(t) - 1 downto 0);

begin

--    --process
--     process
--        --file  open_v_file : text open read_mode is v_file;
--        variable in_line    : line;
--        variable good       : boolean;
--
--        variable input_data : std_logic_vector(data_width-1 downto 0);
--        variable expected_digest : std_logic_vector(getHashSize(t) - 1 downto 0);
--
--    begin
--        file_open(open_v_file, "tb_text00.txt", read_mode);
--        while not endfile(open_v_file) loop
--            readline(open_v_file, in_line);
--            if in_line.all'length = 0 or in_line.all(1)='#' then
--                next;
--            end if;
--
--            hread(in_line, input_data, good);
--            assert good report "I/O error reading input" severity failure;
--            pad_in <= input_data;
--
--            hread(in_line, expected_digest, good);
--            assert good report "I/O error reading expected output" severity failure;
--            output_data <= expected_digest;
--            wait for clk_prd;
--            rst <= '0';
--            wait for clk_prd;
--
--            rst <= '1';
--            start <= '1';
--            wait until ready = '1';
--            start <= '0';
--
--            assert output_sha3=output_data report "Unexpected output. Error!" severity error;
--        end loop;
--        file_close(open_v_file);
--
--        wait for 10*clk_prd;
--
--        sim_done <= true;
--        wait;
--    end process;

    process
    begin
        --wait for 1*clk_prd;

        rst <= '1';
        start <= '1';
        wait until ready = '1';

        start <= '0';
        wait for 1*clk_prd;

        
        rst <= '0';
        wait for 1*clk_prd;

        pad_in <= x"000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFFFFFF000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000FFFFFFFC";
        start <= '1';
        rst <= '1';
        wait until ready = '1';

        rst <= '0';
        start <= '0';
        wait for 5*clk_prd;
        sim_done <= true;


        wait;
    end process;

    --pad_keccak
    pad_keccak : entity work.KEC_PAD0(rtl)
        generic map(
            INPUT_WIDTH  => data_width,
            SIZE_WIDTH => WIDTH_SIZE, 
            PAD_WIDTH => input_width)
        port map(
            pad_in  => pad_in,
            size    => size, 
            pad_out => pad_out);
    --keccak
    uut : entity work.sha3(arch) 
        generic map (
            t => t,
            input_width => input_width) 
        port map(
            kecc_in=>pad_out, 
            rst => rst, 
            clk => clk, 
            start => start, 
            mode => mode, 
            output_sha3 => output_sha3, 
            ready => ready);
   
    --clock process
    clk <= not clk after clk_prd / 2 when sim_done = false else '0';


end architecture arch;

