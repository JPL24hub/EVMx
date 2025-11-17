# 🧩 EVMx: An FPGA-Based Accelerator for Smart Contract Processing

[![License: CERN-OHL-W-2.0](https://img.shields.io/badge/License-CERN--OHL--W--2.0-green.svg)](https://cern-ohl.web.cern.ch/)
[![Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://github.com/JPL24hub/EVMx/tree/main/docs)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1234567.svg)](https://doi.org/10.1109/TVLSI.2025.3628118)

**EVMx** is a hardware implementation of the Ethereum Virtual Machine (EVM) designed for FPGA-based acceleration of smart contract execution.  
The architecture preserves Ethereum’s execution model while exploiting parallel datapaths to significantly reduce latency and energy consumption.

---

## 🧠 Overview

EVMx provides a **synthesizable hardware version of the EVM interpreter**, tailored for FPGA environments such as Xilinx Zynq and UltraScale+ platforms.

EVMx can be used for:
- Smart contract acceleration  
- Blockchain hardware research  
- Instruction-level analysis and profiling  

---

## 🧾 How to Cite

J. P. Lemayian, G. Gagnon, K. Zhang, and P. Giard,  
**“EVMx: An FPGA-Based Accelerator for Smart Contract Processing,”**  
*IEEE Transactions on Very Large Scale Integration (VLSI) Systems*,  
doi: 10.1109/TVLSI.2025.3628118.

---

## 📄 Publication History

### **Preliminary Version — COMPSAC 2025**

> **P. Lemayian, H. Bensalem, G. Gagnon, K. Zhang, and P. Giard**,  
> *“EVMx: An FPGA-Based Smart Contract Processing Unit,”* COMPSAC 2025.  
> [DOI](https://doi.org/10.1109/COMPSAC65507.2025.00231) | [Pre-print](https://arxiv.org/abs/2507.23518)

### **Extended Version — IEEE TVLSI**

> **J. P. Lemayian, G. Gagnon, K. Zhang, and P. Giard**,  
> *“EVMx: An FPGA-Based Accelerator for Smart Contract Processing,”*  
> IEEE Transactions on VLSI Systems.  
> [Publisher](https://ieeexplore.ieee.org/document/11230572) | [PDF](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=11230572)

---

## 📜 License

This project is released under the **CERN Open Hardware License (CERN-OHL-W-2.0)**.  
You may use, study, modify, or manufacture hardware based on this design.  
If you distribute modified hardware, you must also release the source under the same license.

See the full text in [`LICENSE`](./LICENSE.txt).

### 🔑 Keccak Code

The Keccak-256 implementation is provided by its original designers and released under **CC0 (public domain)**:  <https://creativecommons.org/publicdomain/zero/1.0/>

---

## 🧩 Repository Structure

```text
📦 EVMx/
├── constraints/                # Timing, pin, and implementation constraints
├── data/                       
│   └── Block6653220_EVM/       # Example input bytecode for block 6653220
├── docs/                       # Documentation and reference papers
├── rtl/                        # Synthesizable VHDL source code
│   └── EVMx/
│       ├── ALU/                # The arithmetic and logic operations
│       ├── GAS/                # Gas computation and metering logic
│       ├── BYTECODE_MEM/       # Bytecode ROM for contract execution
│       ├── DIV_NON_REST/       # Non-restoring division unit
│       ├── BOOTH_MULT/         # Booth multipliers used for modular arithmetic
│       ├── EXPO/               # Modular exponentiation (binary method)
│       ├── KECCAK256/          # SHA3/Keccak-256 hashing core
│       ├── MEMORY/             # The memory core
│       ├── STACK/              # The stack core
│       └── STORAGE/            # The storage core
├── scripts/                    # TCL & Python automation (build, simulation)
├── sim/                        # Simulation outputs and waveform configurations (.wcfg)
├── tb/                         # Testbenches for verification
├── LICENSE                     # License file
└── README.md                   # Project documentation
```

---

## ⚙️ How to Run

```text
📦 Quick Start
├── 1. Clone the repository
├── 2. Open Vivado 2024.2 (or newer)
├── 3. In the TCL console: cd path_to/EVMx/scripts
├── 4. Run: source evmx.tcl
└── 5. Edit the data path variables in the files listed under the 
       Notes on Data Paths section below
```

This script:
- Creates a fresh Vivado project  
- Imports all RTL and testbench sources  
- Loads waveform configuration from `sim/`   

---

## ⚙️ Notes on Data Paths

These files require valid paths for loading Ethereum block data:

1. `Etherscan_Scraper.ipynb`  
2. `TB_EVM_BLC.vhd`  
3. `TB_EVM.vhd`  
