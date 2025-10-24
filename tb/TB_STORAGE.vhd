library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity TB_STORAGE is
end TB_STORAGE;

architecture sim of TB_STORAGE is
    constant CLK_PERIOD : time := 1000 ns;
    constant WIDTH_KEYS    : integer := 10;
    constant STORAGE_DEPTH : integer := 2**WIDTH_KEY;
    constant STORAGE_WIDTH : integer := 256;

    signal clk      : std_logic := '0';
    signal write_en : std_logic := '0';
    signal key      : std_logic_vector(WIDTH_KEY - 1 downto 0) := (others => '0');
    signal value   : std_logic_vector(STORAGE_WIDTH - 1 downto 0) := (others => '0');
    signal value_out : std_logic_vector(STORAGE_WIDTH - 1 downto 0);
    signal done_sim : boolean := false;

    -- Instantiate the Key_Value_Storage module

begin
    -- Instantiate the Key_Value_Storage unit
    UUT: entity work.STORAGE(rtl)
        generic map(
            WIDTH_KEY    => WIDTH_KEY,   
            STORAGE_DEPTH => STORAGE_DEPTH,
            STORAGE_WIDTH => STORAGE_WIDTH
        )
        port map (
            clk      => clk,
            write_en => write_en,
            key      => key,
            value  => value,
            value_out => value_out
        );

    -- Clock process
    clk <= not clk after CLK_PERIOD / 2 when done_sim = false else '0';

    -- Test sequence
    process
    begin
        wait for CLK_PERIOD;

        -- Write value 0xDEADBEEF to key 5
        write_en <= '1';
        key <= std_logic_vector(to_unsigned(5, WIDTH_KEY));
        value <= x"DEADBEEF00000000000000000000000000000000000000000000000000000000";
        wait for CLK_PERIOD;
        write_en <= '0';

        -- Read back value from key 5
        key <= std_logic_vector(to_unsigned(5, WIDTH_KEY));
        wait for 2*CLK_PERIOD;

        done_sim <= true;

        -- Stop simulation
        wait;
    end process;
end architecture;
