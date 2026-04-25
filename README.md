# Elevator Controller — VHDL 🏢

> A fully synthesizable multi-floor elevator controller implemented in VHDL and deployed on the **Altera DE1-SoC (Cyclone V FPGA)**

![VHDL](https://img.shields.io/badge/Language-VHDL-blue?style=flat-square)
![FPGA](https://img.shields.io/badge/Board-DE1--SoC-orange?style=flat-square)
![Device](https://img.shields.io/badge/Device-Cyclone%20V%205CSEMA5F31C6-green?style=flat-square)
![Tool](https://img.shields.io/badge/Tool-Quartus%20Prime-red?style=flat-square)
![State Diagram](docs/state_diagram.png)

---

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [System Architecture](#system-architecture)
- [Module Descriptions](#module-descriptions)
- [State Machine](#state-machine)
- [Scheduling Algorithm](#scheduling-algorithm)
- [How to Use (Hardware)](#how-to-use-hardware)
- [Testbench](#testbench)
- [Pin Mapping (DE1-SoC)](#pin-mapping-de1-soc)
- [File Structure](#file-structure)

---

## Overview

This project implements a real-time elevator control system in VHDL, synthesized and tested on the Altera DE1-SoC development board. The system manages floor requests from button presses, moves the elevator up or down one floor at a time, opens the door upon arrival, then services the next pending request — all driven by a hardware clock and displayed on the board's 7-segment display.

| Property         | Value                         |
| ---------------- | ----------------------------- |
| Target Device    | Cyclone V — 5CSEMA5F31C6      |
| Board            | Altera DE1-SoC                |
| Number of Floors | 10 (configurable via generic) |
| Clock Input      | 50 MHz (divided internally)   |
| Display          | 7-segment (HEX0)              |
| Scheduling       | SCAN (elevator algorithm)     |

---

## Features

- **Configurable floor count** via VHDL generic `n` (default: 10 floors, 0–9)
- **SCAN scheduling** — services requests in the current direction first, then reverses, minimizing travel time
- **Clock divider** — reduces the 50 MHz board clock to a human-observable rate for floor movement and door timing
- **7-segment display** — shows the current floor number in real time
- **LED indicators** — separate LEDs signal moving up, moving down, and door open states
- **Active-low push button** input with debounce-friendly latching
- **Self-checking VHDL testbench** with pass/fail reporting and 7-segment output verification

---

## System Architecture

The design is split into three independent, composable components:

```
┌─────────────────────────────────────────────┐
│               elevator_ctrl                  │  Top-level entity
│                                             │
│  ┌─────────────┐      ┌──────────────────┐  │
│  │   RESOLVER  │      │       ssd        │  │
│  │             │      │  (7-seg decoder) │  │
│  │  Floor Scan │      │                  │  │
│  │  Scheduler  │      │  bin → seg[6:0]  │  │
│  └─────────────┘      └──────────────────┘  │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │           Main FSM Process           │   │
│  │  idle → moving_up / moving_down      │   │
│  │       → door_op → door_close → idle  │   │
│  └──────────────────────────────────────┘   │
│                                             │
│  ┌──────────────────────────────────────┐   │
│  │         Clock Divider Process        │   │
│  │  50 MHz → clk_en (configurable)      │   │
│  └──────────────────────────────────────┘   │
└─────────────────────────────────────────────┘
```

---

## Module Descriptions

### `elevator_ctrl` — Top-Level Controller

The main entity that ties everything together. It contains:

- A **clock divider** that generates a `clk_en` enable signal to slow the system clock to a usable rate for simulation and synthesis.
- A **main FSM process** that drives the elevator through its five states.
- Instantiations of the `RESOLVER` and `ssd` components.

**Ports:**

| Port        | Direction | Width | Description                                   |
| ----------- | --------- | ----- | --------------------------------------------- |
| `clk`       | IN        | 1     | 50 MHz system clock                           |
| `rst`       | IN        | 1     | Active-low asynchronous reset                 |
| `push`      | IN        | 1     | Active-low button — registers a floor request |
| `bn`        | IN        | 4     | Floor number to request (binary encoded, 0–9) |
| `mv_up`     | OUT       | 1     | High when elevator is moving up               |
| `mv_dn`     | OUT       | 1     | High when elevator is moving down             |
| `door_open` | OUT       | 1     | High when door is open                        |
| `floor`     | OUT       | 7     | 7-segment encoded current floor number        |

---

### `RESOLVER` — Floor Request Scheduler

Implements the **SCAN (elevator) algorithm**. Given the current floor, the pending request bitmap, and the current direction of travel, it outputs the next target floor and the next direction.

**Behavior:**

- If moving **up**: scans floors above the current one for pending requests. If none found, reverses and scans downward.
- If moving **down**: scans floors below the current one for pending requests. If none found, reverses and scans upward.
- Outputs are purely **combinational** — they update immediately whenever inputs change.

**Ports:**

| Port           | Direction | Description                                  |
| -------------- | --------- | -------------------------------------------- |
| `CurrentFloor` | IN        | Current floor (integer)                      |
| `Request`      | IN        | Bitmask of pending floor requests (`n` bits) |
| `Direction`    | IN        | Current direction: `'1'` = up, `'0'` = down  |
| `TargetFloor`  | OUT       | Next floor the elevator should travel to     |
| `NextDir`      | OUT       | Direction after reaching the target          |

---

### `ssd` — Seven-Segment Display Decoder

A simple combinational look-up table that converts a 4-bit binary floor number (0–9) into a 7-segment display encoding.

| Input  | Display |
| ------ | ------- |
| `0000` | `0`     |
| `0001` | `1`     |
| ...    | ...     |
| `1001` | `9`     |
| Others | Blank   |

---

## State Machine

The elevator FSM has five states:

```
         ┌─────────────────────────────────────────┐
         │                                         │
         ▼                                         │
    ┌─────────┐   request above    ┌────────────┐  │
    │  idle   │ ─────────────────► │ moving_up  │  │
    │         │                    └─────┬──────┘  │
    │         │   request below    ┌─────▼──────┐  │
    │         │ ─────────────────► │moving_down │  │
    └─────────┘                    └─────┬──────┘  │
         ▲                               │          │
         │                    arrived at target     │
         │                         ▼               │
         │                    ┌─────────┐           │
         │                    │ door_op │           │
         │                    └─────┬───┘           │
         │               timer expires              │
         │                         ▼               │
         │                  ┌────────────┐          │
         └──────────────────│ door_close │──────────┘
                            └────────────┘
          (clears request bit, returns to idle)
```

| State         | Description                                                                         |
| ------------- | ----------------------------------------------------------------------------------- |
| `idle`        | Waiting for a request. Queries the RESOLVER to determine next direction.            |
| `moving_up`   | Increments `CurrentFloor` every `DELAY` ticks. Transitions to `door_op` on arrival. |
| `moving_down` | Decrements `CurrentFloor` every `DELAY` ticks. Transitions to `door_op` on arrival. |
| `door_op`     | Holds the door open for `DELAY` ticks while outputting `door_open = '1'`.           |
| `door_close`  | Clears the request bit for the current floor, then returns to `idle`.               |

---

## Scheduling Algorithm

The RESOLVER uses the **SCAN algorithm** (also known as the elevator algorithm):

1. Continue moving in the current direction, stopping at every requested floor along the way.
2. When no more requests exist in the current direction, reverse and service requests in the opposite direction.

This approach minimizes the total distance traveled compared to a naive FIFO queue, and prevents starvation of requests at either end of the shaft.

**Example:**

```
Current floor: 3  |  Direction: UP  |  Requests: [2, 5, 7, 9]

→ Services: 5, 7, 9  (upward scan)
→ Then reverses: 2   (downward scan)
```

---

## How to Use (Hardware)

### Requirements

- Altera DE1-SoC board
- Quartus Prime (Lite or Standard)
- The provided `.qsf` pin assignment file

### Steps

1. **Open Quartus** and create a new project targeting `5CSEMA5F31C6`.

2. **Add all VHDL source files** to the project:
   - `elevator_ctrl.vhd` (top-level)
   - `RESOLVER.vhd`
   - `ssd.vhd`

3. **Import pin assignments** — in Quartus, go to _Assignments → Import Assignments_ and load the provided `.qsf` file. This maps all ports to the correct DE1-SoC pins.

4. **Compile** the project (`Ctrl+L` or _Processing → Start Compilation_).

5. **Program the board** via _Tools → Programmer_, selecting the generated `.sof` file.

### Controls

| Physical Control         | Function                                                            |
| ------------------------ | ------------------------------------------------------------------- |
| `KEY[3]` (SW pin `rst`)  | Active-low reset — resets elevator to floor 0                       |
| `KEY[2]` (SW pin `push`) | Active-low button — registers the floor request set on the switches |
| `SW[3:0]` (pins `bn`)    | Binary-encoded floor number to request (0–9)                        |
| `LEDR[0]` (`mv_up`)      | Lit when elevator is moving up                                      |
| `LEDR[1]` (`mv_dn`)      | Lit when elevator is moving down                                    |
| `LEDR[2]` (`door_open`)  | Lit when door is open                                               |
| `HEX0` (`floor`)         | Displays the current floor number                                   |

### Requesting a Floor

1. Set `SW[3:0]` to the binary representation of your desired floor (e.g., `0101` for floor 5).
2. Press `KEY[2]` briefly — the request is latched into the request bitmap.
3. Repeat to queue multiple floors.
4. The elevator will service them automatically in SCAN order.

---

## Testbench

The testbench (`elevator_ctrl_tb.vhd`) provides automated simulation with pass/fail output.

### Test Cases

| Test   | Description                           | Expected Result                         |
| ------ | ------------------------------------- | --------------------------------------- |
| Reset  | System reset from power-on            | Floor = 0, all outputs low              |
| Test 1 | Request floor 3 from floor 0          | Elevator moves up, arrives at floor 3   |
| Test 2 | Request floor 7 from floor 3          | Elevator moves up, arrives at floor 7   |
| Test 3 | Request floor 2 from floor 7          | Elevator moves down, arrives at floor 2 |
| Test 4 | Request floors 5 and 9 simultaneously | SCAN services 5 then 9                  |

### Running the Testbench

**In ModelSim / QuestaSim:**

```bash
vlib work
vcom ssd.vhd
vcom RESOLVER.vhd
vcom elevator_ctrl.vhd
vcom elevator_ctrl_tb.vhd
vsim elevator_ctrl_tb
run -all
```

The testbench prints `PASS` or `FAIL` for each test case to the transcript window, along with the expected and received floor number.

### Timing Parameters

The testbench uses compressed timing for fast simulation:

| Parameter         | Testbench Value | Real Equivalent |
| ----------------- | --------------- | --------------- |
| Clock period      | 20 ns           | 50 MHz          |
| Floor travel time | 5 ms            | ~1 second       |
| Door hold time    | 2 ms            | ~0.5 seconds    |

To adjust timing for synthesis, modify `CLK_FREQ` and `DELAY` constants in `elevator_ctrl.vhd`.

---

## Pin Mapping (DE1-SoC)

Key pin assignments from the `.qsf` file:

| Signal       | Pin             | Board Component     |
| ------------ | --------------- | ------------------- |
| `clk`        | `PIN_AF14`      | 50 MHz clock        |
| `rst`        | `PIN_Y16`       | KEY[3] (active low) |
| `push`       | `PIN_W15`       | KEY[2] (active low) |
| `bn[0]`      | `PIN_AB12`      | SW[0]               |
| `bn[1]`      | `PIN_AC12`      | SW[1]               |
| `bn[2]`      | `PIN_AF9`       | SW[2]               |
| `bn[3]`      | `PIN_AF10`      | SW[3]               |
| `mv_up`      | `PIN_V16`       | LEDR[0]             |
| `mv_dn`      | `PIN_W16`       | LEDR[1]             |
| `door_open`  | `PIN_V17`       | LEDR[2]             |
| `floor[0:6]` | `PIN_AE26–AH28` | HEX0 (7-segment)    |

---

## File Structure

```
├── elevator_ctrl.vhd      # Top-level entity — FSM, clock divider, I/O
├── RESOLVER.vhd           # Floor request scheduler (SCAN algorithm)
├── ssd.vhd                # 7-segment display decoder
├── elevator_ctrl_tb.vhd   # Self-checking simulation testbench
├── DE1_SoC.qsf            # Quartus pin assignment file
└── DE1_SoC.sdc            # Timing constraints file
```

---
