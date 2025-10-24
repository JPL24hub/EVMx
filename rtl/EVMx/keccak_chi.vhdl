
library IEEE;
use IEEE.std_logic_1164.all;
use work.PKG_KECCAK.all;

entity keccak_chi is
port(
	input : in StateArray;
	output : out StateArray
);
end entity keccak_chi;

architecture arch of keccak_chi is

begin
	gen_y : for y in 0 to 4 generate
		gen_x : for x in 0 to 4 generate
			output(y * 5 + x) <= input(y * 5 + x) xor ((not input(y * 5 + (x + 1) mod 5)) and input(y * 5 + (x + 2) mod 5));
		end generate;
	end generate;
end architecture arch;