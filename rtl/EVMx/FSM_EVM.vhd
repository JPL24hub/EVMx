--------------------------------------------------------------------------------------
-- FILE:        FSM_EVM.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 28/11/2024 - File created.
-- DESCRIPTION: FSM of new EVM
-- COMMENTS:    
--------------------------------------------------------------------------------------

library IEEE;
use std.textio.all;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all;
use work.PKG_EVM.all;

-- Entity
entity FSM_EVM is
    generic(
        WIDTH_8     : integer := 8;
        WDTH_enPC   : integer := 2;
        WIDTH_CNTL1 : integer := 8;
        WIDTH_CNTR  : integer := 6;
        DUP_OFFSET  : integer := 10;
        WIDTH_opALU : integer := 6;
        SIZE_COPY   : integer := 256;
        WIDTH_SEL_MEM : integer := 3;
        WIDTH_SELBYTS : integer := 3
    );
    port(
        clk         : in std_logic;
        rst         : in std_logic;
        done_MEMwt  : in std_logic;
        done_MEMrd  : in std_logic;
        startEVM    : in std_logic;
        doneKecc    : in std_logic;
        doneEXP     : in std_logic;
        doneSAM     : in std_logic;
        doneBTCDjump : in std_logic;
        --ldByte      : in std_logic;
        readyDiv    : in std_logic;
        enCntr2PC   : out std_logic_vector(WIDTH_SEL_MEM - 1 downto 0);
        selShftCntr : out std_logic_vector(WDTH_enPC - 1 downto 0);
        selByts     : out std_logic_vector(WIDTH_SELBYTS - 1 downto 0);
        sel_mem     : out std_logic_vector(WIDTH_SEL_MEM - 1 downto 0);
        selRpl      : out std_logic_vector(WDTH_enPC - 1 downto 0);
        wrt_cntr    : out std_logic_vector(WDTH_enPC - 1 downto 0);
        rd_cntr     : out std_logic_vector(WDTH_enPC - 1 downto 0);
        cntlCntr0   : out std_logic_vector(WDTH_enPC - 1 downto 0);
        stack_out   : in std_logic_vector(SIZE_COPY - 1 downto 0);
        outBYTCD8   : in std_logic_vector(WIDTH_8 - 1 downto 0);
        cntr_out    : in std_logic_vector(WIDTH_CNTR - 1 downto 0);
        addr_offset : out std_logic_vector(DUP_OFFSET - 1 downto 0);
        top_stack   : in  std_logic_vector(DUP_OFFSET - 1 downto 0);  -- Next empty space at the top of stack
        enPC        : out std_logic_vector(WIDTH_SEL_MEM - 1 downto 0);
        cntl_sigs1  : out std_logic_vector(WIDTH_CNTL1 - 1 downto 0);
        en_shft     : out std_logic_vector(WDTH_enPC - 1 downto 0);
        selRegALU   : out std_logic_vector(WIDTH_SEL_MEM - 1 downto 0);
        selSTACK    : out SELECT_STACK;
        sel_retValCntr : out std_logic_vector(WDTH_enPC - 1 downto 0);
        opALU       : out std_logic_vector(WIDTH_opALU - 1 downto 0);
        brokeFlag : in std_logic;
        divBy224 : in std_logic

    );
end entity;

-- Architecture
architecture rtl of FSM_EVM is
    
    constant HOLD_BYTE : integer := 8;

    signal we_stack, push, pop, wrt_stack, enAccm, doneEVM, rstCntr, enCntr, en_reg0, rstAccm, en_holdB, enRegALU,
     start_rd_mem, start_wrt_mem, rstMemAcc, en_reg1, en_reg2, en_reg3, sel_reg0, enMEM_cpy, enStorage, 
     selStorage, selDiv, startKecc, rstKecc, en_reg4, mem_wrt, enCallD, rstCallD, startEXP, rstEXP, rstSAM, 
     en_TopStack, startSAM, weRv, startDiv, rstDiv, enGasLimit, rstGas, enTotGas, selOpcode, selNum, rstPC, selStrg, 
     wrtbytcd, sigJump : std_logic;
    signal holdByte, holdByte_next : std_logic_vector(HOLD_BYTE - 1 downto 0) := (others => '0');
    signal selAddrOffset : std_logic_vector(1 downto 0);
    signal top_stackReg, top_stackRegNxt : std_logic_vector(DUP_OFFSET - 1 downto 0);

    type STATES is (IDLE, BRANCH, STOP_EVM, PUSH1, PUSH_STATE, DUP, SWAP0, SWAP1, SWAP2, OPALU0, OPALU1, 
                    MSTORE0, MSTORE1, CALDATACOPY0, CALDATACOPY1, EXTCODECOPY, MCOPY0, MCOPY1, MLOAD0, MLOAD1, MLOAD2,
                    MLOAD3, SSTORE0, SSTORE1, SLOAD0, SLOAD1, JUMP0, JUMP01, JUMPI0, JUMPI1, BALANCE, KECCAK256_0, 
                    KECCAK256_1, KECCAK256_2, KECCAK256_3, KECCAK256_4, BYTE0, BYTE1, CREATE0, CREATE2, RESETKECC,
                    RETURN0, RETURN1, RETURN2, RETURN3, ISZERO, CODECOPY0, MSTORE01, MSTORE8, CALLDATALOAD0, 
                    CALLDATALOAD1, CALDATACOPY_1, EXP0, EXP1, MUL_STATE, PUSH_ALU, DUP0, DIV_STATE, SIGNEXTEND, ST_POPGAS, 
                    ST_POPADDR, ST_POPARGSOFFSET, ST_POPARGSSIZE, LOADCOUNTER1, ST_COPYMEM, ST_POPRETOFFSET, MCOPY01, 
                    POP_RETOFFSET, POP_RETSIZE, LOADCOUNTER0, WRITE_MEM, STATE_BLOCKHASH, MLOAD12, LOAD_BYTCODE_MEM, STATE_JUMP);
    signal reg_state, next_state : STATES := IDLE;

