# I2C Protocol

## 1. Introduction

I2C (Inter-Integrated Circuit) is a synchronous, multi-device serial communication protocol that uses two shared signals:

- **SDA** — Serial Data
- **SCL** — Serial Clock

In this project, an **I2C Master Controller** is implemented using Verilog RTL. The current implementation supports basic single-byte READ and WRITE transactions.

---

## 2. I2C Signals

| Signal | Name | Description |
|---|---|---|
| SDA | Serial Data | Carries address, data, ACK/NACK |
| SCL | Serial Clock | Synchronizes data transfer |

Both SDA and SCL use an **open-drain/open-collector style interface** with pull-up resistors.

### Open-Drain Operation

The device does not actively drive the bus HIGH.

```text
Drive LOW  → Signal = 0
Release    → Pull-up makes Signal = 1
```

For SDA:

```text
sda_drive_low = 1 → SDA = LOW
sda_drive_low = 0 → SDA released → SDA = HIGH
```

This allows the master and slave to safely share the same bus.

---

## 3. I2C Bus Idle Condition

When the I2C bus is idle:

```text
SCL = HIGH
SDA = HIGH
```

Both lines are HIGH because they are released and pulled up.

```text
SCL ───────────────── HIGH
SDA ───────────────── HIGH
```

---

## 4. START Condition

An I2C START condition occurs when:

```text
SCL = HIGH
SDA changes HIGH → LOW
```

The master generates the START condition before every transaction.

```text
SCL  ──────────────── HIGH ─────────────
SDA  ────────────┐
                 └──────── LOW
                  ↑
                START
```

After START, the master begins transmitting the address.

---

## 5. STOP Condition

An I2C STOP condition occurs when:

```text
SCL = HIGH
SDA changes LOW → HIGH
```

The master generates STOP after completing the transaction.

```text
SCL  ─────────────── HIGH ───────────────
SDA  ──────── LOW ───────┐
                         └──── HIGH
                           ↑
                          STOP
```

---

## 6. Data Transfer

I2C transfers data **one bit at a time**, with the most significant bit (MSB) transmitted first.

The important timing rule is:

> SDA may change while SCL is LOW, but SDA must remain stable while SCL is HIGH during normal data transfer.

### Data Bit = 1

```text
SCL     ____|‾‾‾‾|____
SDA     ‾‾‾‾|‾‾‾‾|‾‾‾‾
            ↑
          Sample
```

### Data Bit = 0

```text
SCL     ____|‾‾‾‾|____
SDA     ____|_____|____
            ↑
          Sample
```

Therefore:

```text
SCL LOW  → Prepare/change SDA
SCL HIGH → Receiver samples SDA
```

SDA being HIGH while SCL is LOW is completely valid.

---

## 7. Address Format

This project uses the standard **7-bit I2C address format**.

The first transmitted byte contains:

```text
7-bit Address + R/W bit
```

For example:

```text
Address = 1010000
```

### WRITE

For WRITE:

```text
R/W = 0
```

Therefore:

```text
1010000 + 0
```

becomes:

```text
10100000
```

### READ

For READ:

```text
R/W = 1
```

Therefore:

```text
1010000 + 1
```

becomes:

```text
10100001
```

---

## 8. ACK and NACK

After every group of 8 transmitted bits, the receiver provides an acknowledgment bit.

### ACK

ACK is represented by:

```text
SDA = LOW
```

during the ninth clock pulse.

For an address transfer:

```text
Address + R/W
       ↓
    8 bits
       ↓
     ACK
```

### NACK

NACK is represented by:

```text
SDA = HIGH
```

during the ninth clock pulse.

A NACK can indicate that:

- The slave did not respond.
- The receiver does not want more data.
- A READ transaction has reached its final byte.

---

## 9. WRITE Transaction

During a WRITE transaction, the master sends data to the slave.

The basic sequence is:

```text
START
   ↓
7-bit Address + WRITE
   ↓
Slave ACK
   ↓
8-bit Data
   ↓
Slave ACK
   ↓
STOP
```

### Example

The current testbench uses:

```text
Address = 1010000
R/W     = 0
Data    = 10100101
```

The transaction becomes:

```text
START
   ↓
10100000
   ↓
ACK
   ↓
10100101
   ↓
ACK
   ↓
STOP
```

### Direction

```text
Master ───────────────→ Slave
        Address/Data
```

---

## 10. READ Transaction

During a READ transaction, the master requests data from the slave.

The basic sequence is:

```text
START
   ↓
7-bit Address + READ
   ↓
Slave ACK
   ↓
Slave sends 8-bit Data
   ↓
Master NACK
   ↓
STOP
```

### Example

The current READ testbench uses:

