library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity PowerOfTwoDivider is
    Port (
        numDiv     : in  std_logic_vector(255 downto 0);
        denDiv     : in  std_logic_vector(255 downto 0);
        quoDiv     : out std_logic_vector(255 downto 0);
        power_of_two_flag : out std_logic
    );
end PowerOfTwoDivider;

architecture Behavioral of PowerOfTwoDivider is
    -- Helper function to count number of 1s in denDiv
    function count_ones(vec: std_logic_vector) return integer is
        variable cnt : integer := 0;
    begin
        for i in vec'range loop
            if vec(i) = '1' then
                cnt := cnt + 1;
            end if;
        end loop;
        return cnt;
    end function;

    -- Function to compute position of the single '1' in denDiv (for shift amount)
    function get_shift_amount(vec: std_logic_vector) return integer is
        variable pos : integer := 0;
    begin
        for i in vec'range loop
            if vec(i) = '1' then
                pos := vec'length - 1 - i; -- MSB = 0
                exit;
            end if;
        end loop;
        return pos;
    end function;
begin
    process(numDiv, denDiv)
        variable ones_count : integer;
        variable shift_amt  : integer;
        variable temp_result : std_logic_vector(255 downto 0);
    begin
        ones_count := count_ones(denDiv);

        if ones_count = 1 then
            power_of_two_flag <= '1';
            shift_amt := get_shift_amount(denDiv);

            if shift_amt = 256 then
                temp_result := (others => '0');
            else
                temp_result := (shift_amt - 1 downto 0 => '0') & numDiv(255 downto shift_amt);
            end if;
            quoDiv <= temp_result;
        else
            power_of_two_flag <= '0';
            quoDiv <= (others => '0');
        end if;
    end process;
end Behavioral;
