# FPGA Lab : DE SOUZA & REGUEMALI

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

After compiling the following code which makes the LED blink:

``` library ieee;
use ieee.std_logic_1164.all;

entity led_blink is
    port (
        i_clk : in std_logic;
        i_rst_n : in std_logic;
        o_led : out std_logic
    );
end entity led_blink;

architecture rtl of led_blink is
    signal r_led : std_logic := '0';
begin
    process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_led <= '0';
        elsif (rising_edge(i_clk)) then
            r_led <= not r_led;
        end if;
    end process;
    o_led <= r_led;
end architecture rtl;
```

We should obtain the following diagram: 

<img width="1600" height="800" alt="WhatsApp Image 2026-10-01 at 09 21 13" src="https://github.com/user-attachments/assets/3993c9c2-4360-426e-8d45-d3c18feb726c" />


The diagram proposed by Quartus is the following one:

<img width="1502" height="817" alt="WhatsApp Image 2026-10-01 at 08 58 42" src="https://github.com/user-attachments/assets/1a5cd2d6-746b-4b62-86c4-9eadc0411a3d" />


The previous program toggles `r_led` on every rising edge of the clock. With a 50 MHz clock, the LED changes state every 20 ns, corresponding to a full blinking period of 40 ns (25 MHz). This is too fast for the human eye to perceive.

The following code dds a counter that waits for a large number of clock cycles before generating an enable signal. This allows the LED to toggle much more slowly.

``` process(i_clk, i_rst_n)
    variable counter : natural range 0 to 5000000 := 0;
begin
    if (i_rst_n = '0') then
        counter := 0;
        r_led_enable <= '0';
    elsif (rising_edge(i_clk)) then
        if (counter = 5000000) then
            counter := 0;
            r_led_enable <= '1';
        else
            counter := counter + 1;
            r_led_enable <= '0';
        end if;
    end if;
end process; 
```

Here is the hand-drawn diagram for the new code:

<img width="1600" height="1116" alt="WhatsApp Image 2026-10-01 at 10 33 50" src="https://github.com/user-attachments/assets/fdf77449-5562-4d9d-8605-901f9485718a" />




We compare it with the one in the RTL Viewer:

<img width="1515" height="388" alt="image" src="https://github.com/user-attachments/assets/a313c247-b2c5-4b7e-bd55-f195eebcaf28" />




Lastly, the suffix `_n` indicates that the reset is active-low: it is asserted when `i_rst_n = '0'` and released when `i_rst_n = '1'`.

This matches the KEY0 push button, which outputs a logic 0 when pressed. Pressing the button therefore resets the circuit. The naming convention makes the signal’s active level explicit.

## 3. Chaser!

Our next objective is to design our own component: an LED chaser

We want to move a single lit LED through eight positions at an adjustable speed. The commented VHDL code is provided below and filed as blink_led.vhd as well:

```
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity blink_led is
    port (
        i_clk : in std_logic;
        i_rst_n : in std_logic;
        o_led : out std_logic_vector (9 downto 0)
    );
end entity blink_led;

architecture rtl of blink_led is
	 signal r_led_enable : std_logic := '0';
	 signal r_led_index : integer range 0 to 9 := 0;

begin

	--Frequency divisor
	 process(i_clk, i_rst_n)
		variable counter : natural range 0 to 5000000 := 0;
	begin
		if (i_rst_n = '0') then
        counter := 0;
        r_led_enable <= '0';
		elsif (rising_edge(i_clk)) then
        if (counter = 5000000) then
            counter := 0;
            r_led_enable <= '1';
        else
            counter := counter + 1;
            r_led_enable <= '0';
        end if;
		end if;
	end process;
	 
	 
	-- LED Index Adder
	process(i_clk, i_rst_n)
	begin
		if(i_rst_n = '0') then
			r_led_index <= 0; 
			
	   elsif (rising_edge(i_clk)) then
		
				if(r_led_enable = '1') then
				
						if(r_led_index < 9) then
							r_led_index<= r_led_index+1;
						else
							r_led_index<=0;
						end if;
	
					end if;
        end if;
	
	end process;
   
		-- LED Shift
    o_led <= std_logic_vector(shift_left(to_unsigned(1,10),r_led_index));
	 
	
	 
	 
end architecture rtl;
```





