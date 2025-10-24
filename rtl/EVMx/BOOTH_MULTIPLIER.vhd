----------------------------------------------------------------------
-- FILE:        BOOTH_MULTIPLIER.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 13/02/2025 - File created.
-- DESCRIPTION: Booth Multiplier implementation. It handles A=1, B=1, A=0, B=0, A=1, B=0, A=0, B=1.
-- COMMENTS: Working as expected.
--------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BOOTH_MULTIPLIER is
    generic (WIDTH : natural := 4);
    port (
        multiplicant    : in  std_logic_vector(WIDTH-1 downto 0); --Mulriplicant M, Multiplier Q
        multiplier      : in  std_logic_vector(WIDTH-1 downto 0);
        clk, rst, start : in std_logic;
        done : out std_logic;
        product : out std_logic_vector(2*WIDTH-1 downto 0)
    );
end entity BOOTH_MULTIPLIER;

architecture rtl of BOOTH_MULTIPLIER is
    constant ZEROS : std_logic_vector(WIDTH-1 downto 0) := (others => '0');
    signal regA, regM, mCant, mLier : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal regQ, regQ_nxt : unsigned(WIDTH downto 0) := (others => '0');
    signal regA_nxt, regM_nxt, aluOut : unsigned(WIDTH-1 downto 0) := (others => '0');
    signal selA, selQ, sel_prod : std_logic_vector(1 downto 0) := (others => '0');
    signal q0q1 : unsigned(1 downto 0) := (others => '0');
    signal counter, counter_nxt : natural := 0;
    signal enCounter, opALU, selM : std_logic := '0';
    
    type states is (idle, load, booth_step, shift);
    signal reg_state, next_state : states;

begin
    mCant <= unsigned(multiplicant);
    mLier <= unsigned(multiplier);

    -- Register update process
    process(clk, rst) 
    begin
        if rising_edge(clk) then
            if rst = '0' then
                regA <= (others => '0');
                regQ <= (others => '0');
                regM <= (others => '0');
                counter <= 0;
            else
                regA <= regA_nxt;
                regQ <= regQ_nxt;
                regM <= regM_nxt;
                counter <= counter_nxt;
            end if;
        end if;
    end process;

    counter_nxt <= counter + 1 when enCounter = '1' else counter; -- Counter increment
    regM_nxt <= unsigned(multiplicant) when selM = '1' else regM; -- Multiplicand M

    aluOut <= NOT regM + 1 + regA when opALU = '1' else regM + regA; -- 2's complement of M

    with selA select
        regA_nxt <=  regA when "00", -- Retain A
                    (others => '0') when "01", -- Load A with zeros
                    regA(WIDTH - 1) & regA(WIDTH - 1 downto 1) when "10", -- Shift A right
                    aluOut when others; -- ALU operation
    
    with selQ select
        regQ_nxt <= regQ when "00", -- Retain Q
                    unsigned(multiplier) & '0' when "01", -- Load Q with multiplier
                    regA(0) & regQ(WIDTH downto 1) when others; -- 10 Shift Q right

    q0q1 <= regQ(1 downto 0); -- Concatenate Q(0) and Q(1)

    -- controller: state memory process
    process(clk, rst) is
        begin
            if rising_edge(clk) then
                if(rst='0') then
                    reg_state <= idle;
                else
                    reg_state <= next_state;
                end if;
            end if;
        end process;

    -- Next state logic
    process(reg_state, start, counter, q0q1) is
    begin
        
        selM <= '0'; -- Default value for selM
        selA <= "00"; -- Default value for selA
        selQ <= "00"; -- Default value for selQ
        opALU <= '0'; -- Default value for opALU
        enCounter <= '0'; -- Default value for enCounter
        sel_prod <= "00"; -- Default value for sel_prod
        done <= '0'; -- Default value for done

        case reg_state is
            when idle =>
                if start = '1' then
                    next_state <= load;
                else
                    next_state <= idle;
                end if;

            when load =>
                if mCant = 0 OR mLier = 0 then
                    done <= '1';
                    sel_prod <= "01";
                    next_state <= idle;
                elsif mCant = 1 then
                    done <= '1';
                    sel_prod <= "10";
                    next_state <= idle;
                elsif mLier = 1 then
                    done <= '1';
                    sel_prod <= "11";
                    next_state <= idle;
                else
                    selM <= '1'; -- Load M with multiplicand
                    selA <= "01"; -- Load A with zeros
                    selQ <= "01"; -- Load Q with multiplier
                    next_state <= booth_step;
                end if;
            when booth_step =>
                if q0q1 = "00" OR q0q1 = "11" then -- Arithmetic right shift
                    selA <= "10"; -- Extend A for sign bit
                    selQ <= "10"; -- Extend Q with an extra bit
                    enCounter <= '1'; -- Enable counter
                    if counter = WIDTH then
                        done <= '1';
                        next_state <= idle;
                    else
                        next_state <= booth_step;
                    end if;
                elsif q0q1 = "01" then -- -- A = A + M
                    selA <= "11"; -- Load A with ALU output
                    next_state <= shift;
                else -- A_reg + mCant', ARS
                    opALU <= '1'; -- Select 2's complement of multiplicand M
                    selA <= "11"; -- Perform ALU operation based on Booth encoding
                    next_state <= shift;
                end if; 
            when shift => 
                selA <= "10"; -- Extend A for sign bit
                selQ <= "10"; -- Extend Q with an extra bit
                enCounter <= '1'; -- Enable counter
                if counter = WIDTH then
                    done <= '1';
                    next_state <= idle;
                else
                    next_state <= booth_step;
                end if;
            when others =>
                next_state <= idle;
        end case;
    end process;

    -- Output product
    with sel_prod select
        product <= std_logic_vector(regA & regQ(WIDTH downto 1)) when "00", -- Output product
                   (others => '0') when "01", -- Output zeros
                   ZEROS & multiplier when "10", -- Output multiplicand
                   ZEROS & multiplicant when others; -- -- Output multiplicand

end architecture;