begin
    cntl_sigs1 <= sigJump & selStrg & wrtbytcd & rstPC & selNum & selOpcode & enTotGas & rstGas & enGasLimit & startDiv & rstDiv & weRv & startSAM & rstSAM & startEXP 
    & rstEXP & enCallD & rstCallD & mem_wrt & en_reg4 & rstKecc & startKecc & selDiv & selStorage & enStorage & enMEM_cpy & sel_reg0 
    & en_reg3 & en_reg2 & en_reg1 & start_rd_mem & start_wrt_mem & rstMemAcc & enRegALU & rstAccm & en_reg0 & enCntr & rstCntr & we_stack 
    & push & pop & wrt_stack & enAccm & doneEVM;

    FSM_R: process(clk) is
        begin
            if rising_edge(clk) then
                if rst = '0' then
                    reg_state <= IDLE;
                    holdByte <= (others => '0');
                    top_stackReg <= (others => '0');
                else
                    reg_state <= next_state;
                    holdByte <= holdByte_next;
                    top_stackReg <= top_stackRegNxt;
                end if;
            end if;
        end process;
        holdByte_next <= outBYTCD8(HOLD_BYTE - 1 downto 0) when en_holdB = '1' else  holdByte;
        top_stackRegNxt <= top_stack when en_TopStack = '1' else top_stackReg;

        with selAddrOffset select
        addr_offset <= (others => '0') when "00",
                        std_logic_vector(unsigned(top_stackReg) - unsigned(outBYTCD8(3 downto 0)) - 1) when "01",
                        std_logic_vector(unsigned(top_stackReg) - unsigned(holdByte(3 downto 0)) - 2) when "10",
                        std_logic_vector(unsigned(top_stackReg) - unsigned(holdByte(3 downto 0)) - 1) when others;

    FSM: process(reg_state, brokeFlag, rst, clk, startEVM, outBYTCD8, divBy224, cntr_out, holdByte, done_MEMwt, done_MEMrd, stack_out, doneKecc, doneEXP, doneSAM, readyDiv, doneBTCDjump) is
        
            variable v_STOP : integer := 0;
            variable v_ADD : integer := 0;
            variable v_MUL : integer := 0;
            variable v_SUB : integer := 0;
            variable v_DIV : integer := 0;
            variable v_SDIV : integer := 0;
            variable v_MOD : integer := 0;
            variable v_SMOD : integer := 0;
            variable v_ADDMOD : integer := 0;
            variable v_MULMOD : integer := 0;
            variable v_EXP : integer := 0;
            variable v_SIGNEXTEND : integer := 0;
            variable v_LT : integer := 0;
            variable v_GT : integer := 0;
            variable v_SLT : integer := 0;
            variable v_SGT : integer := 0;
            variable v_EQ : integer := 0;
            variable v_ISZERO : integer := 0;
            variable v_AND : integer := 0;
            variable v_OR : integer := 0;
            variable v_XOR : integer := 0;
            variable v_NOT : integer := 0;
            variable v_BYTE : integer := 0;
            variable v_SHL : integer := 0;
            variable v_SHR : integer := 0;
            variable v_SAR : integer := 0;
            variable v_KECCAK256 : integer := 0;
            variable v_ADDRESS : integer := 0;
            variable v_BALANCE : integer := 0;
            variable v_ORIGIN : integer := 0;
            variable v_CALLER : integer := 0;
            variable v_CALLVALUE : integer := 0;
            variable v_CALLDATALOAD : integer := 0;
            variable v_CALLDATASIZE : integer := 0;
            variable v_CALLDATACOPY : integer := 0;
            variable v_CODESIZE : integer := 0;
            variable v_CODECOPY : integer := 0;
            variable v_GASPRICE : integer := 0;
            variable v_EXTCODESIZE : integer := 0;
            variable v_EXTCODECOPY : integer := 0;
            variable v_RETURNDATASIZE : integer := 0;
            variable v_RETURNDATACOPY : integer := 0;
            variable v_EXTCODEHASH : integer := 0;
            variable v_BLOCKHASH : integer := 0;
            variable v_COINBASE : integer := 0;
            variable v_TIMESTAMP : integer := 0;
            variable v_NUMBER : integer := 0;
            variable v_DIFFICULTY : integer := 0;
            variable v_GASLIMIT : integer := 0;
            variable v_CHAINID : integer := 0;
            variable v_BASEFEE : integer := 0;
            variable v_POP : integer := 0;
            variable v_MLOAD : integer := 0;
            variable v_MSTORE : integer := 0;
            variable v_MSTORE8 : integer := 0;
            variable v_SLOAD : integer := 0;
            variable v_SSTORE : integer := 0;
            variable v_JUMP : integer := 0;
            variable v_JUMPI : integer := 0;
            variable v_GETPC : integer := 0;
            variable v_MSIZE : integer := 0;
            variable v_GAS : integer := 0;
            variable v_JUMPDEST : integer := 0;
            variable v_PUSH1 : integer := 0;
            variable v_PUSH2 : integer := 0;
            variable v_PUSH3 : integer := 0;
            variable v_PUSH4 : integer := 0;
            variable v_PUSH5 : integer := 0;
            variable v_PUSH6 : integer := 0;
            variable v_PUSH7 : integer := 0;
            variable v_PUSH8 : integer := 0;
            variable v_PUSH9 : integer := 0;
            variable v_PUSH10 : integer := 0;
            variable v_PUSH11 : integer := 0;
            variable v_PUSH12 : integer := 0;
            variable v_PUSH13 : integer := 0;
            variable v_PUSH14 : integer := 0;
            variable v_PUSH15 : integer := 0;
            variable v_PUSH16 : integer := 0;
            variable v_PUSH17 : integer := 0;
            variable v_PUSH18 : integer := 0;
            variable v_PUSH19 : integer := 0;
            variable v_PUSH20 : integer := 0;
            variable v_PUSH21 : integer := 0;
            variable v_PUSH22 : integer := 0;
            variable v_PUSH23 : integer := 0;
            variable v_PUSH24 : integer := 0;
            variable v_PUSH25 : integer := 0;
            variable v_PUSH26 : integer := 0;
            variable v_PUSH27 : integer := 0;
            variable v_PUSH28 : integer := 0;
            variable v_PUSH29 : integer := 0;
            variable v_PUSH30 : integer := 0;
            variable v_PUSH31 : integer := 0;
            variable v_PUSH32 : integer := 0;
            variable v_DUP1 : integer := 0;
            variable v_DUP2 : integer := 0;
            variable v_DUP3 : integer := 0;
            variable v_DUP4 : integer := 0;
            variable v_DUP5 : integer := 0;
            variable v_DUP6 : integer := 0;
            variable v_DUP7 : integer := 0;
            variable v_DUP8 : integer := 0;
            variable v_DUP9 : integer := 0;
            variable v_DUP10 : integer := 0;
            variable v_DUP11 : integer := 0;
            variable v_DUP12 : integer := 0;
            variable v_DUP13 : integer := 0;
            variable v_DUP14 : integer := 0;
            variable v_DUP15 : integer := 0;
            variable v_DUP16 : integer := 0;
            variable v_SWAP1 : integer := 0;
            variable v_SWAP2 : integer := 0;
            variable v_SWAP3 : integer := 0;
            variable v_SWAP4 : integer := 0;
            variable v_SWAP5 : integer := 0;
            variable v_SWAP6 : integer := 0;
            variable v_SWAP7 : integer := 0;
            variable v_SWAP8 : integer := 0;
            variable v_SWAP9 : integer := 0;
            variable v_SWAP10 : integer := 0;
            variable v_SWAP11 : integer := 0;
            variable v_SWAP12 : integer := 0;
            variable v_SWAP13 : integer := 0;
            variable v_SWAP14 : integer := 0;
            variable v_SWAP15 : integer := 0;
            variable v_SWAP16 : integer := 0;
            variable v_LOG0 : integer := 0;
            variable v_LOG1 : integer := 0;
            variable v_LOG2 : integer := 0;
            variable v_LOG3 : integer := 0;
            variable v_LOG4 : integer := 0;
            variable v_JUMPTO : integer := 0;
            variable v_JUMPIF : integer := 0;
            variable v_JUMPSUB : integer := 0;
            variable v_JUMPSUBV : integer := 0;
            variable v_BEGINSUB : integer := 0;
            variable v_BEGINDATA : integer := 0;
            variable v_RETURNSUB : integer := 0;
            variable v_PUTLOCAL : integer := 0;
            variable v_GETLOCAL : integer := 0;
            variable v_SLOADBYTES : integer := 0;
            variable v_SSTOREBYTES : integer := 0;
            variable v_SSIZE : integer := 0;
            variable v_CREATE : integer := 0;
            variable v_CALL : integer := 0;
            variable v_CALLCODE : integer := 0;
            variable v_RETURN : integer := 0;
            variable v_DELEGATECALL : integer := 0;
            variable v_CREATE2 : integer := 0;
            variable v_STATICCALL : integer := 0;
            variable v_TXEXECGAS : integer := 0;
            variable v_REVERT : integer := 0;
            variable v_INVALID : integer := 0;
            variable v_SELFDESTRUCT : integer := 0;
            variable v_UNKNOWN : integer := 0;

        begin
            enPC        <= "000";
            we_stack    <= '0';
            wrt_stack   <= '0';
            push        <= '0';
            pop         <= '0';
            doneEVM     <= '0';
            selSTACK    <= ZERO256Sel;
            enAccm      <= '0';
            rstCntr     <= '0';
            enCntr      <= '0';
            en_reg0     <= '0';
            sel_reg0    <= '0';
            en_reg1     <= '0';
            selAddrOffset <= "00";
            rstAccm     <= '0';
            en_holdB    <= '0';
            opALU       <= (others => '0');
            enRegALU    <= '0';
            start_rd_mem <= '0';
            start_wrt_mem <= '0';
            rstMemAcc  <= '1';
            sel_mem    <= "000";
            selByts    <= "000";
            en_reg2    <= '0';
            en_reg3    <= '0';
            en_shft    <= "00"; -- Reset shift
            enMEM_cpy  <= '0';
            enStorage  <= '0';
            selStorage <= '0';
            selDiv   <= '0';
            startKecc <= '0';
            selRpl    <= "00";
            rstKecc   <= '1';
            en_reg4   <= '0';
            enCntr2PC <= "000";
            selShftCntr <= "00";
            wrt_cntr <= "00";
            rd_cntr <= "00";
            mem_wrt <= '0';
            enCallD <= '0';
            rstCallD <= '0';
            cntlCntr0 <= "00";
            startEXP <= '0';
            rstEXP <= '0';
            selRegALU <= "000";
            startSAM <= '0';
            rstSAM <= '0';
            en_TopStack <= '0';
            weRv <= '0';
            sel_retValCntr <= "00";
            startDiv <= '0';
            rstDiv <= '0';
            enGasLimit <= '0';
            rstGas <= '1';
            enTotGas <= '0';
            selOpcode <= '0';
            selNum <= '0';
            rstPC <= '1';
            wrtbytcd <= '0';
            selStrg <= '1';
            sigJump <= '0';

            case reg_state is
                when IDLE =>
                    rstMemAcc  <= '0';
                    rstKecc   <= '0';
                    rstGas <= '0';
                    rstPC <= '0';
                    if startEVM = '1' then
                        wrtBYTCD <= '1'; -- Enable writing
                        enPC <= "100"; -- Increment PC
                        rstPC <= '1';
                        enGasLimit <= '1';
                        rstGas <= '1';
                        next_state <= BRANCH;
                    else
                        next_state <= IDLE;
                    end if;
                --when LOAD_BYTCODE_MEM =>
                --    enPC <= "100"; -- Increment PC
                --    wrtBYTCD <= '1'; -- Enable writing
                --    if ldByte = '1' then
                --        enGasLimit <= '1';
                --        rstGas <= '1';
                --        rstPC <= '0';
                --        wrtBYTCD <= '0'; -- Enable writing
                --        next_state <= BRANCH;
                --    else
                --        next_state <= LOAD_BYTCODE_MEM;
                --    end if;
                when BRANCH =>
                    if brokeFlag = '0' then -- If gas is available
                        report "" & to_hstring(outBYTCD8);
                        selOpcode <= '1';
                        enTotGas <= '1';
                        case outBYTCD8 is
                            when x"5F" => -- PUSH0
                                enPC <= "001";
                                we_stack <= '1';
                                push <= '1';
                                next_state <= BRANCH;
                            when x"5A" => -- GAS
                                selSTACK <= remGasPadSel;
                                enPC <= "001"; -- Increment PC
                                we_stack <= '1';
                                push <= '1';
                                next_state <= BRANCH;
                            when x"60" => -- PUSH1
                                enPC <= "001"; -- Increment PC
                                next_state <= PUSH1;
                            when x"50" => -- POP
                                enPC <= "001";
                                pop <= '1';
                                next_state <= BRANCH;
                            when  x"61" | x"62" | x"63" | x"64" | x"65" | x"66" | x"67" | x"68" | x"69" | x"6A" | x"6B" | x"6C" | x"6D" | x"6E" | x"6F" |
                                  x"70" | x"71" | x"72" | x"73" | x"74" | x"75" | x"76" | x"77" | x"78" | x"79" | x"7A" | x"7B" | x"7C" | x"7D" | x"7E" | x"7F" => -- PUSH2 - PUSH32
                                en_holdB  <= '1'; -- Hold 5 LSBs of outBYTCD8 in holdByte
                                enPC <= "001"; -- Increment PC
                                next_state <= PUSH_STATE;
                            when x"80" | x"81" | x"82" | x"83" | x"84" | x"85" | x"86" | x"87" | x"88" | x"89" | x"8A" | x"8B" | x"8C" | x"8D" | x"8E" | x"8F" => -- DUP1 - DUP16
                                en_TopStack <= '1';
                                next_state <= DUP0; -- Read from stack
                            when x"90" | x"91" | x"92" | x"93" | x"94" | x"95" | x"96" | x"97" | x"98" | x"99" | x"9A" | x"9B" | x"9C" | x"9D" | x"9E" | x"9F" => -- SWAP1 - SWAP16
                                -- Pop stack
                                pop <= '1';  -- Pop a
                                en_holdB  <= '1'; -- Hold 5 LSBs of outBYTCD8 in holdByte
                                en_TopStack <= '1';
                                next_state <= SWAP0;
                            when x"01" | x"02" | x"03" | x"04" | x"05" | x"06" | x"07" | x"08" | x"09" | x"10" | x"11" | x"12" | x"13" | x"14" | x"16" | x"17" | x"18" | x"1B" | x"1C" | x"1D" => -- LT, GT, SLT, SGT, EQ, SDIV, MOD, SMOD
                                -- POP a
                                pop <= '1'; -- SHL: shift
                                en_holdB  <= '1'; -- Hold 5 LSBs of outBYTCD8 in holdByte
                                next_state <= OPALU0;
                            when x"15" => -- ISZERO: pop a
                                pop <= '1'; -- Pop a
                                next_state <= ISZERO;
                            when x"19" => -- NOT
                                pop <= '1'; -- Pop a
                                en_holdB  <= '1'; -- Hold 5 LSBs of outBYTCD8 in holdByte
                                next_state <= OPALU1;
                            when x"00" => -- STOP
                                next_state <= STOP_EVM;
                            when x"52" | x"53" | x"37" | x"39" | x"3E" | x"3C" | x"5E" => -- MSTORE, MSTORE8, CALLDATACOPY Pop offset, destOffset, EXTCODECOPY. CODECOPY. MCOPY
                                pop <= '1'; -- CODECOPY, RETURNDATACOPY, MCOPY: DestOffset. MSTORE: offset, MSTORE8: offset. CALLDATACOPY: destOffset
                                if outBYTCD8 = x"3C" then
                                    next_state <= EXTCODECOPY; -- Pop address
                                else
                                    next_state <= MSTORE0;
                                end if;
                            when x"51" => -- MLOAD. Pop offset
                                pop <= '1'; -- Pop offset
                                next_state <= MLOAD0;
                            when x"59" => -- MSIZE. Push activMEM
                                selSTACK <= activMEMSel;
                                enPC <= "001"; -- Increment PC
                                we_stack <= '1';
                                push <= '1';
                                next_state <= BRANCH;
                            when x"55" => -- SSTORE. Pop key
                                pop <= '1'; -- Pop offset
                                next_state <= SSTORE0;
                            when x"54" => -- SLOAD. Pop key
                                pop <= '1'; -- Pop key
                                next_state <= SLOAD0;
                            when x"56" => --JUMP: pop counter
                                pop <= '1'; -- Pop counter
                                next_state <= JUMP01;
                            when x"57" => -- JUMPI: pop count
                                pop <= '1'; -- Pop counter
                                next_state <= JUMPI0;
                            when x"5B" => -- JUMPDEST
                                enPC <= "001"; -- Increment PC
                                next_state <= BRANCH;
                            when x"58" => -- PC
                                enPC <= "001"; -- Increment PC
                                selSTACK <=  out_pcSel;
                                we_stack <= '1';
                                push <= '1';
                                next_state <= BRANCH;
                            when x"30" => -- ADDRESS
                                selSTACK <=  addrCurntSCSel;
                                enPC <= "001"; -- Increment PC
                                we_stack <= '1';
                                push <= '1';
                                next_state <= BRANCH;
                            when x"31" => -- BALANCE: pop addr
                                pop <= '1'; -- Pop addr
                                next_state <= BALANCE;
                            when x"32" | x"33" | x"34" | x"36" | x"38" | x"3A" | x"3D" | x"41" | x"42" | x"43" | x"44" | x"45" | x"46" | x"47" | x"48" | x"3B" | x"3F" => 
                                if outBYTCD8 = x"33" then -- CALLER
                                    selSTACK <=  callerAddrSel;
                                elsif outBYTCD8 = x"34" then -- CALLVALUE
                                    selSTACK <= callValueSel;
                                elsif outBYTCD8 = x"36" then -- CALLDATASIZE
                                    selSTACK <= calDatSizeSel;
                                elsif outBYTCD8 = x"38" then -- CODESIZE
                                    selSTACK <= codeSizeSel;
                                elsif outBYTCD8 = x"3A" then -- GASPRICE
                                    selSTACK <= gasPriceSel;
                                elsif outBYTCD8 = x"3B" then -- EXTCODESIZE
                                    selSTACK <= extCodSizeSel;
                                elsif outBYTCD8 = x"3F" then -- EXTCODEHASH
                                    selSTACK <= extCodHashSel;
                                elsif outBYTCD8 = x"3D" then -- RETURNDATASIZE
                                    selSTACK <= retDatSizeSel;
                                elsif outBYTCD8 = x"41" then -- COINBASE
                                    selSTACK <= coinBasAddrSel;
                                elsif outBYTCD8 = x"42" then -- TIMETAMP
                                    selSTACK <= timestampSel;
                                elsif outBYTCD8 = x"43" then -- NUMBER
                                    selSTACK <= blockNumberSel;
                                elsif outBYTCD8 = x"44" then -- PREVRANDAO
                                    selSTACK <= prevRandaoSel;
                                elsif outBYTCD8 = x"45" then -- GASLIMIT
                                    selSTACK <= gasLimitSel;
                                elsif outBYTCD8 = x"46" then -- CHAINID
                                    selSTACK <= chainIdSel;
                                elsif outBYTCD8 = x"47" then -- SELFBALANCE
                                    selSTACK <= selfBalanceSel;
                                elsif outBYTCD8 = x"48" then -- BASEFEE
                                    selSTACK <= baseFeeSel;
                                else
                                    selSTACK <=  addrEOASel; -- ORIGIN
                                end if;
                                enPC <= "001"; -- Increment PC
                                we_stack <= '1';
                                push <= '1';
                                next_state <= BRANCH; 
                            when x"20" => -- KECCAK256: pop offset
                                pop <= '1';
                                next_state <= KECCAK256_0;
                            when x"1A" => --BYTE: pop byte offset
                                pop <= '1';
                                next_state <= BYTE0;
                            when x"F0" | x"F5" => -- CREATE, CREATE2: pop value
                                pop <= '1';
                                next_state <= CREATE0;
                            when x"F3"| x"FD" => -- RETURN, REVERT: pop offset
                                pop <= '1'; -- RETURN: offset
                                next_state <= RETURN0;
                            when x"35" => -- CALLDATALOAD
                                pop <= '1'; -- Pop i
                                next_state <= CALLDATALOAD0;
                            when x"0A" | x"0B" => -- EXP: pop a. SIGNEXTEND: pop b
                                pop <= '1'; -- Pop a
                                next_state <= EXP0;
                            when x"F1" | x"F4" | x"FA" => -- CALL, DELEGATECALL, STATICCALL
                                pop <= '1'; -- Pop gas
                                next_state <= ST_POPGAS;
                            when x"40" => -- BLOCKHASH
                                pop <= '1'; -- Pop blockNumber
                                next_state <= STATE_BLOCKHASH;
                            when x"A0" | x"A1" | x"A2" | x"A3" | x"A4" =>  -- LOG0
                                pop <= '1'; -- pop offset
                                next_state <= ST_POPARGSSIZE;
                            when others =>
                                next_state <= STOP_EVM;
                        end case;
                    else
                        next_state <= STOP_EVM;
                    end if;
