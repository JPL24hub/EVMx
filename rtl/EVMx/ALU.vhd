----------------------------------------------------------------------
-- FILE:        ALU.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 21/06/2024 - File created.
-- DESCRIPTION: 
-- COMMENTS:   
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity ALU is
    generic (
        WIDTH_256 : integer := 256;
        WIDTH_opALU : integer := 6
        );
    port(
        a       : in  std_logic_vector(WIDTH_256-1 downto 0); -- 256-bit input 'a'
        b       : in  std_logic_vector(WIDTH_256-1 downto 0); -- 256-bit input 'b'
        opALU   : in  std_logic_vector(WIDTH_opALU-1 downto 0);           -- Operation code opO
        alu_out : out std_logic_vector(WIDTH_256-1 downto 0)  -- 256-bit ALU output
    );
end entity;

architecture rtl of ALU is
    -- Signals for ALU operations
    signal aN, bN, bNeg, sigLT, sigGT, sigSLT, sigSGT, sigEQ : unsigned(WIDTH_256-1 downto 0);  -- Operands converted to unsigned

    signal result              : unsigned(WIDTH_256-1 downto 0);  -- Arithmetic result
    --signal mul_result          : unsigned(2*WIDTH_256-1 downto 0);  -- Multiplication result
    --signal div_result          : unsigned(WIDTH_256-1 downto 0);  -- Division result
    --signal shift_result        : unsigned(WIDTH_256-1 downto 0);  -- Shift result
    --signal logical_result      : std_logic_vector(WIDTH_256-1 downto 0); -- Logical operation result
    --signal sigOne              : unsigned(WIDTH_256-1 downto 0) := (0=>'1', others=>'0');
    signal op, opO              : std_logic_vector(2 downto 0);
    signal is_zero              : integer;

    -- Declare the DSP inference attribute
    --attribute use_dsp : string;

    -- Assign the DSP inference attribute to the relevant signals
    -- attribute use_dsp of result      : signal is "yes";
    --attribute use_dsp of mul_result  : signal is "yes";
    --attribute use_dsp of div_result  : signal is "yes";


begin

    is_zero <= 1 when (OR bN) = '0' else 0;
    
    op <= opALU(5 downto 3);
    opO <= opALU(2 downto 0);
    -- Convert inputs to unsigned for arithmetic operations
    aN <= unsigned(a);
    bN <= unsigned(b);
    --sigb <= sigOne when bN = 0 else bN; -- To prevent division by 0

    -- Use control signal 'op' to determine whether to add or subtract
    -- If subtracting (op = "0001"), negate b (two's complement: NOT b + 1)
    bNeg <= not bN + 1 when op = "010" else bN;

    -- Addition or subtraction (DSP inference for addition and subtraction)
    result <= aN + bNeg;

    -- Multiplication (guide Vivado to use DSP blocks for multiplication)
    --mul_result <= aN * bN;

    -- Division (Vivado might not always use DSPs for division, but this attribute helps)
    --div_result <= aN / sigb;

    -- Comparisons
    sigLT <= (0=>'1',others=>'0') when aN < bN else (others=>'0'); --LT
    sigGT <= (0=>'1',others=>'0') when aN > bN else (others=>'0'); --GT
    sigSLT <= (0=>'1',others=>'0') when signed(a) < signed(b) else (others=>'0'); --SLT
    sigSGT <= (0=>'1',others=>'0') when signed(a) > signed(b) else (others=>'0'); --SGT
    sigEQ <= (0=>'1',others=>'0') when aN = bN else (others=>'0'); --EQ

    -- ALU operation: select the appropriate result based on the op code
    PROC_ARI: process (op, opALU, result) is
        variable sigMUX0, sigMUX1, sigMUX2, sigMUX3 : unsigned(WIDTH_256-1 downto 0);
    begin

        -- Arithmetic operations
        case op is
            when "000" =>  -- Addition
                sigMUX0 := result;
            when "001" =>  -- ISZERO
                sigMUX0 := to_unsigned(is_zero, WIDTH_256);
            when "010" =>  -- Division
                sigMUX0 := result; -- Substracted result
            when others =>  -- Multiplication
                sigMUX0 := (others=>'0'); --mul_result(WIDTH_256-1 downto 0);
         end case;
         
         -- Comparison operations
        case op is
            when "000" =>  -- SLT
                sigMUX1 := sigSLT;  
            when "001" =>  -- SGT
                sigMUX1 := sigSGT;
            when "010" =>  -- LT
                sigMUX1 := sigLT;
            when "011" => -- GT
                sigMUX1 := sigGT; 
            when others =>  --EQ
                sigMUX1 := sigEQ; 
        end case;

        -- LOGICAL operations
        case op is
            when "000" =>  -- Logical AND
                sigMUX2 := aN AND bN;
            when "001" =>  -- Logical OR
                sigMUX2 := aN OR bN;
            when "010" =>  -- Logical XOR
                sigMUX2 := aN XOR bN;
            when others =>  -- Logical NOT
                sigMUX2 := NOT bN;
        end case;

        -- Shift operations
        case op is
            when "000" =>  -- Shift Left (SHL)
                sigMUX3 := shift_left(bN, to_integer(aN(31 downto 0))); 
            when "001" =>  -- Logical Shift Right (SHR)
                sigMUX3 := shift_right(bN, to_integer(aN(31 downto 0)));
            when others =>  -- Arithmetic Shift Right (SAR)
                sigMUX3 := unsigned(shift_right(signed(bN), to_integer(aN(31 downto 0))));
        end case;
        
        -- Mux selection
        case opO is
            when "000" =>
                alu_out <= std_logic_vector(sigMUX0);
            when "001" =>
                alu_out <= std_logic_vector(sigMUX1);
            when "010" =>
                alu_out <= std_logic_vector(sigMUX2);
            when others =>
                alu_out <= std_logic_vector(sigMUX3);
        end case;
    end process;

    -- -- SIGNEXTEND process
    --PROC_SIGNEXTEND: process(aN, bN, op) 
    --    variable sigextend     : unsigned(WIDTH_256-1 downto 0) := (others=>'0');
    --begin
    --    sigextend := bN;
    --    if op = "10010" then
    --        if bN(to_integer(aN)+7) = '1' then
    --            for i in 0 to WIDTH_STACK/8 - 1 loop
    --                    if i > to_integer(aN)+7 then
    --                        sigextend(to_integer(aN)+i) := '1';
    --                    end if;
    --            end loop;
    --        else
    --            for i in 0 to WIDTH_STACK/8 - 1 loop
    --                if i > to_integer(aN)+7 then
    --                    sigextend(to_integer(aN)+i) := '0';
    --                end if;
    --        end loop;
    --        end if;
--
    --        sig_extend <= sigextend;
    --    end if;
    --end process;
   
end architecture;
