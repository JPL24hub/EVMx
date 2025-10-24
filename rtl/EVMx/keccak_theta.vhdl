
library IEEE;
use IEEE.std_logic_1164.all;
use work.PKG_KECCAK.all;

entity keccak_theta is
port(
	input : in StateArray;
	output : out StateArray
);
end entity keccak_theta;

architecture arch of keccak_theta is
	type pairity_t is array(4 downto 0) of Lane;
	signal slicePairity, combinedPairity : pairity_t;
	function rotlOne(input : Lane) return Lane is
	begin
		return input(62 downto 0) & input(63);
	end function rotlOne;
begin
	slicePairityCalculation : for x in 0 to 4 generate
		slicePairity(x) <= input(x) xor input(x + 5) xor input(x + 10) xor input(x + 15) xor input(x + 20);
	end generate;
	combinedPairityCalculation : for x in 0 to 4 generate
		combinedPairity(x) <= slicePairity((x + 4) mod 5) xor rotlOne(slicePairity((x + 1) mod 5));
	end generate;
	outputCalculation : for i in 0 to 24 generate
		output(i) <= input(i) xor combinedPairity(i mod 5);
	end generate;

end architecture arch;