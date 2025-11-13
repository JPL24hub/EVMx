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
-- FILE:        PKG_EVM.vhd
-- ENGINEER:    Poncha Lemayian
-- REVISION:    1.0 - 18/12/2024 - File created.
-- DESCRIPTION: Package for EVMx.
-- COMMENTS:    
--------------------------------------------------------------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

package PKG_EVM is

    constant WIDTH_SIGEX : integer := 256;


    -- Types
    type SELECT_STACK is (padBytesSel, ZERO256Sel, accmBytesSel, reg0Sel, stack_outSel, regALUSel, outShiftRegSel, activMEMSel, 
                            value_outSel, out_pcSel, addrCurntSCSel, addrBalSel, addrEOASel, callerAddrSel, callValueSel, 
                            calDatSizeSel, codeSizeSel, gasPriceSel, retDatSizeSel, coinBasAddrSel, timestampSel, blockNumberSel, 
                            prevRandaoSel, gasLimitSel, chainIdSel, selfBalanceSel, baseFeeSel, outKeccSel, oneByteSel, ethAddrSel,
                            callDataOutSel, extCodHashSel, extCodSizeSel, blockHASHSel, remGasPadSel);

    ---- Functions
    --function SIGNEXTEND( x : std_logic_vector(WIDTH_SIGEX-1 downto 0); 
    --                     b : std_logic_vector(WIDTH_SIGEX-1 downto 0) ) return std_logic_vector;




end PKG_EVM;
package body PKG_EVM is


    --function SIGNEXTEND(
    --    x : std_logic_vector(WIDTH_SIGEX-1 downto 0); 
    --    b : std_logic_vector(WIDTH_SIGEX-1 downto 0)) return std_logic_vector is
    --    variable extended       : std_logic_vector(WIDTH_SIGEX-1 downto 0);
    --    variable index          : integer;
    --    variable msb            : std_logic;
    --    variable selected_byte  : std_logic_vector(7 downto 0);
    --begin
    --    -- Convert `x` to integer and limit it to the range [0, WIDTH_SIGEX/8 - 1]
    --    if to_integer(unsigned(b)) >= WIDTH_SIGEX/8 then
    --        index := WIDTH_SIGEX/8 - 1; -- Clamp to max index
    --    else
    --        index := to_integer(unsigned(b));
    --    end if;
    --
    --    -- Extract the byte at the given index
    --    selected_byte := x((index+1)*8-1 downto index*8);
    --
    --    -- Extract MSB of selected byte for sign extension
    --    msb := selected_byte(7);
    --
    --    -- Fill with MSB of selected byte (sign extension)
    --    extended := (others => msb);
    --
    --    -- Copy `b` into `extended`, keeping original content from LSB up to the selected byte
    --    extended((index+1)*8-1 downto 0) := x((index+1)*8-1 downto 0); 
    --
    --    return extended;
    --end function;

end PKG_EVM;