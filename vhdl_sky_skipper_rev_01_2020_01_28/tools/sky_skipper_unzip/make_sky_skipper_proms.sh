#!/bin/bash
# converted from make_sky_skipper_proms.bat
# 11/2024 Red~Bote (Glenn Neidermeier)

#copy /B tnx1-c.2a + tnx1-c.2b + tnx1-c.2c + tnx1-c.2d + tnx1-c.2e + tnx1-c.2f + tnx1-c.2g sky_skipper_cpu.bin
#make_vhdl_prom sky_skipper_cpu.bin sky_skipper_cpu.vhd
#
#make_vhdl_prom tnx1-t.4a sky_skipper_bg_palette_rgb.vhd
#make_vhdl_prom tnx1-t.3a sky_skipper_sp_palette_rg.vhd
#make_vhdl_prom tnx1-t.2a sky_skipper_sp_palette_gb.vhd
#make_vhdl_prom tnx1-t.1a sky_skipper_ch_palette_rgb.vhd
#
#make_vhdl_prom tnx1-t.1e sky_skipper_sp_bits_1.vhd
#make_vhdl_prom tnx1-t.2e sky_skipper_sp_bits_2.vhd
#make_vhdl_prom tnx1-t.3e sky_skipper_sp_bits_3.vhd
#make_vhdl_prom tnx1-t.5e sky_skipper_sp_bits_4.vhd
#
#make_vhdl_prom tnx1-v.3h sky_skipper_ch_bits.vhd
#
#
#rem ROM from skyskipr.zip
#rem
#rem tnx1-c.2a CRC bdc7f218
#rem tnx1-c.2b CRC cbe601a8
#rem tnx1-c.2c CRC 5ca79abf
#rem tnx1-c.2d CRC 6b7a7071
#rem tnx1-c.2e CRC 6b0c0525
#rem tnx1-c.2f CRC d1712424
#rem tnx1-c.2g CRC 8b33c4cf
#
#rem tnx1-v.3h CRC ecb6a046
#
#rem tnx1-t.1e CRC 01c1120e
#rem tnx1-t.2e CRC 70292a71
#rem tnx1-t.3e CRC 92b6a0e8
#rem tnx1-t.5e CRC cc5f0ac3
#
#rem tnx1-t.4a CRC 98846924
#rem tnx1-t.1a CRC c2bca435
#rem tnx1-t.3a CRC 8abf9de4
#rem tnx1-t.2a CRC aa7ff322
#
#rem tnx1-t.3j CRC 1c5c8dea n.u.


cat tnx1-c.2a tnx1-c.2b tnx1-c.2c tnx1-c.2d tnx1-c.2e tnx1-c.2f tnx1-c.2g > sky_skipper_cpu.bin
./make_vhdl_prom sky_skipper_cpu.bin sky_skipper_cpu.vhd

./make_vhdl_prom tnx1-t.4a sky_skipper_bg_palette_rgb.vhd
./make_vhdl_prom tnx1-t.3a sky_skipper_sp_palette_rg.vhd
./make_vhdl_prom tnx1-t.2a sky_skipper_sp_palette_gb.vhd
./make_vhdl_prom tnx1-t.1a sky_skipper_ch_palette_rgb.vhd

./make_vhdl_prom tnx1-t.1e sky_skipper_sp_bits_1.vhd
./make_vhdl_prom tnx1-t.2e sky_skipper_sp_bits_2.vhd
./make_vhdl_prom tnx1-t.3e sky_skipper_sp_bits_3.vhd
./make_vhdl_prom tnx1-t.5e sky_skipper_sp_bits_4.vhd

./make_vhdl_prom tnx1-v.3h sky_skipper_ch_bits.vhd

rm sky_skipper_cpu.bin

