# LimePSB RPCM Board Support Package

This repository contains device tree overlays, scripts, and other related components to support LimePSB RPCM (Raspberry Pi Compute Module) boards.

## Board Variants

### LimePSB-RPCM_1v3
- Initial release for Raspberry Pi CM4
- Features: FPGA configuration, GPIO expander, system ADC, temperature sensor, RTC, fan control, PA/LNA control

### LimePSB-RPCM_1v4
- Enhanced version for **Raspberry Pi CM4 and CM5**
- All features from v1.3 plus RF power detector for transmit channels
- **Raspberry Pi CM5 (BCM2712) support**: Device tree overlays and scripts automatically detect and support both CM4 (BCM2711/spi_bcm2835) and CM5 (BCM2712/spi_rp1) hardware

### LimePSB-RPCM-CA23_1v0
- Raspberry Pi CM5 native design
- Features: RFFE control software, GPIO expander (3x), system ADC, temperature sensor, fan control, LimeSuite integration

## Raspberry Pi CM5 Compatibility

The v1.4 board variant is fully compatible with Raspberry Pi CM5:
- Device tree overlays include BCM2712 compatibility strings
- SPI scripts automatically detect and load the appropriate driver (spi_bcm2835 for CM4, spi_rp1 for CM5)
- All components (FPGA configuration, GPIO expanders, power detectors, system ADC) work on both platforms

## Installation

### Quick Installation for v1.4 on Raspberry Pi CM5

**Automated installation:**
```bash
cd LimePSB-RPCM_1v4
sudo bash QUICK_INSTALL_CM5.sh
```

**Manual installation:**

See the comprehensive [Installation Guide for CM5](INSTALL_CM5.md) for detailed step-by-step instructions.

### Installation for Other Variants

- **LimePSB-RPCM_1v3**: See component README files in the `LimePSB-RPCM_1v3/` directory
- **LimePSB-RPCM-CA23_1v0**: See component README files in the `LimePSB-RPCM-CA23_1v0/` directory

## Documentation

For detailed information about each component, refer to the README files in the respective directories:
- Device tree overlays
- GPIO expander configuration
- FPGA programming
- Power detector usage
- System ADC setup
- Temperature monitoring
- RTC configuration