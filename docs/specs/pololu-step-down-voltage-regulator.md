# Pololu 5V, 5.5A Step-Down Voltage Regulator D36V50F5

> **Source:** [Pololu Product #4091](https://www.pololu.com/product/4091)
> **Category:** Step-Down (Buck) Voltage Regulators → D36V50Fx Family

---

## Overview

The D36V50Fx family of synchronous buck (step-down) voltage regulators generates lower output voltages from input voltages as high as 50V. They are switching regulators (SMPS / DC-to-DC converters), which makes them much more efficient than linear voltage regulators, especially when the difference between the input and output voltage is large.

These regulators can typically support continuous output currents between 2A and 9A, depending on the input and output voltage.

## Key Specifications

| Parameter | Value |
|-----------|-------|
| **Output voltage** | 5V (4% accuracy) |
| **Input voltage** | 5.5V to 50V (min input subject to dropout voltage) |
| **Typical max continuous output current** | 3.5A to 8A (varies with input voltage) |
| **Typical efficiency** | 80% to 95% |
| **Switching frequency** | ~500 kHz (heavy loads) |
| **No-load quiescent current** | 2–4 mA typical |
| **Sleep mode current** | ~10–20 µA per volt on VIN |
| **Dimensions** | 1″ × 1″ × 0.375″ (25.4 × 25.4 × 9.5 mm) |
| **Mounting holes** | Three 0.086″ holes for #2 or M2 screws |

## Features

- Input reverse voltage protection up to 40V
- Output undervoltage and overvoltage protection
- Over-current and short-circuit protection
- Thermal shutdown
- Soft-start feature (limits inrush current, gradually ramps output voltage)
- Power-save mode with ultrasonic operation (keeps switching frequency above 20 kHz)
- **Enable (EN) input** with precise cutoff threshold for low-power sleep state
- **"Power good" (PG) output** — goes low when output voltage is out of regulation

## Connections

| Pin | Function | Description |
|-----|----------|-------------|
| **VIN** | Input voltage | 5.5V to 50V input power |
| **VRP** | Input after reverse protection | Access input voltage after reverse protection; can bypass protection |
| **VOUT** | Regulated output | 5V regulated output |
| **GND** | Ground | Common ground |
| **EN** | Enable | Active high (default enabled). Below 1.2V = sleep mode. |
| **PG** | Power Good | Open-drain output; low when output is out of regulation |

- All connections are on a 0.1″ grid for breadboard compatibility
- Power connections (VIN, VRP, VOUT, GND) are duplicated across both rows
- EN and PG are not duplicated — take care to avoid shorting when installing headers

> **Note:** Each header pin is rated for 3A (6A combined per pair). For higher-power applications, solder thick wires directly to the board.

## Dropout Voltage

The dropout voltage is the minimum amount by which the input voltage must exceed the output voltage. It increases approximately linearly with load. For 5V output, generally plan for VIN ≥ 6V under load.

## Power-Save Mode

- At light loads, reduces switching frequency to improve efficiency
- Keeps frequency above the audible range (20 kHz) — ultrasonic operation
- Under heavy load, the switcher operates in PWM mode regardless

## Thermal Considerations

> **Warning:** During normal operation, this product can get hot enough to burn you. Take care when handling.

Maximum continuous output current depends on:
- Input voltage
- Ambient temperature
- Air flow
- Heat sinking

## D36V50Fx Family

| Part # | Output Voltage |
|--------|----------------|
| #4090 | 3.3V |
| **#4091** | **5V** |
| #4092 | 6V |
| #4093 | 7V |
| #4094 | 9V |
| #4095 | 12V |

## Included Hardware

- 1× D36V50F5 regulator board
- 1×12 (or 2×6) straight male header strips
