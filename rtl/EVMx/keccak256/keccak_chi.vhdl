
-- The Keccak sponge function, designed by Guido Bertoni, Joan Daemen,
-- Micha�l Peeters and Gilles Van Assche. For more information, feedback or
-- questions, please refer to our website: http://keccak.noekeon.org/

-- Implementation by the designers,
-- hereby denoted as "the implementer".

-- To the extent possible under law, the implementer has waived all copyright
-- and related or neighboring rights to the source code in this file.
-- http://creativecommons.org/publicdomain/zero/1.0/

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