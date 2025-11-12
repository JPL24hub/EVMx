
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.all;
use work.pkg_keccak_types.all;

entity keccak_f is
port(
	input : in StateArray;
	rst : in std_logic;
	clk : in std_logic;
	start : in std_logic;
	output : out StateArray;
	ready : out std_logic
);
end entity keccak_f;

architecture arch of keccak_f is

	component keccak_p is
		port(
			input : in StateArray;
			roundIndex : in Natural range 0 to 23;
			output : out StateArray
		);
	end component;

	signal permutation_input : StateArray;
	signal current_round : Natural range 0 to 23;
	signal permutation_output : StateArray;
	signal running : std_logic := '0';
	signal done : std_logic := '0';
	
	signal debug_input_vector, debug_output_vector : std_logic_vector(1599 downto 0);
begin
	
	permutation : keccak_p port map(input => permutation_input, roundIndex => current_round, output => permutation_output);
	
	process(clk, rst) is
	begin
		if rst = '0' then
			permutation_input <= to_StateArray(std_logic_vector(to_unsigned(0, 1600)));
			running <= '0';
			done <= '0';
			current_round <= 0;
		elsif rising_edge(clk) then
			if running = '0' then
				if start = '1' then
					running <= '1';
					current_round <= 0;
                    permutation_input <= input;
				end if;
			else
				if current_round = 23 then
					running <= '0';
					done <= '1';
				else
                    permutation_input <= permutation_output;
					current_round <= current_round + 1;
				end if;
			end if;
		end if;
	end process;
	
	output <= permutation_output;
	ready <= done;
	
	debug_input_vector <= to_std_logic_vector(input);
	debug_output_vector <= to_std_logic_vector(permutation_output);
	
end architecture arch;
