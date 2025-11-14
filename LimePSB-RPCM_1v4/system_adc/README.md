# System Voltage ADC

LimePSB RPCM v1.4 board features ADC (MCP3208) controlled via SPI bus. It is used to measure various on-board voltages.

**Note:** This is compatible with both Raspberry Pi CM4 (BCM2711) and CM5 (BCM2712). The device tree overlay includes support for both SoC variants.

## Device Tree

A pre-compiled device tree source (mcp3208.dts) with CM5 support is provided in this directory.

To compile the device tree overlay:

```
dtc -@ -I dts -O dtb -o mcp3208.dtbo mcp3208.dts
```

Copy to overlay folder:

```
sudo cp mcp3208.dtbo /boot/firmware/overlays/
```

## Installation

Raspberry Pi OS provides driver for MCP3208 ADC. To enable it add this line to the /boot/firmware/config.txt file:

```
dtoverlay=mcp3208,spi1-0-present
```

Make sure there is a following line in the /boot/firmware/config.txt file (cs0_pin parameter is most important while ADC is controlled by CS0 pin):

```
dtoverlay=spi1-3cs,cs0_pin=18,cs1_pin=17,cs2_pin=16
```

Reboot.

## Check if it is Working

Navigate to /sys/bus/iio/devices/iio:device0

Note please that there may be more IIO devices. In this case our ADC may be represented by different iio:deviceN, not iio:device0.

Read first analog channel:

```
cat in_voltage0_raw
```
