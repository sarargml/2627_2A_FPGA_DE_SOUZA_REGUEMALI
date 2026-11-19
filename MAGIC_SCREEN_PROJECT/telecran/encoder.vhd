library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity encoder is
    generic(
        e_size : positive := 9
    );
    port (
        i_clk   : in std_logic;
        i_rst_n : in std_logic;

        i_A     : in std_logic;
        i_B     : in std_logic;
        o_led   : out std_logic_vector (9 downto 0);
		o_counter : out natural
    );
end entity encoder;

architecture rtl of encoder is

    -- Sinais para sincronização e amostragem
    signal r_tick      : std_logic := '0';
    signal r_A_sync0   : std_logic := '0';
    signal r_A_sync1   : std_logic := '0';
    signal r_B_sync0   : std_logic := '0';
    signal r_B_sync1   : std_logic := '0';

    signal prev_A      : std_logic := '0';
    signal prev_B      : std_logic := '0';
    signal r_edge_A    : std_logic := '0';
    signal r_edge_B    : std_logic := '0';

    signal increment_enable : std_logic := '0';
    signal decrement_enable : std_logic := '0';

    signal r_counter : natural range 0 to e_size := 0;

begin

    process(i_clk, i_rst_n)
        variable counter : natural range 0 to 1000000 := 0;
    begin
        if (i_rst_n = '0') then
            counter := 0;
            r_tick <= '0';
        elsif rising_edge(i_clk) then
            if (counter = 5000) then 
                counter := 0;
                r_tick <= '1';
            else
                counter := counter + 1;
                r_tick <= '0';
            end if;
        end if;
    end process;

    
    process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_A_sync0 <= '0';
            r_A_sync1 <= '0';
            r_B_sync0 <= '0';
            r_B_sync1 <= '0';
            prev_A    <= '0';
            prev_B    <= '0';
            r_edge_A  <= '0';
            r_edge_B  <= '0';
        elsif rising_edge(i_clk) then
           
            r_A_sync0 <= i_A;
            r_B_sync0 <= i_B;

            if (r_tick = '1') then
                r_A_sync1 <= r_A_sync0;
                r_B_sync1 <= r_B_sync0;

                prev_A    <= r_A_sync1;
                prev_B    <= r_B_sync1;

                r_edge_A  <= (not prev_A) and r_A_sync1;
                r_edge_B  <= (not prev_B) and r_B_sync1;
            else
                r_edge_A  <= '0';
                r_edge_B  <= '0';
            end if;
        end if;
    end process;

    increment_enable <= r_edge_A and (not r_B_sync1);
    decrement_enable <= r_edge_B and (not r_A_sync1);

    process(i_clk, i_rst_n)
    begin
        if (i_rst_n = '0') then
            r_counter <= 0;
        elsif rising_edge(i_clk) then
            if (increment_enable = '1' and decrement_enable = '0') then
                if (r_counter < e_size) then
                    r_counter <= r_counter + 1;
                end if;
            elsif (decrement_enable = '1' and increment_enable = '0') then
                if (r_counter > 0) then
                    r_counter <= r_counter - 1;
                end if;
            end if;
        end if;
    end process;

    -- 5. Acionamento dos LEDs
    o_led <= std_logic_vector(shift_left(to_unsigned(1, 10), r_counter));
	 o_counter <= r_counter;

end architecture rtl;