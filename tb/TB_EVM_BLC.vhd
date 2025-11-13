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
-- FILE:        TB_EVM_BLC.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 
-- DESCRIPTION: TB for reading data within an Ethereum block
-- COMMENTS: 
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.STD_LOGIC_TEXTIO.ALL;
use STD.TEXTIO.ALL;

entity TB_EVM_BLC is
end entity;
architecture sim of TB_EVM_BLC is
    constant clk_prd : time := 1000 ns;
    constant WIDTH_256 : integer := 256;
    constant WIDTH_CALLDATA : integer := 1024;
    constant ETH_ADDR_SIZE  : natural := 160;
    constant ETH_NONCE_SIZE  : natural := 8;
    constant GAS_WIDTH : natural := 25;
    constant BYTCD_LEN : natural := 1024; -- How many bits we write to BYTECODE_MEM at a time

    signal clk          : std_logic := '1';
    signal rst          : std_logic := '0';
    signal startEVM     : std_logic := '0';
    signal loadBytecode   : std_logic := '0';
    signal BytecodeLoaded : std_logic := '0';
    --signal ldByte       : std_logic := '0';
    signal toBYTCD      : std_logic_vector(BYTCD_LEN-1 downto 0) := (others => '0');
    signal doneEVM      : std_logic; -- fcb8f512cc9ea8da6ee682cca0b2f40961f929bc52ac61de0e78359a1e23469a
    signal callData     : std_logic_vector(WIDTH_CALLDATA-1 downto 0) := x"7f8661a10000000000000000000000000000000000000000000000002010fa22a7c478390000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
    signal callDataLen     : std_logic_vector(WIDTH_256-1 downto 0) := std_logic_vector(to_unsigned(WIDTH_CALLDATA, WIDTH_256));
    signal byteCode     : std_logic_vector(WIDTH_256 - 1 downto 0) := x"FC6002600550505061FFFF73FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFCF";
    signal addrCurntSC  : std_logic_vector(WIDTH_256 - 1 downto 0) := x"0000000000000000000000009bbfed6889322e016e0a02ee459d306fc19545d8";
    signal addrBal      : std_logic_vector(WIDTH_256 - 1 downto 0) := x"000000000000000000000000000000000000000000000000000000000003d842";
    signal extCodSize   : std_logic_vector(WIDTH_256 - 1 downto 0) := (others => '0');
    signal extCodHash   : std_logic_vector(WIDTH_256 - 1 downto 0) := (others => '0');
    signal addrEOA      : std_logic_vector(WIDTH_256 - 1 downto 0) := x"000000000000000000000000be862ad9abfe6f22bcb087716c7d89a26051f74c";
    signal callerAddr   : std_logic_vector(WIDTH_256 - 1 downto 0) := x"000000000000000000000000be862ad9abfe6f22bcb087716c7d89a26051f74c";
    signal callValue    : std_logic_vector(WIDTH_256 - 1 downto 0) := std_logic_vector(to_unsigned(3100000, WIDTH_256));
    signal gasPrice     : std_logic_vector(WIDTH_256 - 1 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000010";
    signal retDatSize   : std_logic_vector(WIDTH_256 - 1 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000020";
    signal coinBasAddr  : std_logic_vector(WIDTH_256 - 1 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000021";
    signal timestamp    : std_logic_vector(WIDTH_256 - 1 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000022";
    signal blockNumber  : std_logic_vector(WIDTH_256 - 1 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000023";
    signal prevRandao   : std_logic_vector(WIDTH_256 - 1 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000024";
    signal gasLimit     : std_logic_vector(WIDTH_256 - 1 downto 0) := x"0000000000000000000000000000000000000000000000000000000000F0FF25";
    signal chainId      : std_logic_vector(WIDTH_256 - 1 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000026";
    signal selfBalance  : std_logic_vector(WIDTH_256 - 1 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000027";
    signal baseFee      : std_logic_vector(WIDTH_256 - 1 downto 0) := x"0000000000000000000000000000000000000000000000000000000000000028";
    signal codeSize     : std_logic_vector(WIDTH_256 - 1 downto 0) := std_logic_vector(to_unsigned(250, WIDTH_256)); 
    signal blockHASH    : std_logic_vector(WIDTH_256 - 1 downto 0) := x"000000000000000000000000144Ce249cc886a4DA19Dbefd365E9B5Aadfa6f54";
    signal sender_address: std_logic_vector(ETH_ADDR_SIZE - 1 downto 0) := x"144Ce249cc886a4DA19Dbefd365E9B5Aadfa6f54";
    signal sender_nonce  : std_logic_vector(ETH_NONCE_SIZE - 1 downto 0) := x"AB";
    signal bramWords : unsigned(ETH_NONCE_SIZE - 1 downto 0) := (others=>'0');
    signal popedaddress : std_logic_vector(WIDTH_256 - 1 downto 0);
    signal returnData   : std_logic_vector(WIDTH_256 - 1 downto 0) := (others => '1');
    signal retRevData     : std_logic_vector(4*WIDTH_256 - 1 downto 0) := (others => '0');
    signal scValue      : std_logic_vector(WIDTH_256 - 1 downto 0) := (others => '0');
    signal extcodcpyAddr : std_logic_vector(WIDTH_256 - 1 downto 0) := (others => '0');
    signal returnValue  : std_logic_vector(ETH_NONCE_SIZE - 1 downto 0) := (others => '0');
    signal total_Gas : std_logic_vector(GAS_WIDTH - 1 downto 0);
    signal done_sim     : boolean := false;

    signal numDivO    : std_logic_vector(WIDTH_256-1 downto 0);
    signal denDivO    : std_logic_vector(WIDTH_256-1 downto 0);
    signal startDivO  : std_logic;
    signal readyDivO  : std_logic;
    signal quoDivO    : std_logic_vector(WIDTH_256-1 downto 0);
    
    --==============================Laptop==========================================================================================
    constant in_data_file   : string := "path_to_blockfolder\Block6653186_EVM\file_list.txt";
    constant callData_file  : string := "path_to_blockfolder\Block6653186_EVM\inputData.txt";
    --constant in_data_file   : string := "path_to_blockfolder\Block6653197_EVM\file_list.txt";
    --constant callData_file  : string := "path_to_blockfolder\Block6653197_EVM\inputData.txt";
    --constant in_data_file   : string := "path_to_blockfolder\Block6653232_EVM\file_list.txt";
    --constant callData_file  : string := "path_to_blockfolder\Block6653232_EVM\inputData.txt";
    --constant in_data_file   : string := "path_to_blockfolder\Block6653208_EVM\file_list.txt";
    --constant callData_file  : string := "path_to_blockfolder\Block6653208_EVM\inputData.txt";
    --constant in_data_file   : string := "path_to_blockfolder\Block6653220_EVM\file_list.txt";
    --constant callData_file  : string := "path_to_blockfolder\Block6653220_EVM\inputData.txt";
    --constant in_data_file   : string := "path_to_blockfolder\Block6653205_EVM\file_list.txt";
    --constant callData_file  : string := "path_to_blockfolder\Block6653205_EVM\inputData.txt";
    --constant in_data_file   : string := "path_to_blockfolder\Block6653209_EVM\file_list.txt";
    --constant callData_file  : string := "path_to_blockfolder\Block6653209_EVM\inputData.txt";
    --================================================================================================================================================

    begin


    process
        file list_file : text open read_mode is in_data_file; -- Master file containing file directories
        file calDat_file : text open read_mode is callData_file; -- Master file containing file names
        variable file_name_line : line;
        variable calDatLine : line;
        variable file_name : string(1 to 108);  -- Laptop. You may need to adjust to match the width of your path        
        file file1 : text;  -- Declare the input file dynamically
        variable line_in_file : line;
        variable BYTCD : std_logic_vector(BYTCD_LEN-1 downto 0) := (others => '0');
        variable calDatData : std_logic_vector(WIDTH_CALLDATA-1 downto 0) := (others => '0');
        variable good, goodData : boolean;
        variable status : file_open_status;
        variable wordsInRAM : unsigned(ETH_NONCE_SIZE - 1 downto 0) := (others=>'0');

    begin
        
        wait for 2 * clk_prd;
        
        -- Read file names from the master file
        while not endfile(list_file) OR not endfile(calDat_file) loop
            readline(list_file, file_name_line);
            read(file_name_line, file_name);
        
            -- Read from callData file
            readline(calDat_file, calDatLine);
            hread(calDatLine, calDatData , goodData);
            --assert goodData report "Error reading Call Data " severity failure;
            --report "Call Data is: " & to_hstring(calDatData);
            callData <= calDatData;
               
            wait for 2 * clk_prd;
            rst   <= '1';
            loadBytecode <= '1';  
             
            -- Open each input file
            file_open(status, file1, file_name, read_mode);
            --assert status = open_ok report "Error opening input file: " & file_name severity failure;
            --report "Opened file: " & file_name;

            wordsInRAM := (others => '0');   

            -- Read data from the file
            while not endfile(file1) loop
                readline(file1, line_in_file);
                hread(line_in_file, BYTCD, good);
                --assert good report "Error reading from " & file_name severity failure;
                toBYTCD <= BYTCD;
                wordsInRAM := wordsInRAM + 1;
                wait for 1 * clk_prd; -- Load a word to BRAM
            end loop;

            bramWords <= wordsInRAM; -- How many words are writen in BRAM from this contract

            BytecodeLoaded <= '1';
            wait for 1 * clk_prd;
                 
            startEVM <= '1';
            wait until doneEVM = '1';
            
            -- Close the file
            --file_close(file1);
            rst <= '0';
            loadBytecode <= '0';
            BytecodeLoaded <= '0'; 
            startEVM <= '0';
            
        end loop;

        done_sim <= true;
        wait for 2 * clk_prd;
        wait;
    end process;
    UUT : entity work.EVM(rtl)
    generic map(
        WIDTH_256 => WIDTH_256,
        WIDTH_CALLDATA => WIDTH_CALLDATA,
        ETH_ADDR_SIZE  => ETH_ADDR_SIZE ,
        ETH_NONCE_SIZE => ETH_NONCE_SIZE,
        GAS_WIDTH => GAS_WIDTH,
        BYTCD_LEN => BYTCD_LEN
    )
    port map(
        clk      => clk,         
        rst      => rst,        
        startEVM => startEVM,
        --ldByte  => ldByte,
        loadBytecode   => loadBytecode,  
        BytecodeLoaded => BytecodeLoaded,
        toBYTCD => toBYTCD,
        callData => callData,
        
        callDataLen => callDataLen,
        returnData => returnData,
        byteCode => byteCode,
        addrEOA => addrEOA,
        addrCurntSC => addrCurntSC,
        callerAddr => callerAddr,
        callValue => callValue,
        codeSize => codeSize,
        gasPrice => gasPrice,
        retDatSize => retDatSize,
        coinBasAddr => coinBasAddr,
        timestamp   => timestamp, 
        blockNumber => blockNumber,
        prevRandao  => prevRandao, 
        gasLimit    => gasLimit,   
        chainId     => chainId,    
        selfBalance => selfBalance,
        baseFee     => baseFee,    
        addrBal => addrBal,
        extCodSize => extCodSize,
        extCodHash => extCodHash,
        blockHASH => blockHASH,
        sender_address => sender_address,
        sender_nonce  => sender_nonce,
        bramWords => bramWords,
        popedaddress => popedaddress,
        scValue => scValue,   
        doneEVM  => doneEVM,    
        retRevData => retRevData,
        returnValue => returnValue,
        extcodcpyAddr => extcodcpyAddr,
        total_Gas => total_Gas
        --=============================
        --numDivO   => numDivO,  
        --denDivO   => denDivO,  
        --startDivO => startDivO,
        --readyDivO => readyDivO,
        --quoDivO   => quoDivO   
        );

    --clk
    clk <= not clk after clk_prd / 2 when done_sim = false else '0';

end architecture;