---------------------------------------------------------------------------------
-- DE10_lite Top level for Sky skipper by Dar (darfpga@aol.fr) (26/12/2019)
-- http://darfpga.blogspot.fr
---------------------------------------------------------------------------------
--
-- release rev 01 : few change but hardware description
--  (27/01/2020)
--
-- release rev -- : rev 00 release
--  (18/01/2020)
--
-- release rev -- : beta release
--  (12/01/2020)
--
---------------------------------------------------------------------------------
-- Educational use only
-- Do not redistribute synthetized file with roms
-- Do not redistribute roms whatever the form
-- Use at your own risk
---------------------------------------------------------------------------------
-- Use sky_skipper_de10_lite.sdc to compile (Timequest constraints)
-- /!\
-- Don't forget to set device configuration mode with memory initialization 
--  (Assignments/Device/Pin options/Configuration mode)
---------------------------------------------------------------------------------
--
-- Main features :
--  PS2 keyboard input @gpio pins 35/34 (beware voltage translation/protection) 
--  Audio pwm output   @gpio pins 1/3 (beware voltage translation/protection) 
--
--  Video         : VGA 31kHz/60Hz progressive and TV 15kHz interlaced
--  Cocktail mode : NO
--  Sound         : OK
-- 
-- For hardware schematic see my other project : NES
--
-- Uses 1 pll 40MHz from 50MHz to make 20MHz and 8Mhz 
--
-- Board key :
--   0 : reset game
--
-- Keyboard players inputs :
--
--   F1 : Add coin1
--   F2 : Add coin2
--   F3 : Start 1 player
--   F4 : Start 2 players

--   F7 : Service mode
--   F8 : 15kHz interlaced / 31 kHz progressive

--   SPACE  : fire1 (speed up plane)
--   F      : fire2 (bomb)

--   RIGHT arrow : move right
--   LEFT  arrow : move left
--   UP    arrow : up stairs
--   DOWN  arrow : down stairs
--
-- Other details : see sky skipper.vhd
-- For USB inputs and SGT5000 audio output see my other project: xevious_de10_lite
---------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.numeric_std.all;

library work;
--use work.usb_report_pkg.all;

entity sky_skipper_de10_lite is
port(
 max10_clk1_50  : in std_logic;
-- max10_clk2_50  : in std_logic;
-- adc_clk_10     : in std_logic;
 ledr           : out std_logic_vector(9 downto 0);
 key            : in std_logic_vector(1 downto 0);
 sw             : in std_logic_vector(9 downto 0);

-- dram_ba    : out std_logic_vector(1 downto 0);
-- dram_ldqm  : out std_logic;
-- dram_udqm  : out std_logic;
-- dram_ras_n : out std_logic;
-- dram_cas_n : out std_logic;
-- dram_cke   : out std_logic;
-- dram_clk   : out std_logic;
-- dram_we_n  : out std_logic;
-- dram_cs_n  : out std_logic;
-- dram_dq    : inout std_logic_vector(15 downto 0);
-- dram_addr  : out std_logic_vector(12 downto 0);

 hex0 : out std_logic_vector(7 downto 0);
 hex1 : out std_logic_vector(7 downto 0);
 hex2 : out std_logic_vector(7 downto 0);
 hex3 : out std_logic_vector(7 downto 0);
 hex4 : out std_logic_vector(7 downto 0);
 hex5 : out std_logic_vector(7 downto 0);

 vga_r     : out std_logic_vector(3 downto 0);
 vga_g     : out std_logic_vector(3 downto 0);
 vga_b     : out std_logic_vector(3 downto 0);
 vga_hs    : inout std_logic;
 vga_vs    : inout std_logic;
 
-- gsensor_cs_n : out   std_logic;
-- gsensor_int  : in    std_logic_vector(2 downto 0); 
-- gsensor_sdi  : inout std_logic;
-- gsensor_sdo  : inout std_logic;
-- gsensor_sclk : out   std_logic;

-- arduino_io      : inout std_logic_vector(15 downto 0); 
-- arduino_reset_n : inout std_logic;
 
 gpio          : inout std_logic_vector(35 downto 0)
);
end sky_skipper_de10_lite;

architecture struct of sky_skipper_de10_lite is

 signal pll_locked: std_logic;
 signal clock_40  : std_logic;
 signal clock_kbd : std_logic;
 signal reset     : std_logic;
 
 signal clock_div : std_logic_vector(3 downto 0);
 
