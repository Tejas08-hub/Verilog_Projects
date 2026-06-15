# UART Baud Mismatch Analysis in Verilog

## Overview

This project investigates the effect of baud-rate mismatch in UART communication. The design uses the same UART Transmitter and Receiver developed in the Basic Loopback project but intentionally configures different baud rates for the transmitter and receiver.

The objective is to observe how timing mismatches affect data integrity and to understand why practical UART receivers require accurate timing synchronization and oversampling techniques.

---

## Project Objective

To study the impact of baud-rate mismatch between UART transmitter and receiver and analyze its effect on received data.

---

## Architecture

```text
                +----------------------+
                | Baud Rate Generator  |
                +----------------------+
                    |           |
                 tx_enb      rx_enb
                    |           |
                    v           v

          +----------------+   +----------------+
          | Transmitter    |-->| Receiver       |
          +----------------+   +----------------+
                    |
                    |
                   tx
```

The transmitter output is directly connected to the receiver input through a loopback connection.

---

## Baud Configuration

In this experiment:

TX Baud Enable:

* Generated every 50 clock cycles

RX Baud Enable:

* Generated every 60 clock cycles

This creates a timing mismatch between transmission and reception.

---

## UART Frame Format

```text
| Start Bit | D0 | D1 | D2 | D3 | D4 | D5 | D6 | D7 | Stop Bit |
|     0     |               8 Data Bits              |     1     |
```

Data is transmitted LSB first.

---

## Modules Used

### Baud Rate Generator

Generates independent enable pulses for:

* Transmitter (`tx_enb`)
* Receiver (`rx_enb`)

Different baud periods are intentionally used to create timing errors.

---

### UART Transmitter

Converts parallel data into serial UART format.

FSM States:

* IDLE
* START
* DATA
* STOP

---

### UART Receiver

Receives serial UART data and reconstructs the original byte.

FSM States:

* IDLE
* START
* DATA
* STOP

---

### UART Top Module

Integrates:

* Baud Rate Generator
* UART Transmitter
* UART Receiver

and performs loopback communication.

---

## Simulation Test Cases

Input Data:

```text
8'h55
8'hA3
```

---

## Observations

When the transmitter and receiver operate at different baud rates:

```text
TX Baud = RX Baud
→ Correct Reception

TX Baud ≠ RX Baud
→ Data Corruption
```

Example observation:

```text
data_in  = 01010101
data_out = 11101001

data_in  = 10100011
data_out = 11111010
```

The received data no longer matches the transmitted data.

---

## Reason for Data Corruption

UART communication depends on the receiver sampling incoming bits at the correct time.

Due to baud-rate mismatch:

* Receiver samples occur earlier or later than expected.
* Some bits are sampled incorrectly.
* Bit positions shift over time.
* The reconstructed byte becomes corrupted.

This phenomenon is known as timing drift.

---

## Engineering Significance

This experiment demonstrates why:

* UART transmitter and receiver must use closely matched baud rates.
* Timing synchronization is critical for reliable communication.
* Practical UART receivers implement oversampling techniques.

---

## Motivation for Oversampling

A simple UART receiver samples only once per bit.

Industrial UART receivers typically use:

* Start-bit detection
* Mid-bit sampling
* 16× oversampling

These techniques allow the receiver to tolerate small baud-rate mismatches and noise.

---

## Results

Simulation successfully demonstrates:

* Correct UART transmission
* Effect of baud-rate mismatch
* Timing drift
* Data corruption caused by incorrect sampling

---

## Future Improvements

* UART Receiver with 16× Oversampling
* Configurable Baud Rate Generator
* Parity Bit Support
* FIFO Integration
* FPGA Hardware Validation

---

## Tools Used

* Verilog HDL
* Xilinx Vivado
* Behavioral Simulation

