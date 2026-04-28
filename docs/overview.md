# Project Description: The "Rollie Mk. I" — Spherical Robot

## 1. Overview

**Objective**
To construct an autonomous spherical robot (approx. 120mm diameter) using a gravity-stabilized internal pendulum ("hamster") drive. The robot rolls by displacing its internal center of mass — pitching the stator forward causes the ball to roll forward.

### Core Architecture (The "Split-Brain")

* **The Reflexes (Cerebellum):** A **Raspberry Pi Pico 2 W** runs a dedicated MicroPython control loop. It reads the **BNO055 IMU** and drives the motors via the **Pimoroni Motor SHIM** to hold a precise pitch angle. It acts as an **Angle-Holding Coprocessor**.
* **The Cognition (Cerebrum):** A **Raspberry Pi Zero 2 W** runs Linux. It handles WiFi, Computer Vision (Pi Camera), AI, and high-level path planning. It sends angle commands (e.g., `<PITCH:12>`) to the Pico via UART.

### The Drive Mechanism (Gravity-Stabilized Pendulum)

1. **Stator (Internal):** A weighted cylinder hangs inside the ball. Gravity pulls its battery-laden bottom (**Keel**) downwards, keeping it vertical.
2. **Rotor (External):** Two hemispherical shells form the "skin," mechanically isolated from the Stator by Lazy Susan bearings.
3. **Action:** Motors bolted to the Stator drive the Rotors. Since the Stator resists rotation (gravity), the force rolls the ball. To roll forward, the Pico pitches the stator forward, shifting the center of mass.

---

## 2. Pico Firmware Architecture (The 5-Step Tethered Checklist)

### Step 1: Sensor Fusion (Zeroing the Pendulum)

The BNO055 IMU provides fused accelerometer + gyroscope data. Inside a rolling sphere, the stator acts like a pendulum susceptible to harmonic swinging (wobbling when stopping).

**Goal:** Fast, clean reading of the stator's absolute pitch relative to gravity. Software filter tuned to ignore high-frequency wheel vibrations while catching low-frequency pendulum swings so the motors can counteract them.

The BNO055 runs its own Cortex-M0 sensor fusion internally — we read Euler angles directly via I2C.

### Step 2: PID "Angle Tracking" Loop

Unlike a standard balancing robot (target = 0°), in Rollie the **target angle dictates speed**.

- **Target 0°** → stationary (camera level)
- **Target 10°** → rolling forward at constant speed
- **Target -10°** → rolling backward

The PID loop must smoothly drive motors to hit the target and lock it there rigidly, preventing the stator from bouncing (e.g., between 5° and 15° when targeting 10°).

### Step 3: Motor Deadband & Shell Traction

Find the exact minimum motor power to overcome rolling resistance of the shell on the floor. If the PID commands a small angle change but motors can't overcome friction, the integral term winds up and eventually jerks the camera violently. Deadband calibration ensures smooth, cinematic panning.

### Step 4: Anti-Tumble Limit

If acceleration is too aggressive or the ball hits an obstacle, the stator can swing 360° inside the shell, tearing wiring. **Hard angle limit:** if pitch exceeds ±45°, the Pico instantly overrides PID and applies reverse torque / dynamic braking.

### Step 5: UART Listener (Pi Zero → Pico)

The Pi Zero sends commands like `<PITCH:12>` via UART. The Pico receives the target, executes the PID loop to hold the stator at exactly 12°, and the ball rolls as a physical result.

**Protocol:**
- `<PITCH:xx>` — set target pitch angle (positive = forward)
- `<YAW:xx>` — differential steering (positive = right)
- `<STOP>` — emergency stop, target = 0°, braking

---

## 3. Hardware Pin Map

### Pimoroni Motor SHIM (Soldered onto Pico)

The SHIM is soldered directly onto the top of the Pico headers as per manual. It uses a DRV8833 dual H-bridge.

| Function | GPIO | Physical Pin | Notes |
|---|---|---|---|
| Motor A IN1 | GP6 | Pin 9 | SHIM internal (do NOT use) |
| Motor A IN2 | GP7 | Pin 10 | SHIM internal (do NOT use) |
| Motor B IN1 | GP27 | Pin 32 | SHIM internal (do NOT use) |
| Motor B IN2 | GP26 | Pin 31 | SHIM internal (do NOT use) |
| I2C SDA (STEMMA QT) | GP4 | Pin 6 | (Unused, moved to GP2 to free up UART0) |
| I2C SCL (STEMMA QT) | GP5 | Pin 7 | (Unused, moved to GP3 to free up UART0) |
| NSLEEP | 3V3_EN | — | Always enabled |

### BNO055 IMU (Moved from SHIM STEMMA QT Connector)

The STEMMA QT cable data lines must be routed to GP2 (SDA) and GP3 (SCL) instead of the SHIM's directly.

| BNO055 Pin | Pico Pin | Function |
|---|---|---|
| VIN | 3V3 | Power |
| GND | GND | Ground |
| SDA | GP2 | I2C Data (Moved from GP4) |
| SCL | GP3 | I2C Clock (Moved from GP5) |

I2C Address: `0x28` (default)

### UART — Brain Link (Pi Zero ↔ Pico)

Wires crossed (TX→RX):

| Pi Zero 2 W | Pin # | Pico | Pin # | Wire Color |
|---|---|---|---|---|
| GPIO 14 (TX) | Pin 8 | GP 1 (RX) | Pin 2 | Yellow |
| GPIO 15 (RX) | Pin 10 | GP 0 (TX) | Pin 1 | Orange |
| GND | Pin 6 | GND | Pin 3 | **Black** |

