# 5-Stage Pipelined RISC-V Processor

## Overview

This project presents a **Five-Stage Pipelined RISC-V Processor** designed in Verilog HDL. It mitigates structural and data hazards using forwarding and stalling techniques. The architecture follows the standard RISC pipeline model with a clear separation of datapath and control logic, making it suitable for learning, RTL design practice, and FPGA deployment.

### Design Focus
- Modular RTL architecture  
- Clear pipeline stage separation  
- Efficient hazard handling mechanisms  

---

## Key Features

- Fully pipelined architecture with 5 stages  
- Register file supporting synchronous write and combinational read  
- Pipeline registers between stages (IF/ID, ID/EX, EX/MEM, MEM/WB)  
- ALU supporting arithmetic and logical operations  
- Data hazard resolution through forwarding  
- Pipeline stalling for load-use dependencies  
- Control flow handling with branch logic and PC updates  
- Synthesizable RTL ready for FPGA implementation  

---

## Pipeline Architecture

The processor consists of five stages that operate in parallel on different instructions, improving throughput while maintaining correct execution.

---

## Instruction Fetch (IF)

This stage updates the Program Counter (PC) and fetches instructions from memory. The instruction at the current PC address is stored in the IF/ID pipeline register, while `PC + 4` is computed for sequential execution. The stage also handles control flow changes such as branches and jumps by updating the PC accordingly.

---

## Instruction Decode / Register Fetch (ID)

In this stage, the fetched instruction is decoded and control signals are generated. The register file is accessed to obtain operand values, and immediate values are generated using sign extension. All decoded information and control signals are passed to the next stage via the ID/EX pipeline register.

---

## Execute (EX)

The execute stage performs arithmetic and logical operations using the ALU. It also computes memory addresses for load/store instructions and evaluates branch conditions. Operand selection is enhanced with forwarding paths to reduce hazards. Branch target computation is also performed here to enable faster control decisions.

---

## Memory Access (MEM)

This stage interacts with data memory. Load instructions retrieve data from memory, while store instructions write data to the specified address. The results and control signals are passed to the next stage through the MEM/WB pipeline register.

---

## Write Back (WB)

The final stage updates the register file with either the ALU result or memory data. A multiplexer selects the correct value to be written back, ensuring proper program execution and maintaining architectural state consistency.

---
<img width="823" height="582" alt="image" src="https://github.com/user-attachments/assets/98295a88-5626-4feb-a7bc-d7cc970d65a7" />
