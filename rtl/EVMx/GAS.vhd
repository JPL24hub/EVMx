----------------------------------------------------------------------
-- FILE:        GAS.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 27/02/2025 - File created.
-- DESCRIPTION: This file defines the gas operations for the EVM.
-- COMMENTS:    
--------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;

entity GAS is
    generic(
        WIDTH : natural := 256
    );
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        opcode      : in std_logic_vector(7 downto 0);
        gasLimit    : in std_logic_vector(WIDTH - 1 downto 0);
        enGasLimit  : in std_logic;
        enTotGas    : in std_logic;
        selOpcode   : in std_logic;
        brokeFlag   : out std_logic;
        total_Gas   : out std_logic_vector(WIDTH - 1 downto 0); -- Total used gas
        remGas      : out std_logic_vector(WIDTH - 1 downto 0) -- Difference between gasLimit and usedGas
    );
end entity GAS;
architecture rtl of GAS is

    signal regGasLim, gas, nxtRegGasLim, usedGas, nxtTotGas, totalGas, minGas : unsigned(WIDTH - 1 downto 0);

    begin

        --brokeFlag <= '1' when (usedGas > regGasLim) else '0'; --

    process(clk, rst) is
    begin
        if rising_edge(clk) then
            if rst = '0' then
                regGasLim <= (others => '0');
                totalGas <= (others => '0');
            else
                regGasLim <= nxtRegGasLim;
                totalGas <= nxtTotGas;
            end if;
        end if;
    end process;

    nxtRegGasLim <= unsigned(gasLimit) when enGasLimit = '1' else regGasLim;

    nxtTotGas <= usedGas when enTotGas = '1' else totalGas;
    usedGas <= totalGas + minGas;

    total_Gas <= std_logic_vector(totalGas);
    
    minGas <= gas when selOpcode = '1' else (others => '0');

    remGas <= std_logic_vector(regGasLim - usedGas);


    process(clk)
        begin
            if rising_edge(clk) then
                if rst = '0' then
                    brokeFlag <= '0'; -- Reset condition
                else
                    if usedGas > regGasLim then
                        brokeFlag <= '1';
                    else
                        brokeFlag <= '0';
                    end if;
                end if;
            end if;
        end process;

    
    with opcode select
    gas <= to_unsigned(0, WIDTH) when x"00",
                to_unsigned(3, WIDTH) when x"01",
                to_unsigned(5, WIDTH) when x"02",
                to_unsigned(3, WIDTH) when x"03",
                to_unsigned(5, WIDTH) when x"04",
                to_unsigned(5, WIDTH) when x"05",
                to_unsigned(5, WIDTH) when x"06",
                to_unsigned(5, WIDTH) when x"07",
                to_unsigned(8, WIDTH) when x"08",
                to_unsigned(8, WIDTH) when x"09",
                to_unsigned(10, WIDTH) when x"0a",
                to_unsigned(5, WIDTH) when x"0b",
                to_unsigned(3, WIDTH) when x"10",
                to_unsigned(3, WIDTH) when x"11",
                to_unsigned(3, WIDTH) when x"12",
                to_unsigned(3, WIDTH) when x"13",
                to_unsigned(3, WIDTH) when x"14",
                to_unsigned(3, WIDTH) when x"15",
                to_unsigned(3, WIDTH) when x"16",
                to_unsigned(3, WIDTH) when x"17",
                to_unsigned(3, WIDTH) when x"18",
                to_unsigned(3, WIDTH) when x"19",
                to_unsigned(3, WIDTH) when x"1a",
                to_unsigned(3, WIDTH) when x"1b",
                to_unsigned(3, WIDTH) when x"1c",
                to_unsigned(3, WIDTH) when x"1d",
                to_unsigned(30, WIDTH) when x"20",
                to_unsigned(2, WIDTH) when x"30",
                to_unsigned(100, WIDTH) when x"31",
                to_unsigned(2, WIDTH) when x"32",
                to_unsigned(2, WIDTH) when x"33",
                to_unsigned(2, WIDTH) when x"34",
                to_unsigned(3, WIDTH) when x"35",
                to_unsigned(2, WIDTH) when x"36",
                to_unsigned(3, WIDTH) when x"37",
                to_unsigned(2, WIDTH) when x"38",
                to_unsigned(3, WIDTH) when x"39", 
                to_unsigned(2, WIDTH) when x"3a",
                to_unsigned(100, WIDTH) when x"3b", 
                to_unsigned(100, WIDTH) when x"3c",
                to_unsigned(2, WIDTH) when x"3d",
                to_unsigned(3, WIDTH) when x"3e",
                to_unsigned(100, WIDTH) when x"3f",
                to_unsigned(20, WIDTH) when x"40",
                to_unsigned(2, WIDTH) when x"41",
                to_unsigned(2, WIDTH) when x"42",
                to_unsigned(2, WIDTH) when x"43",
                to_unsigned(2, WIDTH) when x"44",
                to_unsigned(2, WIDTH) when x"45",
                to_unsigned(2, WIDTH) when x"46",
                to_unsigned(5, WIDTH) when x"47",
                to_unsigned(2, WIDTH) when x"48",
                to_unsigned(3, WIDTH) when x"49",
                to_unsigned(2, WIDTH) when x"4a",
                to_unsigned(2, WIDTH) when x"50",
                to_unsigned(3, WIDTH) when x"51",
                to_unsigned(3, WIDTH) when x"52",
                to_unsigned(3, WIDTH) when x"53",
                to_unsigned(100, WIDTH) when x"54",
                to_unsigned(100, WIDTH) when x"55",
                to_unsigned(8, WIDTH) when x"56",
                to_unsigned(10, WIDTH) when x"57",
                to_unsigned(2, WIDTH) when x"58",
                to_unsigned(2, WIDTH) when x"59",
                to_unsigned(2, WIDTH) when x"5a",
                to_unsigned(1, WIDTH) when x"5b",
                to_unsigned(100, WIDTH) when x"5c",
                to_unsigned(100, WIDTH) when x"5d",
                to_unsigned(3, WIDTH) when x"5e",
                to_unsigned(2, WIDTH) when x"5f",
                to_unsigned(3, WIDTH) when x"60",
                to_unsigned(3, WIDTH) when x"61",
                to_unsigned(3, WIDTH) when x"62",
                to_unsigned(3, WIDTH) when x"63",
                to_unsigned(3, WIDTH) when x"64",
                to_unsigned(3, WIDTH) when x"65",
                to_unsigned(3, WIDTH) when x"66",
                to_unsigned(3, WIDTH) when x"67",
                to_unsigned(3, WIDTH) when x"68",
                to_unsigned(3, WIDTH) when x"69",
                to_unsigned(3, WIDTH) when x"6a",
                to_unsigned(3, WIDTH) when x"6b",
                to_unsigned(3, WIDTH) when x"6c",
                to_unsigned(3, WIDTH) when x"6d",
                to_unsigned(3, WIDTH) when x"6e",
                to_unsigned(3, WIDTH) when x"6f",
                to_unsigned(3, WIDTH) when x"70",
                to_unsigned(3, WIDTH) when x"71",
                to_unsigned(3, WIDTH) when x"72",
                to_unsigned(3, WIDTH) when x"73",
                to_unsigned(3, WIDTH) when x"74",
                to_unsigned(3, WIDTH) when x"75",
                to_unsigned(3, WIDTH) when x"76",
                to_unsigned(3, WIDTH) when x"77",
                to_unsigned(3, WIDTH) when x"78",
                to_unsigned(3, WIDTH) when x"79",
                to_unsigned(3, WIDTH) when x"7a",
                to_unsigned(3, WIDTH) when x"7b",
                to_unsigned(3, WIDTH) when x"7c",
                to_unsigned(3, WIDTH) when x"7d",
                to_unsigned(3, WIDTH) when x"7e",
                to_unsigned(3, WIDTH) when x"7f",
                to_unsigned(3, WIDTH) when x"80",
                to_unsigned(3, WIDTH) when x"81",
                to_unsigned(3, WIDTH) when x"82",
                to_unsigned(3, WIDTH) when x"83",
                to_unsigned(3, WIDTH) when x"84",
                to_unsigned(3, WIDTH) when x"85",
                to_unsigned(3, WIDTH) when x"86",
                to_unsigned(3, WIDTH) when x"87",
                to_unsigned(3, WIDTH) when x"88",
                to_unsigned(3, WIDTH) when x"89",
                to_unsigned(3, WIDTH) when x"8a",
                to_unsigned(3, WIDTH) when x"8b",
                to_unsigned(3, WIDTH) when x"8c",
                to_unsigned(3, WIDTH) when x"8d",
                to_unsigned(3, WIDTH) when x"8e",
                to_unsigned(3, WIDTH) when x"8f",
                to_unsigned(3, WIDTH) when x"90",
                to_unsigned(3, WIDTH) when x"91",
                to_unsigned(3, WIDTH) when x"92",
                to_unsigned(3, WIDTH) when x"93",
                to_unsigned(3, WIDTH) when x"94",
                to_unsigned(3, WIDTH) when x"95",
                to_unsigned(3, WIDTH) when x"96",
                to_unsigned(3, WIDTH) when x"97",
                to_unsigned(3, WIDTH) when x"98",
                to_unsigned(3, WIDTH) when x"99",
                to_unsigned(3, WIDTH) when x"9a",
                to_unsigned(3, WIDTH) when x"9b",
                to_unsigned(3, WIDTH) when x"9c",
                to_unsigned(3, WIDTH) when x"9d",
                to_unsigned(3, WIDTH) when x"9e",
                to_unsigned(3, WIDTH) when x"9f",
                to_unsigned(375, WIDTH) when x"a0",
                to_unsigned(750, WIDTH) when x"a1",
                to_unsigned(1125, WIDTH) when x"a2",
                to_unsigned(1500, WIDTH) when x"a3",
                to_unsigned(1875, WIDTH) when x"a4",
                to_unsigned(3200, WIDTH) when x"f0",
                to_unsigned(100, WIDTH) when x"f1",
                to_unsigned(100, WIDTH) when x"f2",
                to_unsigned(0, WIDTH) when x"f3",
                to_unsigned(100, WIDTH) when x"f4",
                to_unsigned(3200, WIDTH) when x"f5",
                to_unsigned(100, WIDTH) when x"fa",
                to_unsigned(0, WIDTH) when x"fd",
                to_unsigned(5000, WIDTH) when x"ff", 
                to_unsigned(0, WIDTH) when others; -- "FE"              

end architecture rtl;
