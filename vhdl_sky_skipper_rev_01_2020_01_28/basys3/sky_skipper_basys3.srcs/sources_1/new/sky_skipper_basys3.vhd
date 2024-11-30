----------------------------------------------------------------------------------
-- Company: Red~Bote
-- Engineer: Glenn Neidermeier
-- 
-- Create Date: 11/28/2024 06:47:20 PM
-- Design Name: 
-- Module Name: sky_skipper_basys3 
-- Project Name: Sky skipper by Dar
-- Target Devices: Basys 3 Artix-7 FPGA Trainer Board
-- Tool Versions: 
-- Description: 
--   Sky skipper by Dar port to Basys 3 Artix-7 FPGA Trainer Board
-- Dependencies: 
--   vhdl_sky_skipper_rev_01_2020_01_28.zip
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;
entity sky_skipper_basys3 is
    port (
        clk : in std_logic;

        O_PMODAMP2_AIN : out std_logic;
        O_PMODAMP2_GAIN : out std_logic;
        O_PMODAMP2_SHUTD : out std_logic;

        vga_r : out std_logic_vector (3 downto 0);
        vga_g : out std_logic_vector (3 downto 0);
        vga_b : out std_logic_vector (3 downto 0);
        vga_hs : out std_logic;
        vga_vs : out std_logic;

        ps2_clk : in std_logic;
        ps2_dat : in std_logic;

        sw : in std_logic_vector (15 downto 0));
end sky_skipper_basys3;

architecture struct of sky_skipper_basys3 is

    signal pll_locked : std_logic;
    signal clock_40 : std_logic;
    signal clock_kbd : std_logic;
    signal reset : std_logic;

    signal clock_div : std_logic_vector(3 downto 0);

    signal r : std_logic_vector(2 downto 0);
    signal g : std_logic_vector(2 downto 0);
    signal b : std_logic_vector(1 downto 0);
    signal hsync : std_logic;
    signal vsync : std_logic;
    signal csync : std_logic;
    signal blankn : std_logic;
    signal tv15Khz_mode : std_logic;

    signal audio : std_logic_vector(15 downto 0);
    signal pwm_accumulator : std_logic_vector(17 downto 0);

    signal kbd_intr : std_logic;
    signal kbd_scancode : std_logic_vector(7 downto 0);
    signal joy_BBBBFRLDU : std_logic_vector(8 downto 0);
    signal fn_pulse : std_logic_vector(7 downto 0);
    signal fn_toggle : std_logic_vector(7 downto 0);

    signal dbg_cpu_addr : std_logic_vector(15 downto 0);

    component clk_wiz_0
        port (
            clk_out1 : out std_logic;
            locked : out std_logic;
            clk_in1 : in std_logic
        );
    end component;

begin

    reset <= '0'; -- not reset_n;

    tv15Khz_mode <= '0'; -- not fn_toggle(7); -- F8

    -- Clock 40MHz for Video and CPU board
    clocks : clk_wiz_0
    port map(
        -- Clock out ports  
        clk_out1 => clock_40,
        -- Status and control signals
        locked => pll_locked,
        -- Clock in ports
        clk_in1 => clk
    );

    -- Sjy skipper
    sky_skipper : entity work.sky_skipper
        port map(
            clock_40 => clock_40,
            reset => reset,

            tv15Khz_mode => tv15Khz_mode,
            video_r => r,
            video_g => g,
            video_b => b,
            video_csync => csync,
            video_blankn => blankn,
            video_hs => hsync,
            video_vs => vsync,

            audio_out => audio,

            coin1 => fn_pulse(0), -- F1
            coin2 => fn_pulse(1), -- F2
            start1 => fn_pulse(2), -- F3
            start2 => fn_pulse(3), -- F4

            right1 => joy_BBBBFRLDU(3),
            left1 => joy_BBBBFRLDU(2),
            up1 => joy_BBBBFRLDU(0),
            down1 => joy_BBBBFRLDU(1),
            fire10 => joy_BBBBFRLDU(4),
            fire11 => joy_BBBBFRLDU(5),

            right2 => joy_BBBBFRLDU(3),
            left2 => joy_BBBBFRLDU(2),
            up2 => joy_BBBBFRLDU(0),
            down2 => joy_BBBBFRLDU(1),
            fire20 => joy_BBBBFRLDU(4),
            fire21 => joy_BBBBFRLDU(5),

            --      ...DCBA
            sw1 => not("1111111"), --  n.u.(3b hard wired)  / coinage(DCBA)

            --      PONMLKJI
            sw2 => not("11111101"), -- cocktail(P) / service2(O) / bonus(N) / difficulty(MLK) / lives(IJ)
            -- sw2            => not(sw(7 downto 0)),

            service1 => fn_toggle(6), -- F7

            dbg_cpu_addr => dbg_cpu_addr
        );

    -- adapt video to 4bits/color only and blank
    vga_r <= r & '0' when blankn = '1' else "0000";
    vga_g <= g & '0' when blankn = '1' else "0000";
    vga_b <= b & "00" when blankn = '1' else "0000";

    -- synchro composite/ synchro horizontale
    -- vga_hs <= csync;
    -- vga_hs <= hsync;
    vga_hs <= csync when tv15Khz_mode = '1' else hsync;
    -- commutation rapide / synchro verticale
    -- vga_vs <= '1';
    -- vga_vs <= vsync;
    vga_vs <= '1' when tv15Khz_mode = '1' else vsync;

    -- get scancode from keyboard
    process (reset, clock_40)
    begin
        if reset = '1' then
            clock_div <= (others => '0');
            clock_kbd <= '0';
        else
            if rising_edge(clock_40) then
                if clock_div = "1001" then
                    clock_div <= (others => '0');
                    clock_kbd <= not clock_kbd;
                else
                    clock_div <= clock_div + '1';
                end if;
            end if;
        end if;
    end process;

    keyboard : entity work.io_ps2_keyboard
        port map(
            clk => clock_kbd, -- synchrounous clock with core
            kbd_clk => ps2_clk,
            kbd_dat => ps2_dat,
            interrupt => kbd_intr,
            scancode => kbd_scancode
        );

    -- translate scancode to joystick
    joystick : entity work.kbd_joystick
        port map(
            clk => clock_kbd, -- synchrounous clock with core
            kbdint => kbd_intr,
            kbdscancode => std_logic_vector(kbd_scancode),
            joy_BBBBFRLDU => joy_BBBBFRLDU,
            fn_pulse => fn_pulse,
            fn_toggle => fn_toggle
        );

    -- pwm sound output
    process (clock_40) -- use same clock as Sky skipper core
    begin
        if rising_edge(clock_40) then

            if clock_div = "0000" then
                pwm_accumulator <= ('0' & pwm_accumulator(16 downto 0)) + ('0' & audio & '0');
            end if;

        end if;
    end process;

    --pwm_audio_out_l <= pwm_accumulator(17);
    --pwm_audio_out_r <= pwm_accumulator(17);

    -- active-low shutdown pin
    O_PMODAMP2_SHUTD <= sw(14);
    -- gain pin is driven high there is a 6 dB gain, low is a 12 dB gain 
    O_PMODAMP2_GAIN <= sw(15);

    O_PMODAMP2_AIN <= pwm_accumulator(17);

end struct;
