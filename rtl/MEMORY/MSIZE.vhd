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

entity MSIZE is
    generic(
        WIDTH_256 : integer := 256;
        WIDTH_MEMORY_ADDR : integer := 256
    );
    port(
        size            : in std_logic_vector(WIDTH_256-1 downto 0); -- Input data
        start_wrt_mem   : in std_logic; -- EN writing
        offDestOff      : in std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0); -- == Reading and Writing. offset or destOffset MEM address offset, where to start writng
        offset          : in std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0); -- Reading MEM. Only used during MCOPY
        mem_rd          : in std_logic;
        access_MEM      : out std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0) := (others=>'0')
        );
end entity;
architecture rtl of MSIZE is
    
begin

    process(clk) is
        variable temp : integer := 0;
        variable var_MEM_access : integer := 0;
    begin
        if rising_edge(clk) then
            -- Write memory
            if start_wrt_mem = '1' then
                if unsigned(size) = 1 then
                    -- Calculate output for MSIZE for a byte writing
                    var_MEM_access  := (to_integer(unsigned(offDestOff)/32 + 1)) * 32;
                else
                    -- Calculate output for MSIZE by word writing
                    var_MEM_access := (to_integer((unsigned(offDestOff)+32)/32 + 1)) * 32; 
                end if;
            end if;

            -- Read memory
            if mem_rd = '1' then
                -- Calculate output for MSIZE by word reading
                var_MEM_access := (to_integer((unsigned(offset)+32)/32 + 1)) * 32;
                --report "rd var_MEM_access: " & integer'image(var_MEM_access);
            end if;
            
            -- Take and keep the largest access
            if var_MEM_access > temp then 
                temp := var_MEM_access;     
            end if;

            access_MEM <= std_logic_vector(to_unsigned(temp, WIDTH_MEMORY_ADDR));
        end if;
    end process;
    

   
end architecture;