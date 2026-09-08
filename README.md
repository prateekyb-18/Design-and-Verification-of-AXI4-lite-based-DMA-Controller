# AXI4-Lite Based DMA Controller – RTL Design and UVM Verification

## 📌 Project Overview

This project presents the **RTL design and UVM-based verification of an AXI4-Lite based DMA (Direct Memory Access) Controller** using SystemVerilog.

The DMA controller enables data transfer between source and destination memory without continuous CPU intervention. The CPU configures the DMA controller through an AXI4-Lite slave interface by writing the source address, destination address, and transfer length. Once the transfer is started, the DMA controller manages the complete data movement using dedicated AXI read and write master interfaces.

The project includes complete **RTL design, block-level verification, UVM-based verification, simulation waveforms, and synthesis results**.

---

## 🎯 Project Objectives

* Design an AXI4-Lite based DMA controller using SystemVerilog.
* Implement CPU-accessible DMA configuration registers.
* Implement AXI read and write master interfaces.
* Buffer transferred data using a FIFO.
* Automatically generate and update source and destination addresses.
* Control the DMA operation using a finite state machine.
* Generate an interrupt after completion of the DMA transfer.
* Verify the individual RTL blocks using dedicated testbenches.
* Develop a complete UVM verification environment.
* Analyze simulation waveforms using GTKWave.
* Perform RTL synthesis using Yosys.
* Generate and analyze the synthesized DMA subsystem structure.

---

# 🏗️ DMA Controller Architecture

The DMA controller consists of the following major blocks:

```text
                         +------------------+
                         |       CPU        |
                         +--------+---------+
                                  |
                                  | AXI4-Lite
                                  v
                    +-------------------------+
                    | AXI4-Lite Register      |
                    | Interface              |
                    +-----------+-------------+
                                |
                                v
                    +-------------------------+
                    |     Control FSM         |
                    +----+---------------+----+
                         |               |
                         |               |
                         v               v
                +----------------+   +----------------+
                |   AXI Read     |   |   AXI Write    |
                |    Master      |   |    Master      |
                +-------+--------+   +-------+--------+
                        |                    ^
                        |                    |
                        v                    |
                  +-----------------------------+
                  |       Data FIFO             |
                  +-----------------------------+
                        |
                        |
                        v
                +----------------+
                | Address        |
                | Generator      |
                +----------------+

                         |
                         v
                   +-----------+
                   | Interrupt |
                   +-----------+
```

---

# 🔹 Main RTL Blocks

## 1. AXI4-Lite Register Interface

The register interface provides the CPU-facing AXI4-Lite slave interface.

It is responsible for:

* Receiving AXI4-Lite write transactions.
* Receiving AXI4-Lite read transactions.
* Storing DMA configuration information.
* Providing status information to the CPU.
* Generating the DMA start control.
* Handling register read/write responses.

### Configuration Registers

| Address | Register            | Description                            |
| ------: | ------------------- | -------------------------------------- |
|  `0x00` | Source Address      | Starting address of source memory      |
|  `0x04` | Destination Address | Starting address of destination memory |
|  `0x08` | Transfer Length     | Number of bytes to transfer            |
|  `0x0C` | Start               | Starts the DMA transfer                |
|  `0x10` | Status              | DMA transfer status                    |

---

## 2. Control FSM

The Control FSM coordinates the complete DMA transfer.

It controls:

* DMA initialization.
* Read operation.
* FIFO operation.
* Write operation.
* Address updates.
* Transfer completion.
* Interrupt generation.

The FSM ensures that the read and write operations occur in the correct sequence.

---

## 3. AXI Read Master

The AXI Read Master is responsible for reading data from the source memory.

It performs:

* Read address generation.
* AXI read transactions.
* Read data reception.
* Read response handling.
* FIFO write control.
* Burst completion detection.

The received data is stored temporarily in the FIFO before being transferred to the destination.

---

## 4. AXI Write Master

The AXI Write Master transfers data from the FIFO to the destination memory.

It performs:

* Write address generation.
* Write data generation.
* Write strobe control.
* Last-beat generation.
* Write response handling.
* FIFO read control.
* Burst completion detection.

---

## 5. Data FIFO

The FIFO provides temporary storage between the AXI read and write paths.

The FIFO helps to:

* Buffer incoming data.
* Decouple read and write operations.
* Prevent data loss.
* Provide controlled data flow between the read and write masters.

The implemented FIFO is:

* **Depth:** 16 entries
* **Data width:** 32 bits

---

## 6. Address Generator

The Address Generator manages the source and destination addresses during DMA operation.

It performs:

* Initial source address loading.
* Initial destination address loading.
* Source address increment.
* Destination address increment.
* Transfer length tracking.

