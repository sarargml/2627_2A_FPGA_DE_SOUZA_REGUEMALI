# FPGA Lab — DE SOUZA & REGUEMALI

## Objective

This report presents the design of digital circuits in VHDL, their compilation using Quartus Prime, and their validation on an FPGA board.

## Hardware and Software

**Software:** Quartus Prime
**Board:** DE10-Nano with the Télécran mezzanine board
**Target FPGA:** 5CSEBA6U23I7
**Language:** VHDL

## 1. Controlling an LED with a Push Button

### Objective

Control LED0 using the push button on the left rotary encoder.


### Results and Observations

After compiling the code and defining the pins, the push button does indeed control the LED0. 

After changing the line:

led0 <= push;

into

led <= not push;

we have managed to invert the behaviour of the LED so that it is on by default and turns off when the encoder is pressed

## 2. Blinking an LED
The clock named FPGA_CLK1_50 connected on **PIN_V11**

*To be completed: circuit diagram, clock and reset roles, counter design, blinking frequency, and test results.*

## 3. LED Chaser

*To be completed: operating principle, VHDL code, circuit diagram, and validation on the board.*

## Conclusion

*To be written at the end of the lab: skills acquired, difficulties encountered, and solutions implemented.*

## Reference

[FPGA Lab Instructions](https://github.com/lfiack/ENSEA_2A_FPGA_Public/blob/main/mineure/3-tp/fpga_tp.md)
