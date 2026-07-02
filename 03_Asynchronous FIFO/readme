# Asynchronous FIFO (Dual-Clock FIFO) in Verilog

A parameterized Asynchronous FIFO implementation in Verilog, designed for reliable data transfer between two independent clock domains. This design uses the industry-standard Gray-code pointer synchronization technique to safely handle Clock Domain Crossing (CDC) and avoid metastability issues.

## Repository Structure

| File | Description |
|---|---|
| `async_fifo.v` | RTL design of the asynchronous FIFO |
| `tb_async_fifo.v` | Testbench for simulation |
| `schematic.png` | Block-level schematic of the design |
| `waveform.png` | Simulation waveform output |

## Overview

A FIFO (First-In-First-Out) buffer is commonly used to transfer data between two clock domains that are not synchronized to each other, for example between a fast processor and a slower peripheral. Since the write and read operations occur in different clock domains, directly comparing pointers can lead to metastability and data corruption.

This design solves that problem by:

- Using binary pointers internally for memory addressing
- Converting pointers to Gray code before crossing clock domains
- Passing Gray-coded pointers through a 2-stage synchronizer (double flip-flop) in the destination clock domain
- Generating accurate `full` and `empty` flags based on the synchronized pointers

## Module: async_fifo

### Parameters

| Parameter | Description | Default |
|---|---|---|
| `width` | Data width (bits) | 8 |
| `depth` | FIFO depth (number of entries) | 8 |

### Ports

| Port | Direction | Width | Description |
|---|---|---|---|
| `wr_clk` | Input | 1 | Write clock |
| `rd_clk` | Input | 1 | Read clock |
| `wr_en` | Input | 1 | Write enable |
| `rd_en` | Input | 1 | Read enable |
| `rst` | Input | 1 | Asynchronous reset (active high) |
| `data_in` | Input | width | Data to be written into the FIFO |
| `data_out` | Output | width | Data read from the FIFO |
| `full` | Output | 1 | High when FIFO is full |
| `empty` | Output | 1 | High when FIFO is empty |

## Design Details

### 1. Write Domain (wr_clk)

Data is written into the memory array `FIFO` when `wr_en` is asserted and the FIFO is not full. The binary write pointer `wb_ptr` increments on every successful write. The write pointer is converted to Gray code (`wg_ptr`) to be safely passed to the read clock domain.

### 2. Read Domain (rd_clk)

Data is read from the memory array when `rd_en` is asserted and the FIFO is not empty. The binary read pointer `rb_ptr` increments on every successful read. The read pointer is converted to Gray code (`rg_ptr`) to be safely passed to the write clock domain.

### 3. Clock Domain Crossing (CDC)

Gray-coded pointers are passed through 2-flip-flop synchronizer chains:

- `wg_ptr` is synchronized into the `rd_clk` domain as `wg_ptr_sync2`
- `rg_ptr` is synchronized into the `wr_clk` domain as `rg_ptr_sync2`

Gray code is used instead of binary because only one bit changes at a time between consecutive values, which eliminates the risk of sampling an invalid intermediate value during synchronization.

### 4. Full and Empty Flag Generation

Empty is asserted when the read Gray pointer equals the synchronized write Gray pointer:

```verilog
empty = (rg_ptr == wg_ptr_sync2);
```

Full is asserted when the next write Gray pointer equals the synchronized read Gray pointer with the two MSBs inverted (standard Gray-code full detection):

```verilog
full = (wg_ptr_next == {~rg_ptr_sync2[MSB:MSB-1], rg_ptr_sync2[MSB-2:0]});
```

## Testbench: tb_async_fifo

The testbench verifies the FIFO by:

1. Driving two independent, asynchronous clocks: `wr_clk` at a 10 ns period (100 MHz) and `rd_clk` at a 24 ns period (about 41.6 MHz)
2. Applying an asynchronous reset at the start of simulation
3. Write phase: writing 11 sequential values (1 to 11) into the FIFO, checking the `full` flag before every write
4. Read phase: reading back 11 values from the FIFO, checking the `empty` flag before every read
5. Logging all read/write transactions with `$display` for waveform correlation

Sample console output:

```
---- Writing Data ----
20 ns : WRITE data_in = 1 (full = 0)
30 ns : WRITE data_in = 2 (full = 0)
---- Reading Data ----
120 ns : READ data_out = 1 (empty = 0)
144 ns : READ data_out = 2 (empty = 0)
```

## Schematic

The block-level architecture of the design, showing the write/read logic, Gray code converters, and dual flip-flop synchronizers:

![Schematic](schematic.png)

## Simulation Waveform

Example simulation waveform showing write and read operations across the two asynchronous clock domains:

![Waveform](waveform.png)

## How to Simulate (Xilinx Vivado)

1. Open Vivado and create a new RTL project.
2. Add `async_fifo.v` as a design source.
3. Add `tb_async_fifo.v` as a simulation source.
4. Set `tb_async_fifo` as the top module under Simulation Sources.
5. Run behavioral simulation:
   - Flow Navigator → **Simulation** → **Run Simulation** → **Run Behavioral Simulation**
6. View the waveform in the Vivado Waveform Viewer, and check the Tcl console for the `$display` log output.

### Using Vivado in Tcl/batch mode (optional)

```tcl
create_project fifo_sim ./fifo_sim -part xc7a35tcpg236-1 -force
add_files -norecurse async_fifo.v
add_files -fileset sim_1 -norecurse tb_async_fifo.v
set_property top tb_async_fifo [get_filesets sim_1]
launch_simulation
run all
```

## Key Concepts Demonstrated

- Clock Domain Crossing (CDC)
- Gray code pointer conversion for safe multi-bit signal crossing
- Double flip-flop synchronizers to mitigate metastability
- Parameterized, reusable FIFO design
- Full/Empty flag generation using Gray-code comparison

## Notes and Possible Improvements

- Add `$dumpfile` / `$dumpvars` in the testbench to auto-generate a `.vcd` waveform file
- Add almost-full / almost-empty flags for flow-control applications
- Add assertions (SVA) to formally verify pointer synchronization correctness
- Parameterize the number of synchronizer stages for higher-frequency designs

## Tools Used

- Verilog HDL
- Xilinx Vivado (simulation and waveform viewing)

## License

This project is open-source and available for educational and personal use.
