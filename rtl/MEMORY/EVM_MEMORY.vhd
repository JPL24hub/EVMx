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
-- REVISION:    1.0 - 16/05/2024 - File created.
-- DESCRIPTION: The EVM memory is byte addresable. You can write one byte or
--              32 bytes (a word). However, you can only read words. It also 
--              tracks the highest nunber of words accessed, which is outputted in bytes.
-- COMMENTS:    
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

-- Entity
entity EVM_MEMORY is
    generic(
        WIDTH_256 : integer := 256;
        WIDTH_MEMORY_ADDR : integer := 256;
        WIDTH_CNTR  : integer := 256;
        SIZE_COPY   : integer := 10;
        DEPTH_STACK : integer := 1024; -- Define depth of stack
        WIDTH_STACK : integer := 8  -- Define the size of word the stack
        );
    port(
        MEM_in      : in std_logic_vector(WIDTH_256-1 downto 0); -- Input data
        mem_rd      : in std_logic;
        start_wrt_mem  : in std_logic;
        size        : in std_logic_vector(SIZE_COPY-1 downto 0); -- How many bytes to write OR READ
        destOffset  : in std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0); -- destOffset MEM address offset, where to start writng
        offset      : in std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0); -- The ofest of data we are writing to memory. Used by all opcodes with offset 
        rdOffset    : in std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0); -- Reading MEM. Only used during MCOPY
        clk         : in std_logic;
        rst         : in std_logic;
        rstMemAcc   : in std_logic; -- Reset mem access. This should always be inactive throughtout the EVM run
        done_wt     : out std_logic;
        done_rd     : out std_logic;
        access_MEM  : out std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0) := (others=>'0');
        MEM_out     : out std_logic_vector(WIDTH_STACK-1 downto 0) := (others=>'0');
        sizeOut     : out std_logic_vector(WIDTH_MEMORY_ADDR - 1 downto 0) -- The size of active memory space when accessed
        );
end entity;

-- Architecture
architecture rtl of EVM_MEMORY is

    signal sel_cntr0, sel_cntr1, rst_cntr : std_logic_vector(1 downto 0) := "00";
    signal bytData : std_logic_vector(7 downto 0) := (others=>'0'); 
    signal cntr_out0, cntr_out1 : std_logic_vector(WIDTH_CNTR-1 downto 0);
    signal counter : integer := 0;
    signal next_counter : integer := 0;
    signal sel_msize, mem_wrt : std_logic := '0';
    signal msize, msize_nxt, sig_mux : unsigned(WIDTH_MEMORY_ADDR - 1 downto 0);

begin

    process(clk) is
    begin
        if rising_edge(clk) then
            if(rst = '0') then
                counter <= 0;
            else
                counter <= next_counter;
            end if;
        end if;
    end process;

    with rst_cntr select
        next_counter <= 0 when "00",
                    counter + 1 when "01",
                    to_integer(unsigned(offset)) when others;

    -- MSIZE
    PROC_MSIZE: process(clk) is     
    begin
        if rising_edge(clk) then
            if (rstMemAcc = '0') then
                msize <= (others=>'0');
            else
                msize <= msize_nxt;
             end if;
        end if;
    end process;
    -- MUX to msize
    msize_nxt <= sig_mux when sel_msize = '1' else msize;
    -- Get active memory space
    sig_mux <= to_unsigned((((to_integer(unsigned(size)) - 1 + to_integer(unsigned(destOffset))) / 32 + 1 ) * 32), WIDTH_MEMORY_ADDR); 
    -- Update old active mem space only if new is greater
    sel_msize <= '1' when sig_mux > msize else '0';
    -- Output active memory space
    sizeOut <= std_logic_vector(msize);

    -- ADD_SUB_CNTR
    COUNTER0: entity work.ADD_SUB_CNTR(rtl)
    generic map(WIDTH_CNTR => WIDTH_CNTR)
    port map(
        clk      => clk,     
        rst      => rst,     
        sel_cntr => sel_cntr0,
        data_in  => destOffset, 
        data_out => cntr_out0);

    COUNTER1: entity work.ADD_SUB_CNTR(rtl)
    generic map(WIDTH_CNTR => WIDTH_CNTR)
    port map(
        clk      => clk,     
        rst      => rst,     
        sel_cntr => sel_cntr1,
        data_in  => rdOffset, 
        data_out => cntr_out1);

    -- Instantiate MEMORY
    MEMORY: entity work.MEMORY(rtl)
    generic map(RAM_DEPTH  => DEPTH_STACK, 
                RAM_WIDTH  => WIDTH_STACK,
                ARRD_WIDTH => WIDTH_MEMORY_ADDR)
    port map(
        clk  => clk,
        we   => mem_wrt, -- Enabled only during writting
        wt_addr => unsigned(cntr_out0),
        rd_addr => unsigned(cntr_out1),
        di   => bytData,
        do   => MEM_out
    );

    bytData <= MEM_in(8*counter + 7 downto 8*counter); -- Get the byte to write to memory
    
    -- MEM Reading processor
    PROCESSORR: entity work.PROCESSORR(rtl)
    generic map(
        SIZE_COPY  => SIZE_COPY, 
        WIDTH_CNTR => WIDTH_CNTR,
        WIDTH_MEMORY_ADDR => WIDTH_MEMORY_ADDR
    )
    port map(
        clk       => clk,
        rst       => rst,
        mem_rd    => mem_rd,   
        size      => size,
        offDestOff=>destOffset,     
        cntr_out1 => cntr_out1,
        sel_cntr1 => sel_cntr1,
        done_rd   => done_rd 
    );

    -- MEM Writing processor
    PROCESSORW: entity work.PROCESSORW(rtl)
    generic map(
        SIZE_COPY  => SIZE_COPY, 
        WIDTH_CNTR => WIDTH_CNTR,
        WIDTH_MEMORY_ADDR => WIDTH_MEMORY_ADDR
    )
    port map(
        clk       => clk,
        rst       => rst,
        start_wrt_mem => start_wrt_mem, 
        size      => size,
        offDestOff=>destOffset,     
        cntr_out0 => cntr_out0,
        counter   => counter,
        mem_wrt   => mem_wrt, 
        sel_cntr0 => sel_cntr0,
        done_wt   => done_wt,  
        rst_cntr  => rst_cntr 
    );

end architecture;