-- SPDX-License-Identifier: CERN-OHL-W-2.0
--
-- This source describes Open Hardware and is licensed under the CERN-OHL-W v2.
-- 
-- You may redistribute and modify this source and make products using it under
-- the terms of the CERN-OHL-W v2 (Weakly Reciprocal).
--
-- You should have received a copy of the CERN-OHL-W v2 license with this source.
-- If not, see: https://cern-ohl.web.cern.ch/
--
-- The Documentation and source code for this project are available at:
-- https://github.com/JPL24hub/EVMx
--
-- COPYRIGHT (C) 2025 Joel Poncha Lemayian
----------------------------------------------------------------------
-- FILE:        EVM.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 21/06/2024 - File created. 
--              1.1 - 28/05/2025 - Added Booth Multiplier.
--              1.2 - 30/05/2025 - Reduced number of inputs to match ZCU104
-- DESCRIPTION: Booth Multiplier implementation. It handles A=1, B=1, A=0, B=0, A=1, B=0, A=0, B=1.
-- COMMENTS: Working as expected. I need to add division by 2^x
--------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.PKG_EVM.all;
use work.PKG_KECCAK.all;

entity EVM is
    generic(
        WIDTH_256 : integer := 256;
        WIDTH_CALLDATA : integer := 1024;
        ETH_ADDR_SIZE  : natural := 160;
        ETH_NONCE_SIZE  : natural := 8;
        GAS_WIDTH : natural := 25;
        BYTCD_LEN : natural := 1024
    );
    port(
        clk             : in std_logic;
        rst             : in std_logic;
        startEVM        : in std_logic;
        --ldByte          : in std_logic;
        loadBytecode    : in std_logic;
        BytecodeLoaded  : in std_logic;
        toBYTCD         : in std_logic_vector(BYTCD_LEN - 1 downto 0); -- Input data for BYTECODE_MEM
        callData        : in std_logic_vector(WIDTH_CALLDATA - 1 downto 0); -- External data sent along with a transaction

        
        callDataLen     : in std_logic_vector(WIDTH_256 - 1 downto 0);
        returnData      : in std_logic_vector(WIDTH_256 - 1 downto 0); -- Data returned from the SC execution (RETURNDATACOPY)
        byteCode        : in std_logic_vector(WIDTH_256 - 1 downto 0); -- Bytecode of another SC used when executing EXTCODECOPY
        addrEOA         : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The address of the original sender of the transaction, from EOA (ORIGIN)
        addrCurntSC     : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The addr of the currently executing SC (ADDRESS)
        callerAddr      : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The address of the immediate sender of the current message call (CALLER)
        callValue       : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The amount of Ether (ETH) sent with the current call or transaction (CALLVALUE)
        codeSize        : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The contract’s deployed bytecode (in bytes) (CODESIZE)
        gasPrice        : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The gas price (in wei per gas unit) of the transaction that triggered the execution. (GASPRICE)
        retDatSize      : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The size of the data returned by the previous call, e.g,STATICCALL (RETURNDATASIZE)
        coinBasAddr     : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The address of the block miner, i.e., the address of the account that mined the current block. (COINBASE)
        timestamp       : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The block timestamp, which is the Unix timestamp (i.e., the number of seconds since January 1, 1970) at the time the block was mined.(TIMETAMP)
        blockNumber     : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The block number of the current block (NUMBER)
        prevRandao      : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The randomness from the previous block's blockhash (PREVRANDAO)
        gasLimit        : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The gas limit of the current block (GASLIMIT)
        chainId         : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The chain ID of the current Ethereum network. A unique identifier that distinguishes between different Ethereum networks (mainnet, testnets, etc.) (CHAINID)
        selfBalance     : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The amount of Ether held by the contract at the time of execution. (SELFBALANCE)
        baseFee         : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The minimum amount of gas required for a transaction to be included in the block (BASEFEE)
        addrBal         : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The ballance of SC in popedaddress (BLANCE)
        extCodSize      : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The size of the code of the SC at the address in popedaddress (EXTCODESIZE)
        extCodHash      : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The hash of the code of the SC at the address in popedaddress (EXTCODEHASH)
        blockHASH       : in std_logic_vector(WIDTH_256 - 1 downto 0); -- The hash of the block (BLOCKHASH)
        sender_address  : in std_logic_vector(ETH_ADDR_SIZE-1 downto 0);
        sender_nonce    : in std_logic_vector(ETH_NONCE_SIZE-1 downto 0);
        bramWords       : in unsigned(ETH_NONCE_SIZE - 1 downto 0);



        popedaddress    : out std_logic_vector(WIDTH_256 - 1 downto 0); -- The addr to a SC poped from stack (BLANCE)
        scValue         : out std_logic_vector(WIDTH_256 - 1 downto 0); -- SC value (CREATE)(CALL)
        doneEVM         : out std_logic;
        retRevData      : out std_logic_vector(4*WIDTH_256 - 1 downto 0); -- The output after RETURN or REVERT is executed
        returnValue     : out std_logic_vector(ETH_NONCE_SIZE - 1 downto 0); -- The return value from the SC execution (RETURN)
        extcodcpyAddr   : out std_logic_vector(WIDTH_256 - 1 downto 0) := (others=>'0'); -- (CALL): address
        total_Gas       : out std_logic_vector(GAS_WIDTH - 1 downto 0) -- Total used gas

    --=================================================================
        --numDivO    : out std_logic_vector(WIDTH_256-1 downto 0);
        --denDivO    : out std_logic_vector(WIDTH_256-1 downto 0);
        --startDivO  : out std_logic;
        --readyDivO  : out std_logic;
        --quoDivO    : out std_logic_vector(WIDTH_256-1 downto 0)
        );