This allows the DMA controller to automatically move through consecutive memory locations.

---

## 7. Interrupt Controller

The interrupt block generates an interrupt when the DMA transfer is completed.

It provides:

* DMA completion indication.
* Interrupt enable control.
* Interrupt generation.
* Interrupt clear functionality.

---

# 🔄 DMA Transfer Operation

The complete DMA operation follows these steps:

```text
1. CPU configures source address
             ↓
2. CPU configures destination address
             ↓
3. CPU configures transfer length
             ↓
4. CPU writes START
             ↓
5. DMA Control FSM starts
             ↓
6. AXI Read Master reads source data
             ↓
7. Data is stored in FIFO
             ↓
8. AXI Write Master reads FIFO data
             ↓
9. Data is written to destination memory
             ↓
10. Source and destination addresses are updated
             ↓
11. Remaining transfer length is checked
             ↓
12. DMA completes when all data is transferred
             ↓
13. Interrupt is generated
```

---

# ⚙️ DMA Configuration

The current implementation uses:

| Parameter       | Value      |
| --------------- | ---------- |
| Address Width   | 32 bits    |
| Data Width      | 32 bits    |
| Burst Length    | 4 beats    |
| Bytes per Beat  | 4 bytes    |
| Bytes per Burst | 16 bytes   |
| FIFO Depth      | 16 entries |

For example:

```text
Transfer Length = 16 bytes

32-bit data = 4 bytes/beat

16 bytes / 4 bytes = 4 beats
```

Therefore, a 16-byte transfer requires one 4-beat burst.

---

# 🧠 Control FSM

The DMA controller uses a finite state machine to control the transfer process.

The major states include:

```text
IDLE
  ↓
LOAD_CONFIG
  ↓
WAIT_FIFO_SPACE
  ↓
READ_BURST
  ↓
WAIT_READ
  ↓
WAIT_FIFO_DATA
  ↓
WRITE_BURST
  ↓
CHECK_DONE
  ↓
DONE
```

The FSM coordinates the AXI read master, FIFO, AXI write master, address generator, and interrupt logic.

---

# 🧪 Verification

The project contains two levels of verification.

## 1. Block-Level Verification

Individual testbenches were created for the major RTL blocks.

The verified blocks include:

* Address Generator
* Control FSM
* FIFO
* Interrupt
* AXI Read Master
* AXI4-Lite Register Interface
* AXI Write Master
* DMA Subsystem Top

These testbenches verify the functionality of each block independently.

---

# 🧪 UVM Verification Environment

A complete UVM-based verification environment was developed for the DMA subsystem.

The UVM architecture contains:

```text
                    +----------------+
                    |    AXI Test    |
                    +-------+--------+
                            |
                            v
                    +----------------+
                    |    AXI Env     |
                    +-------+--------+
                            |
             +--------------+--------------+
             |                             |
             v                             v
      +-------------+              +--------------+
      |  AXI Agent  |              |  Scoreboard  |
      +------+------+              +--------------+
             |
       +-----+-----+----------+
       |           |          |
       v           v          v
+----------+ +----------+ +----------+
|Sequencer | |  Driver  | | Monitor  |
+----------+ +----------+ +----------+
                            |
                            v
                    +---------------+
                    | Memory Model  |
                    +---------------+
```

---

# 🔹 UVM Components

## AXI Transaction

Defines the transaction-level representation of AXI operations.

File:

```text
axi_transaction.sv
```

---

## AXI Sequence

Generates AXI transactions used to configure and start the DMA.

File:

```text
axi_sequence.sv
```

---

## AXI Sequencer

Controls the flow of transactions from the sequence to the driver.

File:

```text
axi_sequencer.sv
```

---

## AXI Driver

Drives AXI4-Lite transactions onto the DUT interface.

File:

```text
axi_driver.sv
```

---

## AXI Monitor

Observes AXI transactions from the DUT interface and sends them to the scoreboard.

File:

```text
axi_monitor.sv
```

---

## AXI Scoreboard

Receives monitored transactions and performs checking of the expected behavior.

File:

```text
axi_scoreboard.sv
```

---

## AXI Agent

Contains the:

* Sequencer
* Driver
* Monitor

File:

```text
axi_agent.sv
```

---

## AXI Environment

Integrates the agent, scoreboard, and other verification components.

File:

```text
axi_env.sv
```

---

## AXI Memory Model

Provides a simulated memory environment for the DMA read and write operations.

File:

```text
axi_memory_model.sv
```

---

## AXI Interface

Provides the connection between the UVM testbench and DUT.

File:

```text
axi_dma_if.sv
```

---

## AXI Testbench

