# Raspberry Pi Zero 2 W — Product Brief

> **Manufacturer:** Raspberry Pi Ltd
> **Published:** April 2024
> **Product Page:** [raspberrypi.com/products/raspberry-pi-zero-2-w](https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/)

---

## Overview

Raspberry Pi Zero 2 W is the latest product in the most affordable range of single-board computers. The successor to the breakthrough Raspberry Pi Zero W, Raspberry Pi Zero 2 W is a form factor–compatible drop-in replacement for the original board.

The board incorporates a **quad-core 64-bit Arm Cortex-A53 CPU**, clocked at 1GHz. At its heart is a Raspberry Pi **RP3A0** system-in-package (SiP), integrating a Broadcom BCM2710A1 die with 512MB of LPDDR2 SDRAM.

### Performance vs Original Zero

| Metric | Improvement |
|--------|-------------|
| Single-threaded performance | **40% faster** |
| Multi-threaded performance | **5× faster** |
| Approximate performance vs Pi 3B | ~80% |

---

## Specifications

| Parameter | Value |
|-----------|-------|
| **Form factor** | 65mm × 30mm |
| **Processor** | Broadcom BCM2710A1, quad-core 64-bit SoC (Arm Cortex-A53 @ 1GHz) |
| **System-in-Package** | Raspberry Pi RP3A0 (integrates BCM2710A1 + 512MB LPDDR2) |
| **Memory** | 512MB LPDDR2 SDRAM |
| **GPU** | VideoCore IV |
| **Wireless LAN** | 2.4GHz IEEE 802.11 b/g/n, onboard antenna |
| **Bluetooth** | Bluetooth 4.2, BLE (Bluetooth Low Energy) |
| **Modular compliance** | Certified |
| **USB** | 1× Micro USB 2.0 OTG (data) |
| **Power input** | 1× Micro USB (5V DC, 2.5A recommended) |
| **GPIO** | HAT-compatible 40-pin I/O header footprint (unpopulated) |
| **Storage** | microSD card slot |
| **Video output** | Mini HDMI port (up to 1080p) |
| **Camera** | CSI-2 camera connector (adapter cable required) |
| **Composite video** | Available via `TV` test point on underside of board |
| **Video decode** | H.264, MPEG-4 decode (1080p30) |
| **Video encode** | H.264 encode (1080p30) |
| **Graphics** | OpenGL ES 1.1, 2.0 |
| **Operating temperature** | -20°C to +70°C |
| **Production lifetime** | Until at least **January 2030** |

---

## Power Consumption

| State | Typical Current @ 5V | Power |
|-------|----------------------|-------|
| **Idle** | ~100–280 mA | ~0.5–1.4W |
| **Bare-board active** | ~350 mA | ~1.75W |
| **Full CPU stress (4 cores)** | ~500–580 mA | ~2.3–3.0W |

> **Note:** A 5V power supply with a minimum of **2.5A** is recommended for stable operation, especially when connecting peripherals.

### Power Optimization Tips

- Disable unused CPU cores to reduce consumption
- Disable HDMI output (`tvservice -o`) when not needed
- Disable onboard LED via `/boot/config.txt`

---

## GPIO Header (40-Pin)

The Raspberry Pi Zero 2 W uses the standard Raspberry Pi 40-pin GPIO header layout (HAT-compatible). The header footprint is **unpopulated** — you'll need to solder your own header pins.

### Pin Layout

```
                    3V3  (1) (2)  5V
          GPIO2/SDA (3) (4)  5V
          GPIO3/SCL (5) (6)  GND
            GPIO4   (7) (8)  GPIO14/TXD
              GND   (9) (10) GPIO15/RXD
           GPIO17  (11) (12) GPIO18/PCM_CLK
           GPIO27  (13) (14) GND
           GPIO22  (15) (16) GPIO23
              3V3  (17) (18) GPIO24
  GPIO10/SPI_MOSI  (19) (20) GND
   GPIO9/SPI_MISO  (21) (22) GPIO25
  GPIO11/SPI_SCLK  (23) (24) GPIO8/SPI_CE0
              GND  (25) (26) GPIO7/SPI_CE1
    GPIO0/ID_SDA   (27) (28) GPIO1/ID_SCL
            GPIO5  (29) (30) GND
            GPIO6  (31) (32) GPIO12/PWM0
      GPIO13/PWM1  (33) (34) GND
  GPIO19/PCM_FS    (35) (36) GPIO16
           GPIO26  (37) (38) GPIO20/PCM_DIN
              GND  (39) (40) GPIO21/PCM_DOUT
```

