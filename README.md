# 🧩 EVMx: An FPGA-Based Accelerator for Smart Contract Processing

[![License: CERN-OHL-W-2.0](https://img.shields.io/badge/License-CERN--OHL--W--2.0-green.svg)](https://cern-ohl.web.cern.ch/)
[![Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://github.com/JPL24hub/EVMx/tree/main/docs)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1234567.svg)](https://doi.org/10.1109/TVLSI.2025.3628118)

**EVMx** is a hardware implementation of the Ethereum Virtual Machine (EVM) designed for FPGA-based acceleration of smart contract execution.  
The architecture preserves Ethereum’s execution model while exploiting parallel datapaths to significantly reduce latency and energy consumption.

---

## 🧠 Overview

EVMx provides a **synthesizable, cycle-accurate hardware version of the EVM interpreter**, tailored for FPGA environments such as Xilinx Zynq and UltraScale+ platforms.

The design:
- Implements Ethereum’s **stack-based execution model** natively in hardware  
- Includes **hardware gas metering**, **Keccak-256 hashing**, and **256-bit arithmetic**  
- Uses **parallel execution pipelines** to accelerate critical opcodes  
- Achieves substantial speedups on **Zynq UltraScale+ ZCU104**

EVMx can be used for:
- Smart contract acceleration  
- Blockchain hardware research  
- ZKP preprocessing pipelines  
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

---

## 🧩 Repository Structure

```text
📦 EVMx/
├── constraints/                # Timing, pin, and implementation constraints
├── data/                       
│   └── Block6653220_EVM/       # Input bytecode, transactions, and test vectors
├── docs/                       # Documentation and reference papers
├── rtl/                        # Synthesizable VHDL source code
│   └── EVMx/
│       ├── ALU/                # 256-bit arithmetic and logic operations
│       ├── GAS/                # Gas computation and metering logic
│       ├── BYTECODE_MEM/       # Bytecode ROM for contract execution
│       ├── DIV_NON_REST/       # Non-restoring division unit
│       ├── BOOTH_MULT/         # Booth multipliers used for modular arithmetic
│       ├── EXPO/               # Modular exponentiation (binary method)
│       ├── KECCAK256/          # SHA3/Keccak-256 hashing core
│       ├── MEMORY/             # Unified memory (stack, calldata, storage)
│       ├── STACK/              # 256-bit stack manager
│       └── STORAGE/            # Persistent contract storage and state handler
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
└── 4. Run: source evmx.tcl
```

This script:
- Creates a fresh Vivado project  
- Imports all RTL and testbench sources  
- Loads waveform configuration from `sim/`  
- Runs the simulation until the `done` signal asserts  

---

## ⚙️ Notes on Data Paths

These files require valid paths for loading Ethereum block data:

1. `Etherscan_Scraper.ipynb`  
2. `TB_EVM_BLC.vhd`  
3. `TB_EVM.vhd`  

Ensure they point to:

```
./data/Block6653220_EVM/
```
