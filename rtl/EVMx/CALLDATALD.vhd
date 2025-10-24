----------------------------------------------------------------------
-- FILE:        CALLDATALD.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 20/01/2025 - File created.
-- DESCRIPTION: Used to execute the CALLDATALOAD opcode. It reads the data from the transaction input data.
-- COMMENTS:    It takes 256-bits starting from a specific offset.
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

-- Entity
entity CALLDATALD is
    generic(
        WIDTH_INPUT : integer := 1024;
        WIDTH_256 : integer := 256
        );
    port(
        clk      : in std_logic;
        rst      : in std_logic;
        en       : in std_logic;
        callData : in std_logic_vector(WIDTH_INPUT-1 downto 0);
        offset   : in std_logic_vector(WIDTH_256-1 downto 0);
        callDataOut : out std_logic_vector(WIDTH_256-1 downto 0) := (others=>'0')
    );
end entity;
architecture rtl of CALLDATALD is

    --signal callDataOutSig : std_logic_vector(WIDTH_256-1 downto 0) := (others=>'0');
begin

    process(clk, rst)
        variable offset_i : integer;
        variable k : integer;
        variable max_index : integer := WIDTH_256 / 8 - 1;
    begin
        if rising_edge(clk) then
            if rst = '0' then
                callDataOut <= (others => '0');
            elsif en = '1' then
                offset_i := to_integer(unsigned(offset));
                k := WIDTH_256 - 1;

                for i in 0 to WIDTH_256 / 8 - 1 loop
                    if i >= offset_i and i < WIDTH_INPUT / 8 and k > -1 then
                        callDataOut(k downto k - 7) <= callData(WIDTH_INPUT - 1 - i * 8 downto WIDTH_INPUT - i * 8 - 8); -- Read 8 bytes from callData
                        k := k - 8;
                    end if;
                end loop;
            end if;

        end if;
    end process;

end architecture;