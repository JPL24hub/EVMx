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
-- FILE:        MUX_LARGE.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 18/12/2024 - File created.
-- DESCRIPTION: Large mux to STACK.
-- COMMENTS:    
--------------------------------------------------------------------------------------
-- Libraries
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.PKG_EVM.all;

-- Entity
entity MUX_LARGE is
    generic (
        WIDTH_DATA  : integer := 256
    );
    port(
        sel         : in SELECT_STACK;
        padBytes    : in std_logic_vector(WIDTH_DATA - 1 downto 0); 
        accmBytes   : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        ZERO256     : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        reg0        : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        data_out    : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        regALU      : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        outShiftReg : in std_logic_vector(WIDTH_DATA - 1 downto 0); 
        activMEM    : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        value_out   : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        out_pc      : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        addrBal     : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        addrEOA     : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        addrCurntSC : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        callerAddr  : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        callValue   : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        calDatSize  : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        codeSize    : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        gasPrice    : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        retDatSize  : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        coinBasAddr : in std_logic_vector(WIDTH_DATA - 1 downto 0); 
        extCodHash  : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        extCodSize  : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        timestamp   : in std_logic_vector(WIDTH_DATA - 1 downto 0); 
        blockNumber : in std_logic_vector(WIDTH_DATA - 1 downto 0); 
        prevRandao  : in std_logic_vector(WIDTH_DATA - 1 downto 0); 
        gasLimit    : in std_logic_vector(WIDTH_DATA - 1 downto 0); 
        chainId     : in std_logic_vector(WIDTH_DATA - 1 downto 0); 
        selfBalance : in std_logic_vector(WIDTH_DATA - 1 downto 0); 
        baseFee     : in std_logic_vector(WIDTH_DATA - 1 downto 0); 
        outKecc     : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        oneByte     : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        ethAddr     : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        callDataOut : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        blockHASH   : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        remGasPad   : in std_logic_vector(WIDTH_DATA - 1 downto 0);
        muxOut      : out std_logic_vector(WIDTH_DATA - 1 downto 0)
    );
end entity;
-- Architecture
architecture rtl of MUX_LARGE is
begin
    with sel select
    muxOut <= padBytes when padBytesSel,
                accmBytes when accmBytesSel,
                reg0 when reg0Sel,
                data_out when stack_outSel,
                regALU when regALUSel, 
                ZERO256 when ZERO256Sel,
                outShiftReg when outShiftRegSel,
                activMEM when activMEMSel,
                out_pc when out_pcSel,
                addrCurntSC when addrCurntSCSel,
                addrBal when addrBalSel,
                addrEOA when addrEOASel,
                callerAddr when callerAddrSel,
                callValue when callValueSel,
                calDatSize when calDatSizeSel,
                codeSize when codeSizeSel,
                gasPrice when gasPriceSel,
                retDatSize when retDatSizeSel,
                coinBasAddr when coinBasAddrSel,
                timestamp   when timestampSel,
                blockNumber when blockNumberSel,
                prevRandao  when prevRandaoSel,
                gasLimit  when gasLimitSel,
                chainId  when chainIdSel,
                selfBalance when selfBalanceSel,
                baseFee  when baseFeeSel,
                outKecc  when outKeccSel,
                oneByte  when oneByteSel,
                ethAddr  when ethAddrSel,
                callDataOut when callDataOutSel,
                extCodHash when extCodHashSel,
                extCodSize when extCodSizeSel,
                blockHASH when blockHASHSel,
                remGasPad when remGasPadSel,
                value_out when others;

end architecture;

