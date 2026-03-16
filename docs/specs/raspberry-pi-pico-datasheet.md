# Raspberry Pi Pico Datasheet

> **Source:** [Raspberry Pi Pico Datasheet (PDF)](https://datasheets.raspberrypi.com/pico/pico-datasheet.pdf)
> **Build Date:** 2024-10-15
> **© 2020–2024 Raspberry Pi Ltd**

---

## 1. About Raspberry Pi Pico

Raspberry Pi Pico is a microcontroller board based on the Raspberry Pi RP2040 microcontroller chip. It has been designed to be a low cost yet flexible development platform for RP2040.

### Key Features

- **RP2040 microcontroller** with 2MB Flash
- **Micro-USB B** port for power and data (and for reprogramming the Flash)
- **40-pin** 21×51 'DIP' style 1mm thick PCB with 0.1″ through-hole pins and edge castellations
  - Exposes 26 multi-function 3.3V GPIO
  - 23 GPIO are digital-only and 3 are ADC capable
  - Can be surface mounted as a module
- **3-pin ARM Serial Wire Debug (SWD)** port
- Simple yet highly flexible power supply architecture
  - Various options for powering from micro-USB, external supplies or batteries
- High quality, low cost, high availability
- Comprehensive SDK, software examples and documentation

### RP2040 Highlights

- Dual-core Cortex M0+ at up to 133MHz (on-chip PLL for variable core frequency)
- 264kB multi-bank high performance SRAM
- External Quad-SPI Flash with eXecute In Place (XIP) and 16kB on-chip cache
- High performance full-crossbar bus fabric
- On-board USB1.1 (device or host)
- 30 multi-function GPIO (4 can be used for ADC)
  - 1.8–3.3V IO Voltage (**Pico IO voltage is fixed at 3.3V**)
- 12-bit 500ksps Analogue to Digital Converter (ADC)
- Digital peripherals:
  - 2× UART, 2× I2C, 2× SPI, 16× PWM channels
  - 1× Timer with 4 alarms, 1× Real Time Counter
- 2× Programmable IO (PIO) blocks, 8 state machines total
  - Flexible, user-programmable high-speed IO
  - Can emulate interfaces such as SD Card and VGA

### Design Files

| Resource | Description |
|----------|-------------|
| Schematic | Full schematic in Appendix B; also distributed alongside layout files |
| Layout | Full CAD files (Cadence Allegro PCB Editor format) |
| STEP 3D | 3D model for visualization and fit check |
| Fritzing | Fritzing part for breadboard layouts |

---

## 2. Mechanical Specification

Raspberry Pi Pico is a single-sided **51×21mm**, 1mm thick PCB with a micro-USB port overhanging the top edge and dual castellated/through-hole pins around the remaining edges.

- **40 main user pins** on a 2.54mm (0.1″) pitch grid with 1mm holes
- Compatible with veroboard and breadboard
- **4× 2.1mm (± 0.05mm)** drilled mounting holes

### 2.1. Pico Pinout

The Pico pinout directly brings out as much of the RP2040 GPIO and internal circuitry function as possible.

#### Internal GPIO Usage

| GPIO | Direction | Function |
|------|-----------|----------|
| GPIO29 | Input | ADC mode (ADC3) — measures VSYS/3 |
| GPIO25 | Output | Connected to user LED |
| GPIO24 | Input | VBUS sense — high if VBUS is present |
| GPIO23 | Output | Controls on-board SMPS Power Save pin |

#### Other Pins (40-pin interface)

| Pin # | Name | Description |
|-------|------|-------------|
| 40 | VBUS | 5V from micro-USB port (0V if USB not connected) |
| 39 | VSYS | Main system input voltage (1.8V to 5.5V) |
| 37 | 3V3_EN | SMPS enable pin (pulled high via 100kΩ to VSYS; short low to disable 3.3V) |
| 36 | 3V3 | 3.3V supply from on-board SMPS (max ~300mA recommended external load) |
| 35 | ADC_VREF | ADC power supply/reference voltage (filtered from 3.3V) |
| 33 | AGND | Analog ground reference for GPIO26–29 |
| 30 | RUN | RP2040 enable pin (~50kΩ internal pull-up to 3.3V; short low to reset) |

#### Test Points

| Test Point | Function |
|------------|----------|
| TP1 | Ground (close coupled for differential USB) |
| TP2 | USB DM |
| TP3 | USB DP |
| TP4 | GPIO23/SMPS PS pin (do not use) |
| TP5 | GPIO25/LED (not recommended for external use) |
| TP6 | BOOTSEL |

### 2.3. Recommended Operating Conditions

| Parameter | Value |
|-----------|-------|
| Operating Temp Max | 85°C (including self-heating) |
| Operating Temp Min | -20°C |
| VBUS | 5V ± 10% |
| VSYS Min | 1.8V |
| VSYS Max | 5.5V |
| Recommended max ambient | 70°C |

---

## 3. Electrical Specification

### 3.1. Power Consumption

Power consumption measurements are from VBUS at 5V for three typical Pico devices with various software use cases.

#### DORMANT Mode

The lowest power state. Typical VBUS current:

| Temperature | Current |
|-------------|---------|
| -25°C | ~1.2 mA |
| 25°C | ~0.8 mA |
| 85°C | ~1.4 mA |

#### SLEEP Mode

Low power state with some clock infrastructure alive:

| Temperature | Current |
|-------------|---------|
| -25°C | ~1.4 mA |
| 25°C | ~1.3 mA |
| 85°C | ~1.9 mA |

#### BOOTSEL Mode (USB idle)

| Temperature | Current |
|-------------|---------|
| -25°C | ~9.4 mA |
| 25°C | ~8.7 mA |
| 85°C | ~9.0 mA |

#### BOOTSEL Mode (USB active)

| Temperature | Current |
|-------------|---------|
| -25°C | ~10.5 mA |
| 25°C | ~9.9 mA |
| 85°C | ~10.1 mA |

#### Popcorn Demo (VGA, SD card, I2S audio)

| Temperature | Average | Maximum |
|-------------|---------|---------|
| -25°C | ~85.6 mA | ~91.6 mA |
| 25°C | ~86.5 mA | ~91.6 mA |
| 85°C | ~88.0 mA | ~92.8 mA |

---

## 4. Applications Information

### 4.1. Programming the Flash

- **USB method:** Hold BOOTSEL while powering up → Pico appears as USB Mass Storage Device → drag `.uf2` file onto it
- **SWD method:** Use Serial Wire Debug port to load and run code without button presses
- USB boot code is stored in ROM and cannot be overwritten

### 4.2. General Purpose I/O

- Pico GPIO is powered from the on-board 3.3V rail (fixed at 3.3V)
- 26 of 30 possible RP2040 GPIO pins exposed
- GPIO0–GPIO22: digital only
- GPIO26–28: digital or ADC (software selectable)

> **Note:** ADC-capable GPIO26–29 have an internal reverse diode to VDDIO (3V3). Input voltage must not exceed VDDIO + ~300mV. If RP2040 is unpowered, voltage applied to these pins will leak through the diode. Normal digital GPIO 0–25 do not have this restriction.

### 4.3. Using the ADC

- RP2040 ADC uses its own power supply as reference (no on-board reference)
- ADC_AVDD generated from 3.3V via R-C filter (201Ω into 2.2μF)
- Inherent offset of ~30mV due to ADC current draw through the filter resistor
- **Tip:** Drive GPIO23 high to force SMPS into PWM mode, reducing ripple on ADC supply
- **Tip:** For improved performance, connect an external 3.0V shunt reference (e.g., LM4040) to ADC_VREF

### 4.4. Powerchain

- **VBUS** → Schottky diode (D1) → **VSYS** → RT6150 buck-boost SMPS → **3.3V**
- VSYS is R-C filtered and divided by 3, monitorable on ADC channel 3 (crude battery monitor)
- Buck-boost SMPS maintains 3.3V from ~1.8V to 5.5V input

#### GPIO23 — Power Save Control

| GPIO23 State | SMPS Mode | Efficiency | Ripple |
|-------------|-----------|------------|--------|
| Low (default) | PFM (Pulse Frequency Modulation) | High at light loads | Higher |
| High | PWM (Pulse Width Modulation) | Lower at light loads | Lower |

### 4.5. Powering Pico

1. **USB only:** Plug in micro-USB. Can short VBUS to VSYS to eliminate Schottky diode drop.
2. **External supply only:** Connect to VSYS (1.8V to 5.5V). Do not use USB.
3. **Dual supply (diode OR):** Feed second supply into VSYS via another Schottky diode.
4. **Dual supply (P-FET OR):** Use P-channel MOSFET (e.g., DMG2305UX) for better efficiency — gate controlled by VBUS, disconnects secondary source when VBUS is present.

> **Important:** If using USB Host mode, you must provide 5V to the VBUS pin.

> **Caution:** Lithium-Ion cells must have adequate protection against over-discharge, over-charge, and overcurrent.

### 4.6. Using a Battery Charger

A 'Power Path' type charger can seamlessly manage swapping between powering from battery or input source. Feed VBUS to the charger input and VSYS from the charger output via a P-FET arrangement.

### 4.7. USB

- RP2040 has an integrated USB1.1 PHY and controller (Device or Host mode)
- Pico adds two 27Ω external resistors and a standard micro-USB port

### 4.8. Debugging

- 3-pin SWD debug header on the lower edge of the board
- RP2040 has internal pull-ups on SWDIO and SWCLK (~60kΩ each)

---

## Appendix A: Availability

Raspberry Pi guarantees availability of Raspberry Pi Pico until at least **January 2028**.

### Ordering Codes

| Model | Order Code | RRP |
|-------|------------|-----|
| Raspberry Pi Pico | SC0915 / SC0916 | US$4.00 |
| Raspberry Pi Pico H | SC0917 | US$5.00 |
