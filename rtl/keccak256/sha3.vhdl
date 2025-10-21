 
library IEEE;
use IEEE.std_logic_1164.all;
use work.pkg_keccak_types.all;
use work.all;

entity sha3 is
generic (t : sha3_type := sha256;
        input_width : natural := 1600);-- can ether be 512 or 80
port(
    kecc_in    : in std_logic_vector(input_width-1 downto 0);
    rst         : in std_logic;
    clk         : in std_logic;
    start       : in std_logic;
    mode        : in sha3_mode;
    output_sha3 : out std_logic_vector(getHashSize(t) - 1 downto 0);
    ready       : out std_logic
);
end entity sha3;

architecture arch of sha3 is

    signal f_input          : StateArray;
    signal f_output         : StateArray;
    signal output_arraged   : std_logic_vector(getHashSize(t) - 1 downto 0);
    
begin
  
    with mode select 
        f_input <= to_StateArray(kecc_in) when init,
                    to_StateArray(to_std_logic_vector(f_output) xor kecc_in) when append;
    
    output_arraged <= to_std_logic_vector(f_output)(getHashSize(t) - 1 downto 0);
    
    loop_a : for int_i in 0 to getHashSize(t)/8 - 1 generate  --rearange a, abcd => cdab
        output_sha3(getHashSize(t)-8*int_i-1 downto getHashSize(t)-8*int_i - 8) <= output_arraged(8 + 8*int_i-1 downto 8*int_i);
    end generate loop_a;

    f : entity work.keccak_f(arch) 
    port map(
        input   => f_input, 
        rst     => rst, 
        clk     => clk, 
        start   => start, 
        output  => f_output, 
        ready   => ready);
    
end architecture arch;
