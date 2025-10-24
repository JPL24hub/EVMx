library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity COUNTER_PC is
    generic(
        WIDTH_PC  : integer := 10;
        WDTH_enPC : integer := 3
    );
    port(
        pc_inA  : in std_logic_vector(WIDTH_PC - 1 downto 0);
        pc_inB  : in std_logic_vector(WIDTH_PC - 1 downto 0);
        pc_inC  : in std_logic_vector(WIDTH_PC - 1 downto 0);
        clk     : in std_logic;
        rst     : in std_logic;
        enPC    : in std_logic_vector(WDTH_enPC - 1 downto 0);
        out_pc  : out std_logic_vector(WIDTH_PC - 1 downto 0)        
        );
end entity;
architecture rtl of COUNTER_PC is

    signal  pc, pc_next : unsigned(WIDTH_PC-1 downto 0) := (others=>'0');

begin
    -- Sync register
    process(clk) is
    begin
        if rising_edge(clk) then
            if rst = '0' then
                pc <= (others => '0');
            else
                pc <= pc_next;
            end if;
        end if;
    end process;
    
    -- Next state
    with enPC select
    pc_next <= pc when "000",
                pc + 1 when "001",
                unsigned(pc_inA) when "010",
                unsigned(pc_inB) when "011",
                pc + unsigned(pc_inC) when others;
    
    -- Output
    out_pc <= std_logic_vector(pc);

end architecture;