-- signal max3421e_clk : std_logic;
 
 signal r         : std_logic_vector(2 downto 0);
 signal g         : std_logic_vector(2 downto 0);
 signal b         : std_logic_vector(1 downto 0);
 signal hsync     : std_logic;
 signal vsync     : std_logic;
 signal csync     : std_logic;
 signal blankn    : std_logic;
 signal tv15Khz_mode : std_logic;
 
 signal audio           : std_logic_vector(15 downto 0);
 signal pwm_accumulator : std_logic_vector(17 downto 0);

 alias reset_n         : std_logic is key(0);
 alias ps2_clk         : std_logic is gpio(35); --gpio(0);
 alias ps2_dat         : std_logic is gpio(34); --gpio(1);
 alias pwm_audio_out_l : std_logic is gpio(1);  --gpio(2);
 alias pwm_audio_out_r : std_logic is gpio(3);  --gpio(3);
 
 signal kbd_intr       : std_logic;
 signal kbd_scancode   : std_logic_vector(7 downto 0);
 signal joy_BBBBFRLDU  : std_logic_vector(8 downto 0);
 signal fn_pulse       : std_logic_vector(7 downto 0);
 signal fn_toggle      : std_logic_vector(7 downto 0);

 signal vsync_r        : std_logic;
 
-- signal start : std_logic := '0';
-- signal usb_report : usb_report_t;
-- signal new_usb_report : std_logic := '0';
  
signal dbg_cpu_addr : std_logic_vector(15 downto 0);

begin

reset <= not reset_n;

tv15Khz_mode <= not fn_toggle(7); -- F8

--arduino_io not used pins
--arduino_io(7) <= '1'; -- to usb host shield max3421e RESET
--arduino_io(8) <= 'Z'; -- from usb host shield max3421e GPX
--arduino_io(9) <= 'Z'; -- from usb host shield max3421e INT
--arduino_io(13) <= 'Z'; -- not used
--arduino_io(14) <= 'Z'; -- not used

-- Clock 40MHz for Video and CPU board
clocks : entity work.max10_pll_40M
port map(
 inclk0 => max10_clk1_50,
 c0 => clock_40,
 locked => pll_locked
);

-- Sjy skipper
sky_skipper : entity work.sky_skipper
port map(
 clock_40   => clock_40,
 reset      => reset,
 
 tv15Khz_mode => tv15Khz_mode,
 video_r      => r,
 video_g      => g,
 video_b      => b,
 video_csync  => csync,
 video_blankn => blankn,
 video_hs     => hsync,
 video_vs     => vsync,
 
 audio_out    => audio,
   
 coin1         => fn_pulse(0), -- F1
 coin2         => fn_pulse(1), -- F2
 start1        => fn_pulse(2), -- F3
 start2        => fn_pulse(3), -- F4

 right1         => joy_BBBBFRLDU(3),
 left1          => joy_BBBBFRLDU(2),
 up1            => joy_BBBBFRLDU(0),
 down1          => joy_BBBBFRLDU(1),
 fire10         => joy_BBBBFRLDU(4),
 fire11         => joy_BBBBFRLDU(5),
 
 right2         => joy_BBBBFRLDU(3),
 left2          => joy_BBBBFRLDU(2),
 up2            => joy_BBBBFRLDU(0),
 down2          => joy_BBBBFRLDU(1),
 fire20         => joy_BBBBFRLDU(4),
 fire21         => joy_BBBBFRLDU(5),

                --      ...DCBA
 sw1            => not("1111111"),  --  n.u.(3b hard wired)  / coinage(DCBA)

                --      PONMLKJI
 sw2            => not("11111101"), -- cocktail(P) / service2(O) / bonus(N) / difficulty(MLK) / lives(IJ)
-- sw2            => not(sw(7 downto 0)),
 
 service1       => fn_toggle(6),    -- F7
    
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
vga_vs <= '1'   when tv15Khz_mode = '1' else vsync;

--sound_string <= "00" & audio & "000" & "00" & audio & "000";

-- get scancode from keyboard
process (reset, clock_40)
begin
	if reset='1' then
		clock_div <= (others => '0');
		clock_kbd  <= '0';
	else 
		if rising_edge(clock_40) then
			if clock_div = "1001" then
				clock_div <= (others => '0');
				clock_kbd  <= not clock_kbd;
			else
				clock_div <= clock_div + '1';			
			end if;
		end if;
	end if;
end process;

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_kbd, -- synchrounous clock with core
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);