### GPIO Summary

| Resource | Count / Details |
|----------|-----------------|
| **Total GPIO pins** | 26 general-purpose I/O lines |
| **3.3V power** | 2 pins (pin 1, 17) |
| **5V power** | 2 pins (pin 2, 4) |
| **Ground** | 8 pins (pin 6, 9, 14, 20, 25, 30, 34, 39) |
| **I²C** | 1 bus — SDA (GPIO2), SCL (GPIO3) |
| **SPI** | 1 bus — MOSI (GPIO10), MISO (GPIO9), SCLK (GPIO11), CE0 (GPIO8), CE1 (GPIO7) |
| **UART** | 1 port — TXD (GPIO14), RXD (GPIO15) |
| **PWM** | 2 channels — PWM0 (GPIO12/18), PWM1 (GPIO13/19) |
| **PCM/I²S** | CLK (GPIO18), FS (GPIO19), DIN (GPIO20), DOUT (GPIO21) |
| **1-Wire** | GPIO4 (default) |
| **ID EEPROM** | SDA (GPIO0), SCL (GPIO1) — for HAT identification |

### GPIO Electrical Characteristics

| Parameter | Value |
|-----------|-------|
| Logic level | 3.3V |
| Max current per GPIO pin | 16 mA |
| Max total current (all GPIO combined) | 50 mA |

> **Warning:** GPIO pins are **3.3V only**. Connecting 5V signals directly to GPIO pins will damage the board.

---

## Board Interfaces & Connectors

### Micro USB Ports (×2)

| Port | Function |
|------|----------|
| **USB PWR** | 5V power input only |
| **USB DATA** | USB 2.0 OTG — data transfers, USB devices, or USB gadget mode |

### Mini HDMI Port

- Full HDMI output up to 1080p60
- Requires Mini HDMI to HDMI adapter cable
- HDMI CEC supported

### CSI-2 Camera Connector

- 22-pin FFC connector (smaller than full-size Pi)
- Requires a **Zero-specific CSI adapter cable** (different from standard Pi camera cable)
- Supports Raspberry Pi Camera Modules

### microSD Card Slot

- Push-push type
- Supports SD, SDHC, SDXC cards
- Used for OS boot and storage

---

## Test Points & Solder Pads

The Zero 2 W exposes several test points on the underside of the board:

| Test Point | Function | Description |
|------------|----------|-------------|
| **TV** | Composite video | Solder a wire here for composite video output |
| **RUN** | Hardware reset | Momentarily short to GND to reset the Pi |
| **USB_DP** | USB Data+ | USB differential signal |
| **USB_DM** | USB Data− | USB differential signal |
| **5V** | 5V supply | 5V power rail |
| **3V3** | 3.3V supply | 3.3V regulated rail |
| **1V8** | 1.8V supply | 1.8V internal rail |
| **CORE** | Core voltage | CPU core voltage |
| **WL_ON** | Wireless LAN enable | WiFi control |
| **BT_ON** | Bluetooth enable | Bluetooth control |
| **OTG** | USB OTG ID | USB OTG identification |
| **STATUS_LED** | Activity LED | Board activity LED control |

### Enabling Composite Video

1. Solder a wire to the `TV` test point (video signal) and a nearby `GND` pad
2. Edit `/boot/config.txt`:
   ```
   enable_tvout=1
   sdtv_mode=0      # 0=NTSC, 1=Japanese NTSC, 2=PAL, 3=Brazilian PAL
   sdtv_aspect=1    # 1=4:3, 2=14:9, 3=16:9
   ```
3. Optionally add `hdmi_ignore_hotplug=1` to force composite output

### Using the RUN (Reset) Pad

- Solder a momentary push-button between `RUN` and `GND`
- Pressing the button resets the Pi (equivalent to power cycle)
- **Caution:** Resetting during write operations may corrupt the SD card

---

## Wireless & Networking

### WiFi

| Parameter | Value |
|-----------|-------|
| Standard | IEEE 802.11 b/g/n |
| Frequency | 2.4 GHz |
| Antenna | Onboard PCB antenna |
| Security | WPA/WPA2/WPA3 |

### Bluetooth

| Parameter | Value |
|-----------|-------|
| Version | Bluetooth 4.2 |
| BLE | Bluetooth Low Energy supported |
| Profiles | Various (A2DP, HID, etc.) |

---

## Multimedia

### Video Output

