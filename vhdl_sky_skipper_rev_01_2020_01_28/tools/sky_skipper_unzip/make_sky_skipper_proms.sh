#!/bin/bash
# Port of make_sky_skipper_proms.bat for the Basys3 build. Run from this
# directory (the unzipped skyskipr.zip) by contrib/tools/roms.sh, which sets:
#   MAKE_VHDL_PROM  path of the compiled make_vhdl_prom
#   PROM_DIR        output directory for the PROM VHDL
# make_vhdl_prom names the entity after its output argument, so it runs inside
# PROM_DIR with bare output file names.

set -euo pipefail

: "${MAKE_VHDL_PROM:?}" "${PROM_DIR:?}"
roms="$(pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

cat tnx1-c.2a tnx1-c.2b tnx1-c.2c tnx1-c.2d tnx1-c.2e tnx1-c.2f tnx1-c.2g > "$tmp/sky_skipper_cpu.bin"

cd "$PROM_DIR"
"$MAKE_VHDL_PROM" "$tmp/sky_skipper_cpu.bin" sky_skipper_cpu.vhd
"$MAKE_VHDL_PROM" "$roms/tnx1-t.4a"          sky_skipper_bg_palette_rgb.vhd
"$MAKE_VHDL_PROM" "$roms/tnx1-t.3a"          sky_skipper_sp_palette_rg.vhd
"$MAKE_VHDL_PROM" "$roms/tnx1-t.2a"          sky_skipper_sp_palette_gb.vhd
"$MAKE_VHDL_PROM" "$roms/tnx1-t.1a"          sky_skipper_ch_palette_rgb.vhd
"$MAKE_VHDL_PROM" "$roms/tnx1-t.1e"          sky_skipper_sp_bits_1.vhd
"$MAKE_VHDL_PROM" "$roms/tnx1-t.2e"          sky_skipper_sp_bits_2.vhd
"$MAKE_VHDL_PROM" "$roms/tnx1-t.3e"          sky_skipper_sp_bits_3.vhd
"$MAKE_VHDL_PROM" "$roms/tnx1-t.5e"          sky_skipper_sp_bits_4.vhd
"$MAKE_VHDL_PROM" "$roms/tnx1-v.3h"          sky_skipper_ch_bits.vhd
