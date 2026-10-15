# Magic Screen — FPGA Lab Report

Authors: DE SOUZA Luis Henrique
REGUEMALI Sara


## Objective

Build a digital Etch A Sketch on the DE10-Nano board: two rotary encoders control the cursor position, a memory stores the drawing, and a button clears the screen.


## Progress

- [ ] 1. Encoder management
- [ ] 2. HDMI controller
- [ ] 3. Moving a pixel
- [ ] 4. Drawing memory
- [ ] 5. Clearing the screen

## 1. Encoder Management

### Objective

Design a counter with a configurable bit width that increments or decrements according to the direction of rotation. Initial validation uses a 10-bit counter and the board LEDs.

### Operating Principle and Circuit Diagram

To be completed: operation of channels A and B, edge detection, counting conditions, and circuit diagram.

### VHDL Implementation

To be completed: component interface, counter width, clock, reset, and behavior at the counter limits.

### Simulation

Status: not yet performed.

| Planned test | Expected result | Observed result |
| --- | --- | --- |
| Reset | Counter set to zero | To be completed |
| Rotation in one direction | Counter increments | To be completed |
| Rotation in the opposite direction | Counter decrements | To be completed |
| Stationary encoder | Counter remains unchanged | To be completed |
| Counting beyond the limits | According to the chosen boundary behavior | To be completed |

Include simulation waveforms and explain the significant transitions.

### Hardware Validation

Status: not yet performed.

To be completed: connections, LED observations, issues encountered, and corrections.

## 2. HDMI Controller

The diagram uses two D flip-flops connected in series and driven by the same clock CLK. At each rising edge of CLK:

- The first flip-flop samples input "A", producing "Acourant".
- The second flip-flop stores the previous value of the first, producing "Aprev".

Comparing these two values detects a transition:

| Aprev | Acourant | Interpretation |
|---|---|---|
| 0 | 0 | No change |
| 0 | 1 | Rising edge |
| 1 | 0 | Falling edge |
| 1 | 1 | No change |

A rising edge is detected when the current sample is high and the previous sample is low:


E_rising = Acourant AND NOT Aprev


A falling edge is detected when the current sample is low and the previous sample is high:


E_falling = NOT Acourant AND Aprev


The block marked "???" therefore contains an AND gate and an inverter, connected according to the desired edge. Each detected transition generates a pulse lasting one clock period.

## 3. Moving a Pixel

To be completed 

## 4. Drawing Memory

To be completed 

## 5. Clearing the Screen

To be completed 

## Conclusion

To be completed