end entity;
architecture rtl of EVM is
    -- Constants
    constant WDTH_enPC          : integer := 2;
    constant DEPTH_STACK        : integer := 1024;
    constant WIDTH_STACK        : integer := 256;
    constant DUP_OFFSET         : integer := 10;
    constant WIDTH_8            : integer := 8;
    constant KEC_PAD_WIDTH      : natural := 1600;
    constant KEC_SIZE           : natural := 7;
    constant WIDTH_PC           : integer := 15;
    constant CALLDATCPY_CNTR    : integer := 10; -- Counter width for CALLDATACOPY
    constant ZERO248            : std_logic_vector(247 downto 0) := (others=>'0');
    constant ZERO256            : std_logic_vector(255 downto 0) := (others=>'0');
    constant WIDTH_CNTL1        : integer := 44;
    constant WIDTH_CNTR         : integer := 6;
    constant WIDTH_opALU        : integer := 6;
    constant DEPTH_MEM          : integer := 32768; -- So that we can have same size as the stack
    constant WIDTH_SEL_MEM      : integer := 3;
    constant WIDTH_SELBYTS      : integer := 3;
    constant WIDTH_MEMORY_ADDR  : integer := 256;
    constant WIDTH_CNTR_MEM     : integer := 256;
    constant SIZE_COPY          : integer := 256;
    constant BYTS32             : std_logic_vector(SIZE_COPY - 1 downto 0) := std_logic_vector(to_unsigned(32, SIZE_COPY));
    constant BYTS1              : std_logic_vector(SIZE_COPY - 1 downto 0) := std_logic_vector(to_unsigned(1, SIZE_COPY));
    constant BYTS23             : std_logic_vector(SIZE_COPY - 1 downto 0) := std_logic_vector(to_unsigned(23, SIZE_COPY));
    constant BYTS85             : std_logic_vector(SIZE_COPY - 1 downto 0) := std_logic_vector(to_unsigned(85, SIZE_COPY));
    constant STORAGE_DEPTH      : integer := 1024;
    constant PAD_OUTPC          : std_logic_vector(WIDTH_STACK - WIDTH_PC - 1 downto 0) := (others=>'0');
    constant T                  : sha3_type := sha256;
    constant RPL_WIDTH          : integer := 184;
    constant REG4_PAD           : integer := 344;
    constant SFT_DIV            : integer := 224 ; -- For division by 0x0100000000000000000000000000000000000000000000000000000000000000
    constant DIV_ZEROS          : std_logic_vector(SFT_DIV - 1 downto 0) := (others=>'0');
    constant CONST_DIVIDER           : std_logic_vector(WIDTH_STACK - 1 downto 0) := (224=>'1',others=>'0');
    --=========================================================
    constant WIDTH_EXP          : integer := 256;
    constant WIDTH_DIV          : integer := 256;
    constant WIDTH_MULT         : integer := 256;
    --======================================================
    constant GAS_ZEROS          : std_logic_vector(WIDTH_STACK - GAS_WIDTH - 1 downto 0) := (others=>'0');
    constant BYTCD_IN_WIDTH     : std_logic_vector(WIDTH_PC - 1 downto 0) := std_logic_vector(to_unsigned(BYTCD_LEN/8, WIDTH_PC));
    constant WIDTH_BUFF         : integer := 128;
    constant WIDTH_BUFPC        : integer := 7;

    -- Signals
    signal selSTACK     : SELECT_STACK := padBytesSel;
    signal cntl_sigs1   : std_logic_vector(WIDTH_CNTL1 - 1 downto 0);
    signal cntr_out     : std_logic_vector(WIDTH_CNTR - 1 downto 0);
    signal opALU        : std_logic_vector(WIDTH_opALU - 1 downto 0);
    signal activMEM     : std_logic_vector(WIDTH_MEMORY_ADDR-1 downto 0) := (others=>'0');
    signal bytes2MEM    : std_logic_vector(SIZE_COPY-1 downto 0) := (others=>'0'); -- How many bytes to write OR READ
    signal selByts      : std_logic_vector(WIDTH_SELBYTS - 1 downto 0);
    signal kecPadOut    : std_logic_vector(KEC_PAD_WIDTH - 1 downto 0);
    signal mode         : sha3_mode := init;
    signal rpl_digest   : std_logic_vector(DEPTH_STACK - 1 downto 0) := (others=>'0');
    signal pad_in       : std_logic_vector(DEPTH_STACK - 1 downto 0) := (others=>'0');
    signal padReg4      : std_logic_vector(REG4_PAD - 1 downto 0) := (others=>'0');
    signal zeroEXP      : std_logic_vector(WIDTH_STACK - WIDTH_EXP - 1 downto 0) := (others=>'0');
    signal zeroDiv      : std_logic_vector(WIDTH_STACK - WIDTH_DIV - 1 downto 0) := (others=>'0');
    signal zeroMULT     : std_logic_vector(WIDTH_STACK - 2*WIDTH_MULT-1 downto 0) := (others=>'0');
    signal multOut      : std_logic_vector(2*WIDTH_MULT - 1 downto 0) := (others=>'0');
    signal multA, multB : std_logic_vector(WIDTH_MULT - 1 downto 0) := (others=>'0');
    signal remGas       : std_logic_vector(GAS_WIDTH - 1 downto 0) := (others=>'0');
    signal remGasPad    : std_logic_vector(WIDTH_STACK - 1 downto 0) := (others=>'0');
    signal outBYTCD8, outMem, bytOutPC  : std_logic_vector(WIDTH_8 - 1 downto 0);
    signal en_shft, selRpl, selShftCntr, wrt_cntr, rd_cntr, cntlCntr0, sel_retValCntr : std_logic_vector(WDTH_enPC - 1 downto 0);
    signal we_stack, push, pop, wrt_stack, enAccm, rstCntr, enCntr, en_reg0, en_reg1, rstAccm, enRegALU, start_wrt_mem, 
           rstMemAcc, done_MEMwt, done_MEMrd, start_rd_mem, en_reg2, en_reg3, sel_reg0, enMEM_cpy, enStorage, 
           selStorage, selStrg, startKecc, doneKecc, rstKecc, en_reg4, mem_wrt, enCallD, rstCallD, rstEXP, startEXP, doneEXP,
           doneSAM, startSAM, rstSAM, weRv, startDiv, rstDiv, readyDiv, brokeFlag, enGasLimit, rstGas, enTotGas, selOpcode, selNum, rstPC, wrtbytcd, 
           readBUFF, loadNextBytecode, ldNxtByt, jump, doneBTCDjump, EVMready, selDiv, divBy224 : std_logic;
    signal data_in, padBytes, accmBytes, reg0, reg0_nxt, reg1, reg1_nxt, stack_out, alu_out, regALU, regALU_nxt, regALUin, product,
           MEM_in, outMemPad, outFLIP, reg2, reg2_nxt, reg3, reg3_nxt, toReg0, value_out, storeKey, key, shftReg256, outKecc, sftDiv, outDiv,
           ethAddr, oneByte, PADout_pc, reg4_nxt, reg4, PadBytOutPC, callDataOut, outCallData, powerEXP, remainder, quotient, sigExtend, 
           calDatSize : std_logic_vector(WIDTH_STACK - 1 downto 0);
    signal pc_inA, pc_inA2, out_pc, cnt2PC : std_logic_vector(WIDTH_PC - 1 downto 0);
    signal outShiftRegNext, outShiftReg, reg4Pad : std_logic_vector(DEPTH_STACK - 1 downto 0) := (others=>'0');
    signal addr_offset, top_stack : std_logic_vector(DUP_OFFSET - 1 downto 0) := (others=>'0');
    signal sel_mem, selRegALU, enPC, enCntr2PC : std_logic_vector(WIDTH_SEL_MEM - 1 downto 0);
    --signal returnedData : std_logic_vector(2*WIDTH_256 - 1 downto 0) := (others=>'0'); -- To be deleated
    signal exponent, expA, power : std_logic_vector(WIDTH_EXP - 1 downto 0) := (others=>'0');
    signal retValCntr, retValCntr_nxt : unsigned(WIDTH_CNTR_MEM - 1 downto 0) := (others=>'0');
    signal numDiv, denDiv, remDiv, quoDiv : std_logic_vector(WIDTH_DIV - 1 downto 0) := (others=>'0');
    signal bytInt       : integer := to_integer(unsigned(reg3(WIDTH_8 - 4 downto 0)));
    signal out_pcBUFF, cnt2PCBUFF : std_logic_vector(WIDTH_BUFPC - 1 downto 0);
    signal jumpToAddr : integer := 0;
    signal savPC : std_logic_vector(WIDTH_PC - 1 downto 0) := (others=>'0');
    signal counterBout  : unsigned(WIDTH_8 - 1 downto 0);


