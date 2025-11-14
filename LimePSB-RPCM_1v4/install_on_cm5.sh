#!/bin/bash
# Installation Commands for LimePSB-RPCM v1.4 on Raspberry Pi CM5
# Run these commands on your ACTUAL CM5 hardware
#
# Usage: Copy this file to your CM5, then run:
#   chmod +x install_on_cm5.sh
#   sudo ./install_on_cm5.sh

set -e

echo "============================================"
echo "LimePSB-RPCM v1.4 Installation for CM5"
echo "============================================"
echo ""

# Change to the script's directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "[1/7] Compiling GPIO Expander overlay..."
cd gpio_expander
dtc -@ -I dts -O dtb -o mcp23017_LimePSB-RPCM.dtbo mcp23017_LimePSB-RPCM.dts
cp mcp23017_LimePSB-RPCM.dtbo /boot/firmware/overlays/
echo "✓ Done"

echo ""
echo "[2/7] Compiling System ADC overlay..."
cd ../system_adc
dtc -@ -I dts -O dtb -o mcp3208.dtbo mcp3208.dts
cp mcp3208.dtbo /boot/firmware/overlays/
echo "✓ Done"

echo ""
echo "[3/7] Installing FPGA configuration..."
cd ../fpga_configuration
make install
echo "✓ Done"

echo ""
echo "[4/7] Backing up config.txt..."
cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.$(date +%Y%m%d_%H%M%S)
echo "✓ Backup created"

echo ""
echo "[5/7] Updating /boot/firmware/config.txt..."
cat >> /boot/firmware/config.txt << 'EOF'

# LimePSB-RPCM v1.4 Configuration (installed $(date))
dtoverlay=mcp23017_LimePSB-RPCM,noints,i2c_csi_dsi
dtoverlay=spi0-0cs
dtoverlay=spi1-3cs,cs0_pin=18,cs1_pin=17,cs2_pin=16
dtoverlay=mcp3208,spi1-0-present
dtoverlay=i2c-sensor,lm75,addr=0x48
dtoverlay=i2c-rtc,pcf85063a,i2c_csi_dsi
EOF
echo "✓ Done"

echo ""
echo "[6/7] Setting up FPGA auto-configuration..."
CRON_LINE="@reboot sudo bash /usr/local/bin/fpga_conf.sh /usr/local/bin/LimePSB_RPCM_top_bitmap.bin"
(crontab -l 2>/dev/null | grep -v "fpga_conf.sh"; echo "$CRON_LINE") | crontab -
echo "✓ Done"

echo ""
echo "[7/7] Installation complete!"
echo ""
echo "============================================"
echo "REBOOT REQUIRED!"
echo "============================================"
echo ""
echo "Configuration backup: /boot/firmware/config.txt.backup.*"
echo ""
echo "After reboot, verify with:"
echo "  gpiodetect"
echo "  gpioinfo gpiochip5"
echo "  gpioinfo gpiochip6"
echo "  lsmod | grep spi"
echo ""
read -p "Reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    reboot
fi