-- translate scancode to joystick
joystick : entity work.kbd_joystick
port map (
  clk           => clock_kbd, -- synchrounous clock with core
  kbdint        => kbd_intr,
  kbdscancode   => std_logic_vector(kbd_scancode), 
  joy_BBBBFRLDU => joy_BBBBFRLDU,
  fn_pulse      => fn_pulse,
  fn_toggle     => fn_toggle
);

-- usb host for max3421e arduino shield (modified)
--max3421e_clk <= clock_11;
--usb_host : entity work.usb_host_max3421e
--port map(
-- clk     => max3421e_clk,
-- reset   => reset,
-- start   => start,
-- 
-- usb_report => usb_report,
-- new_usb_report => new_usb_report,
-- 
-- spi_cs_n  => arduino_io(10), 
-- spi_clk   => arduino_io(13),
-- spi_mosi  => arduino_io(11),
-- spi_miso  => arduino_io(12)
--);

-- usb keyboard report decoder

--keyboard_decoder : entity work.usb_keyboard_decoder
--port map(
-- clk     => max3421e_clk,
-- 
-- usb_report => usb_report,
-- new_usb_report => new_usb_report,
-- 
-- joyBCPPFRLDU  => joyBCPPFRLDU
--);

-- usb joystick decoder (konix drakkar wireless)

--joystick_decoder : entity work.usb_joystick_decoder
--port map(
-- clk     => max3421e_clk,
-- 
-- usb_report => usb_report,
-- new_usb_report => new_usb_report,
-- 
-- joyBCPPFRLDU  => open --joyBCPPFRLDU
--);

-- debug display

--ledr(8 downto 0) <= joyBCPPFRLDU;
--
--h0 : entity work.decodeur_7_seg port map(kbd_scancode(3 downto 0), hex0);
--h1 : entity work.decodeur_7_seg port map(kbd_scancode(7 downto 4), hex1);
h0 : entity work.decodeur_7_seg port map(dbg_cpu_addr( 3 downto  0),hex0);
h1 : entity work.decodeur_7_seg port map(dbg_cpu_addr( 7 downto  4),hex1);
h2 : entity work.decodeur_7_seg port map(dbg_cpu_addr(11 downto  8),hex2);
h3 : entity work.decodeur_7_seg port map(dbg_cpu_addr(15 downto 12),hex3);

-- 7 segment bits:
--     --0--
--     5   1 
--     |-6-|
--     4   2
--     --3-- .7 (dot) 

--h4 : entity work.decodeur_7_seg port map(sp_rom_cycle(3 downto 0),hex4);
--h5 : entity work.decodeur_7_seg port map(dummy3,hex5);

-- audio for sgtl5000 

--sample_data <= "00" & audio & "000" & "00" & audio & "000";				

-- Clock 1us for ym_8910

--p_clk_1us_p : process(max10_clk1_50)
--begin
--	if rising_edge(max10_clk1_50) then
--		if cnt_1us = 0 then
--			cnt_1us  <= 49;
--			clk_1us  <= '1'; 
--		else
--			cnt_1us  <= cnt_1us - 1;
--			clk_1us <= '0'; 
--		end if;
--	end if;	
--end process;	 

-- sgtl5000 (teensy audio shield on top of usb host shield)

--e_sgtl5000 : entity work.sgtl5000_dac
--port map(
-- clock_18   => clock_18,
-- reset      => reset,
-- i2c_clock  => clk_1us,  
--
-- sample_data  => sample_data,
-- 
-- i2c_sda   => arduino_io(0), -- i2c_sda, 
-- i2c_scl   => arduino_io(1), -- i2c_scl, 
--
-- tx_data   => arduino_io(2), -- sgtl5000 tx
-- mclk      => arduino_io(4), -- sgtl5000 mclk 
-- 
-- lrclk     => arduino_io(3), -- sgtl5000 lrclk
-- bclk      => arduino_io(6), -- sgtl5000 bclk   
-- 
-- -- debug
-- hex0_di   => open, -- hex0_di,
-- hex1_di   => open, -- hex1_di,
-- hex2_di   => open, -- hex2_di,
-- hex3_di   => open, -- hex3_di,
-- 
-- sw => sw(7 downto 0)
--);

-- pwm sound output
process(clock_40)  -- use same clock as Sky skipper core
begin
  if rising_edge(clock_40) then
  
		if clock_div = "0000" then 
			pwm_accumulator  <=  ('0'&pwm_accumulator(16 downto 0)) + ('0'&audio&'0');
		end if;
		
  end if;
end process;

pwm_audio_out_l <= pwm_accumulator(17);
pwm_audio_out_r <= pwm_accumulator(17); 


end struct;
