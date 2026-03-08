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
