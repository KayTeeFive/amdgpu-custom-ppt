#!/bin/bash -x

echo "!!! amdgpu.ppfeaturemask=0xffffffff must be enabled !!!"

###### PowerPlay Tables #########
# cap 0: 1 (GFXCLK_LIMITS)
# cap 1: 1 (GFXCLK_CURVE)
# cap 2: 1 (UCLK_LIMITS)
# cap 3: 1 (POWER_LIMIT)
# cap 4: 1 (FAN_ACOUSTIC_LIMIT)
# cap 5: 1 (FAN_SPEED_MIN)
# cap 6: 1 (TEMPERATURE_FAN)
# cap 7: 1 (TEMPERATURE_SYSTEM)
# cap 8: 1 (MEMORY_TIMING_TUNE)
# cap 9: 1 (FAN_ZERO_RPM_CONTROL)
# cap 10: 1 (AUTO_UV_ENGINE)
# cap 11: 1 (AUTO_OC_ENGINE)
# cap 12: 1 (AUTO_OC_MEMORY)
# cap 13: 1 (FAN_CURVE)
# cap 14: 1 (SMU_11_0_ODCAP_AUTO_FAN_ACOUSTIC_LIMIT)
# cap 15: 1 (POWER_MODE)
#################################


CARD_INDEX=1
PP_TABLE="/sys/class/drm/card${CARD_INDEX}/device/pp_table"
PP_MOD_BIN="$HOME/RX6400_mod_pp_table.bin"

echo "=== Starting overdrive_table caps update ==="

cat $PP_MOD_BIN > $PP_TABLE
sleep 1

echo "=== Done ==="


###### OVERDRIVE SETTINGS #######
# cat /sys/class/drm/card1/device/pp_od_clk_voltage
# OD_SCLK:
# 0: 500Mhz
# 1: 2218Mhz
# OD_VDDGFX_OFFSET:
# 0mV
# OD_RANGE:
# SCLK:     500Mhz       2750Mhz
#################################

GPU_FREQ_MAX=2218
echo "Set GPU MAX Frequency: ${GPU_FREQ_MAX}Mhz ..."
echo "s 1 ${GPU_FREQ_MAX}" | tee /sys/class/drm/card1/device/pp_od_clk_voltage
echo "Applying..."
echo "c" | tee /sys/class/drm/card1/device/pp_od_clk_voltage
echo "Done!"

