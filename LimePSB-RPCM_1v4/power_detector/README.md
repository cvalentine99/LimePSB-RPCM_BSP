# Power Detector

LimePSB RPCM v1.4 board features on board RF signal power detectors for transmit channels. Measured values may be read using provided script.

**Note:** This is compatible with both Raspberry Pi CM4 (BCM2711) and CM5 (BCM2712). The script automatically detects and loads the appropriate SPI driver (spi_bcm2835 for CM4 or spi_rp1 for CM5).

## Prerequisites

It requires spi-tools and xxd command line program to be installed.
To install spi-tools use this [repository](https://github.com/cpb-/spi-tools) and follow instructions.
To install xxd, use this command:

```
sudo apt install xxd
```

## Using the Script

To read power detector measured values execute the following command:

```
sudo ./pdread.sh
```

The script will execute required SPI commands and will read values from both power detectors. Values will be shown in decimal as well as in hexadecimal format.
