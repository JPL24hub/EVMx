# 🧩 EVMx: An FPGA-Based Accelerator for Smart Contract Processing

[![License: CERN-OHL-W-2.0](https://img.shields.io/badge/License-CERN--OHL--W--2.0-green.svg)](https://cern-ohl.web.cern.ch/)
[![Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://joelponcha.github.io/evmx)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1234567.svg)](https://doi.org/10.1109/TVLSI.2025.3628118)

**EVMx** is a hardware accelerator for the Ethereum Virtual Machine (EVM) that executes smart contracts directly on FPGA fabric.  
The design preserves Ethereum’s stack-based model while leveraging parallel datapaths to improve throughput and energy efficiency.

---

## 🧠 Overview

EVMx provides a **hardware implementation of the EVM interpreter** tailored for FPGA devices.  
It executes EVM bytecode at low latency and reduced power compared to software clients or general-purpose processors.

The architecture:
- Preserves EVM’s **stack-based execution** semantics.
- Implements **modular arithmetic**, **opcode decoding**, and **gas metering** in hardware.
- Supports **parallel instruction execution** for performance-critical opcodes.
- Is fully synthesizable and verified on the **Xilinx Zynq UltraScale+ ZCU104** board.

---

## 🧾 How to Cite
J. P. Lemayian, G. Gagnon, K. Zhang and P. Giard, "EVMx: An FPGA-Based Accelerator for Smart Contract Processing," in IEEE Transactions on Very Large Scale Integration (VLSI) Systems, doi: 10.1109/TVLSI.2025.3628118.



## 📄 Publication

A **preliminary version** of this work was presented at the *IEEE COMPSAC 2025* conference:

> **P. Lemayian, H. Bensalem, G. Gagnon, K. Zhang, and P. Giard**,  
> *“EVMx: An FPGA-Based Smart Contract Processing Unit,”*  
> *IEEE Annual Computer Software and Applications Conference (COMPSAC)*,  
> Toronto, Canada, July 2025, pp. 1708–1713.  
> [DOI](https://doi.org/10.1109/COMPSAC65507.2025.00231) | [Pre-print](https://arxiv.org/abs/2507.23518)

A **complete implementation and extended analysis** of this work is discussed in detail in the following article.

> **J. P. Lemayian, G. Gagnon, K. Zhang and P. Giard**,  
> *“EVMx: An FPGA-Based Accelerator for Smart Contract Processing,”*  
> *IEEE Transactions on Very Large Scale Integration (VLSI)*,  
> [Publisher](https://ieeexplore.ieee.org/document/11230572) | [PDF](https://ieeexplore.ieee.org/stamp/stamp.jsp?tp=&arnumber=11230572)
---

## 📜 License
This project is licensed under the **CERN Open Hardware Licence – Weakly Reciprocal (CERN-OHL-W-2.0)**.  
You may use, modify, and build hardware from this design, but if you distribute modified hardware,  
you must release the source under the same license.

See the full license in the [`LICENSE`](./LICENSE) file.

## 🧩 Repository Structure

The repository follows a modular organization to promote readability, maintainability, and independent verification of each hardware component.

```text
📦 EVMx/
├── docs/                # Documentation, figures, schematics, and reference papers
├── rtl/                 # VHDL source code (Register Transfer Level design)
│   ├── BOOTH_MULT/          # Booth multiplier modules for modular arithmetic
│   ├── BYTECODE_MEM/        # On-chip memory containing EVM bytecode
│   ├── DIVNONREST/          # Non-restoring division implementation
│   ├── EVMx/                # Core EVMx architecture (control unit, datapath, opcode unit)
│   ├── Expo_Binary_Booth/   # Modular exponentiation using binary Booth algorithm
│   ├── keccak256/           # Keccak-256 (SHA3) hashing engine
│   ├── MEMORY/              # Unified memory module for stack, calldata, and storage access
│   ├── STACK/               # Stack manager handling 256-bit operand operations
│   └── STORAGE/             # Persistent contract storage and state handler
│
├── scripts/             # TCL and Python scripts for build automation (synthesis, implementation, sim)
├── sim/                 # Simulation outputs and waveform configurations (.wcfg)
├── tb/                  # Testbenches for module-level and system-level verification
├── LICENSE              # CERN-OHL-W-2.0 hardware license
└── README.md            # Project overview and documentation
