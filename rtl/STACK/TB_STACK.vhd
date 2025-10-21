----------------------------------------------------------------------
-- FILE:        TB_STACK.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 26/09/2024 - File created.
-- DESCRIPTION: Test bench for new STACK module.
-- COMMENTS:    
--------------------------------------------------------------------------------------

-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Entity
entity TB_STACK is
end entity;

-- Architecture
architecture sim of TB_STACK is

    constant DEPTH_STACK : integer := 1024;
    constant WIDTH_STACK : integer := 256; --  Word size
    constant DUP_OFFSET  : integer := 10;

    signal clk_prd : time := 1000 ns;
    signal done_sim : boolean := false; 

    signal clk          : std_logic := '1';     
    signal reset        : std_logic := '0';
    signal push         : std_logic := '0';
    signal pop          : std_logic := '0';
    signal data_in      : std_logic_vector(WIDTH_STACK-1 downto 0) := (others=>'0');
    --signal rd          : std_logic;
    signal wrt         : std_logic := '0';
    signal addr_offset : std_logic_vector(DUP_OFFSET-1 downto 0);
    signal data_out0    : std_logic_vector(WIDTH_STACK-1 downto 0);
    signal data_out_1   : std_logic_vector(WIDTH_STACK-1 downto 0);
    signal we    : std_logic := '0';    -- stack must be enabled when we push or write
    
begin

    process
    begin
        wait for clk_prd*2; -- push
        we      <= '1';
        reset   <= '1';
        push    <= '1';
        data_in <= (0=>'1',others=>'0'); -- push
        wait for clk_prd*1;

        data_in <= (1=>'1',others=>'0'); -- push
        wait for clk_prd*1;

        data_in <= (2=>'1', others=>'0'); -- push
        wait for clk_prd*1;

        data_in <= (3=>'1', others=>'0'); -- push
        wait for clk_prd*1;

        we <= '0'; -- Should 0 when not writing
        push <= '0';
        pop <= '1';     -- pop
        wait for clk_prd*4;

        pop <= '0';
        wrt <= '1';
        we <= '1';
        addr_offset <= "0000000111";
        data_in <= (4=>'1', others=>'0'); -- push
        wait for clk_prd*2;


        done_sim <= true;
        wait;
    end process;

    -- clk
    clk <= not clk after clk_prd/2 when done_sim = false else '0';

    -- uut
    uut: entity work.STACK_EVM(rtl)
    generic map(
        DEPTH_STACK => DEPTH_STACK,
        WIDTH_STACK => WIDTH_STACK,
        DUP_OFFSET => DUP_OFFSET
    )
    port map (
        
        clk     => clk,     
        reset   => reset, 
        we      => we,      
        push    => push,    
        pop     => pop,     
        data_in => data_in,  
        wrt         => wrt,      
        addr_offset => addr_offset,
        data_out   => data_out0        
        );


end architecture;