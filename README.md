# 🧩 EVMx: An FPGA-Based Accelerator for Smart Contract Processing

[![License](https://img.shields.io/badge/License-Apache--2.0-green.svg)](LICENSE)
[![Documentation](https://img.shields.io/badge/docs-latest-blue.svg)](https://joelponcha.github.io/evmx)
[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.1234567.svg)](https://doi.org/10.5281/zenodo.1234567)

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

## 🧩 Repository Structure

📦 EVMx/
├── docs/ # Documentation, figures, schematics, and reference papers
├── rtl/ # VHDL source code (Register Transfer Level design)
│ ├── BOOTH_MULT/ # Booth multiplier modules for modular arithmetic
│ ├── BYTECODE_MEM/ # On-chip memory containing EVM bytecode
│ ├── DIVNONREST/ # Non-restoring division implementation
│ ├── EVMx/ # Core EVMx architecture (control unit, datapath, opcode unit)
│ ├── Expo_Binary_Booth/ # Modular exponentiation using binary Booth algorithm
│ ├── keccak256/ # Keccak-256 (SHA3) hashing engine
│ ├── MEMORY/ # Unified memory module for stack, calldata, and storage access
│ ├── STACK/ # Stack manager handling 256-bit operand operations
│ └── STORAGE/ # Persistent contract storage and state handler
│
├── scripts/ # TCL and Python scripts for build automation (synthesis, implementation, sim)
├── sim/ # Simulation outputs and waveform configurations (.wcfg)
├── tb/ # Testbenches for module-level and system-level verification
└── README.md # Project overview and documentation