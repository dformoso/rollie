# Adafruit BNO055 Absolute Orientation Sensor

> **Source:** [Adafruit Learning Guide](https://learn.adafruit.com/adafruit-bno055-absolute-orientation-sensor)
> **Last Updated:** 2025-05-16

---

## Overview

If you've ever ordered and wired up a 9-DOF sensor, chances are you've also realized the challenge of turning the sensor data from an accelerometer, gyroscope and magnetometer into actual "3D space orientation"! Orientation is a hard problem to solve. The sensor fusion algorithms (the secret sauce that blends accelerometer, magnetometer and gyroscope data into stable three-axis orientation output) can be mind-numbingly difficult to get right and implement on low cost real time systems.

Bosch is the first company to get this right by taking a MEMS accelerometer, magnetometer and gyroscope and putting them on a single die with a high speed ARM Cortex-M0 based processor to digest all the sensor data, abstract the sensor fusion and real time requirements away, and spit out data you can use in quaternions, Euler angles or vectors.

> **Note:** The BNO055 I2C implementation violates the I2C protocol in some circumstances. This causes it not to work well with certain chip families. It does not work well with NXP i.MX RT1011, and it does not work well with I2C multiplexers. With ESP32 and ESP32-S3, CircuitPython 9.2.2 and later (which use ESP-IDF 5.3.2 and later) work better. Operation with SAMD51, RP2040, STM32F4, and nRF52840 is more reliable.

The board includes SparkFun qwiic compatible STEMMA QT connectors for the I2C bus so you don't even need to solder!

### Data Output

The BNO055 can output the following sensor data:

- **Absolute Orientation (Euler Vector, 100Hz)** — Three axis orientation data based on a 360° sphere
- **Absolute Orientation (Quaternion, 100Hz)** — Four point quaternion output for more accurate data manipulation
- **Angular Velocity Vector (100Hz)** — Three axis of 'rotation speed' in rad/s
- **Acceleration Vector (100Hz)** — Three axis of acceleration (gravity + linear motion) in m/s²
- **Magnetic Field Strength Vector (20Hz)** — Three axis of magnetic field sensing in micro Tesla (uT)
- **Linear Acceleration Vector (100Hz)** — Three axis of linear acceleration data (acceleration minus gravity) in m/s²
- **Gravity Vector (100Hz)** — Three axis of gravitational acceleration (minus any movement) in m/s²
- **Temperature (1Hz)** — Ambient temperature in degrees Celsius

### Related Resources

- [Datasheet](https://adafru.it/f0H)
- [Adafruit BNO055 Library (GitHub)](https://adafru.it/f0I)
- [Comparing the BNO085 vs BNO055 (Adafruit Forums)](https://adafru.it/19Cb)

---

## Pinouts

> **Note:** The pin order on the STEMMA QT version of the board is not the same as the original version. The pins are the same otherwise.

### Power Pins

| Pin | Description |
|-----|-------------|
| **VIN** | 3.3–5.0V power supply input |
| **3VO** | 3.3V output from the on-board linear voltage regulator, up to ~50mA |
| **GND** | Common/GND pin for power and logic |

### I2C Pins

| Pin | Description |
|-----|-------------|
| **SCL** | I2C clock pin. Works with 3V or 5V logic. 10K pullup included. |
| **SDA** | I2C data pin. Works with 3V or 5V logic. 10K pullup included. |

### STEMMA QT Version

STEMMA QT connectors allow you to connect to dev boards with STEMMA QT connectors or to other things with various associated accessories.

### Other Pins

| Pin | Description |
|-----|-------------|
| **RST** | Hardware reset pin. Set low then high to reset. 5V safe. |
| **INT** | HW interrupt output pin (not currently supported in Adafruit library). 3V output. |
| **ADR** | Set high to change the default I2C address if connecting two ICs on the same bus. |
| **PS0 / PS1** | Mode change pins (HID-I2C, UART). Normally left unconnected. |

---

## Assembly

1. **Prepare the header strip:** Cut the strip to length if necessary. Insert into a breadboard — long pins down.
2. **Add the breakout board:** Place the breakout board over the pins so that the short pins poke through the breakout pads.
3. **Solder:** Be sure to solder all pins for reliable electrical contact. Solder the longer power/data strip first.

---

## Arduino Code

### Wiring for Arduino

Connect the assembled BNO055 breakout to an Arduino Uno:

- **Vin** (red wire) → power supply (3–5V)
- **GND** (black wire) → common ground
- **SCL** (blue wire) → I2C clock (A5 on Uno, digital 21 on Mega, digital 3 on Leonardo)
- **SDA** (yellow wire) → I2C data (A4 on Uno, digital 20 on Mega, digital 2 on Leonardo)

> **Note:** If using a Genuino Zero or Arduino Zero with the built-in EDBG interface, you may need to use I2C address `0x29` since `0x28` is 'taken' by the DBG chip.

### Software

Install via the Arduino Library Manager:

1. Search for and install the **Adafruit Sensor** library
2. Search for and install the **Adafruit BNO055** library

### Adafruit Unified Sensor System

```cpp
#include <Wire.h>
#include <Adafruit_Sensor.h>
#include <Adafruit_BNO055.h>
#include <utility/imumaths.h>

Adafruit_BNO055 bno = Adafruit_BNO055(55);

void setup(void) {
    Serial.begin(9600);
    Serial.println("Orientation Sensor Test");

    if (!bno.begin()) {
        Serial.print("Ooops, no BNO055 detected ... Check your wiring or I2C ADDR!");
        while (1);
    }

    delay(1000);
    bno.setExtCrystalUse(true);
}

void loop(void) {
    sensors_event_t event;
    bno.getEvent(&event);

    Serial.print("X: "); Serial.print(event.orientation.x, 4);
    Serial.print("\tY: "); Serial.print(event.orientation.y, 4);
    Serial.print("\tZ: "); Serial.print(event.orientation.z, 4);
    Serial.println("");

    delay(100);
}
```

### Raw Sensor Data

Key raw data functions:

- **`.getVector(adafruit_vector_type_t vector_type)`** — Returns 3-axis vector data
  - `VECTOR_MAGNETOMETER` (uT)
  - `VECTOR_GYROSCOPE` (rad/s)
  - `VECTOR_EULER` (degrees, 0–359)
  - `VECTOR_ACCELEROMETER` (m/s²)
  - `VECTOR_LINEARACCEL` (m/s²)
  - `VECTOR_GRAVITY` (m/s²)

- **`.getQuat(void)`** — Returns a Quaternion (easier and more accurate than Euler angles)

- **`.getTemp(void)`** — Returns ambient temperature in °C

---

## Device Calibration

The BNO055 includes internal algorithms to constantly calibrate the gyroscope, accelerometer and magnetometer inside the device.

Four calibration registers return a value between `0` (uncalibrated) and `3` (fully calibrated).

> **Important:** When running in NDOF mode, any data where the system calibration value is `0` should generally be ignored.

### Generating Calibration Data

- **Gyroscope:** The device must be standing still in any position
- **Magnetometer:** Perform figure-8 motions (with recent devices, fast magnetic compensation takes place with normal movement)
- **Accelerometer:** Place in 6 standing positions for +X, -X, +Y, -Y, +Z and -Z

### Persisting Calibration Data

The BNO doesn't contain any internal EEPROM. You will need to perform a new calibration every time the device starts up, or manually restore previous calibration values.

---

## Python & CircuitPython

### I2C Initialization

```python
import board
import busio
import adafruit_bno055

i2c = busio.I2C(board.SCL, board.SDA)
sensor = adafruit_bno055.BNO055_I2C(i2c)
```

### UART Initialization (CircuitPython)

```python
import board
import busio
import adafruit_bno055

uart = busio.UART(board.TX, board.RX)
sensor = adafruit_bno055.BNO055_UART(uart)
```

### UART Initialization (Python / Raspberry Pi)

```python
import serial
import adafruit_bno055

uart = serial.Serial("/dev/serial0")
sensor = adafruit_bno055.BNO055_UART(uart)
```

### Available Properties

| Property | Description |
|----------|-------------|
| `temperature` | Sensor temperature in °C |
| `acceleration` | (X, Y, Z) accelerometer values in m/s² |
| `magnetic` | (X, Y, Z) magnetometer values in microteslas |
| `gyro` | (X, Y, Z) gyroscope values in degrees/sec |
| `euler` | (heading, roll, pitch) orientation Euler angles |
| `quaternion` | (w, x, y, z) orientation quaternion values |
| `linear_acceleration` | (X, Y, Z) linear acceleration (no gravity) in m/s² |
| `gravity` | (X, Y, Z) gravity acceleration (no linear) in m/s² |

### Full Example Code

```python
import time
import board
import adafruit_bno055

i2c = board.I2C()
sensor = adafruit_bno055.BNO055_I2C(i2c)

last_val = 0xFFFF

def temperature():
    global last_val
    result = sensor.temperature
    if abs(result - last_val) == 128:
        result = sensor.temperature
        if abs(result - last_val) == 128:
            return 0b00111111 & result
    last_val = result
    return result

while True:
    print(f"Temperature: {sensor.temperature} degrees C")
    print(f"Accelerometer (m/s^2): {sensor.acceleration}")
    print(f"Magnetometer (microteslas): {sensor.magnetic}")
    print(f"Gyroscope (rad/sec): {sensor.gyro}")
    print(f"Euler angle: {sensor.euler}")
    print(f"Quaternion: {sensor.quaternion}")
    print(f"Linear acceleration (m/s^2): {sensor.linear_acceleration}")
    print(f"Gravity (m/s^2): {sensor.gravity}")
    print()
    time.sleep(1)
```

### Python Installation

```bash
sudo pip3 install adafruit-circuitpython-bno055
```

> **Note:** Older versions of the Raspberry Pi firmware do not have I2C clock stretching support. Please ensure your firmware is updated and slow down the I2C as explained [here](https://learn.adafruit.com/circuitpython-on-raspberrypi-linux/i2c-clock-stretching).

---

## BNO055 Sensor Calibration in CircuitPython

### Stand-alone Calibrator

```python
import time
import board
import adafruit_bno055

class Mode:
    CONFIG_MODE = 0x00
    NDOF_MODE = 0x0C

i2c = board.STEMMA_I2C()
sensor = adafruit_bno055.BNO055_I2C(i2c)
sensor.mode = Mode.NDOF_MODE

# Step 1: Magnetometer - figure-eight dance
print("Magnetometer: Perform the figure-eight calibration dance.")
while not sensor.calibration_status[3] == 3:
    print(f"Mag Calib Status: {100 / 3 * sensor.calibration_status[3]:3.0f}%")
    time.sleep(1)
print("... CALIBRATED")

# Step 2: Accelerometer - six-step rotate
print("Accelerometer: Perform the six-step calibration dance.")
while not sensor.calibration_status[2] == 3:
    print(f"Accel Calib Status: {100 / 3 * sensor.calibration_status[2]:3.0f}%")
    time.sleep(1)
print("... CALIBRATED")

# Step 3: Gyroscope - hold still
print("Gyroscope: Perform the hold-in-place calibration dance.")
while not sensor.calibration_status[1] == 3:
    print(f"Gyro Calib Status: {100 / 3 * sensor.calibration_status[1]:3.0f}%")
    time.sleep(1)
print("... CALIBRATED")

print("\nCALIBRATION COMPLETED")
print(f"  Offsets_Magnetometer:  {sensor.offsets_magnetometer}")
print(f"  Offsets_Gyroscope:     {sensor.offsets_gyroscope}")
print(f"  Offsets_Accelerometer: {sensor.offsets_accelerometer}")
```

### User Orientation Offset (Target Angle Offset)

A user orientation offset to correct for the alignment of the display in relationship with the sensor. Changing the target angle offset doesn't recalibrate the sensor — it just uses the current Euler angle to provide the offset for future position readings.

### Tap Detection

The BNO055 does not have native tap detection. A simple non-blocking single and double tap detection scheme can use the accelerometer's 100Hz data rate as a high-pass filter by measuring the delta between two consecutive measurements.

- **Tap sensitivity threshold:** 1.0 (overly sensitive) → 5.0 (typical) → 10.0 (numb)
- **Tap debounce:** 0.1s (securely mounted) → 0.3s (typical) → 0.5s (loosely mounted)

---

## FAQs

**Q: Can I manually set the calibration constants?**
Yes — save and restore calibration using the `restore_offsets` example. Note that the magnetometer needs recalibration even if offsets are loaded, as EMF environment changes.

**Q: Does the device make any assumptions about its initial orientation?**
Axes can be customized (see section 3.4 of the BNO055 datasheet). Until calibrated, orientation output is relative to power-on position.

**Q: Why doesn't Euler output seem to match the Quaternion output?**
Euler angles from the chip are based on "automatic orientation detection" and should only be used for eCompass where pitch and roll stay below 45°. For absolute orientation, always use quaternions.

**Q: I'm getting I2C errors in CircuitPython?**
The BNO055 I2C implementation violates the protocol in some cases. Works best with SAMD51, RP2040, STM32F4, and nRF52840.

**Q: I'm losing data over I2C?**
Add stronger pullups — 3.3K on SCL and 2.2K on SDA to override the default 10K pullups.

---

## Downloads

- [Arduino Library (GitHub)](https://adafru.it/f0I)
- [EagleCAD PCB files (GitHub)](https://adafru.it/sEn)
- [BNO055 STEMMA 3D models (GitHub)](https://adafru.it/11Am)
- [BNO055 Datasheet (2021)](https://adafru.it/19Cj)
- [Fritzing object (Adafruit Fritzing Library)](https://adafru.it/aP3)
