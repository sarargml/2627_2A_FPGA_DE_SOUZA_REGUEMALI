library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library pll;
use pll.all;

entity telecran is
    port (
        -- FPGA
        i_clk_50: in std_logic;

        -- HDMI
        io_hdmi_i2c_scl       : inout std_logic;
        io_hdmi_i2c_sda       : inout std_logic;
        o_hdmi_tx_clk        : out std_logic;
        o_hdmi_tx_d          : out std_logic_vector(23 downto 0);
        o_hdmi_tx_de         : out std_logic;
        o_hdmi_tx_hs         : out std_logic;
        i_hdmi_tx_int        : in std_logic;
        o_hdmi_tx_vs         : out std_logic;

        -- KEYs
        i_rst_n : in std_logic;

        -- LEDs
        o_leds : out std_logic_vector(9 downto 0);
        o_de10_leds : out std_logic_vector(7 downto 0);

        -- EnCoder
        i_left_ch_a : in std_logic;
        i_left_ch_b : in std_logic;
        i_left_pb : in std_logic;
        i_right_ch_a : in std_logic;
        i_right_ch_b : in std_logic;
        i_right_pb : in std_logic
    );
end entity telecran;

architecture rtl of telecran is
    component I2C_HDMI_Config
        port (
            iCLK : in std_logic;
            iRST_N : in std_logic;
            I2C_SCLK : out std_logic;
            I2C_SDAT : inout std_logic;
            HDMI_TX_INT  : in std_logic
        );
    end component;

    component pll
        port (
            refclk : in std_logic;
            rst : in std_logic;
            outclk_0 : out std_logic;
            locked : out std_logic
        );
    end component;

    constant h_res      : natural := 720;
    constant v_res      : natural := 480;
    constant pixel_size : natural := 4;
    constant fb_w       : natural := h_res / pixel_size;   -- 180
    constant fb_h       : natural := v_res / pixel_size;   -- 120


    signal s_clk_27 : std_logic;
    signal s_rst_n  : std_logic;
    signal s_pll_rst : std_logic;

    -- Contadores dos encoders (na grade do framebuffer)
    signal r_left_counter  : natural range 0 to fb_w - 1 := 0;
    signal r_right_counter : natural range 0 to fb_h - 1 := 0;

    -- Controlador HDMI
    signal s_x_counter : natural range 0 to (h_res - 1);
    signal s_y_counter : natural range 0 to (v_res - 1);

    -- Controle do Pixel (na grade do framebuffer)
    signal r_enable_draw_position : std_logic;
    signal s_position_x : natural range 0 to fb_w - 1;
    signal s_position_y : natural range 0 to fb_h - 1;

    -- Framebuffer (1 bit por posicao)
    signal s_wr_addr : natural range 0 to (fb_w * fb_h - 1);
    signal s_rd_addr : natural range 0 to (fb_w * fb_h - 1);
    signal s_rd_data : std_logic_vector(0 downto 0);
    signal s_wr_data : std_logic_vector(0 downto 0);

    -- Limpeza da tela (varre toda a RAM escrevendo 0)
    signal s_pb_pressed  : std_logic;
    signal r_pb_sync0    : std_logic := '0';   -- '1' = botao apertado
    signal r_pb_sync1    : std_logic := '0';
    signal r_pb_prev     : std_logic := '0';
    signal r_clearing    : std_logic := '1';
    signal r_clear_addr  : natural range 0 to (fb_w * fb_h - 1) := 0;

