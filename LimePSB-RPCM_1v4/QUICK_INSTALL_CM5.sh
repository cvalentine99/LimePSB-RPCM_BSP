#!/bin/bash
#
# Quick Installation Script for LimePSB-RPCM v1.4 on Raspberry Pi CM5
# This script automates the installation process
#
# Usage: sudo bash QUICK_INSTALL_CM5.sh
#

set -e  # Exit on error

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "============================================"
echo "LimePSB-RPCM v1.4 Installation for CM5"
echo "============================================"
echo ""

# Get the script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

echo "[1/9] Installing prerequisite packages..."
apt update
apt install -y device-tree-compiler gpiod libgpiod-dev xxd git

echo ""
echo "[2/9] Installing spi-tools..."
if ! command -v spi-config &> /dev/null; then
    cd /tmp
    if [ -d "spi-tools" ]; then
        rm -rf spi-tools
    fi
    git clone https://github.com/cpb-/spi-tools.git
    cd spi-tools
    ./autogen.sh
    ./configure
    make
    make install
    cd "$SCRIPT_DIR"
    echo "spi-tools installed successfully"
else
    echo "spi-tools already installed"
fi

echo ""
echo "[3/9] Installing GPIO Expander device tree overlay..."
cd "$SCRIPT_DIR/gpio_expander"
dtc -@ -I dts -O dtb -o mcp23017_LimePSB-RPCM.dtbo mcp23017_LimePSB-RPCM.dts
cp mcp23017_LimePSB-RPCM.dtbo /boot/firmware/overlays/
echo "GPIO Expander overlay installed"

echo ""
echo "[4/9] Installing System ADC device tree overlay..."
cd "$SCRIPT_DIR/system_adc"
dtc -@ -I dts -O dtb -o mcp3208.dtbo mcp3208.dts
cp mcp3208.dtbo /boot/firmware/overlays/
echo "System ADC overlay installed"

echo ""
echo "[5/9] Installing FPGA configuration..."
cd "$SCRIPT_DIR/fpga_configuration"
make install
echo "FPGA configuration installed"

echo ""
echo "[6/9] Configuring /boot/firmware/config.txt..."

CONFIG_FILE="/boot/firmware/config.txt"

# Backup config.txt
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup.$(date +%Y%m%d_%H%M%S)"

# Function to add line if not exists
add_config_line() {
    local line="$1"
    if ! grep -qF "$line" "$CONFIG_FILE"; then
        echo "$line" >> "$CONFIG_FILE"
        echo "  Added: $line"
    else
        echo "  Already exists: $line"
    fi
}

echo "  Updating config.txt..."
add_config_line "# LimePSB-RPCM v1.4 Configuration"
add_config_line "dtoverlay=mcp23017_LimePSB-RPCM,noints,i2c_csi_dsi"
add_config_line "dtoverlay=spi0-0cs"
add_config_line "dtoverlay=spi1-3cs,cs0_pin=18,cs1_pin=17,cs2_pin=16"
add_config_line "dtoverlay=mcp3208,spi1-0-present"
add_config_line "dtoverlay=i2c-sensor,lm75,addr=0x48"
add_config_line "dtoverlay=i2c-rtc,pcf85063a,i2c_csi_dsi"

echo ""
echo "[7/9] Setting up FPGA configuration at boot..."
CRON_LINE="@reboot sudo bash /usr/local/bin/fpga_conf.sh /usr/local/bin/LimePSB_RPCM_top_bitmap.bin"
(crontab -l 2>/dev/null | grep -v "fpga_conf.sh"; echo "$CRON_LINE") | crontab -
echo "FPGA auto-configuration enabled"

echo ""
echo "[8/9] Verifying installation..."
echo "  Device tree compiler: $(which dtc)"
echo "  GPIO tools: $(which gpioinfo)"
echo "  SPI config: $(which spi-config)"
echo "  FPGA script: $(ls -l /usr/local/bin/fpga_conf.sh 2>/dev/null | awk '{print $9}')"

echo ""
echo "[9/9] Installation complete!"
echo ""
echo "============================================"
echo "IMPORTANT: System reboot required!"
echo "============================================"
echo ""
echo "After reboot, verify installation with:"
echo "  gpiodetect                     # Check GPIO chips"
echo "  lsmod | grep spi               # Check SPI driver"
echo "  ls /dev/spidev*                # Check SPI devices"
echo "  sudo i2cdetect -y 10           # Check I2C devices"
echo ""
echo "To test components:"
echo "  cd $SCRIPT_DIR/power_detector"
echo "  sudo ./pdread.sh"
echo ""
echo "Configuration backup saved to: ${CONFIG_FILE}.backup.*"
echo ""
read -p "Reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting in 3 seconds..."
    sleep 3
    reboot
else
    echo "Please reboot manually: sudo reboot"
fi
