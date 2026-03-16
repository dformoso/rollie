# Motor SHIM for Pico — Schematic

> **Source:** [Pimoroni Motor SHIM Schematic (PDF)](https://cdn.shopify.com/s/files/1/0174/1800/files/motor_shim_schematic.pdf?v=1652702111)

---

## Motor Driver IC

**DRV8833PWP** — Dual H-Bridge Motor Driver

## Pi Pico Pin Mapping

| Pico Pin | Function | Description |
|----------|----------|-------------|
| GP6 | MOT_AP | Motor A, Input 1 (AIN1) |
| GP7 | MOT_AN | Motor A, Input 2 (AIN2) |
| GP27 (ADC1) | MOT_BP | Motor B, Input 1 (BIN1) |
| GP26 (ADC0) | MOT_BN | Motor B, Input 2 (BIN2) |
| GP4 | SDA | I2C Data (Qw/ST connector) |
| GP5 | SCL | I2C Clock (Qw/ST connector) |
| 3V3_EN | NSLEEP | DRV8833 sleep control (active low) |

## DRV8833 Connections

```
                 DRV8833PWP
           ┌────────────────────┐
    VM ────┤ VM         AIN1   ├──── MOT_AP (GP6)
           │            AIN2   ├──── MOT_AN (GP7)
    VCP ───┤ VCP        BIN1   ├──── MOT_BP (GP27)
           │            BIN2   ├──── MOT_BN (GP26)
    VINT ──┤ VINT              │
           │           AOUT1   ├──── OUT_MOT_AP ─── Motor A (+)
 3V3_EN ──┤ NSLEEP    AOUT2   ├──── OUT_MOT_AN ─── Motor A (-)
           │           BOUT1   ├──── OUT_MOT_BP ─── Motor B (+)
           │  NFAULT   BOUT2   ├──── OUT_MOT_BN ─── Motor B (-)
           │                   │
           │  AISEN            │
           │  BISEN            │
    GND ───┤ GND               │
           └────────────────────┘
```

## Current Sensing Resistors

- **R13, R14:** 0.82Ω each
- **Current limit formula:** `Current = 200mV / Resistance`
- With 0.82Ω: **0.244A** current limit per motor channel
- **Resistor power dissipation:** 0.244A × 0.2V = **0.049W**

## Motor Connectors

Two JST-ZH 2-pin connectors:

| Connector | Pin 1 | Pin 2 |
|-----------|-------|-------|
| Motor A | OUT_MOT_AP | OUT_MOT_AN |
| Motor B | OUT_MOT_BP | OUT_MOT_BN |

## Qw/ST (I2C) Connector

| Pin | Signal |
|-----|--------|
| 1 | — |
| 2 | — |
| 3 | SDA (GP4) |
| 4 | SCL (GP5) |