begin
    o_de10_leds <= (others => '0');
    o_leds      <= (others => '0');

    -- PLL: 27 MHz para o HDMI
    s_pll_rst <= not i_rst_n;

    pll0 : component pll
        port map (
            refclk   => i_clk_50,
            rst      => s_pll_rst,
            outclk_0 => s_clk_27,
            locked   => s_rst_n
        );

    -- Configura o ADV7513 para 480p
    I2C_HDMI_Config0 : component I2C_HDMI_Config
        port map (
            iCLK        => i_clk_50,
            iRST_N      => i_rst_n,
            I2C_SCLK    => io_hdmi_i2c_scl,
            I2C_SDAT    => io_hdmi_i2c_sda,
            HDMI_TX_INT => i_hdmi_tx_int
        );

    -- Encoders (no mesmo clock da RAM, para evitar escrita espuria por glitch)
    -- Esquerdo = horizontal (0..fb_w-1)
    encoder1 : entity work.encoder
        generic map (
            e_size => fb_w - 1
        )
        port map (
            i_clk     => s_clk_27,
            i_rst_n   => i_rst_n,
            i_A       => i_left_ch_a,
            i_B       => i_left_ch_b,
            o_led     => open,
            o_counter => r_left_counter
        );

    -- Direito = vertical (0..fb_h-1)
    encoder2 : entity work.encoder
        generic map (
            e_size => fb_h - 1
        )
        port map (
            i_clk     => s_clk_27,
            i_rst_n   => i_rst_n,
            i_A       => i_right_ch_a,
            i_B       => i_right_ch_b,
            o_led     => open,
            o_counter => r_right_counter
        );

    -- Controlador HDMI (480p)
    hdmi_controler0 : entity work.hdmi_controler
        generic map (
            h_res => h_res,
            v_res => v_res
        )
        port map (
            i_clk           => s_clk_27,
            i_rst_n         => s_rst_n,
            o_hdmi_hs       => o_hdmi_tx_hs,
            o_hdmi_vs       => o_hdmi_tx_vs,
            o_hdmi_de       => o_hdmi_tx_de,
            o_pixel_en      => open,
            o_pixel_address => open,
            o_x_counter     => s_x_counter,
            o_y_counter     => s_y_counter
        );

    -- Clock de pixel do ADV7513
    o_hdmi_tx_clk <= s_clk_27;

    -- Posicao do estilete
    s_position_x <= r_left_counter;
    s_position_y <= r_right_counter;

    -- Botao do encoder esquerdo apaga a tela
    s_pb_pressed <= '1' when (i_left_pb = '0') else '0';

    process(s_clk_27, s_rst_n)
    begin
        if (s_rst_n = '0') then
            r_pb_sync0   <= '0';
            r_pb_sync1   <= '0';
            r_pb_prev    <= '0';
            r_clearing   <= '1';     
            r_clear_addr <= 0;
        elsif rising_edge(s_clk_27) then
            r_pb_sync0 <= s_pb_pressed;
            r_pb_sync1 <= r_pb_sync0;
            r_pb_prev  <= r_pb_sync1;

            if (r_pb_sync1 = '1' and r_pb_prev = '0') then
                r_clearing   <= '1';
                r_clear_addr <= 0;
            elsif (r_clearing = '1') then
                if (r_clear_addr = fb_w * fb_h - 1) then
                    r_clearing   <= '0';
                    r_clear_addr <= 0;
                else
                    r_clear_addr <= r_clear_addr + 1;
                end if;
            end if;
        end if;
    end process;

    s_wr_addr <= r_clear_addr when (r_clearing = '1') else
                 s_position_y * fb_w + s_position_x;
    s_wr_data <= "0" when (r_clearing = '1') else "1";

    s_rd_addr <= (s_y_counter / pixel_size) * fb_w + (s_x_counter / pixel_size);

    framebuffer : entity work.dpram
        generic map (
            mem_size   => fb_w * fb_h,
            data_width => 1
        )
        port map (
            i_clk_a  => s_clk_27,
            i_clk_b  => s_clk_27,
            i_data_a => s_wr_data,
            i_data_b => "0",
            i_addr_a => s_wr_addr,
            i_addr_b => s_rd_addr,
            i_we_a   => '1',
            i_we_b   => '0',
            o_q_a    => open,
            o_q_b    => s_rd_data
        );

    r_enable_draw_position <= '1' when ((s_x_counter / pixel_size) = s_position_x) and
                                       ((s_y_counter / pixel_size) = s_position_y) else '0';

        o_hdmi_tx_d <= x"000000" when (s_rd_data(0) = '1') else x"C1E1C1";


end architecture rtl;