| Feature | Specification |
|---------|---------------|
| HDMI | Mini HDMI, up to 1080p60 |
| Composite | Via `TV` test point (requires config) |
| HDMI CEC | Supported |

### Video Decode / Encode

| Codec | Capability |
|-------|------------|
| H.264 decode | 1080p30 |
| MPEG-4 decode | 1080p30 |
| H.264 encode | 1080p30 |

### Graphics

| Feature | Specification |
|---------|---------------|
| GPU | VideoCore IV |
| OpenGL ES | 1.1, 2.0 |

---

## Physical Specification

### Dimensions

```
        ┌──────────────── 65mm ────────────────┐
        │                                       │
  30mm  │     ┌──┐                        ┌──┐  │
        │     │  │  Mounting holes (×4)   │  │  │  3.5mm
        │     └──┘                        └──┘  │  (board
        │                                       │   height)
        └───────────────────────────────────────┘
```

| Dimension | Value |
|-----------|-------|
| Length | 65 mm |
| Width | 30 mm |
| Height (max) | ~3.5 mm (excluding connectors) |
| Mounting holes | 4× (corner locations) |
| Mounting hole spacing (length) | 58 mm (between centers) |
| Mounting hole spacing (width) | 23 mm (between centers) |
| Mounting hole offset from edges | 3.5 mm |

### Key Component Positions (from left edge)

| Distance | Component |
|----------|-----------|
| 12.4 mm | First mounting hole center |
| 41.4 mm | Camera connector center |
| 54.0 mm | Second mounting hole center |

---

## Supported Operating Systems

- **Raspberry Pi OS** (32-bit and 64-bit) — recommended
- Ubuntu Server
- DietPi
- Various other Linux distributions with ARM64 support

> **Note:** 64-bit OS recommended to take full advantage of the Cortex-A53 architecture.

---

## Comparison with Other Pi Zero Models

| Feature | Zero | Zero W | **Zero 2 W** |
|---------|------|--------|-------------|
| Processor | BCM2835 (1 core, 1GHz) | BCM2835 (1 core, 1GHz) | **BCM2710A1 (4 cores, 1GHz)** |
| RAM | 512MB | 512MB | **512MB** |
| WiFi | No | 802.11n | **802.11n** |
| Bluetooth | No | BT 4.1, BLE | **BT 4.2, BLE** |
| Form factor | 65×30mm | 65×30mm | **65×30mm** |
| GPIO | 40-pin | 40-pin | **40-pin** |
| USB | Micro USB OTG | Micro USB OTG | **Micro USB OTG** |
| Video | Mini HDMI | Mini HDMI | **Mini HDMI** |
| Camera | CSI-2 | CSI-2 | **CSI-2** |

---

## Design Resources

- [Product Brief (PDF)](https://datasheets.raspberrypi.com/rpizero2/raspberry-pi-zero-2-w-product-brief.pdf)
- [Reduced Schematics](https://datasheets.raspberrypi.com/rpizero2/raspberry-pi-zero-2-w-reduced-schematics.pdf)
- [Mechanical Drawing](https://datasheets.raspberrypi.com/rpizero2/raspberry-pi-zero-2-w-mechanical-drawing.pdf)
- [Test Pad Specification](https://datasheets.raspberrypi.com/rpizero2/raspberry-pi-zero-2-w-test-pads.pdf)
- [BCM2837 ARM Peripherals Specification](https://datasheets.raspberrypi.com/bcm2835/bcm2835-peripherals.pdf) (functionally equivalent to BCM2710A1)
- [Compliance Documentation](https://pip.raspberrypi.com)

---

## Warnings

- Any external power supply must comply with relevant regulations and standards applicable in the country of intended use
- Operate in a well-ventilated environment; if used inside a case, the case should not be covered
- Place on a stable, flat, non-conductive surface during use
- Connection of incompatible devices may affect compliance, damage the unit, and void the warranty
- All peripherals must comply with relevant standards for the country of use
- Cables and connectors of all peripherals must have adequate insulation

## Safety Instructions

- Do not expose to water or moisture, or place on a conductive surface whilst in operation
- Do not expose to heat from any source; designed for reliable operation at normal ambient temperatures
- Take care to avoid mechanical or electrical damage to the printed circuit board and connectors
- While powered, avoid handling the PCB, or only handle by the edges to minimise ESD risk

---

*The terms HDMI, HDMI High-Definition Multimedia Interface, and the HDMI Logo are trademarks or registered trademarks of HDMI Licensing Administrator, Inc.*

*Raspberry Pi is a trademark of Raspberry Pi Ltd*
