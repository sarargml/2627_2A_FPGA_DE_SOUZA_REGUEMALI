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

This part of the project involves implementing the HDMI controller designed during the tutorial session. We add the `hdmi_controler.vhd` file to the project and connect the pixel coordinate outputs to the `x` and `y` counters. We then instantiate the `hdmi_controler` component in the top-level file, `telecran.vhd`.

<img width="787" height="402" alt="image" src="https://github.com/user-attachments/assets/ae9c0233-05c9-43e9-a459-5ba068ec2ec2" />



In the configuration shown above, each color channel (red, green, and blue, or RGB) is encoded using 8 bits. 

After adding the adapter in VLC and compiling the project, we obtain the following result:

<img width="646" height="591" alt="image" src="https://github.com/user-attachments/assets/58561fd6-5b4f-4080-968a-2ba87faba1e2" />


## 3. Moving a Pixel

At this stage of the project, we display a single pixel whose position is controlled by two encoders. The left encoder moves the pixel horizontally, and the right encoder moves it vertically.

Only the relevant sections of telecran.vhd are show



<img width="1022" height="166" alt="image" src="https://github.com/user-attachments/assets/53ae6a55-d0a6-45e5-9e84-3e148511df5f" />



The pixel is displayed as such:

<img width="637" height="593" alt="image" src="https://github.com/user-attachments/assets/18bb5ebd-55c9-4405-8efc-4fa0a102a261" />



We also chose to change colours for better visualisation:


<img width="640" height="592" alt="image" src="https://github.com/user-attachments/assets/3f39acfb-d8da-432e-a097-60893946c2ce" />



## 4. Drawing Memory

The goal of this stage is to store the pixels visited by the cursor so that its path remains visible, just like on a real Etch A Sketch. We use a framebuffer to store the pixels that have already been lit. The file `dpram.vhd` provides the VHDL implementation of a dual-port RAM.

Dual-port RAM (DPRAM, short for *dual-port random-access memory*) has two independent ports. In the implementation used here, both ports can read from memory, and one can also write to it. Each port has its own clock, address, and associated control signals. This allows two processes, such as updating the drawing and refreshing the display, to run concurrently.

In our project, the DPRAM serves as a framebuffer, storing the pixels to be displayed on the screen.

- **Port A** handles writes. It stores a white pixel at the cursor’s new position whenever the cursor moves. When the entire screen is cleared, it writes black pixels across the framebuffer.
- **Port B** continuously reads the framebuffer to supply pixel data to the HDMI display.
- **A multiplexer** selects whether port A receives the cursor’s pixel position and drawing data or the address and data used to clear the screen.

This allows the HDMI display to refresh continuously while the user draws or clears the screen.



<img width="597" height="845" alt="image" src="https://github.com/user-attachments/assets/73164655-c4a6-4473-a3ee-153d26725791" />

We have managed to do the memorisation and the obtain resulted is shown below:


<img width="1226" height="917" alt="image" src="https://github.com/user-attachments/assets/76bcb826-713c-4816-b022-c1d4c856b9c2" />

<img width="823" height="877" alt="image" src="https://github.com/user-attachments/assets/6a93a91c-f5fd-426b-a84f-3f1e4d1e9874" />







## 5. Clearing the Screen

When the user presses the clear button, an address counter steps through the framebuffer and writes a `0` to each address, turning every stored pixel black. During this operation, a multiplexer routes the counter address and the value `0` to the RAM’s write port. The HDMI controller continues reading from the other port, so the display keeps refreshing. Once the last address has been cleared, the write port switches back to the cursor so the user can draw again.

<img width="475" height="581" alt="image" src="https://github.com/user-attachments/assets/7d9054c7-0f4b-40c9-955d-de17e9d1387c" />


This process controls screen clearing. It synchronizes the left encoder button with the 27 MHz clock and detects when the button is pressed. At startup or after a button press, it sets `r_clearing` and starts at framebuffer address `0`. The address advances on each clock cycle so the write logic can set each pixel to black. After the last address is reached, the process ends clearing and normal drawing resumes.


## Conclusion

In this project, we developed a digital Etch A Sketch on the DE10-Nano using VHDL. We first tested the rotary encoder counter in simulation and on the board, then integrated two encoders to control the horizontal and vertical positions of a cursor displayed over HDMI. Adding a dual-port RAM as a framebuffer allowed us to store the pixels visited by the cursor so that its path remained visible as it moved. The two memory ports allow the HDMI controller to refresh the display while the drawing is updated. The final step is to validate the screen-clearing function on the board by checking that pressing the button clears the entire framebuffer and that drawing can resume afterward.



