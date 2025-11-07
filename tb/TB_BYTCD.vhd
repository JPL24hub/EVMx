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
-- FILE:        TB_BYTCD.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 27/03/2025 - File created.
-- DESCRIPTION: TB dor BYTECODE MEM.
-- COMMENTS:    
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity TB_BYTCD is
end entity;
architecture rtl of TB_BYTCD is 
    constant CLK_PRD : time := 1000 ns;
    constant INPUT_WIDTH : natural := 1024;
    constant OUPUT_WIDTH : natural := 8;
    constant WIDTH_PC    : natural := 10;

    signal clk      : std_logic := '1';
    signal rst      : std_logic := '0';
    signal start    : std_logic := '0';
    signal RAMloaded  : std_logic := '0'; -- Assert after loading RAM
    signal ldNext   : std_logic := '0';
    signal toBYTCD  : std_logic_vector(INPUT_WIDTH - 1 downto 0);
    signal pc       : std_logic_vector(WIDTH_PC - 1 downto 0);
    signal cnt2PC   : std_logic_vector(WIDTH_PC - 1 downto 0);
    signal readBUFF : std_logic;
    signal bytOutPC  : std_logic_vector(OUPUT_WIDTH - 1 downto 0);
    signal outBYTCD8 : std_logic_vector(OUPUT_WIDTH - 1 downto 0);
    signal doneSim  : boolean := false;

    constant in_data_file : string := "C:\Users\AR43170\Desktop\PhD_desktop\PHD_Codes\Gitlab\poncha\vhdl\1_PhD\EVM\BYTCODE_NEW\0x0ABeFb7611Cb3A01EA3FaD85f33C3C934F8e2cF4.txt";

begin

    clk <= not clk after CLK_PRD / 2 when doneSim = false else '0';

    BYTECODE_STORE: entity work.BYTECODE_STORE(rtl)
    generic map(
        INPUT_WIDTH => INPUT_WIDTH,
        OUPUT_WIDTH => OUPUT_WIDTH,
        WIDTH_PC    => WIDTH_PC   
    )
    port map(
        clk       => clk,      
        rst       => rst,      
        start     => start,    
        RAMloaded   => RAMloaded,  
        ldNext    => ldNext,   
        toBYTCD   => toBYTCD,  
        pc        => pc,       
        cnt2PC    => cnt2PC,   
        readBUFF => readBUFF,
        bytOutPC  => bytOutPC, 
        outBYTCD8 => outBYTCD8
        );

    process
        file list_file : text open read_mode is in_data_file;
        variable line_in_file : line;
        variable BYTCD : std_logic_vector(INPUT_WIDTH-1 downto 0) := (others => '0');
        variable good : boolean;
    begin
        wait for 2 * CLK_PRD;
        rst   <= '1';
        start <= '1';

        while not endfile(list_file) loop
            readline(list_file, line_in_file);
            hread(line_in_file, BYTCD, good);
            assert good report "Error reading from file " severity failure;
            toBYTCD <= BYTCD;
            wait for 1 * CLK_PRD; -- Go to loadByte
        end loop;
        RAMloaded <= '1'; -- RAM loaded
        wait until readBUFF = '1'; -- Buffer loaded and we as waiting to load it agaian
        wait for 5 * CLK_PRD;

        ldNext <= '1'; -- Load next data from RAM
        wait for 1 * CLK_PRD;
        ldNext <= '0'; -- Disable loading from RAM
        wait for 1 * CLK_PRD;
        doneSim <= true;
        wait for 2 * CLK_PRD;
        wait;

    end process;

end architecture;