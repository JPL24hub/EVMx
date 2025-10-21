
library IEEE;
use IEEE.std_logic_1164.all;
use work.pkg_keccak_types.all;

entity keccak_rho is
port(
	input : in StateArray;
	output : out StateArray
);
end entity keccak_rho;

architecture arch of keccak_rho is
	
	function rotl(l : Lane; n : natural) return Lane is
	begin
		return l(63 - n downto 0) & l(63 downto 63 - n + 1);
	end function rotl;
	
	type offset_t is array(0 to 24) of natural;
	
	constant offsets : offset_t := (0, 1, 62, 28, 27, 36, 44, 6, 55, 20, 3, 10, 43, 25, 39, 41, 45, 15, 21, 8, 18, 2, 61, 56, 14);
	
begin
	
	permutate : for i in 0 to 24 generate
		output(i) <= rotl(input(i), offsets(i));
	end generate;
	
end architecture arch;