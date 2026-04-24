# STUB DRIVER — begin() always returns False, which causes main.py to fall back to
# Direct Drive mode (no IMU feedback). This is intentional for the v0.1 hardware bringup
# phase where the BNO055 integration is not yet complete.
#
# To use a real BNO055 driver, replace this file with a full I2C implementation.
# Reference: https://github.com/adafruit/Adafruit_CircuitPython_BNO055
#            https://github.com/pimoroni/pimoroni-pico (MicroPython examples)

class BNO055:
    def __init__(self, i2c, address=0x28):
        self.i2c = i2c
        self.address = address

    def begin(self):
        # Always return False to trigger the Direct Drive fallback in main.py
        return False

    def calibration_status(self):
        return (0, 0, 0, 0)

    def pitch(self):
        return 0.0

    def gyro(self):
        return (0.0, 0.0, 0.0)
