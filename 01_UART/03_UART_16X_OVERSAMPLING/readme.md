# UART Receiver with 16× Oversampling (Verilog)

## Overview

This project implements a UART (Universal Asynchronous Receiver Transmitter) in Verilog using a **16× oversampling receiver architecture**. The design consists of a UART transmitter, UART receiver, baud rate generator, top module, and testbench.

Unlike a basic UART loopback design where both transmitter and receiver operate using the same baud enable signal, this implementation uses:

- Transmitter operating at the UART baud rate (9600 baud)
- Receiver operating at 16× the baud rate
- Start bit validation
- Mid-bit sampling
- Stop bit validation
- Reliable serial data recovery

This architecture closely resembles practical UART receiver implementations used in digital systems and FPGA-based designs.

---

## Project Specifications

| Parameter | Value |
|------------|---------|
| System Clock | 50 MHz |
| Baud Rate | 9600 |
| Oversampling Ratio | 16× |
| Data Bits | 8 |
| Stop Bits | 1 |
| Parity | None |

---

## Project Structure

```text
03_UART_16X_OVERSAMPLING
│
├── baud_rate_generator.v
├── transmitter.v
├── receiver.v
├── uart_top.v
├── uart_top_tb.v
├── schematic.png
├── waveform.png
└── README.md
```

---

## UART Frame Format

A UART frame contains:

```text
| Start | D0 | D1 | D2 | D3 | D4 | D5 | D6 | D7 | Stop |
|   0   |            8 Data Bits             |   1   |
```

Example for data `8'h55`:

```text
0 1 0 1 0 1 0 1 0 1
↑                 ↑
Start           Stop
```

---

## Design Architecture

```text
                 +------------------+
                 | Baud Generator   |
                 +------------------+
                     |         |
                     |         |
                  tx_enb    rx_enb
                     |         |
                     |         |
                     v         v

+-------------+     tx     +-------------+
| Transmitter | ---------->|  Receiver   |
+-------------+            +-------------+

       |                        |
       |                        |
      busy                    rdy
                               |
                               |
                           data_out
```

---

# Module Description

## 1. Baud Rate Generator

### Function

Generates timing enable pulses required by the transmitter and receiver.

### Inputs

| Signal | Description |
|----------|-------------|
| clk | 50 MHz system clock |
| rst | Active-high reset |

### Outputs

| Signal | Description |
|----------|-------------|
| tx_enb | Transmitter baud enable pulse |
| rx_enb | Receiver oversampling enable pulse |

### Baud Rate Calculation

#### Transmitter Enable

```text
Baud Rate = 9600

Divider = 50,000,000 / 9600
        ≈ 5208
```

Therefore:

```verilog
tx_count == 5207
```

generates one transmitter enable pulse every UART bit period.

#### Receiver Enable

Receiver operates at:

```text
9600 × 16
= 153600 Hz
```

Divider:

```text
50,000,000 / 153600
≈ 326
```

Therefore:

```verilog
rx_count == 325
```

generates the receiver sampling clock.

---

## 2. UART Transmitter

### Function

Converts parallel data into UART serial data.

### Inputs

| Signal | Description |
|----------|-------------|
| clk | System clock |
| rst | Active-high reset |
| wr_enb | Data load enable |
| enb | Baud enable pulse |
| data_in[7:0] | Parallel input data |

### Outputs

| Signal | Description |
|----------|-------------|
| tx | Serial transmit line |
| busy | Transmission status |

### Transmitter FSM

```text
IDLE → START → DATA → STOP → IDLE
```

### IDLE State

- UART line remains high
- Waits for `wr_enb`

```text
tx = 1
```

### START State

Transmits start bit:

```text
0
```

### DATA State

Transmits:

```text
D0 D1 D2 D3 D4 D5 D6 D7
```

Data is transmitted LSB first.

### STOP State

Transmits stop bit:

```text
1
```

Returns to IDLE after completion.

---

## 3. UART Receiver

### Function

Receives serial UART data and reconstructs the original parallel byte.

### Inputs

| Signal | Description |
|----------|-------------|
| clk | System clock |
| rst | Active-high reset |
| rx | Serial receive line |
| clk_enb | 16× sampling enable |
| rdy_clr | Clears receive flag |

### Outputs

| Signal | Description |
|----------|-------------|
| rdy | Receive complete flag |
| data_out[7:0] | Recovered data |

### Receiver FSM

```text
IDLE → START → DATA → STOP → IDLE
```

### IDLE State

Receiver continuously monitors:

```text
rx = 1
```

A transition:

```text
1 → 0
```

indicates start bit detection.

### START State

Receiver validates the start bit by sampling near its center.

```text
sample_count = 7
```

If:

```text
rx = 0
```

the start bit is considered valid and reception begins.

### DATA State

Receiver samples each bit after 16 oversampling clocks.

Received bits are stored in:

```verilog
temp_register[bit_count]
```

until all 8 bits are received.

### STOP State

Receiver validates the stop bit.

Expected:

```text
rx = 1
```

If valid:

```verilog
data_out <= temp_register;
rdy <= 1'b1;
```

Data reception is complete.

---

# Why 16× Oversampling?

In real systems:

- Transmitter and receiver clocks are not perfectly identical
- Clock drift may occur
- Noise can affect communication

Oversampling improves timing accuracy and communication reliability.

### Basic UART

```text
1 Sample per Bit
```

Advantages:

- Simple implementation

Disadvantages:

- Sensitive to timing mismatches

### Oversampling UART

```text
16 Samples per Bit
```

Advantages:

- Better timing recovery
- Improved noise tolerance
- Reliable bit detection
- Industry-standard UART technique

---

# Simulation Results

### Test Case 1

```text
Input Data  : 8'h55
Output Data : 8'h55
```

Result:

```text
PASS
```

### Test Case 2

```text
Input Data  : 8'hA3
Output Data : 8'hA3
```

Result:

```text
PASS
```

---

# Comparison with Previous UART Projects

| Project | Description |
|----------|-------------|
| UART Basic Loopback | TX and RX use the same baud enable signal |
| UART Baud Mismatch | TX and RX operate at different baud rates causing data corruption |
| UART 16× Oversampling | Receiver samples at 16× baud rate for reliable data recovery |

---

# Key Learning Outcomes

Through this project, the following concepts were explored:

- UART communication protocol
- UART frame structure
- Start and stop bit generation
- Baud rate generation
- Finite State Machine (FSM) design
- Parallel-to-serial conversion
- Serial-to-parallel conversion
- Receiver synchronization
- Oversampling techniques
- Timing recovery mechanisms
- UART loopback communication
- Verification using simulation waveforms

---

# Future Improvements

- Parity Bit Support
- Configurable Baud Rate Selection
- FIFO-Based UART Buffers
- Full-Duplex UART Communication
- Error Detection and Framing Error Checks
- Majority-Voting Oversampling Receiver
- FPGA Hardware Validation