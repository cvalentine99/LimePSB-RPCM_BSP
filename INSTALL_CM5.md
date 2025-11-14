# Installation Guide for LimePSB-RPCM v1.4 on Raspberry Pi CM5

This guide provides complete installation instructions for the LimePSB-RPCM v1.4 board support package on Raspberry Pi CM5 (BCM2712).

## Prerequisites

### System Requirements
- Raspberry Pi CM5 with Raspberry Pi OS installed
- Root/sudo access
- Internet connection for package installation

### Required Packages

```bash
# Update package list
sudo apt update

# Install device tree compiler
sudo apt install -y device-tree-compiler

# Install GPIO tools
sudo apt install -y gpiod libgpiod-dev

# Install xxd (for power detector)
sudo apt install -y xxd

# Install git (if not already installed)
sudo apt install -y git
```

### Install spi-tools

```bash
# Clone and install spi-tools
cd /tmp
git clone https://github.com/cpb-/spi-tools.git
cd spi-tools
./autogen.sh
./configure
make
sudo make install
cd ~
```

## Installation Steps

### 1. Clone the Repository

```bash
cd ~
git clone https://github.com/cvalentine99/LimePSB-RPCM_BSP.git
cd LimePSB-RPCM_BSP
```

### 2. GPIO Expander Setup

```bash
cd ~/LimePSB-RPCM_BSP/LimePSB-RPCM_1v4/gpio_expander

# Compile device tree overlay
dtc -@ -I dts -O dtb -o mcp23017_LimePSB-RPCM.dtbo mcp23017_LimePSB-RPCM.dts

# Copy to boot overlays folder
sudo cp mcp23017_LimePSB-RPCM.dtbo /boot/firmware/overlays/
```

**Add to /boot/firmware/config.txt:**
```bash
sudo bash -c 'echo "dtoverlay=mcp23017_LimePSB-RPCM,noints,i2c_csi_dsi" >> /boot/firmware/config.txt'
```

### 3. System ADC Setup

```bash
cd ~/LimePSB-RPCM_BSP/LimePSB-RPCM_1v4/system_adc

# Compile device tree overlay
dtc -@ -I dts -O dtb -o mcp3208.dtbo mcp3208.dts

# Copy to boot overlays folder
sudo cp mcp3208.dtbo /boot/firmware/overlays/
```

**Add to /boot/firmware/config.txt:**
```bash
sudo bash -c 'echo "dtoverlay=spi1-3cs,cs0_pin=18,cs1_pin=17,cs2_pin=16" >> /boot/firmware/config.txt'
sudo bash -c 'echo "dtoverlay=mcp3208,spi1-0-present" >> /boot/firmware/config.txt'
```

### 4. FPGA Configuration Setup

```bash
cd ~/LimePSB-RPCM_BSP/LimePSB-RPCM_1v4/fpga_configuration

# Install FPGA configuration script and binary
sudo make install
```

**Add to /boot/firmware/config.txt:**
```bash
sudo bash -c 'echo "dtoverlay=spi0-0cs" >> /boot/firmware/config.txt'
```

**Set up automatic FPGA configuration at boot:**
```bash
# Open crontab editor
sudo crontab -e

# Add this line at the end of the file:
# @reboot sudo bash /usr/local/bin/fpga_conf.sh /usr/local/bin/LimePSB_RPCM_top_bitmap.bin
```

Or add it directly:
```bash
(sudo crontab -l 2>/dev/null; echo "@reboot sudo bash /usr/local/bin/fpga_conf.sh /usr/local/bin/LimePSB_RPCM_top_bitmap.bin") | sudo crontab -
```

### 5. Temperature Sensor Setup

**Add to /boot/firmware/config.txt:**
```bash
sudo bash -c 'echo "dtoverlay=i2c-sensor,lm75,addr=0x48" >> /boot/firmware/config.txt'
```

### 6. RTC Setup

**Add to /boot/firmware/config.txt:**
```bash
sudo bash -c 'echo "dtoverlay=i2c-rtc,pcf85063a,i2c_csi_dsi" >> /boot/firmware/config.txt'
```

### 7. Fan Control Setup (Optional)

```bash
cd ~/LimePSB-RPCM_BSP/LimePSB-RPCM_1v4/fan

# Follow the instructions in the README.md for your specific fan configuration
```

### 8. PA/LNA Control Setup

```bash
cd ~/LimePSB-RPCM_BSP/LimePSB-RPCM_1v4/pa_lna_control

# Follow the instructions in the README.md for power amplifier control
```