```text
Address = 1010000
R/W     = 1
```

The simulated slave returns:

```text
11001100
```

Therefore:

```text
START
   ↓
10100001
   ↓
ACK
   ↓
11001100
   ↓
NACK
   ↓
STOP
```

### Direction

```text
Master ───────→ Slave
       Address

Slave ─────────→ Master
       Data
```

---

## 11. MSB-First Transmission

I2C transmits the most significant bit first.

For example:

```text
Data = 10100101
```

The transmission order is:

```text
1 → 0 → 1 → 0 → 0 → 1 → 0 → 1
```

Similarly:

```text
11001100
```

is transmitted as:

```text
1 → 1 → 0 → 0 → 1 → 1 → 0 → 0
```

---

## 12. I2C Clock Generation

The RTL design uses a system clock and generates a clock-enable `tick` for I2C SCL generation.

Current simulation configuration:

```text
System Clock = 1 MHz
I2C Clock    = 100 kHz
```

The clock generator calculates the number of system-clock cycles required for half an I2C clock period.

```text
HALF_PERIOD = CLK_FREQ / (2 × I2C_FREQ)
```

For the current configuration:

```text
HALF_PERIOD = 1,000,000 / (2 × 100,000)
            = 5
```

Therefore:

```text
5 system-clock cycles
        ↓
      tick
        ↓
SCL toggles
```

---

## 13. Current RTL Architecture

The current implementation contains two RTL modules:

### `i2c_clk_gen.v`

Generates the timing tick used by the I2C master.

```text
System Clock
     │
     ▼
i2c_clk_gen
     │
     ▼
   tick
```

### `i2c_master.v`

Controls the complete I2C transaction.

```text
start
  │
  ▼
I2C Master FSM
  │
  ├── START
  ├── SEND ADDRESS
  ├── ADDRESS ACK
  ├── WRITE DATA
  ├── WRITE ACK
  ├── READ DATA
  ├── READ ACK/NACK
  └── STOP
```

---

## 14. Basic I2C Master FSM

The master controller uses an FSM to control the transaction.

### WRITE Path

```text
IDLE
  ↓
START
  ↓
SEND_ADDR
  ↓
ADDR_ACK
  ↓
WRITE_DATA
  ↓
WRITE_ACK
  ↓
STOP
  ↓
DONE
  ↓
IDLE
```

### READ Path

```text
IDLE
  ↓
START
  ↓
SEND_ADDR
  ↓
ADDR_ACK
  ↓
READ_DATA
  ↓
READ_ACK/NACK
  ↓
STOP
  ↓
DONE
  ↓
IDLE
```

---

## 15. Verification

Two dedicated testbenches are used for the current implementation.

```text
Testbench/
├── i2c_write_tb.v
└── i2c_read_tb.v
```

### WRITE Verification

The WRITE testbench verifies:

- START condition
- Address transmission
- WRITE bit
- Address ACK
- Data transmission
- Data ACK
- STOP condition
- Transfer completion
- ACK error status

### READ Verification

The READ testbench verifies:

- START condition
- Address transmission
- READ bit
- Address ACK
- Slave data transmission
- Master data reception
- Final NACK
- STOP condition
- Transfer completion
- Received data

The simulated slave transmits:

```text
11001100
```

and the master successfully receives:

```text
rx_data = 11001100
```

which is:

```text
204 decimal
```

---

## 16. Current Implementation Status

| Feature | Status |
|---|:---:|
| I2C Clock Generation | ✅ |
| START Condition | ✅ |
| STOP Condition | ✅ |
| 7-bit Addressing | ✅ |
| READ/WRITE Selection | ✅ |
| Address ACK | ✅ |
| Address NACK Detection | ✅ |
| Single-byte WRITE | ✅ |
| Single-byte READ | ✅ |
| Data ACK | ✅ |
| Final READ NACK | ✅ |
| Open-Drain SDA | ✅ |
| Open-Drain SCL | ✅ |
| Basic Error Detection | ✅ |
| Transfer Completion | ✅ |

---

## 17. Future Enhancements

The current implementation represents the **basic READ/WRITE stage** of the I2C Master Controller.

Future versions will add:

- Clock stretching
- Repeated START
- Improved bus monitoring
- Multi-byte transfers
- Improved interrupt support
- Better error handling
- More comprehensive verification

---

## Summary

The current RTL implements a basic I2C Master capable of performing single-byte READ and WRITE transactions.

The design demonstrates the fundamental I2C concepts:

```text
START
  ↓
ADDRESS + R/W
  ↓
ACK
  ↓
DATA
  ↓
ACK/NACK
  ↓
STOP
```

The design is being developed incrementally, with additional I2C features planned for future stages.
