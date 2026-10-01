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