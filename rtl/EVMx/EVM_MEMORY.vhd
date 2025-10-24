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
        DEPTH_MEM  : integer := 32768; -- Define depth of stack
        WIDTH2   : integer := 2;
        WIDTH_MEM  : integer := 8  -- Define the size of word the stack
        );
    port(
        MEM_in      : in std_logic_vector(WIDTH_256-1 downto 0); -- Input data
        start_rd_mem : in std_logic;
        start_wrt_mem  : in std_logic;
        size        : in std_logic_vector(SIZE_COPY-1 downto 0); -- How many bytes to write OR READ
        destOffset  : in std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0); -- destOffset MEM address offset, where to start writng
        rdOffset    : in std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0); -- Reading MEM. Only used during MCOPY as offset. Also, input offset must be zero
        clk         : in std_logic;
        rst         : in std_logic;
        rstMemAcc   : in std_logic; -- Reset mem access. This should always be inactive throughtout the EVM run
        enMEM_cpy   : in std_logic; -- Only used when writing to memory to either copy MEM_in[7:0](1) or shifted MEM_in.
        selShftCntr : in std_logic_vector(WIDTH2 - 1 downto 0); -- Select shift counter. 00: No shift, 01: Shift
        wrt_cntr    : in std_logic_vector(WIDTH2 - 1 downto 0); -- Writing MEM: 00 hold, 01 increment, 10 reset, 11 load
        rd_cntr     : in std_logic_vector(WIDTH2 - 1 downto 0); -- Reading MEM: 00 hold, 01 increment, 10 reset, 11 load
        mem_wrt     : in std_logic;
        done_wt     : out std_logic;
        done_rd     : out std_logic;
        access_MEM  : out std_logic_vector(WIDTH_MEMORY_ADDR - 1 downto 0) := (others=>'0');
        MEM_out     : out std_logic_vector(WIDTH_MEM - 1 downto 0) := (others=>'0');
        activMEM     : out std_logic_vector(WIDTH_MEMORY_ADDR - 1 downto 0) -- The size of active memory space when accessed
        );
end entity;

-- Architecture
architecture rtl of EVM_MEMORY is

    constant WIDTH_CT : integer := 5;

    signal bytData : std_logic_vector(7 downto 0) := (others=>'0'); 
    signal cntr_out0, cntr_out1 : std_logic_vector(WIDTH_CNTR-1 downto 0);
    signal sel_msize : std_logic := '0';
    signal msize, msize_nxt, sig_mux : unsigned(WIDTH_MEMORY_ADDR - 1 downto 0);
    signal cntrSft, cntrSft_nxt : unsigned(WIDTH_CT - 1 downto 0) := (others=>'0');

begin

    process(clk) is
    begin
        if rising_edge(clk) then
            if(rst = '0') then
                cntrSft <= (others=>'0');
            else
                cntrSft <= cntrSft_nxt;
            end if;
        end if;
    end process;
    
    with selShftCntr select
        cntrSft_nxt <= cntrSft when "00",
        cntrSft + 1 when "01",
        (others=>'0') when others;

    bytData <= MEM_in(WIDTH_256 - 8*to_integer(cntrSft) - 1 downto WIDTH_256 - 8*to_integer(cntrSft) - 8) when enMEM_cpy = '1' else MEM_in(7 downto 0); -- Get the byte to write to memory

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
    activMEM <= std_logic_vector(msize);

    -- ADD_SUB_CNTR: For counting the number of bytes written to memory
    COUNTER0: entity work.COUNTER_NEW(rtl) -- Writing counter
    generic map(WIDTH_CNTR => WIDTH_CNTR)
    port map(
        clk      => clk,     
        rst      => rst,     
        sel_cntr => wrt_cntr,
        data_in  => destOffset, 
        data_out => cntr_out0);

    COUNTER1: entity work.ADD_SUB_CNTR(rtl) -- Reading counter
    generic map(WIDTH_CNTR => WIDTH_CNTR)
    port map(
        clk      => clk,     
        rst      => rst,     
        sel_cntr => rd_cntr,
        data_in  => rdOffset, 
        data_out => cntr_out1);

    -- Instantiate MEMORY
    MEMORY: entity work.MEMORY(rtl)
    generic map(RAM_DEPTH  => DEPTH_MEM , 
                RAM_WIDTH  => WIDTH_MEM ,
                ARRD_WIDTH => WIDTH_MEMORY_ADDR)
    port map(
        clk  => clk,
        we   => mem_wrt, -- Enabled only during writting
        wt_addr => unsigned(cntr_out0),
        rd_addr => unsigned(cntr_out1),
        di   => bytData,
        do   => MEM_out
    );
    
    
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
        start_rd_mem => start_rd_mem,   
        size      => size,
        rdOffset => rdOffset,
        cntr_out1 => cntr_out1,
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
        done_wt   => done_wt
        );

end architecture;