Top-level simulation module that connects the DUT and UVM environment.

File:

```text
axi_tb.sv
```

---

## AXI Test

Top-level UVM test that creates the verification environment and starts the required sequences.

File:

```text
axi_test.sv
```

---

# 📂 Project Structure

```text
AXI4-Lite-DMA-Controller/
│
├── rtl/
│   ├── add_gen.sv
│   ├── cfsm.sv
│   ├── dma_subsystem_top.sv
│   ├── fifo.sv
│   ├── interrupt.sv
│   ├── read_master.sv
│   ├── reg_interface.sv
│   └── write_master.sv
│
├── tb/
│   ├── add_gen_tb.sv
│   ├── cfsm_tb.sv
│   ├── dma_subsystem_top_tb.sv
│   ├── fifo_tb.sv
│   ├── interrupt_tb.sv
│   ├── read_master_tb.sv
│   ├── reg_interface_tb.sv
│   └── write_master_tb.sv
│
├── uvm/
│   ├── axi_agent.sv
│   ├── axi_dma_if.sv
│   ├── axi_driver.sv
│   ├── axi_env.sv
│   ├── axi_memory_model.sv
│   ├── axi_monitor.sv
│   ├── axi_scoreboard.sv
│   ├── axi_sequence.sv
│   ├── axi_sequencer.sv
│   ├── axi_tb.sv
│   ├── axi_test.sv
│   ├── axi_transaction.sv
│   └── uvm_pkg_import.svh
│
├── waveforms/
│
├── terminal output/
│
├── dma_schematic.pdf
│
└── README.md
```

---

# 🛠️ Tools and Technologies

The project was developed and verified using:

* **SystemVerilog** – RTL design and verification
* **UVM** – Universal Verification Methodology
* **Icarus Verilog** – RTL simulation
* **GTKWave** – Waveform analysis
* **Yosys** – RTL synthesis
* **Graphviz** – Netlist visualization
* **Ubuntu Linux** – Development and simulation environment

---

# 📊 Simulation and Waveform Analysis

Simulation waveforms were generated for the individual RTL blocks and DMA subsystem.

The waveforms can be used to verify:

* Clock and reset behavior
* AXI handshaking
* FSM state transitions
* FIFO read/write operation
* Address generation
* Read transactions
* Write transactions
* DMA completion
* Interrupt generation

Waveform screenshots are included in the repository for reference.

---

# 🔬 Synthesis

The RTL design was synthesized using **Yosys**.

The repository contains the synthesized DMA subsystem representation and schematic/netlist output.

Synthesis was performed to verify that the RTL design can be converted into a hardware-oriented representation and to inspect the resulting design structure.

---

# 📈 Verification Flow

The overall verification flow used in this project is:

```text
RTL Design
    ↓
Block-Level Testbenches
    ↓
RTL Simulation
    ↓
Waveform Analysis
    ↓
DMA Subsystem Integration
    ↓
UVM Environment
    ↓
AXI Transactions
    ↓
Memory Model
    ↓
Monitor
    ↓
Scoreboard
    ↓
Verification Results
    ↓
RTL Synthesis
```

---

# 🎓 Key Learning Outcomes

This project provided practical experience in:

* RTL design using SystemVerilog
* AXI4-Lite protocol
* AXI read/write handshaking
* DMA controller architecture
* Finite State Machine design
* FIFO design
* Burst-based data transfer
* Memory-mapped registers
* Address generation
* Interrupt generation
* SystemVerilog interfaces
* UVM testbench architecture
* UVM sequences
* UVM sequencers
* UVM drivers
* UVM monitors
* UVM agents
* UVM environments
* Scoreboards
* Simulation and waveform debugging
* RTL synthesis
* Netlist analysis

---

# 🚀 Future Improvements

The project can be further extended with:

* Functional coverage
* AXI protocol assertions using SVA
* More extensive constrained-random testing
* Variable burst lengths
* Unaligned data transfers
* AXI error-response testing
* Performance and throughput measurement
* More advanced reference-model-based scoreboard
* Multiple DMA channels
* Additional DMA status and control registers

---

# 👨‍💻 Author

**Prateek Badagannavar**

Electronics and Communication Engineering
MVJ College of Engineering, Bengaluru

---

# 📌 Project Title

**RTL Design and UVM Verification of an AXI4-Lite Based DMA Controller**

---

## ⭐ Keywords

```text
AXI4-Lite
DMA Controller
RTL Design
SystemVerilog
UVM
AXI Protocol
FIFO
FSM
ASIC
VLSI
RTL Verification
Functional Verification
Yosys
Icarus Verilog
GTKWave
Digital Design
Hardware Verification
```