## Reboot and Verify

### Reboot the System

```bash
sudo reboot
```

### Verification After Reboot

#### 1. Verify GPIO Expanders

```bash
# Check GPIO chips
gpiodetect

# Expected output should include:
# gpiochip0 [pinctrl-rp1] (54 lines)
# gpiochip1 [raspberrypi-exp-gpio] (8 lines)
# gpiochip2 [mcp23017] (16 lines)
# gpiochip3 [mcp23017] (16 lines)

# Check GPIO info with named pins
gpioinfo gpiochip2

# Should show named GPIOs like:
# line   0:     "LED1_R"       unused input active-high
# line   8:  "EN_TXA_PA"       unused input active-high
# etc.
```

#### 2. Verify SPI Driver

```bash
# Check loaded SPI module (should be spi_rp1 for CM5)
lsmod | grep spi

# Check SPI devices
ls -l /dev/spidev*

# Expected:
# /dev/spidev0.0
# /dev/spidev1.0
```

#### 3. Verify System ADC

```bash
# Navigate to IIO device
ls /sys/bus/iio/devices/

# Read ADC channel (adjust device number if needed)
cat /sys/bus/iio/devices/iio:device0/in_voltage0_raw
```

#### 4. Verify Temperature Sensor

```bash
# Check I2C devices
sudo i2cdetect -y 10

# Read temperature
cat /sys/class/hwmon/hwmon*/temp1_input
```

#### 5. Verify RTC

```bash
# Check RTC device
ls -l /dev/rtc*

# Read RTC time
sudo hwclock -r
```

#### 6. Test FPGA Configuration

```bash
# Check if FPGA was configured at boot
sudo dmesg | grep -i spi

# Manually test FPGA configuration
sudo /usr/local/bin/fpga_conf.sh /usr/local/bin/LimePSB_RPCM_top_bitmap.bin
```

#### 7. Test Power Detector

```bash
cd ~/LimePSB-RPCM_BSP/LimePSB-RPCM_1v4/power_detector

# Read power detector values
sudo ./pdread.sh

# Should output readings for Channel A and Channel B
```

## Troubleshooting

### SPI Driver Issues

If SPI devices don't appear, manually load the driver:
```bash
sudo modprobe spi_rp1
```

### GPIO Expander Not Detected

Check I2C bus for MCP23017 devices:
```bash
# Find CSI/DSI I2C bus (usually bus 10 or 11 on CM5)
ls /dev/i2c-*

# Scan for I2C devices (try different bus numbers)
sudo i2cdetect -y 10
sudo i2cdetect -y 11

# Should see devices at addresses 0x20 and 0x21
```

### Device Tree Overlay Conflicts

Check loaded overlays:
```bash
sudo vcdbg log msg | grep dtoverlay
```

View current device tree:
```bash
sudo dtc -I fs /sys/firmware/devicetree/base
```

## Summary of /boot/firmware/config.txt Additions

All additions in one place for reference:
```
# LimePSB-RPCM v1.4 Configuration
dtoverlay=mcp23017_LimePSB-RPCM,noints,i2c_csi_dsi
dtoverlay=spi0-0cs
dtoverlay=spi1-3cs,cs0_pin=18,cs1_pin=17,cs2_pin=16
dtoverlay=mcp3208,spi1-0-present
dtoverlay=i2c-sensor,lm75,addr=0x48
dtoverlay=i2c-rtc,pcf85063a,i2c_csi_dsi
```

## Post-Installation

After successful installation and verification:

1. **Set system time from RTC:**
   ```bash
   sudo hwclock -s
   ```

2. **Test all GPIO functions** using the named GPIO lines
3. **Configure fan control** based on temperature thresholds
4. **Set up PA/LNA control scripts** for your RF application

## Additional Resources

- Component-specific documentation: See README.md files in each component directory
- LimePSB-RPCM v1.4 schematic: Contact Lime Microsystems
- SPI-tools documentation: https://github.com/cpb-/spi-tools
- Raspberry Pi CM5 documentation: https://www.raspberrypi.com/documentation/

## Notes for Raspberry Pi CM5

- The CM5 uses the **BCM2712** SoC with **RP1** peripheral controller
- SPI driver is **spi_rp1** (automatically detected by scripts)
- GPIO controller is **pinctrl-rp1** with **54 GPIO lines**
- CSI/DSI I2C bus may be on a different number than CM4 (check with `ls /dev/i2c-*`)
- All device tree overlays include BCM2712 compatibility strings
- Scripts automatically detect and load the correct drivers for CM5
