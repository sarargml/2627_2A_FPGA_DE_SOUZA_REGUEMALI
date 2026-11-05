# Magic Screen — FPGA Lab Report

Authors: DE SOUZA Luis Henrique
REGUEMALI Sara


## Objective and Project architecture

Build a digital Etch A Sketch on the DE10-Nano board: two rotary encoders control the cursor position, a memory stores the drawing, and a button clears the screen.

**AJOUTER SCHEMA**

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

The rotary encoder provides two digital signals, A and B, shifted in phase. Their transition order indicates the direction of rotation: A leads B in one direction, while B leads A in the opposite direction.

Since these signals are asynchronous to the FPGA clock, each input first passes through a two-stage synchronizer. For a mechanical encoder, a debounce filter is also used to prevent contact bounce from producing unwanted counts.

A simple decoding method consists of detecting each rising edge of signal A and reading the value of signal B at that instant. Depending on B, the decoder generates either an increment pulse or a decrement pulse. The association between the value of B and the direction can be reversed to match the encoder wiring.

These pulses control an unsigned N-bit up/down counter, where N is configurable. The counter is updated on the rising edge of the FPGA clock:

When reset is asserted, the counter is set to zero.

When an increment pulse is generated, the counter increases by one.

When a decrement pulse is generated, the counter decreases by one.

Otherwise, the counter keeps its current value.

For initial validation, N is set to 10 and the counter output is connected to the ten board LEDs, displaying its value in binary. With modulo counting, the value wraps from 1023 to 0 when incrementing and from 0 to 1023 when decrementing.

<img width="1342" height="925" alt="image" src="https://github.com/user-attachments/assets/1595a6ba-2947-4648-8155-7ab163991e59" />



### VHDL Implementation


The encoder interface is implemented using a configurable N-bit unsigned counter. The generic parameter N is set to 10 by default for validation with the board LEDs.

The A and B inputs are synchronized with the FPGA clock using two flip-flops per channel. A register stores the previous synchronized value of A to detect its rising edges. On each detected rising edge, the counter increments when B is low and decrements when B is high. Reversing this convention reverses the counting direction.

The reset input is active high and synchronous: the counter is cleared on the next rising clock edge. Arithmetic uses the `numeric_std` package. The counter wraps automatically at its limits, from the maximum value to zero and vice versa.

<img width="479" height="188" alt="image" src="https://github.com/user-attachments/assets/af200071-5656-4b14-a085-da4ee522a407" />

The circuit uses two D flip-flops connected in series and driven by the same clock. At each rising clock edge, the first flip-flop samples input A, while the second stores the previous output of the first flip-flop.

Let Q1 be the output of the first flip-flop and Q2 the output of the second. Comparing these two successive samples allows an edge to be detected:

- **Rising edge:** Q1 = 1 and Q2 = 0, indicating a transition from 0 to 1. The detection logic is `E_rising = Q1 AND NOT Q2`.
- **Falling edge:** Q1 = 0 and Q2 = 1, indicating a transition from 1 to 0. The detection logic is `E_falling = NOT Q1 AND Q2`.

If Q1 and Q2 are equal, no transition is detected. Each detected edge generates a pulse lasting one clock period. Therefore, the block marked “???” implements an AND gate with one inverted input, chosen according to the edge to be detected.



<img width="653" height="411" alt="image" src="https://github.com/user-attachments/assets/bbd3d706-40a4-4ccf-8a9d-119688f0cb99" />

<img width="475" height="320" alt="image" src="https://github.com/user-attachments/assets/35d3aa23-e00d-4a1c-b038-af29f6186aed" />

<img width="718" height="466" alt="image" src="https://github.com/user-attachments/assets/08afde48-9bb9-443f-a34c-7d23c7a349a2" />




### Simulation



| Planned test | Expected result | Observed result |
| --- | --- | --- |
| Reset | Counter set to zero | The counter initially displays 0, but reset activation is not shown in the provided waveforms.  |
| Rotation in one direction | Counter increments | The counter changes from 0 to 1 following an increment pulse on o_inc. |
| Rotation in the opposite direction | Counter decrements | The counter changes from 1 to 0 for the opposite input transition sequence. |
| Stationary encoder | Counter remains unchanged | The counter remains stable between the observed counting events.|


<img width="712" height="172" alt="image" src="https://github.com/user-attachments/assets/7ba4465d-e7f0-4eb2-9fc0-39a43aca26c2" />

<img width="1022" height="182" alt="image" src="https://github.com/user-attachments/assets/9cbf2a4d-c516-4287-b9e7-035f29a06e32" />






### Hardware Validation

The encoder works effectively

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



