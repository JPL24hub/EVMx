----------------------------------------------------------------------
-- FILE:        MEMORY.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 28/11/2024 - File created.
-- DESCRIPTION: 
-- COMMENTS:    
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
-- Entity
entity PROCESSORR is
    generic(
        SIZE_COPY   : integer := 10;
        WIDTH_CNTR  : integer := 256;
        WIDTH_MEMORY_ADDR : integer := 256
    );
    port(
        clk       : in std_logic;
        rst       : in std_logic;
        start_rd_mem    : in std_logic;
        size      : in std_logic_vector(SIZE_COPY - 1 downto 0);
        rdOffset  : in std_logic_vector(WIDTH_MEMORY_ADDR - 1 downto 0);
        cntr_out1 : in std_logic_vector(WIDTH_CNTR - 1 downto 0);
        done_rd   : out std_logic

    );
end entity;

-- Architecture
architecture rtl of PROCESSORR is
    -- Reading
    type MEM_STATESR is (IDLER, READ);
    signal reg_stateR, next_stateR : MEM_STATESR := IDLER;
begin

    -------- Reading -------------------------------
    FSM_R: process(clk) is
        begin
            if rising_edge(clk) then
                if rst = '0' then
                    reg_stateR <= IDLER;
                else
                    reg_stateR <= next_stateR;
                end if;
            end if;
        end process;
    

    PROCESSORR: process(reg_stateR, start_rd_mem, size, rdOffset, cntr_out1) is
        begin
            done_rd   <= '0';

            case reg_stateR is
                when IDLER =>
                    if start_rd_mem = '1' then
                        next_stateR <= READ;
                    else
                        next_stateR <= IDLER;
                    end if;
                when READ =>
    
                    if unsigned(cntr_out1) =  unsigned(size) + unsigned(rdOffset) OR unsigned(cntr_out1) >  unsigned(size) + unsigned(rdOffset) then
                        done_rd    <= '1';
                        next_stateR <= IDLER;
                    else
                        next_stateR <= READ;
                    end if;
    
                when others =>
                    next_stateR <= IDLER;
                end case;
        end process;

end architecture;