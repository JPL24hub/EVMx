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
entity PROCESSORW is
    generic(
        SIZE_COPY   : integer := 10;
        WIDTH_CNTR  : integer := 256;
        WIDTH_MEMORY_ADDR : integer := 256
    );
    port(
        clk       : in std_logic;
        rst       : in std_logic;
        start_wrt_mem : in std_logic;
        size      : in std_logic_vector(SIZE_COPY - 1 downto 0); 
        offDestOff: in std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0);
        cntr_out0 : in std_logic_vector(WIDTH_CNTR - 1 downto 0);
        counter   : in integer;
        mem_wrt   : out std_logic;
        sel_cntr0 : out std_logic_vector(1 downto 0);
        done_wt   : out std_logic;
        rst_cntr  : out std_logic_vector(1 downto 0)

    );
end entity;
architecture rtl of PROCESSORW is

    type MEM_STATES is (IDLE, WRITE);
    signal reg_state, next_state : MEM_STATES := IDLE;

begin
    FSM: process(clk) is
        begin
            if rising_edge(clk) then
                if rst = '0' then
                    reg_state <= IDLE;
                else
                    reg_state <= next_state;
                end if;
            end if;
        end process;
    
        PROCESSOR0: process(reg_state, start_wrt_mem, offDestOff, size, cntr_out0, counter) is
        begin
    
            sel_cntr0   <= "00";
            done_wt     <= '0';
            rst_cntr    <= "00"; -- Reset counter
            mem_wrt     <= '0';
    
            case reg_state is
                when IDLE =>
                    if start_wrt_mem = '1' then -- If we are writing or reading mem
                        sel_cntr0 <= "11";
                        rst_cntr    <= "10"; -- Set to offset
                        next_state <= WRITE;
                    else
                        next_state <= IDLE;
                    end if;
                when WRITE =>
                    sel_cntr0   <= "01"; -- Increment counter
                    rst_cntr    <= "01";
                    mem_wrt     <= '1';
                    if unsigned(cntr_out0) = (unsigned(offDestOff) + unsigned(size) - 1) OR counter = 31 then -- If we have written all the bytes. counter can only have 32 bytes
                        done_wt    <= '1';
                        rst_cntr   <= "00";
                        next_state <= IDLE;
                    else
                        next_state <= WRITE;
                    end if;
                when others =>
                    next_state <= IDLE;
                end case;
        end process;
end architecture;