### Motor Encoders (Pololu 50:1 HP with 12 CPR)

**Motor power wires** (Red + Black) connect to the SHIM's motor output pads (soldered).
**Encoder signal wires** connect to Pico GPIO pins (via Dupont connectors to headers).

**Left Motor (Motor 1 / SHIM Motor A)**

| Signal | Wire Color | Connects To | Pin |
|---|---|---|---|
| Motor (+) | Red (thick) | SHIM Pad 1+ | Soldered |
| Motor (−) | Black (thick) | SHIM Pad 1− | Soldered |
| Encoder VCC | Blue | Pico 3V3(OUT) | Pin 36 |
| Encoder GND | Green | Common GND rail | Protoboard |
| Encoder Ch A | Yellow | Pico **GP18** | Pin 24 |
| Encoder Ch B | White | Pico **GP19** | Pin 25 |

**Right Motor (Motor 2 / SHIM Motor B)**

| Signal | Wire Color | Connects To | Pin |
|---|---|---|---|
| Motor (+) | Red (thick) | SHIM Pad 2+ | Soldered |
| Motor (−) | Black (thick) | SHIM Pad 2− | Soldered |
| Encoder VCC | Blue | Pico 3V3(OUT) | Pin 36 |
| Encoder GND | Green | Common GND rail | Protoboard |
| Encoder Ch A | Yellow | Pico **GP16** | Pin 21 |
| Encoder Ch B | White | Pico **GP17** | Pin 22 |

> **Encoder Pin Warning:** Do NOT move encoders to GP6, 7, 26, or 27. Those are used by the Motor SHIM's DRV8833.

### Encoder Constants

| Parameter | Value |
|---|---|
| Motor gear ratio | 51.45:1 |
| Encoder CPR (motor shaft) | 12 |
| Counts per output revolution | 12 × 51.45 ≈ **617** |

---

## 4. Full Parts Listing

### Electronics Core

| Qty | Component | Product Name | SKU |
|---|---|---|---|
| 1 | Brain | Raspberry Pi Zero 2 W | CE08211 |
| 1 | Reflexes | Raspberry Pi Pico 2 W | — |
| 1 | IMU | Adafruit BNO055 9-DOF (STEMMA QT) | ADA4646 |
| 1 | Regulator | Pololu 5V, 3.2A Step-Down (D24V30F5) | POLOLU-3782 |
| 1 | Motor Driver | Pimoroni Motor SHIM for Pico | PIM617 |
| 1 | Motherboard | ProtoBoard 2" (58×78mm) | FIT0203 |

### Drive System

| Qty | Component | Product Name | SKU |
|---|---|---|---|
| 2 | Motors | Pololu 50:1 Micro Metal Gearmotor HP 6V (Extended Shaft + Encoder) | POLOLU-5161 |
| 2 | Cables | 6-Pin JST SH-Style Cable (16cm) | POLOLU-4766 |
| 2 | Bearings | 75mm Lazy Susan Bearing | — |
| 1 | Battery | GNB 7.4V 2S LiPo (XT30) | — |

---

## 5. Assembly Notes

> **The SHIM Sandwich:** Solder the Pimoroni Motor SHIM onto the Pico's pins **before** plugging the Pico into the motherboard sockets. Text on SHIM and pin labels on Pico back should face each other.

> **BNO055 Connection:** The BNO055 SDA connects to Pico GP2 and SCL to GP3 (moved from the SHIM's default GP4/GP5 to avoid UART conflicts). Power and ground can still be drawn from the SHIM or common rails.

> **Cable Modifications:** The 6-pin Pololu motor cables were severed — thick Red+Black soldered to SHIM motor pads, thin Green/White/Yellow/Blue crimped with Dupont connectors for Pico GPIO headers.

> **The Keel Weight:** Battery must be mounted as low as possible inside the stator ring. The robot will not balance correctly if the battery is high.

> **Cable Slack:** Motor cables must be zip-tied to the Stator frame so they don't rub against the rotating Lazy Susan or outer shells.

---

## 6. Software Stack

| Layer | Runs On | Language | Responsibility |
|---|---|---|---|
| `main.py` | Pico 2 W | MicroPython v1.27.0 | PID angle control, IMU reading, raw PWM motor driving, UART listening |
| `boot.py` | Pico 2 W | MicroPython | UART init, boot banner |
| `bno055_minimal.py` | Pico 2 W | MicroPython | Minimal BNO055 I2C driver |
| `camera_feed.py` | Pi Zero 2 W | Python 3 | Camera streaming, AI, high-level control |
| `sync_and_run_on_py.sh` | Dev Machine | Bash | Deploys firmware to Pico (USB), syncs to Pi Zero |
| `keyboard_control.py` | Dev Machine | Python 3 | Debug tool — sends angle commands via USB serial |

### Communication Flow

```
Dev Machine (keyboard_control.py)
    ↓ USB Serial (/dev/ttyACM0, 9600 baud)
Pico 2 W (main.py — PID angle controller)
    ↕ I2C1 (GP2/GP3)       ↕ PWM (SHIM GP6/7/26/27)
BNO055 IMU                  Motors (via DRV8833)

Future (untethered):
Pi Zero 2 W (camera_feed.py)
    ↓ UART0 (GP0/GP1, 9600 baud)
Pico 2 W (main.py)
```