begin

    --returnedData <= outShiftReg(2*WIDTH_256 - 1 downto 0);
    retRevData <= outShiftReg; -- Output when REVERT or RETURN is executed
    -- RPL
    rpl_digest(RPL_WIDTH-1 downto 0) <= x"d6" & x"94" & sender_address & sender_nonce;
    scValue <= reg1; -- Load SC value when processing CREATE

    --data_out <= outShiftReg; 
    extcodcpyAddr <= reg2;

    -- Registers
    PROC_REGS : process(clk) is
        begin
            if rising_edge(clk) then
                if rst = '0' then
                    reg0 <= (others=>'0');
                    reg0 <= (others=>'0');
                    reg1 <= (others=>'0');
                    regALU <= (others=>'0');
                    outShiftReg <= (others=>'0');
                    reg2 <= (others=>'0');
                    reg3 <= (others=>'0');
                    reg4 <= (others=>'0');
                    retValCntr <= (others=>'0');
                else
                    reg0 <= reg0_nxt;
                    reg0 <= reg0_nxt;
                    reg1 <= reg1_nxt;
                    regALU <= regALU_nxt;
                    outShiftReg <= outShiftRegNext;
                    reg2 <= reg2_nxt;
                    reg3 <= reg3_nxt;
                    reg4 <= reg4_nxt;
                    retValCntr <= retValCntr_nxt;
                end if;
            end if;
        end process;
    toReg0 <= ZERO256 when sel_reg0 = '1' else stack_out;
    reg0_nxt <= toReg0 when en_reg0 = '1' else reg0;
    reg1_nxt <= stack_out when en_reg1 = '1' else reg1;
    regALU_nxt <= regALUin when enRegALU = '1' else regALU;
    reg4_nxt <= outKecc when en_reg4 = '1' else reg4;
    
    -- Return value counter
    with sel_retValCntr select
        retValCntr_nxt <= retValCntr when "00",
                          retValCntr + 1 when "01",
                          (others=>'0') when others;

    with en_shft select
        outShiftRegNext <= outShiftReg when "00", -- No shift
        outShiftReg(DEPTH_STACK - 1 - WIDTH_8 downto 0) & outMem when "01", -- Shift left by 1 byte
        (others=>'0') when others; -- Reset shift register
    
    reg2_nxt <= stack_out when en_reg2 = '1' else reg2;
    reg3_nxt <= stack_out when en_reg3 = '1' else reg3;

    shftReg256 <= outShiftReg(WIDTH_STACK - 1 downto 0);

    reg4Pad <= padReg4 & x"FF" & sender_address & stack_out & reg4; -- Pad reg4 with 344 zeros  

    --sigExtend <= SIGNEXTEND(stack_out, reg1); -- Sign extend the value in reg0

    process (clk) is
        variable extended       : std_logic_vector(WIDTH_STACK-1 downto 0);
        variable index          : unsigned(4 downto 0) := to_unsigned(WIDTH_STACK/8 - 1, 5);
        variable msb            : std_logic;
        variable selected_byte  : std_logic_vector(7 downto 0);
    begin
        -- Convert `x` to integer and limit it to the range [0, WIDTH_SIGEX/8 - 1]
        if to_integer(unsigned(reg1)) >= WIDTH_STACK/8 then
            index := to_unsigned(WIDTH_STACK/8 - 1,5); -- Clamp to max index
        else
            index := unsigned(reg1(4 downto 0));
        end if;
    
        -- Extract the byte at the given index
        selected_byte := stack_out((to_integer(index)+1)*8-1 downto to_integer(index)*8);
    
        -- Extract MSB of selected byte for sign extension
        msb := selected_byte(7);
    
        -- Fill with MSB of selected byte (sign extension)
        extended := (others => msb);
    
        -- Copy `b` into `extended`, keeping original content from LSB up to the selected byte
        extended((to_integer(index)+1)*8-1 downto 0) := stack_out((to_integer(index)+1)*8-1 downto 0); 
    
        sigExtend <= extended;
    end process;

    
    with selRegALU select
        regALUin <= alu_out when "000",
                    product when "001",
                    powerEXP when "010",
                    quotient when "011",
                    sigExtend when "100",
                    remainder when others;

    --regALUin <= product when selRegALU = '1' else alu_out; -- Select the input to the ALU
    -- Gas
    GAS : entity work.GAS(rtl)
    generic map(
        WIDTH => GAS_WIDTH
    )
    port map(
        clk => clk,
        rst => rstGas,
        opcode => outBYTCD8,
        gasLimit => gasLimit(GAS_WIDTH - 1 downto 0),
        enGasLimit => enGasLimit,
        enTotGas => enTotGas,
        brokeFlag => brokeFlag,
        total_Gas => total_Gas,
        selOpcode => selOpcode,
        remGas => remGas
    );

    remGasPad <= GAS_ZEROS & remGas; -- Pad remGas with zeros

    -- NON_REST_DIV
    NON_REST_DIV : entity work.NON_REST_DIV
    generic map(WIDTH => WIDTH_DIV)
    port map(
        clk       => clk,
        rst       => rstDiv,
        dividend  => numDiv,
        divisor   => denDiv,
        start     => startDiv,
        ready     => readyDiv,
        remainder => remDiv,
        quotient  => quoDiv
    );

    numDiv <= regALU(WIDTH_DIV - 1 downto 0) when selNum = '1' else  reg0(WIDTH_DIV - 1 downto 0);
    denDiv <= stack_out(WIDTH_DIV - 1 downto 0);
    remainder <= zeroDiv & remDiv;
    outDiv <= zeroDiv & quoDiv;
    sftDiv <= DIV_ZEROS & numDiv(WIDTH_STACK - 1 downto SFT_DIV);

    quotient <= sftDiv when selDiv = '1' else outDiv;
    divBy224 <= '1' when denDiv = CONST_DIVIDER else '0';

    calDatSize <= callDataLen when unsigned(callData) > 0 else (others=>'0');

    -- RETURN VALUE
    RETURN_VALUE : entity work.RETURN_VALUE(rtl)
    generic map(
        RAM_DEPTH => DEPTH_MEM,
        RAM_WIDTH => WIDTH_8,
        ARRD_WIDTH => WIDTH_CNTR_MEM
    )
    port map(
        clk => clk,
        we => weRv,
        addr => retValCntr,
        di => outMem,
        do => returnValue
    );

    -- BOOTH MULTIPLIER
    BOOTH_MULT : entity work.BOOTH_MULTIPLIER(rtl)
    generic map(WIDTH => WIDTH_MULT)
    port map (
        multiplicant => multA,
        multiplier   => multB,
        clk          => clk,
        rst          => rstSAM,
        start        => startSAM,
        done         => doneSAM,
        product      => multOut
    );

    multA <= stack_out(WIDTH_MULT - 1 downto 0);
    multB <= reg0(WIDTH_MULT - 1 downto 0);
    --product <= zeroMULT & multOut;
    product <= multOut(WIDTH_STACK - 1 downto 0);

    --=========== Wring to a file ================
    --numDivO   <= multA;  
    --denDivO   <= multB;  
    --startDivO <= startSAM;
    --readyDivO <= doneSAM;
    --quoDivO   <= product;  
    --==========================
    
    
    -- EXPONENTIAL
    EXPONENTIAL : entity work.EXPONENTIAL(rtl)
    generic map(WIDTH => WIDTH_EXP)
    port map(
        clk  => clk,     
        reset =>  rstEXP,   
        start => startEXP,   
        base  =>  expA,  
        exponent => exponent,
        expResult => power,
        done =>doneEXP     
    );

    expA <= reg1(WIDTH_EXP - 1 downto 0);
    exponent <= stack_out(WIDTH_EXP - 1 downto 0);
    powerEXP <= zeroEXP & power;

    -- CALLDATACOPY
    CALLDATACOPY : entity work.CALLDATACOPY(rtl)
    generic map(
        WIDTH_INPUT => WIDTH_CALLDATA,
        WIDTH_256 => WIDTH_256,
        WIDTH_CNTR => CALLDATCPY_CNTR
    )
    port map(
        clk => clk,
        rst => rst,
        cntlCntr0 => cntlCntr0,
        callData => callData,
        offset => stack_out,
        outCallData => outCallData
    );
    -- CALLDATALD
    CALLDATALD : entity work.CALLDATALD(rtl)
    generic map(
        WIDTH_INPUT => WIDTH_CALLDATA,
        WIDTH_256 => WIDTH_256
    )
    port map(
        clk => clk,
        rst => rstCallD,
        en => enCallD,
        callData => callData,
        offset => stack_out,
        callDataOut => callDataOut
    );

    -- EVM_MEMORY instance
    EVM_MEMORY : entity work.EVM_MEMORY(rtl)
    generic map(
        WIDTH_256         => WIDTH_256,
        WIDTH_MEMORY_ADDR => WIDTH_MEMORY_ADDR, 
        WIDTH_CNTR        => WIDTH_CNTR_MEM,       
        SIZE_COPY         => SIZE_COPY,  
        DEPTH_MEM         => DEPTH_MEM,
        WIDTH2            => WDTH_enPC,
        WIDTH_MEM         => WIDTH_8  
    )
    port map(
        MEM_in     => MEM_in,    
        start_rd_mem     => start_rd_mem,    
        start_wrt_mem => start_wrt_mem,   
        size       => bytes2MEM,      
        destOffset => reg1,
        rdOffset   => reg3,    
        clk        => clk,       
        rst        => rst, 
        rstMemAcc  => rstMemAcc,
        enMEM_cpy  => enMEM_cpy,  
        selShftCntr => selShftCntr,
        wrt_cntr => wrt_cntr,
        rd_cntr => rd_cntr,  
        mem_wrt    => mem_wrt,  
        done_wt    => done_MEMwt,   
        done_rd    => done_MEMrd,   
        MEM_out    => outMem,
        activMEM    => activMEM
        );
    -- Pad outMem to 256 bits
    outMemPad <= ZERO248 & outMem;

    -- Assign outMemPad to MEM_in when sel_mem = '1'
    with sel_mem select
        MEM_in <= stack_out when "000",
                shftReg256 when "001",
                outFLIP when "010",
                outCallData when "011",
                PadBytOutPC  when "100",
                returnData when "101",
                byteCode when "110",
                outMemPad when others;


    --pad_keccak
    PAD_KECCAK : entity work.KEC_PAD0(rtl)
    generic map(
        INPUT_WIDTH  => DEPTH_STACK,
        SIZE_WIDTH => KEC_SIZE, 
        PAD_WIDTH => KEC_PAD_WIDTH
        )
    port map(
        pad_in  => pad_in,
        size    => bytes2MEM(KEC_SIZE - 1 downto 0), 
        pad_out => kecPadOut
        );

        with selRpl select -- Select the input to the keccak
            pad_in <= outShiftReg when "00",
            rpl_digest when "01",
            reg4Pad when others;


    --KECCAK
    KECCAK : entity work.sha3(arch) 
    generic map (
        t => T,
        input_width => KEC_PAD_WIDTH
        ) 
    port map(
        kecc_in=>kecPadOut, 
        rst => rstKecc, 
        clk => clk, 
        start => startKecc, 
        mode => mode, 
        output_sha3 => outKecc, 
        ready => doneKecc
        );

        ethAddr <= x"000000000000000000000000" & outKecc(ETH_ADDR_SIZE - 1 downto 0); -- Get the first 160 bits of outKecc
    
    -- STORAGE
    STORAGE: entity work.STORAGE(rtl)
    generic map(
        WIDTH_KEY => WIDTH_STACK,   
        STORAGE_DEPTH => STORAGE_DEPTH,
        STORAGE_WIDTH => WIDTH_STACK
    )
    port map (
        clk      => clk,
        write_en => enStorage,
        key      => storeKey,
        value  => stack_out,
        value_out => value_out
    );
    key <= stack_out when selStorage = '1' else reg3; -- Read from reg3 or stack
    storeKey <= std_logic_vector(to_unsigned(1023, WIDTH_STACK)) when selStrg = '1' else key; -- Write to reg3 or stack

    -- FLIP_DATA
    FLIP_DATA: entity work.FLIP_DATA(rtl)
    generic map(
        WIDTH_DATA => WIDTH_STACK
    )
    port map(
        toFLIP => stack_out, 
        outFLIP => outFLIP
    );

    -- ALU
    ALU: entity work.ALU(rtl)
    generic map(
        WIDTH_256 => WIDTH_256,
        WIDTH_opALU => WIDTH_opALU
    )
    port map(
        a       => reg0, 
        b       => stack_out, 
        opALU   => opALU, 
        alu_out => alu_out
    );

    -- COUNTER
    COUNTER: entity work.COUNTER(rtl)
    generic map(
        WIDTH_OUT => WIDTH_CNTR
    )
    port map(
        clk => clk, 
        rst => rstCntr, 
        en  => enCntr, 
        cnt => cntr_out
    );

    -- FSM
    FSM_EVM : entity work.FSM_EVM(rtl)
    generic map(
        WIDTH_8  => WIDTH_8, 
        WDTH_enPC => WDTH_enPC,
        WIDTH_CNTL1 => WIDTH_CNTL1,
        WIDTH_CNTR => WIDTH_CNTR,
        DUP_OFFSET => DUP_OFFSET,
        WIDTH_opALU => WIDTH_opALU,
        SIZE_COPY => SIZE_COPY,
        WIDTH_SEL_MEM => WIDTH_SEL_MEM,
        WIDTH_SELBYTS => WIDTH_SELBYTS
    )
    port map(
        clk      =>  clk,     
        rst      =>  rst,
        done_MEMwt => done_MEMwt,
        done_MEMrd => done_MEMrd,     
        startEVM =>  startEVM,
        doneKecc => doneKecc,
        doneEXP => doneEXP,
        doneSAM => doneSAM,
        doneBTCDjump => doneBTCDjump,
        --ldByte => ldByte,
        readyDiv => readyDiv,
        enCntr2PC => enCntr2PC,
        selShftCntr => selShftCntr,
        selByts  =>  selByts,
        sel_mem =>  sel_mem,
        selRpl => selRpl,
        wrt_cntr => wrt_cntr,
        rd_cntr => rd_cntr,
        cntlCntr0 => cntlCntr0,
        stack_out => stack_out,
        outBYTCD8 =>  outBYTCD8,
        cntr_out =>  cntr_out,
        addr_offset => addr_offset,
        top_stack => top_stack,
        enPC     =>  enPC,
        cntl_sigs1 => cntl_sigs1,
        en_shft  =>  en_shft,
        selRegALU => selRegALU,
        selSTACK =>  selSTACK,
        sel_retValCntr => sel_retValCntr,
        opALU    =>  opALU,
        brokeFlag => brokeFlag,
        divBy224 => divBy224
    );
    -- Assign elements from cntl_sigs1
    jump <= cntl_sigs1(43);
    selStrg <= cntl_sigs1(42);
    wrtbytcd <= cntl_sigs1(41);
    rstPC <= cntl_sigs1(40);
    selNum <= cntl_sigs1(39);
    selOpcode <= cntl_sigs1(38);
    enTotGas <= cntl_sigs1(37);
    rstGas <= cntl_sigs1(36);
    enGasLimit <= cntl_sigs1(35);
    startDiv <= cntl_sigs1(34);
    rstDiv <= cntl_sigs1(33);
    weRv <= cntl_sigs1(32);
    startSAM <= cntl_sigs1(31);
    rstSAM <= cntl_sigs1(30);
    startEXP <= cntl_sigs1(29);
    rstEXP <= cntl_sigs1(28);
    enCallD  <= cntl_sigs1(27);
    rstCallD <= cntl_sigs1(26);
    mem_wrt  <= cntl_sigs1(25);
    en_reg4   <= cntl_sigs1(24);
    rstKecc   <= cntl_sigs1(23);
    startKecc  <= cntl_sigs1(22);
    selDiv   <= cntl_sigs1(21);
    selStorage <= cntl_sigs1(20);
    enStorage <= cntl_sigs1(19);
    enMEM_cpy <= cntl_sigs1(18);
    sel_reg0  <= cntl_sigs1(17);
    en_reg3   <= cntl_sigs1(16);
    en_reg2   <= cntl_sigs1(15);
    en_reg1   <= cntl_sigs1(14);
    start_rd_mem    <= cntl_sigs1(13); 
    start_wrt_mem <= cntl_sigs1(12);
    rstMemAcc     <= cntl_sigs1(11);
    enRegALU  <= cntl_sigs1(10);
    rstAccm   <= cntl_sigs1(9);
    en_reg0   <= cntl_sigs1(8); 
    enCntr    <= cntl_sigs1(7);
    rstCntr   <= cntl_sigs1(6);
    we_stack  <= cntl_sigs1(5); 
    push      <= cntl_sigs1(4);
    pop       <= cntl_sigs1(3); 
    wrt_stack <= cntl_sigs1(2);
    enAccm    <= cntl_sigs1(1); 
    EVMready   <= cntl_sigs1(0);

    doneEVM <= '1' when counterBout > bramWords - 1 else EVMready;

    -- Input to stack pad to 256 bits
    padBytes <= ZERO248 & outBYTCD8;

    -- Number of bytes to write to memory
    with selByts select
    bytes2MEM <= BYTS32 when "000",
                 BYTS1 when "001",
                 stack_out when "010",
                 BYTS23 when "011",
                 BYTS85 when others;

    -- MUX_LARGE
    MUX_LARGE: entity work.MUX_LARGE(rtl)
    generic map(
        WIDTH_DATA => WIDTH_STACK
    )
    port map(
        sel       => selSTACK,      
        padBytes  => padBytes, 
        accmBytes => accmBytes,
        ZERO256   => ZERO256,
        reg0      => reg0,
        data_out  => stack_out,
        regALU  => regALU,
        outShiftReg => shftReg256,
        activMEM   => activMEM,
        value_out  => value_out,
        out_pc  => PADout_pc,
        addrBal => addrBal,
        addrEOA => addrEOA,
        addrCurntSC => addrCurntSC,
        callerAddr => callerAddr,
        callValue => callValue,
        calDatSize => calDatSize,
        codeSize => codeSize,
        gasPrice => gasPrice,
        retDatSize => retDatSize,
        coinBasAddr => coinBasAddr,
        extCodHash => extCodHash,
        extCodSize => extCodSize,
        timestamp   => timestamp,  
        blockNumber => blockNumber,
        prevRandao  => prevRandao, 
        gasLimit    => gasLimit,   
        chainId     => chainId,    
        selfBalance => selfBalance,
        baseFee     => baseFee,
        outKecc     => outKecc,
        oneByte     => oneByte, 
        ethAddr     => ethAddr,
        callDataOut => callDataOut,
        blockHASH  => blockHASH,
        --powerEXP    => powerEXP,
        remGasPad => remGasPad,   
        muxOut    => data_in
    );
    bytInt <= to_integer(unsigned(reg3(WIDTH_8 - 4 downto 0))); -- Get integer value from reg3(7 downto 4)
    oneByte <= ZERO256(WIDTH_STACK-1 downto WIDTH_8) & stack_out(WIDTH_8 + ((WIDTH_STACK / WIDTH_8) - 1 - bytInt)*WIDTH_8 - 1 downto ((WIDTH_STACK / WIDTH_8) - 1 - bytInt)*WIDTH_8); -- Get one byte from reg3 starting from MSB
    PADout_pc <= PAD_OUTPC & out_pc;

    -- PC counter
    COUNTER_PC: entity work.COUNTER_PC(rtl)
    generic map(
        WIDTH_PC  => WIDTH_PC, 
        WDTH_enPC => WIDTH_SEL_MEM
    )
    port map(
        pc_inA => pc_inA,
        pc_inB => savPC,
        pc_inC => BYTCD_IN_WIDTH,
        clk    => clk,   
        rst    => rstPC,   
        enPC   => enPC,  
        out_pc => out_pc
    );
    pc_inA <= reg1(WIDTH_PC-1 downto 0);

    -- PC counter2
    COUNTER2_PC: entity work.COUNTER_PC(rtl)
    generic map(
        WIDTH_PC  => WIDTH_PC, 
        WDTH_enPC => WIDTH_SEL_MEM
    )
    port map(
        pc_inA => pc_inA2,
        pc_inB => (others=>'0'),
        pc_inC => (others=>'0'),
        clk    => clk,   
        rst    => rst,   
        enPC   => enCntr2PC,  
        out_pc => cnt2PC
    );
    pc_inA2 <= reg0(WIDTH_PC-1 downto 0);
    PadBytOutPC <= ZERO248 & bytOutPC;

    -- ACCUMULATOR
    ACCUMULATOR: entity work.ACCUMULATOR(rtl)
    generic map(
        WIDTH_IN  => WIDTH_8,
        WIDTH_OUT =>  WIDTH_256
    )
    port map(
        clk        => clk,       
        rst        => rstAccm,       
        en         => enAccm,        
        oneByte_in => outBYTCD8,
        accmBytes  => accmBytes 
    );

    ---- BYTECODE MEMORY
    --BYTECODE_MEM: entity work.BYTECODE_MEM(rtl)
    --generic map(
    --    WIDTH_8  => WIDTH_8, 
    --    WIDTH_PC => WIDTH_PC,
    --    BYTCD_LEN => BYTCD_LEN
    --)
    --port map(
    --    toBYTCD  => toBYTCD, 
    --    wrtBYTCD => wrtbytcd,
    --    pc       => out_pc,
    --    cnt2PC  => cnt2PC,      
    --    clk      => clk,     
    --    outBYTCD8 => outBYTCD8,
    --    bytOutPC  => bytOutPC
    --    );

    -- Bytecode storage
    BYTECODE_STORE: entity work.BYTECODE_STORE(rtl)
    generic map(
        INPUT_WIDTH => BYTCD_LEN,
        OUPUT_WIDTH => WIDTH_8,
        WIDTH_PC    => WIDTH_BUFPC   
    )
    port map(
        clk       => clk,      
        rst       => rst,      
        start     => loadBytecode,    
        RAMloaded   => BytecodeLoaded,  
        ldNext    => ldNxtByt,   
        toBYTCD   => toBYTCD,  
        pc        => out_pcBUFF,       
        cnt2PC    => cnt2PCBUFF,
        jumpToAddr => jumpToAddr,
        jump => jump,   
        readBUFF => readBUFF,
        doneBTCDjump => doneBTCDjump,
        bytOutPC  => bytOutPC,
        counterBout => counterBout, 
        outBYTCD8 => outBYTCD8
        );

    out_pcBUFF <= out_pc(WIDTH_BUFPC - 1 downto 0);
    cnt2PCBUFF <=  cnt2PC(WIDTH_BUFPC - 1 downto 0);
    --loadNextBytecode <= '1' when unsigned(out_pcBUFF) = WIDTH_BUFF - 1 else '0';
    jumpToAddr <= to_integer(unsigned(out_pc)) / WIDTH_BUFF;
    ldNxtByt <= loadNextBytecode AND NOT jump;

    process (clk)
        variable sigFlag : std_logic := '0';
        variable prevCondition : std_logic := '0'; -- Stores previous state of condition
    begin
        if rising_edge(clk) then
            -- Detect rising edge of condition
            if (prevCondition = '0') and (unsigned(out_pcBUFF) > WIDTH_BUFF - 2) then
                loadNextBytecode <= '1';  -- Generate pulse
                sigFlag := '1';
            else
                loadNextBytecode <= '0';  -- Ensure pulse lasts only one cycle
            end if;

            -- Update previous condition for next cycle
            prevCondition := '1' when (unsigned(out_pcBUFF) > WIDTH_BUFF - 2) else '0';
        end if;
    end process;


    -- STACK
    STACK_EVM: entity work.STACK_EVM(rtl)
    generic map(
        DEPTH_STACK => DEPTH_STACK,
        WIDTH_STACK => WIDTH_STACK,
        DUP_OFFSET => DUP_OFFSET
    )
    port map (            
        clk     => clk,     
        reset   => rst, 
        we      => we_stack,      
        push    => push,    
        pop     => pop,     
        data_in => data_in,  
        wrt     => wrt_stack,      
        addr_offset => addr_offset,
        top_stack => top_stack,
        data_out   => stack_out        
        );
        popedaddress <= stack_out;


end architecture;
        