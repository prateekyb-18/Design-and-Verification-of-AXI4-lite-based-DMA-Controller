AXI4-Lite Based DMA Controller — RTL Design & UVM Verification

Overview

This project implements a parameterized DMA (Direct Memory Access) controller using SystemVerilog RTL, with an AXI4-Lite slave interface for CPU configuration and AXI-style master interfaces for moving data between source and destination memory.

The DMA controller is designed to transfer data without requiring the CPU to handle every individual data movement. The CPU configures the DMA through memory-mapped AXI4-Lite registers, starts the transfer, and the DMA controller manages the read, buffering, write, address update, completion, and interrupt-generation operations.

The project also includes a UVM-based verification environment for verifying the AXI4-Lite interface and DMA operation using a simulated memory model, driver, monitor, sequencer, sequence, agent, environment, and scoreboard.

Main Features

SystemVerilog RTL implementation

AXI4-Lite slave/register interface for CPU configuration

AXI read master for fetching source data

AXI write master for sending data to the destination

16-entry, 32-bit data FIFO for temporary data buffering

Burst-based data transfer

Configurable source address, destination address, and transfer length

Automatic source/destination address increment

Transfer-completion detection

DMA completion signal

Interrupt generation with enable and clear control

Debug state outputs for internal FSMs

Individual RTL testbenches for major blocks

UVM verification environment

AXI transaction, driver, monitor, scoreboard, sequencer and memory model

Simulation waveforms and synthesized/netlist representation included

DMA Architecture

The design is divided into the following major blocks:

AXI4-Lite Register Interface

Provides the CPU-facing configuration interface.

Handles AXI4-Lite read and write transactions.

Stores source address, destination address, and transfer length.

Generates the DMA start pulse.

Provides status information.

Control FSM

Controls the complete DMA transfer sequence.

Coordinates configuration loading, read bursts, FIFO operation, write bursts, address updates, and completion.

Read Master

Generates read-address transactions.

Receives source data.

Writes received data into the FIFO.

Detects completion of each read burst.

FIFO

Temporarily stores data between the read and write sides.

Prevents the read and write paths from having to operate at exactly the same time.

Write Master

Generates write-address transactions.

Reads data from the FIFO.

Generates write-data and last-beat indications.

Handles the write response.

Address Generator

Loads the initial source and destination addresses.

Tracks the remaining transfer length.

Automatically increments addresses after each burst.

Interrupt

Generates an interrupt when DMA completion occurs and interrupt generation is enabled.

Supports interrupt clearing.

Register Map

Address

Register

Description

0x00

Source Address

Starting source memory address

0x04

Destination Address

Starting destination memory address

0x08

Transfer Length

Number of bytes to transfer

0x0C

Start

Writing to this register starts the DMA

0x10

Status

DMA completion status

DMA Transfer Flow

CPU
 |
 | AXI4-Lite configuration
 v
+----------------------+
| AXI4-Lite Register   |
| Interface            |
+----------+-----------+
           |
           v
+----------------------+
| Control FSM          |
+----+-------------+---+
     |             |
     v             v
+---------+     +---------+
| Read    | --> |  FIFO   | --> Write
| Master  |     | Buffer  |     Master
+----+----+     +---------+     +----+----+
     |                                |
     v                                v
 Source Memory                  Destination Memory

           |
           v
   Address Generator
           |
           v
     Transfer Done
           |
           v
       Interrupt

Control FSM

The DMA controller uses the following control states:

IDLE

LOAD_CONFIG

WAIT_FIFO_SPACE

READ_BURST

WAIT_READ

WAIT_FIFO_DATA

WRITE_BURST

CHECK_DONE

DONE

The FSM coordinates the read and write masters and ensures that data is transferred only when the FIFO and AXI interfaces are ready.

Burst Configuration

The current implementation uses:

Address width: 32 bits

Data width: 32 bits

Burst length: 4 beats

Data per beat: 4 bytes

Bytes per burst: 16 bytes

FIFO depth: 16 entries

For example, a transfer length of 0x10 represents a 16-byte transfer, corresponding to one 4-beat burst with 32-bit data.

