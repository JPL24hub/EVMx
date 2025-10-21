
library IEEE;
use work.pkg_keccak_types.all;

entity keccak_pi is
port(
	input : in StateArray;
	output : out StateArray
);
end entity keccak_pi;

architecture arch of keccak_pi is

begin
	perm_y : for y in 0 to 4 generate
		perm_x : for x in 0 to 4 generate
			output(y * 5 + x) <= input(x * 5 + (x + 3 * y) mod 5);
		end generate;
	end generate;
end architecture arch;