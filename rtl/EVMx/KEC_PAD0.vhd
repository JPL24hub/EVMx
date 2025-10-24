----------------------------------------------------------------------
-- FILE:        KEC_PAD.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 21/06/2024 - File created.
--              1.1 - 10/01/2025 - Input extended
-- DESCRIPTION: Takes 64 bytes as input, you can use size
--              to select the number of bytes that need to be hashed out of the 64 bytes input.
-- COMMENTS:    
--------------------------------------------------------------------------------------


library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity KEC_PAD0 is
    generic(
        INPUT_WIDTH    : natural := 1024;
        SIZE_WIDTH  : integer := 8;
        PAD_WIDTH   : natural := 1600);
    port(
        pad_in  : in std_logic_vector(INPUT_WIDTH-1 downto 0);
        size    : in std_logic_vector(SIZE_WIDTH-1 downto 0); -- How many bytes of pad_in should we hash
        pad_out : out std_logic_vector(PAD_WIDTH-1 downto 0)
    );
end entity;

architecture rtl of KEC_PAD0 is
    
    constant ZERO : std_logic_vector(511 downto 0) := (others => '0');
    constant ZERO_A : std_logic_vector(1088-(INPUT_WIDTH+1+4) - 1 downto 0) := (others => '0');
    constant PAD_MEG : integer := INPUT_WIDTH + 1;

    signal invtInput : std_logic_vector(INPUT_WIDTH-1 downto 0);
begin
    loop_a : for int_i in 0 to INPUT_WIDTH/8 - 1 generate  --rearange a, abcd => cdab
        invtInput(INPUT_WIDTH-8*int_i-1 downto INPUT_WIDTH-8*int_i - 8) <= pad_in(8 + 8*int_i-1 downto 8*int_i);
    end generate loop_a;

    process(invtInput, size)
        variable tempVec : std_logic_vector(PAD_MEG-1 downto 0);
        variable flip : std_logic_vector(INPUT_WIDTH-1 downto 0);
        variable size_int : integer range 0 to INPUT_WIDTH / 8;
    begin

        flip := (others => '0'); -- Initialize flip with 0s

        size_int := to_integer(unsigned(size)) * 8; -- Convert size to integer
        
        flip(size_int - 1 downto 0) := invtInput(INPUT_WIDTH - 1 downto INPUT_WIDTH - size_int); -- Flip invtInput
        
        tempVec := (others => '0'); -- Initialize t with all zeros
        tempVec(INPUT_WIDTH-1 downto 0) := flip; -- Assign pad_in to lower bits
        
        
        if size_int < PAD_MEG then
            tempVec(size_int) := '1'; -- Set t(size) to 1
        end if;
        
        pad_out <=  ZERO & x"8" & ZERO_A & tempVec; -- Assign t to output
    end process;
end architecture;