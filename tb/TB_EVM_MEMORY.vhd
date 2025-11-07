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
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TB_EVM_MEMORY is
end TB_EVM_MEMORY;

architecture tb of TB_EVM_MEMORY is
    constant CLK_PRD    : time := 1000 ns;

    constant WIDTH_256 : integer := 256;
    constant WIDTH_MEMORY_ADDR : integer := 256;
    constant WIDTH_CNTR  : integer := 256;
    constant SIZE_COPY   : integer := 10;
    constant DEPTH_STACK : integer := 1024; -- Define depth of stack
    constant WIDTH_STACK : integer := 8;  --


    signal MEM_in      : std_logic_vector(WIDTH_256-1 downto 0) := (others=>'0'); -- Input data
    signal mem_rd      : std_logic := '0'; 
    signal start_wrt_mem     : std_logic := '0'; -- Enable memory write
    signal size        : std_logic_vector(SIZE_COPY-1 downto 0); -- How many bytes to write
    signal destOffset  : std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0) := (others=>'0'); -- MEM address offset, where to start writng
    signal offset      : std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0) := (others=>'0'); -- The ofest of data we are writing to memory. Used by all opcodes with offset
    signal rdOffset    : std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0) := (others=>'0'); -- Reading MEM. Only used during MCOPY
    signal clk         : std_logic := '1';
    signal rst         : std_logic := '0';
    signal rstMemAcc   : std_logic := '0'; -- Reset memory access
    signal done_wt     : std_logic;
    signal done_rd     : std_logic;
    signal access_MEM  : std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0) := (others=>'0');
    signal MEM_out     : std_logic_vector(WIDTH_STACK-1 downto 0) := (others=>'0');
    signal sizeOut     : std_logic_vector(WIDTH_MEMORY_ADDR - 1 downto 0);
    signal done_sim  : boolean := false;


begin
    -- Clock generation
    clk <= not clk after CLK_PRD / 2 when done_sim = false else '0';

    -- DUT instance
    dut : entity work.EVM_MEMORY(rtl)
        generic map(
            WIDTH_256         => WIDTH_256,
            WIDTH_MEMORY_ADDR => WIDTH_MEMORY_ADDR, 
            WIDTH_CNTR        => WIDTH_CNTR,       
            SIZE_COPY         => SIZE_COPY,  
            DEPTH_STACK       => DEPTH_STACK, 
            WIDTH_STACK       => WIDTH_STACK  
        )
        port map(
            MEM_in     => MEM_in,    
            mem_rd     => mem_rd,    
            start_wrt_mem    => start_wrt_mem,   
            size       => size,      
            destOffset => destOffset,
            offset     => offset,
            rdOffset   => rdOffset,    
            clk        => clk,       
            rst        => rst, 
            rstMemAcc  => rstMemAcc,      
            done_wt    => done_wt,   
            done_rd    => done_rd,   
            access_MEM => access_MEM,
            MEM_out    => MEM_out,
            sizeOut    => sizeOut
            );

    -- Test process
    test_process : process
    begin
        wait for CLK_PRD*1;

        rst <= '1';
        rstMemAcc <= '1';

        wait for CLK_PRD*1;

        -- Test 1: Write 1 byte
        MEM_in <= x"11111111222222223333333344444444555555556666666677777777886688CD"; -- Data to write
        size <= std_logic_vector(to_unsigned(31, SIZE_COPY));
        offset <= std_logic_vector(to_unsigned(2, WIDTH_MEMORY_ADDR));
        destOffset <= std_logic_vector(to_unsigned(1, WIDTH_MEMORY_ADDR));

        start_wrt_mem <= '1';

        --wait until done_wt = '1';
        --rst <= '0';
--
        --wait for CLK_PRD*1;
--
        --rst <= '1';
--
        ---- Test 2: Write 32 byte
        --MEM_in <= x"7fa3c4d98b2f8a69d7a5ec3e2a43126c98f51b24ee34918d7a71f9eb6d7b2c3d"; -- Data to write
        --start_wrt_mem <= '1';
        --size <= std_logic_vector(to_unsigned(32, SIZE_COPY));
--
        --wait until done_wt = '1';
        --rst <= '0';
--
        --wait for CLK_PRD*1;
--
        --rst <= '1';
--
        ---- Test 2: Write 32 byte
        --mem_rd <= '1';
        --size <= std_logic_vector(to_unsigned(32, SIZE_COPY));

        wait until done_wt = '1';

        wait for CLK_PRD*1;

        done_sim <= true;
        wait;

        ---- Verify byte write (only byte 4 updated, others remain default)
        --assert do(39 downto 32) = x"AB"
        --    report "Test 1 Failed: Byte write mismatch" severity error;
       
    end process;

end tb;