UVM Verification Environment

The project includes a UVM testbench organized into the standard UVM hierarchy:

axi_test
   |
   v
axi_env
   |
   +-------------------+
   |                   |
   v                   v
axi_agent         axi_scoreboard
   |
   +---------------------------+
   |             |             |
   v             v             v
Sequencer      Driver        Monitor
                              |
                              v
                        Analysis Port
                              |
                              v
                          Scoreboard

axi_memory_model
        |
        v
  Simulated Memory

UVM Components

Component

Purpose

axi_transaction.sv

Defines AXI read/write sequence items

axi_sequence.sv

Generates DMA configuration transactions

axi_sequencer.sv

Supplies transactions to the driver

axi_driver.sv

Drives AXI4-Lite transactions onto the interface

axi_monitor.sv

Observes AXI transactions

axi_scoreboard.sv

Reports and checks observed transactions

axi_agent.sv

Groups sequencer, driver and monitor

axi_env.sv

Top-level UVM environment

axi_memory_model.sv

Models source/destination memory behavior

axi_test.sv

Starts the verification sequence

axi_dma_if.sv

SystemVerilog interface connecting the UVM testbench and DUT

axi_tb.sv

Simulation top module

Verification Sequence

The included UVM sequence performs the following configuration:

Source Address      = 0x00001000
Destination Address = 0x00002000
Transfer Length     = 0x00000010
Start               = 1

The testbench then allows the DMA operation to execute while the UVM components observe and report the AXI transactions.

RTL Block Testbenches

Individual testbenches are provided for:

Add/Address Generator

Control FSM

FIFO

Interrupt

Read Master

Register Interface

Write Master

DMA Subsystem Top

These provide block-level verification in addition to the UVM-based subsystem verification.

Repository Structure

.
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
│   ├── add_gen.png
│   ├── cfsm.png
│   ├── fifo.png
│   ├── interrupt.png
│   ├── read_master.png
│   ├── reg_interface.png
│   └── write_master.png
│
├── terminal output/
│   ├── Add_gen.png
│   ├── cfsm.png
│   ├── dma subsystem netlist.png
│   ├── dma subsystem.png
│   ├── interrupt.png
│   ├── read_master.png
│   └── write_master.png
│
└── dma_schematic.pdf

Tools Used

SystemVerilog — RTL design and verification

UVM — constrained-random/structured verification framework

Icarus Verilog — RTL simulation

GTKWave — waveform analysis

Yosys — RTL synthesis

Graphviz — synthesis/netlist visualization

Linux/Ubuntu — development and simulation environment

For UVM simulation, use a simulator/version with the SystemVerilog and UVM features required by the testbench.

Results

The repository contains:

RTL source code for the complete DMA subsystem

Block-level testbenches

UVM verification environment

Simulation waveforms

Synthesized/netlist visualization

DMA schematic

The waveforms can be used to inspect AXI handshakes, FSM transitions, FIFO activity, read/write operations, and interrupt/completion behavior.

Key Learning Outcomes

This project demonstrates practical experience with:

RTL design using SystemVerilog

AXI4-Lite protocol concepts

AXI read/write channel handshaking

DMA architecture

Finite State Machine design

FIFO-based buffering

Burst data transfers

Memory-mapped register design

Interrupt generation

SystemVerilog interfaces

UVM testbench architecture

Drivers, monitors, sequencers and scoreboards

RTL simulation and waveform debugging

RTL synthesis and netlist visualization

Future Improvements

Possible extensions include:

More complete AXI protocol response/error checking

Support for variable burst lengths

Support for unaligned transfers

Separate source and destination memory models

Stronger reference-model-based scoreboard checking

Functional coverage and cross coverage

Assertions/SVA for AXI protocol checking

Multiple DMA channels

More extensive constrained-random testing

Performance/throughput measurements

Author

Prateek Badagannavar

Electronics and Communication Engineering
MVJ College of Engineering, Bengaluru

Project

RTL Design and UVM Verification of an AXI4-Lite Based DMA Controller
