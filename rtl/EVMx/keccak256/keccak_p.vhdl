
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
use IEEE.numeric_std.all;
use work.PKG_KECCAK.all;
use work.all;

entity keccak_p is
port(
	input : in StateArray;
	roundIndex : in natural range 0 to 23;
	output : out StateArray
);
end entity keccak_p;

architecture arch of keccak_p is
	
	component keccak_theta is
		port(
			input : in StateArray;
			output : out StateArray
		);
	end component;
	
	component keccak_rho is
		port(
			input : in StateArray;
			output : out StateArray
		);
	end component;
	
	component keccak_pi is
		port(
			input : in StateArray;
			output : out StateArray
		);
	end component;
	
	component keccak_chi is
		port(
			input : in StateArray;
			output : out StateArray
		);
	end component;
	
	component keccak_iota is
		port(
			input : in StateArray;
			roundIndex : Natural range 0 to 23;
			output : out StateArray
		);
	end component;
	
	signal theta_out : StateArray;
	signal rho_out : StateArray;
	signal pi_out : StateArray;
	signal chi_out : StateArray;
	
	signal out_temp : StateArray;
	
	signal debug_input_vector, debug_output_vector : std_logic_vector(1599 downto 0);
	
begin
	theta : keccak_theta port map(input => input, output => theta_out);
	rho : keccak_rho port map(input => theta_out, output => rho_out);
	pi : keccak_pi port map(input => rho_out, output => pi_out);
	chi : keccak_chi port map(input => pi_out, output => chi_out);
	iota : keccak_iota port map(input => chi_out, roundIndex => roundIndex, output => out_temp);
	output <= out_temp;
	
	debug_input_vector <= to_std_logic_vector(input);
	debug_output_vector <= to_std_logic_vector(out_temp);
	
end architecture arch;