--====================================================================================================================================================
                when STATE_BLOCKHASH =>
                    we_stack <= '1';
                    push <= '1';
                    enPC <= "001"; -- Increment PC
                    if unsigned(stack_out) > 256 then
                        selSTACK <= ZERO256Sel;
                    else
                        selSTACK <= blockHASHSel;
                    end if;
                    next_state <= BRANCH;
                when ST_POPGAS => -- 
                    en_reg0 <= '1'; -- Load reg0 with gas
                    pop <= '1'; -- Pop address
                    next_state <= ST_POPADDR;
                when ST_POPADDR => --
                    en_reg2 <= '1'; -- Load reg2 with address
                    pop <= '1'; -- value
                    if outBYTCD8 = x"F4" OR outBYTCD8 = x"FA" then 
                        next_state <= ST_POPARGSSIZE;
                    else
                        next_state <= ST_POPARGSOFFSET;
                    end if;
                when ST_POPARGSOFFSET => --
                    en_reg1 <= '1'; -- Load reg1 with Value
                    pop <= '1'; -- argsOffset
                    next_state <= ST_POPARGSSIZE;
                when ST_POPARGSSIZE => --
                    en_reg3 <= '1'; -- Load reg3 with argsOffset
                    pop <= '1'; -- argsSize
                    next_state <= LOADCOUNTER1;
                when LOADCOUNTER1 => -- Load read counter
                    rd_cntr <= "11";
                    en_shft <= "10"; -- Reset shift
                    next_state <= ST_COPYMEM;
                when ST_COPYMEM => -- Copy args from MEM
                    start_rd_mem <= '1';
                    en_shft <= "01"; -- Enable shift
                    selByts <= "010"; -- Select bytes to read
                    rd_cntr <= "01";
                    if done_MEMrd = '1' then
                        if outBYTCD8 = x"A0"  then
                            enPC <= "001"; -- Increment PC
                            next_state <= BRANCH; 
                        elsif outBYTCD8 = x"A1" OR outBYTCD8 = x"A2" OR outBYTCD8 = x"A3" OR outBYTCD8 = x"A4" then
                            pop <= '1'; -- Pop topic 1
                            next_state <= ST_POPRETOFFSET;
                        else
                            next_state <= ST_POPRETOFFSET;
                        end if;
                    else
                        next_state <= ST_COPYMEM;
                    end if;
                when ST_POPRETOFFSET => -- Process data copied from MEM. CALL
                    if outBYTCD8 = x"A1" then 
                        en_reg1 <= '1'; -- Load reg1 with topic 1
                        enPC <= "001"; -- Increment PC
                        next_state <= BRANCH; 
                    elsif outBYTCD8 = x"A2" OR outBYTCD8 = x"A3" OR outBYTCD8 = x"A4" then
                        pop <= '1'; -- Pop topic 1
                        next_state <= POP_RETOFFSET;
                    else
                        next_state <= POP_RETOFFSET;
                    end if;
                when POP_RETOFFSET => -- Pop retOffset
                    if outBYTCD8 = x"A2" then
                        en_reg0 <= '1'; -- Load reg0 with topic 2
                        enPC <= "001"; -- Increment PC
                        next_state <= BRANCH;
                    elsif outBYTCD8 = x"A3" OR outBYTCD8 = x"A4" then
                        pop <= '1'; -- Pop topic 3
                        next_state <= POP_RETSIZE;
                    else
                        pop <= '1';
                        next_state <= POP_RETSIZE;
                    end if;
                when POP_RETSIZE => -- Pop retSize
                    if outBYTCD8 = x"A3" then
                        en_reg2 <= '1'; -- Load reg2 with topic 3
                        enPC <= "001"; -- Increment PC
                        next_state <= BRANCH;
                    elsif outBYTCD8 = x"A4" then
                        pop <= '1'; -- Pop topic 4
                        next_state <= LOADCOUNTER0;
                    else
                        pop <= '1'; -- retSize
                        en_reg1 <= '1'; -- Load reg1 with retOffset
                        next_state <= LOADCOUNTER0;
                    end if;
                when LOADCOUNTER0 => -- Load counter0 with retSize
                    if outBYTCD8 = x"A4" then
                        en_reg3 <= '1'; -- Load reg3 with topic 4
                        enPC <= "001"; -- Increment PC
                        next_state <= BRANCH;
                    else
                        wrt_cntr <= "11"; -- Load counter0 with retOffset
                        next_state <= WRITE_MEM;
                    end if;
                when WRITE_MEM => -- Write to MEM
                    start_wrt_mem <= '1';
                    selByts <= "010"; -- Select bytes to write
                    wrt_cntr <= "01";
                    if done_MEMwt = '1' then
                        selSTACK <= ZERO256Sel;
                        we_stack <= '1';
                        push <= '1';
                        enPC <= "001"; -- Increment PC
                        next_state <= BRANCH;
                    else
                        next_state <= WRITE_MEM;
                    end if;
                when DUP0 => 
                    wrt_stack   <= '1';
                    --addr_offset <= std_logic_vector(to_unsigned(to_integer(unsigned(top_stack)) - to_integer(unsigned(outBYTCD8(3 downto 0))) - 1, DUP_OFFSET));
                    selAddrOffset <= "01"; 
                    next_state <= DUP; -- Read from stack
                when EXP0 => -- Pop exponential, load a to reg1. SIGNEXTEND pop x, load b to reg1
                    pop <= '1';
                    en_reg1 <= '1'; -- Load reg1 with a
                    if outBYTCD8 = x"0B" then -- SIGNEXTEND
                        next_state <= SIGNEXTEND;
                    else
                        next_state <= EXP1;
                    end if;
                when SIGNEXTEND => -- Load regALU  
                    selRegALU <= "100"; -- SIGNEXTEND
                    enRegALU <= '1'; -- Enable regALU 
                    next_state <= PUSH_ALU;
                when EXP1 => -- Run exponential
                   startEXP <= '1'; -- Start exponential
                   rstEXP <= '1';
                   if doneEXP = '1' then -- Push to stack
                        selRegALU <= "010";
                        enRegALU <= '1'; -- Enable regALU
                        next_state <= PUSH_ALU;
                   else
                       next_state <= EXP1;
                   end if;
                when CALLDATALOAD0 => 
                    enCallD <= '1';
                    rstCallD <= '1';
                    next_state <= CALLDATALOAD1;
                when CALLDATALOAD1 => -- Push to stack
                    selSTACK <= callDataOutSel;
                    we_stack <= '1';
                    push <= '1';
                    enPC <= "001"; -- Increment PC
                    next_state <= BRANCH;
                when ISZERO => -- ISZERO, Load regALU with result
                    opALU <= "001000"; -- ISZERO
                    enRegALU <= '1'; -- Enable regALU
                    next_state <= PUSH_ALU;
                when RETURN0 => -- pop size, load reg3 with offset, make reg0 0
                    pop <= '1'; -- RETURN: size
                    en_reg3 <= '1'; -- RETURN: offset
                    --sel_reg0 <= '1'; -- Make reg0 0
                    --en_reg0 <= '1';
                    en_shft <= "10"; -- Reset shift
                    next_state <= RETURN1;
                when RETURN1 => -- load COUNTER1 in EVM_MEMORY with rdOffset
                    rd_cntr <= "11"; -- Load counter1 with rdOffset
                    next_state <= RETURN2;
                when RETURN2 => -- Start reading, but dont enable shift yet
                    selByts <= "010"; -- Select bytes to read
                    start_rd_mem <= '1';
                    rd_cntr <= "01";
                    sel_retValCntr <= "10";
                    next_state <= RETURN3;
                when RETURN3 => -- Keep reading, enable shift
                    start_rd_mem <= '1';
                    rd_cntr <= "01";
                    selByts <= "010";
                    en_shft <= "01"; -- Enable shift
                    weRv <= '1';
                    sel_retValCntr <= "01";
                    if done_MEMrd = '1' then
                        --enPC <= "001"; -- Increment PC
                        next_state <= STOP_EVM;
                        --en_shft <= "00"; -- No more shifting
                    else
                        next_state <= RETURN3;
                    end if;
                when CREATE0 => -- Pop offset, load value to reg1
                    pop <= '1';
                    en_reg1 <= '1';
                    next_state <= KECCAK256_0;
                when BYTE0 => -- Pop x, load reg3 with byte offset
                    pop <= '1';
                    en_reg3 <= '1';
                    next_state <= BYTE1;
                when BYTE1 => -- Push byte to stack
                    selSTACK <= oneByteSel;
                    we_stack <= '1';
                    push <= '1';
                    enPC <= "001"; -- Increment PC
                    next_state <= BRANCH;
                when KECCAK256_0 => -- pop size, load reg3 with offset, make reg0 0
                    pop <= '1';
                    en_reg3 <= '1';
                    sel_reg0 <= '1';
                    en_reg0 <= '1';
                    next_state <= KECCAK256_1;
                when KECCAK256_1 => -- load COUNTER1 in EVM_MEMORY with rdOffset
                    selByts <= "010"; -- Select bytes to read 
                    rd_cntr <= "11";
                    next_state <= KECCAK256_2;
                when KECCAK256_2 => -- Start reading, but dont enable shift yet so that you can shift in starting from correct offset
                    selByts <= "010"; -- Select bytes to read
                    start_rd_mem <= '1';
                    rd_cntr <= "01";
                    en_shft <= "10"; -- Reset shift
                    next_state <= KECCAK256_3;
                when KECCAK256_3 => -- Read all bytes from memory, enable shift
                    start_rd_mem <= '1';
                    rd_cntr <= "01";
                    selByts <= "010";
                    en_shft <= "01"; -- Enable shift
                    rstKecc  <= '0';
                    if done_MEMrd = '1' then 
                        next_state <= KECCAK256_4;
                        --en_shft <= "00"; -- No more shifting
                    else
                        next_state <= KECCAK256_3;
                    end if;
                when KECCAK256_4 => -- Start keccak256. CREATE2: First time running keccak256
                    selByts <= "010"; -- Get bytes from stack
                    startKecc <= '1'; -- Start keccak256
                    if outBYTCD8 = x"F0" then -- If CREATE
                        selRpl <= "01"; -- Hash rpl_digest
                        selByts <= "011"; -- Hash 23 bytes
                    end if;
                    if doneKecc = '1' then -- Done reading, push to stack
                        if outBYTCD8 = x"F5" then -- If CREATE2: save kecc digest, pop salt,
                            en_reg4 <= '1'; -- Load reg4 with kecc digest
                            pop <= '1'; -- Pop salt
                            --rstKecc <= '0'; -- Reset keccak256
                            next_state <= RESETKECC;
                        else
                            selSTACK <= outKeccSel;
                            we_stack <= '1';
                            push <= '1';
                            enPC <= "001"; -- Increment PC
                            if outBYTCD8 = x"F0" then -- If CREATE
                                selSTACK <= ethAddrSel; -- Push ETH address to stack
                            end if;
                            next_state <= BRANCH;
                        end if;
                    else
                        next_state <= KECCAK256_4;
                    end if;
                when RESETKECC => -- RESET KECCAK
                    rstKecc <= '0';
                    next_state <= CREATE2;
                when CREATE2 => -- Second time running keccak256
                    selRpl <= "10"; -- Hash reg4Pad
                    selByts <= "100"; -- Hash 85 bytes
                    startKecc <= '1'; -- Start keccak256
                    if doneKecc = '1' then -- Done reading, push to stack
                        selSTACK <= ethAddrSel; -- Push ETH address to stack
                        we_stack <= '1'; -- Enable write to stack
                        push <= '1'; -- Push to stack
                        enPC <= "001"; -- Increment PC
                        next_state <= BRANCH;
                    else
                        next_state <= CREATE2;
                    end if;
                when BALANCE => -- Push ballance
                    selSTACK <=  addrBalSel;
                    enPC <= "001"; -- Increment PC
                    we_stack <= '1';
                    push <= '1';
                    next_state <= BRANCH;
                when JUMPI0 => -- pop b, Push counter to PC, store prev pc
                    pop <= '1'; -- Pop b
                    --enPC <= "010";
                    en_reg1 <= '1'; -- Save counter in reg1
                    --en_savPC <= '1';
                    next_state <= JUMPI1;
                when JUMPI1 => -- Dont jump if b is 0
                    if unsigned(stack_out) = 0 then
                        enPC <= "001"; -- Increment PC
                        next_state <= BRANCH;
                    else
                        enPC <= "010";
                        next_state <= STATE_JUMP;
                    end if;
                when STATE_JUMP =>
                    sigJump <= '1';
                    if doneBTCDjump = '1' then
                        if outBYTCD8 = x"5B" then -- If we jump
                            enPC <= "001"; -- Increment PC
                            next_state <= BRANCH;
                        else
                            next_state <= STOP_EVM;
                        end if;
                    else
                        next_state <= STATE_JUMP;
                    end if;
                when JUMP01 =>
                    en_reg1 <= '1';
                    next_state <= JUMP0;
                when JUMP0 => -- Push counter to PC
                    enPC <= "010";
                    next_state <= STATE_JUMP;
                --when JUMP1 => -- See if JUMPDEST, else STOP
                --    if outBYTCD8 = x"5B" then
                --        enPC <= "001"; -- Increment PC
                --        next_state <= BRANCH;
                --    else
                --        next_state <= STOP_EVM;
                --    end if;
                when SLOAD0 => -- Read Storage
                    selStorage <= '1';
                    next_state <= SLOAD1;
                when SLOAD1 => -- Push value_out to stack
                    we_stack <= '1';
                    push <= '1';
                    selSTACK <= value_outSel;
                    enPC <= "001"; -- Increment PC
                    next_state <= BRANCH;
                when SSTORE0 => -- Pop value, load reg3 with key
                    pop <= '1'; -- Pop value
                    en_reg3 <= '1';
                    if unsigned(stack_out) > 1024 then
                        enPC <= "001"; -- Increment PC
                        next_state <= BRANCH;
                    else
                        next_state <= SSTORE1;
                    end if;
                when SSTORE1 => -- Push to storage
                    enStorage <= '1';
                    selStrg <= '0';
                    enPC <= "001"; -- Increment PC
                    next_state <= BRANCH;
                when MLOAD0 => -- Load offset to reg3, Make reg0 0
                    en_reg3 <= '1'; 
                    sel_reg0 <= '1';
                    en_reg0 <= '1';
                    next_state <= MLOAD1;
                when MLOAD1 => -- Load counter1 with offset
                    rd_cntr <= "11";
                    en_shft <= "10"; -- Reset shift
                    next_state <= MLOAD12;
                when MLOAD12 => -- Start reading, but dont enable shift yet
                    rd_cntr <= "01";
                    en_shft <= "10"; -- Reset shift
                    next_state <= MLOAD2;
                when MLOAD2 =>  -- Keep reading, enable shift
                    start_rd_mem <= '1';
                    rd_cntr <= "01";
                    en_shft <= "01"; -- Enable shift
                    if done_MEMrd = '1' then -- Done reading
                        next_state <= MLOAD3;
                    else
                        next_state <= MLOAD2;
                    end if;
                when MLOAD3 => -- Push to stack
                    selSTACK <= outShiftRegSel;
                    we_stack <= '1';
                    push <= '1';
                    enPC <= "001"; -- Increment PC
                    next_state <= BRANCH;
                when EXTCODECOPY => -- Prepare to Pop destOffset and load reg2 with address
                    en_reg2 <= '1'; -- Enable reg2
                    pop <= '1'; -- Pop offset
                    next_state <= MSTORE0;
                when MSTORE0 => -- Pop value, load reg1 with offset, pop offset, (CALLDATACOPY: load reg1 destOffset, prep pop offset) CODECOPY
                    pop <= '1'; -- MSTORE: value. CODECOPY, RETURNDATACOPY, MCOPY: offset. MSTORE8: value. CALLDATACOPY: offset
                    en_reg1 <= '1'; -- MSTORE, RETURNDATACOPY: offset. CODECOPY: destOffset, MSTORE8: offset. CALLDATACOPY: destOffset
                    if outBYTCD8 = x"37" OR outBYTCD8 = x"39" OR outBYTCD8 = x"5E" OR outBYTCD8 = x"3E" OR outBYTCD8 = x"3C"   then
                        next_state <= CALDATACOPY0; -- Pop size
                    else
                        next_state <= MSTORE01;
                    end if;
                when MSTORE01 =>  -- Load offset to counter
                    wrt_cntr <= "11"; -- Load write counter with offset
                    if outBYTCD8 = x"53" then -- MSTORE
                        next_state <= MSTORE8;
                    else
                        enMEM_cpy <= '1'; -- shift in 8 LSB of MEM_in
                        --sel_mem <= "010"; -- Flip
                        next_state <= MSTORE1;
                    end if;
                when MSTORE8 => -- MSTORE8
                    selByts <= "001"; -- Store 1 bytes, MSTORE8
                    --wrt_cntr <= "01"; -- Increment write MEM counter
                    mem_wrt <= '1'; -- Write to memory
                    enPC <= "001"; -- Increment PC
                    next_state <= BRANCH; 
                when CALDATACOPY0 => -- Prepare to Pop size and load offset to reg0
                    pop <= '1'; -- CODECOPY, RETURNDATACOPY, MCOPY: size. CALLDATACOPY: size. CODECOPY: offset
                    wrt_cntr <= "11"; -- Load write counter with offset
                    if outBYTCD8 = x"5E" then -- MCOPY
                        en_reg3 <= '1'; -- Load rdOfset to reg3
                        next_state <= MCOPY0;
                    elsif outBYTCD8 = x"39" then
                        en_reg0 <= '1'; -- CODECOPY: offset
                        next_state <= CODECOPY0;
                    elsif outBYTCD8 = x"37" then --CALLDATACOPY
                        cntlCntr0 <= "11"; -- Load counter with offset
                        next_state <= CALDATACOPY_1;
                    else
                        en_reg0 <= '1'; -- CODECOPY: offset.
                        next_state <= CALDATACOPY1;
                    end if;
                when CALDATACOPY_1 => -- destOffset, offset, size available
                    selByts <= "010";
                    start_wrt_mem <= '1';
                    wrt_cntr <= "01"; -- Increment write MEM counter
                    cntlCntr0 <= "01"; -- Increment counter
                    sel_mem <= "011"; -- callDataCopy
                    mem_wrt <= '1'; -- Write to memory
                    if done_MEMwt = '1' then
                        enPC <= "001"; -- Increment PC
                        next_state <= BRANCH;
                    else
                        next_state <= CALDATACOPY_1;
                    end if; 
                when MCOPY0 => -- destOffset, offset, size, available. Copy first byte from memory
                    start_rd_mem <= '1';
                    sel_reg0 <= '1'; -- Reset reg0
                    rd_cntr <= "11";
                    --wrt_cntr <= "01";
                    next_state <= MCOPY01;
                when MCOPY01 => -- Load counter 1 with reg3
                    rd_cntr <= "01"; -- Increment read MEM counter
                    next_state <= MCOPY1;
                when MCOPY1 => -- First byte in outMem. Write to memory and read next byte
                    --en_shft <= '1';
                    wrt_cntr <= "01"; -- Increment write MEM write counter
                    rd_cntr <= "01"; -- Increment read MEM counter
                    sel_reg0 <= '1'; -- Reset reg0
                    sel_mem <= "111"; -- outMem
                    --enMEM_cpy <= '1'; -- Write only from 8 LSB of MEM_in
                    start_wrt_mem <= '1'; -- Write to memory
                    mem_wrt <= '1'; -- Write to memory
                    start_rd_mem <= '1'; -- Read from memory
                    if done_MEMrd = '1' then -- Done reading
                        enPC <= "001"; -- Increment PC
                        next_state <= BRANCH;
                    else
                        next_state <= MCOPY1;
                    end if;
                when CODECOPY0 => -- CODECOPY: load offset to counter
                    --pop <= '1'; -- Pop size
                    enCntr2PC <= "010"; -- Load counter to PC
                    start_wrt_mem <= '1';
                    next_state <= CALDATACOPY1;
                when CALDATACOPY1 => -- destOffset, offset, size, available
                    start_wrt_mem <= '1';
                    mem_wrt <= '1'; -- Write to memory
                    selByts <= "010"; -- Store size bytes, MSTORE8
                    if outBYTCD8 = x"39" then
                        sel_mem <= "100"; -- CODECOPY
                        wrt_cntr <= "01"; -- increment write MEM counter
                        enCntr2PC <= "001"; -- Increment PC
                    elsif outBYTCD8 = x"3E" then
                        wrt_cntr <= "01"; -- Increment write MEM counter
                        sel_mem <= "101"; -- returnData
                    elsif outBYTCD8 = x"3C" then
                        wrt_cntr <= "01"; -- Increment write MEM counter
                        sel_mem <= "110"; -- extcodcpyAddr
                    else
                        sel_mem <= "011"; -- callDataCopy
                    end if;

                    if done_MEMwt = '1' then
                        enCntr2PC <= "011" ; -- Reset counter
                        enPC <= "001"; -- Increment PC
                        next_state <= BRANCH;
                    else
                        next_state <= CALDATACOPY1;
                    end if;  
                when MSTORE1 => -- Load MEM
                    start_wrt_mem <= '1';
                    mem_wrt <= '1'; -- Write to memory
                    wrt_cntr <= "01"; -- Increment write MEM counter
                    enMEM_cpy <= '1'; -- shift in 8 LSB of MEM_in
                    selShftCntr <= "01"; -- Increment counter
                    --sel_mem <= "010"; -- Flip
                    if done_MEMwt = '1' then
                        selShftCntr <= "10"; -- Reset counter
                        enPC <= "001"; -- Increment PC
                        wrt_cntr <= "00"; -- Reset counter
                        next_state <= BRANCH;
                    else
                        next_state <= MSTORE1;
                    end if;                   
                when OPALU0 => -- Load a to reg0, pop b
                    en_reg0 <= '1'; -- SHL: shift
                    pop <= '1'; -- SHL: value
                    if holdByte = x"02" OR holdByte = x"09" then -- MUL, MULMOD
                        next_state <= MUL_STATE;
                    elsif holdByte = x"04" OR holdByte = x"06" then -- DIV
                        next_state <= DIV_STATE;
                    else
                        next_state <= OPALU1;
                    end if;
                when DIV_STATE => -- Division
                    startDiv <= '1';
                    rstDiv <= '1';
                    if holdByte = x"08" OR holdByte = x"09" then
                        selNum <= '1'; -- Load numerator
                    end if;
                    if readyDiv = '1' OR divBy224 = '1' then
                        if holdByte = x"06" OR holdByte = x"08" OR holdByte = x"09" then
                            selRegALU <= "101"; -- Load regALU with remainder
                        else
                            selRegALU <= "011"; -- Load regALU with result
                        end if;
                        if divBy224 = '1' then
                            selDiv <= '1';
                        end if;
                        enRegALU <= '1'; -- Enable regALU
                        next_state <= PUSH_ALU;
                    else
                        next_state <= DIV_STATE;
                    end if;
                when MUL_STATE =>
                    startSAM <= '1'; -- Start SAM
                    rstSAM <= '1';
                    if doneSAM = '1' then
                        selRegALU <= "001"; -- Load regALU with result
                        enRegALU <= '1'; -- Enable regALU
                        if holdByte = x"09" then
                            next_state <= DIV_STATE;
                        else
                            next_state <= PUSH_ALU;
                        end if;
                    else
                        next_state <= MUL_STATE;
                    end if;
                when OPALU1 => -- a and b through ALU, load regALU with result
                    enRegALU <= '1'; -- Enable regALU
                    case holdByte is
                        when x"12" => -- SLT
                            opALU <= "000001"; -- SLT
                        when x"13" => -- SGT
                            opALU <= "001001"; -- SGT
                        when x"10" => -- LT
                            opALU <= "010001"; -- LT
                        when x"11" => -- GT
                            opALU <= "011001"; -- GT
                        when x"14" => -- EQ
                            opALU <= "100001"; --  EQ
                        when x"01" => -- ADD
                            opALU <= "000000"; 
                        when x"03" => -- SUB
                            opALU <= "010000"; 
                        --when x"02" => -- MUL
                        --  opALU <= "100000"; 
                        when x"16" => -- AND
                            opALU <= "000010";
                        when x"17" => -- OR
                            opALU <= "001010"; 
                        when x"18" => -- XOR
                            opALU <= "010010"; 
                        when x"19" => -- NOT
                            opALU <= "011010"; 
                        when x"1B" => -- SHL
                            opALU <= "000011";   -- op & op0
                        when x"1C" => -- SHR
                            opALU <= "001011"; 
                        when others => -- 1D SAR
                            opALU <= "010011";
                    end case;
                    if holdByte = x"08" then
                        pop <= '1'; -- Pop N
                        opALU <= "000000";
                        next_state <= DIV_STATE;
                    else
                        next_state <= PUSH_ALU;
                    end if ;
                when PUSH_ALU => -- Push regALU to stack
                    selSTACK <= regALUSel;
                    push <= '1'; -- Push result to stack
                    we_stack <= '1';
                    enPC <= "001"; -- Increment PC
                    next_state <= BRANCH;
                when SWAP0 => -- Put POP in reg0, go to offset address and read value from stack
                    en_reg0 <= '1'; -- Load a
                    --addr_offset <= std_logic_vector(unsigned(top_stack) - unsigned(holdByte(3 downto 0)) - 1);
                    selAddrOffset <= "11";
                    wrt_stack   <= '1'; -- Write to stack a specific address
                    next_state <= SWAP1;
                when SWAP1 => -- PUSH stack_out to stack
                    selAddrOffset <= "11";
                    we_stack <= '1';
                    push <= '1';
                    selSTACK <= stack_outSel;
                    next_state <= SWAP2;
                when SWAP2 => -- Replace value in offset stack addr with reg0
                    enPC <= "001"; -- Increment PC
                    we_stack <= '1';
                    selSTACK <= reg0Sel;
                    --addr_offset <= std_logic_vector(unsigned(top_stack) - unsigned(holdByte(3 downto 0)) - 2);
                    selAddrOffset <= "01";
                    wrt_stack   <= '1';
                    next_state <= BRANCH;
                when DUP => -- Load reg0 with the value from the stack
                    selSTACK <= stack_outSel;
                    selAddrOffset <= "01";
                    we_stack <= '1';
                    push <= '1'; -- push the value back to the stack
                    enPC <= "001"; -- Increment PC
                    next_state <= BRANCH;                
                when PUSH1 =>
                    enPC <= "001"; -- Increment PC
                    we_stack <= '1';
                    push <= '1';
                    selSTACK <= padBytesSel;
                    next_state <= BRANCH;
                when PUSH_STATE => -- PUSH2 - PUSH32
                    enPC <= "001"; -- Increment PC
                    rstAccm <= '1'; -- Unreset accumulator
                    enAccm  <= '1'; -- Accumulate the bytes
                    rstCntr <= '1'; -- Unreset counter
                    enCntr  <= '1'; -- Enable counter
                    if unsigned(cntr_out) =  resize(unsigned(holdByte(4 downto 0)), cntr_out'length) + 1 then
                        enPC <= "000"; -- Hold PC
                        we_stack <= '1';
                        push <= '1';
                        selSTACK <= accmBytesSel;
                        next_state <= BRANCH;
                    else
                        next_state <= PUSH_STATE;
                    end if;
                when STOP_EVM =>
                    doneEVM <= '1';
                    if rst = '1' then
                        next_state <= STOP_EVM;
                    else
                        next_state <= IDLE;
                    end if;    
                when others =>
                    next_state <= IDLE;
                end case;
        end process;

end architecture;