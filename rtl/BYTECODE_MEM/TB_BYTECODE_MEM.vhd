library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity TB_BYTECODE_MEM is
end entity;

architecture tb of TB_BYTECODE_MEM is
    -- Constants
    constant CLK_PERIOD : time := 1000 ns;
    constant MEM_WIDTH  : natural := 8;
    constant MEM_DEPTH  : natural := 32768;
    constant ADRR_WIDTH : natural := 16;

    -- Signals
    signal clk       : std_logic := '1';
    signal toBYTCD   : std_logic_vector(MEM_WIDTH - 1 downto 0);
    signal wrtBYTCD  : std_logic := '0';
    signal addr      : std_logic_vector(ADRR_WIDTH - 1 downto 0);
    signal cnt2PC    : std_logic_vector(ADRR_WIDTH - 1 downto 0) := (others=>'0');
    signal rd_addr   : std_logic_vector(MEM_WIDTH - 1 downto 0);
    signal outBYTCD  : std_logic_vector(MEM_WIDTH - 1 downto 0);
    signal done_sim  : boolean := false;

begin
    -- Instantiate DUT
    BYTECODE_MEM: entity work.BYTECODE_MEM(rtl)
        generic map(
            MEM_WIDTH  => MEM_WIDTH, 
            MEM_DEPTH  => MEM_DEPTH,
            ADRR_WIDTH => ADRR_WIDTH
            )
        port map(
            toBYTCD  => toBYTCD,
            wrtBYTCD => wrtBYTCD,
            pc     => addr,
            cnt2PC => cnt2PC,
            clk      => clk,
            outBYTCD8 => rd_addr,
            bytOutPC => outBYTCD
        );

    -- Clock Process
    clk <= not clk after CLK_PERIOD / 2 when done_sim = false else '0';

    -- Stimulus Process
    process
    begin
        -- Initialize Inputs
        wrtBYTCD <= '0';
        addr <= (others => '0');
        rd_addr <= (others => '0');
        wait for CLK_PERIOD;

        wrtBYTCD <= '1';
        -- Write in position 0
        toBYTCD <= x"A9";
        addr <= std_logic_vector(to_unsigned(0, ADRR_WIDTH)); -- Store at address 1024
        wait for CLK_PERIOD;

        -- Write in position 1
        toBYTCD <= x"7A";
        addr <= std_logic_vector(to_unsigned(1, ADRR_WIDTH)); -- Store at address 1024
        wait for CLK_PERIOD;

        done_sim <= true;
        wait;
    end process;
end architecture;
