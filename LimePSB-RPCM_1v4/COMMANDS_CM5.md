# Quick Command Reference for LimePSB-RPCM v1.4 on Raspberry Pi CM5

## One-Line Installation

```bash
sudo bash QUICK_INSTALL_CM5.sh
```

## Manual Installation Commands

### Prerequisites
```bash
sudo apt update
sudo apt install -y device-tree-compiler gpiod libgpiod-dev xxd git

# Install spi-tools
cd /tmp && git clone https://github.com/cpb-/spi-tools.git
cd spi-tools && ./autogen.sh && ./configure && make && sudo make install
```

### Install Device Tree Overlays
```bash
cd ~/LimePSB-RPCM_BSP/LimePSB-RPCM_1v4

# GPIO Expander
cd gpio_expander
dtc -@ -I dts -O dtb -o mcp23017_LimePSB-RPCM.dtbo mcp23017_LimePSB-RPCM.dts
sudo cp mcp23017_LimePSB-RPCM.dtbo /boot/firmware/overlays/

# System ADC
cd ../system_adc
dtc -@ -I dts -O dtb -o mcp3208.dtbo mcp3208.dts
sudo cp mcp3208.dtbo /boot/firmware/overlays/

# FPGA Configuration
cd ../fpga_configuration
sudo make install
```

### Configure /boot/firmware/config.txt
```bash
sudo tee -a /boot/firmware/config.txt << 'EOF'

# LimePSB-RPCM v1.4 Configuration
dtoverlay=mcp23017_LimePSB-RPCM,noints,i2c_csi_dsi
dtoverlay=spi0-0cs
dtoverlay=spi1-3cs,cs0_pin=18,cs1_pin=17,cs2_pin=16
dtoverlay=mcp3208,spi1-0-present
dtoverlay=i2c-sensor,lm75,addr=0x48
dtoverlay=i2c-rtc,pcf85063a,i2c_csi_dsi
EOF
```

### Setup FPGA Auto-Configuration
```bash
(sudo crontab -l 2>/dev/null; echo "@reboot sudo bash /usr/local/bin/fpga_conf.sh /usr/local/bin/LimePSB_RPCM_top_bitmap.bin") | sudo crontab -
```

### Reboot
```bash
sudo reboot
```

## Verification Commands

### Check GPIO
```bash
gpiodetect                      # List GPIO chips (should show pinctrl-rp1 and mcp23017)
gpioinfo gpiochip2             # Show GPIO expander 1 with named pins
gpioinfo gpiochip3             # Show GPIO expander 2 with named pins
gpiofind "LED1_R"              # Find specific GPIO by name
```

### Check SPI
```bash
lsmod | grep spi               # Should show spi_rp1
ls -l /dev/spidev*             # Should show /dev/spidev0.0 and /dev/spidev1.0
```

### Check I2C Devices
```bash
ls /dev/i2c-*                  # List I2C buses
sudo i2cdetect -y 10           # Scan I2C bus 10 (adjust number as needed)
                               # Should show devices at 0x20, 0x21, 0x48
```

### Check System ADC
```bash
ls /sys/bus/iio/devices/       # List IIO devices
cat /sys/bus/iio/devices/iio:device0/in_voltage0_raw  # Read ADC channel 0
```

### Check Temperature Sensor
```bash
cat /sys/class/hwmon/hwmon*/temp1_input  # Read temperature (in millidegrees)
```

### Check RTC
```bash
ls -l /dev/rtc*                # List RTC devices
sudo hwclock -r                # Read RTC time
sudo hwclock -w                # Write system time to RTC
sudo hwclock -s                # Set system time from RTC
```

### Test FPGA Configuration
```bash
sudo /usr/local/bin/fpga_conf.sh /usr/local/bin/LimePSB_RPCM_top_bitmap.bin
```

### Test Power Detector
```bash
cd ~/LimePSB-RPCM_BSP/LimePSB-RPCM_1v4/power_detector
sudo ./pdread.sh
```

## GPIO Control Examples

### Control LEDs
```bash
# Turn on LED1 Red
gpioset $(gpiofind "LED1_R")=1

# Turn off LED1 Red
gpioset $(gpiofind "LED1_R")=0

# Read LED1 Red state
gpioget $(gpiofind "LED1_R")
```

### Control PA/LNA
```bash
# Enable TX A Power Amplifier
gpioset $(gpiofind "EN_TXA_PA")=1

# Enable RX A Low Noise Amplifier
gpioset $(gpiofind "EN_RXA_LNA")=1

# Disable all
gpioset $(gpiofind "EN_TXA_PA")=0 $(gpiofind "EN_RXA_LNA")=0
```

### Control Fan
```bash
# Turn on fan
gpioset $(gpiofind "FAN_CTRL")=1

# Turn off fan
gpioset $(gpiofind "FAN_CTRL")=0
```

## Troubleshooting Commands

### Load SPI Driver Manually
```bash
sudo modprobe spi_rp1
```

### Check Kernel Messages
```bash
sudo dmesg | grep -i spi       # SPI-related messages
sudo dmesg | grep -i i2c       # I2C-related messages
sudo dmesg | grep -i gpio      # GPIO-related messages
```

### Check Loaded Device Tree Overlays
```bash
sudo vcdbg log msg | grep dtoverlay
```

### View Device Tree
```bash
sudo dtc -I fs /sys/firmware/devicetree/base > /tmp/devicetree.dts
less /tmp/devicetree.dts
```

### Check Config.txt
```bash
cat /boot/firmware/config.txt | grep -A 20 "LimePSB-RPCM"
```

## Uninstallation Commands

### Remove Device Tree Overlays
```bash
sudo rm /boot/firmware/overlays/mcp23017_LimePSB-RPCM.dtbo
sudo rm /boot/firmware/overlays/mcp3208.dtbo
```

### Remove FPGA Configuration
```bash
sudo rm /usr/local/bin/fpga_conf.sh
sudo rm /usr/local/bin/LimePSB_RPCM_top_bitmap.bin
sudo crontab -l | grep -v "fpga_conf.sh" | sudo crontab -
```

### Remove Config.txt Entries
```bash
sudo nano /boot/firmware/config.txt
# Manually remove lines under "# LimePSB-RPCM v1.4 Configuration"
```

### Reboot
```bash
sudo reboot
```

## Useful Aliases (Add to ~/.bashrc)

```bash
# LimePSB-RPCM aliases
alias lpsb-gpios='gpiodetect && gpioinfo gpiochip2 && gpioinfo gpiochip3'
alias lpsb-i2c='sudo i2cdetect -y 10'
alias lpsb-temp='cat /sys/class/hwmon/hwmon*/temp1_input'
alias lpsb-adc='cat /sys/bus/iio/devices/iio:device0/in_voltage*_raw'
alias lpsb-pd='cd ~/LimePSB-RPCM_BSP/LimePSB-RPCM_1v4/power_detector && sudo ./pdread.sh'
alias lpsb-fpga='sudo /usr/local/bin/fpga_conf.sh /usr/local/bin/LimePSB_RPCM_top_bitmap.bin'
```

Reload aliases:
```bash
source ~/.bashrc
```
