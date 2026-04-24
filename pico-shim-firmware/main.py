"""
Ballie Mk. I — Spherical Robot Angle Controller (main.py)
Runs on Raspberry Pi Pico 2 W with Pimoroni Motor SHIM + BNO055 IMU.
Uses standard MicroPython (no Pimoroni library — raw PWM for DRV8833).

The Pico acts as an Angle-Holding Coprocessor:
  - Reads pitch from BNO055 IMU (I2C, GP4/GP5 via SHIM STEMMA QT)
  - Runs a PID loop to hold the stator at a target pitch angle
  - Drives motors via DRV8833 on Motor SHIM (raw PWM)
  - Listens for <PITCH:xx>, <YAW:xx>, <STOP> commands on USB serial + UART

When target pitch = 0  -> ball stationary (camera level)
When target pitch = 10 -> ball rolls forward
When target pitch = -10 -> ball rolls backward
"""

import time
import sys
import select
from machine import Pin, PWM, I2C, UART

# Local BNO055 driver
from bno055_minimal import BNO055

# ============================================================================
# USER CONFIGURATION - TUNE THESE TO FIX MOTOR/ENCODER BEHAVIOR
# ============================================================================
# 1. MOTOR POLARITY: Put robot on stand. Press W. Both wheels MUST spin Forward.
INVERT_LEFT_MOTOR = False
INVERT_RIGHT_MOTOR = True

# 2. ENCODER POLARITY: When pushing the un-powered robot forward on desk,
#    the telemetry V: (Velocity) and E: (Encoder) MUST increase positively.
INVERT_LEFT_ENCODER = True
INVERT_RIGHT_ENCODER = True

# 3. BASELINE STATIC POWER (min_duty): 
#    If the motors jump too fast when starting, lower these numbers towards 0.
#    If the motors hum but don't move at low speeds, raise these numbers (max 65535).
#    If one motor is consistently slower/needs more power to start, adjust them independently!
MIN_DUTY_LEFT = 40000
MIN_DUTY_RIGHT = 40000

# 4. SPEED SCALING: Overall target speed limits (in ticks per second)
MAX_TICKS_PER_SEC = 500.0  # Top speed ceiling limit

# 5. VELOCITY TRACKING PID: If it stutters, lower P. If it's weak on carpet, raise I.
VEL_KP = 0.001  # Proportional correction
VEL_KI = 0.005  # Integral correction (pushes through friction)
VEL_KD = 0.0    # Derivative 
# ============================================================================

# Use Pi Zero Camera Feed's I2C timing configuration
I2C_FREQ = 400_000

# ============================================================================
# RAW DRV8833 MOTOR DRIVER (Pimoroni Motor SHIM pins)
# ============================================================================
# Motor SHIM schematic:
#   Motor A: AIN1 = GP6, AIN2 = GP7
#   Motor B: BIN1 = GP27, BIN2 = GP26
# DRV8833 truth table:
#   Forward:  IN1=PWM, IN2=LOW   -> OUT1=H, OUT2=L
#   Reverse:  IN1=LOW, IN2=PWM   -> OUT1=L, OUT2=H
#   Brake:    IN1=HIGH, IN2=HIGH -> OUT1=L, OUT2=L (slow decay / brake)
#   Coast:    IN1=LOW,  IN2=LOW  -> OUT1=Z, OUT2=Z

PWM_FREQ = 100  # 100 Hz — gives motors more torque/punch than 20kHz

class RawMotor:
    """Drive a DRV8833 H-bridge channel with raw PWM."""

    def __init__(self, pin1_num, pin2_num, min_duty=15000, invert=False):
        self.pwm1 = PWM(Pin(pin1_num))
        self.pwm2 = PWM(Pin(pin2_num))
        self.pwm1.freq(PWM_FREQ)
        self.pwm2.freq(PWM_FREQ)
        self.pwm1.duty_u16(0)
        self.pwm2.duty_u16(0)
        self.min_duty = min_duty
        self.invert = invert
        self.current_speed = 0.0
 
    def speed(self, spd):
        """Set speed from -1.0 (full reverse) to +1.0 (full forward)."""
        if self.invert:
            spd = -spd

        spd = max(-1.0, min(1.0, spd))
        abs_spd = abs(spd)
        
        self.current_speed = spd

        if abs_spd < 0.001:
            duty = 0
            self.current_speed = 0.0
        else:
            # Map [0.001, 1.0] to [min_duty, 65535] to smoothly overcome dynamic friction
            duty = int(self.min_duty + (65535 - self.min_duty) * abs_spd)
            
        if spd > 0:
            self.pwm1.duty_u16(duty)
            self.pwm2.duty_u16(0)
        elif spd < 0:
            self.pwm1.duty_u16(0)
            self.pwm2.duty_u16(duty)
        else:
            self.pwm1.duty_u16(0)
            self.pwm2.duty_u16(0)

    def brake(self):
        """Active brake (slow decay)."""
        self.pwm1.duty_u16(65535)
        self.pwm2.duty_u16(65535)

    def coast(self):
        """Coast (fast decay)."""
        self.pwm1.duty_u16(0)
        self.pwm2.duty_u16(0)

    def disable(self):
        """Disable PWM outputs."""
        self.pwm1.duty_u16(0)
        self.pwm2.duty_u16(0)


# ============================================================================
# HARDWARE SETUP
# ============================================================================

# Motors via DRV8833 on Motor SHIM
motor_left  = RawMotor(6, 7, min_duty=MIN_DUTY_LEFT, invert=INVERT_LEFT_MOTOR)     # Motor A: GP6 (AIN1), GP7 (AIN2)
motor_right = RawMotor(27, 26, min_duty=MIN_DUTY_RIGHT, invert=INVERT_RIGHT_MOTOR) # Motor B: GP27 (BIN1), GP26 (BIN2)

# BNO055 IMU via I2C1 (GP2 = SDA, GP3 = SCL) -> Moved to free up UART
i2c = I2C(1, sda=Pin(2), scl=Pin(3), freq=400_000)
imu = BNO055(i2c)

# UART0 for Pi Zero communication (GP0 = TX, GP1 = RX)
import os
try:
    os.dupterm(None, 1)
except:
    pass
uart = UART(0, baudrate=9600, tx=Pin(0), rx=Pin(1))

# Encoders (rising edge count on Channel A, direction on Channel B)
ENC_LEFT_A  = Pin(10, Pin.IN, Pin.PULL_UP)
ENC_LEFT_B  = Pin(11, Pin.IN, Pin.PULL_UP)
ENC_RIGHT_A = Pin(12, Pin.IN, Pin.PULL_UP)
ENC_RIGHT_B = Pin(13, Pin.IN, Pin.PULL_UP)

enc_left_count  = 0
enc_right_count = 0

def _enc_left_isr(pin):
    global enc_left_count
    if ENC_LEFT_B.value() ^ INVERT_LEFT_ENCODER:
        enc_left_count += 1
    else:
        enc_left_count -= 1

def _enc_right_isr(pin):
    global enc_right_count
    if ENC_RIGHT_B.value() ^ INVERT_RIGHT_ENCODER:
        enc_right_count += 1
    else:
        enc_right_count -= 1

ENC_LEFT_A.irq(trigger=Pin.IRQ_RISING, handler=_enc_left_isr)
ENC_RIGHT_A.irq(trigger=Pin.IRQ_RISING, handler=_enc_right_isr)

# Encoder constants
COUNTS_PER_REV = 617  # 12 CPR * 51.45:1 gear ratio

# ============================================================================
# PID CONTROLLER
# ============================================================================

class PID:
    """Simple PID controller with integral windup protection."""

    def __init__(self, kp, ki, kd, output_min=-1.0, output_max=1.0,
                 integral_limit=0.5):
        self.kp = kp
        self.ki = ki
        self.kd = kd
        self.output_min = output_min
        self.output_max = output_max
        self.integral_limit = integral_limit

        self._integral = 0.0
        self._prev_error = 0.0
        self._prev_time = time.ticks_ms()

    def update(self, error):
        """Calculate PID output given current error. Returns motor speed [-1, 1]."""
        now = time.ticks_ms()
        dt = time.ticks_diff(now, self._prev_time) / 1000.0  # seconds
        self._prev_time = now

        if dt <= 0 or dt > 0.5:
            self._prev_error = error
            return 0.0

        # Proportional
        p = self.kp * error

        # Integral with anti-windup
        self._integral += error * dt
        self._integral = max(-self.integral_limit,
                             min(self.integral_limit, self._integral))
        i = self.ki * self._integral

        # Derivative
        d = self.kd * (error - self._prev_error) / dt
        self._prev_error = error

        # Total output, clamped
        output = p + i + d
        return max(self.output_min, min(self.output_max, output))

    def reset(self):
        self._integral = 0.0
        self._prev_error = 0.0
        self._prev_time = time.ticks_ms()

# ============================================================================
# CONFIGURATION
# ============================================================================

# PID tuning — CONSERVATIVE starting values
PID_KP = 0.05
PID_KI = 0.005
PID_KD = 0.02

# Motor deadband — minimum speed to overcome shell friction
MOTOR_DEADBAND = 0.0

# Anti-tumble safety — hard angle limit (degrees)
ANTI_TUMBLE_ANGLE = 45.0

# Control loop frequency target
LOOP_FREQ_HZ = 100
LOOP_PERIOD_MS = 1000 // LOOP_FREQ_HZ  # 10ms

# Telemetry reporting interval
TELEMETRY_INTERVAL_MS = 200  # 5 Hz

# ============================================================================
# COMMAND PARSER
# ============================================================================

def parse_command(cmd_str):
    """
    Parse angle commands:
      <PITCH:xx>   — set target pitch
      <YAW:xx>     — set yaw offset
      <STOP>       — emergency stop
      <STATUS>     — request status report
      <DEADBAND:x> — set motor deadband
      <KP:x> <KI:x> <KD:x> — set PID gains
    """
    cmd_str = cmd_str.strip()
    if not cmd_str.startswith('<') or not cmd_str.endswith('>'):
        return None

    inner = cmd_str[1:-1]

    if inner == "STOP":
        return ("STOP", 0)
    if inner == "STATUS":
        return ("STATUS", 0)

    if ':' in inner:
        parts = inner.split(':', 1)
        try:
            return (parts[0].upper(), float(parts[1]))
        except ValueError:
            return None

    return None

# ============================================================================
# MAIN CONTROL LOOP
# ============================================================================

def apply_deadband(speed, deadband):
    if abs(speed) < 0.001:
        return 0.0
    if abs(speed) < deadband:
        return 0.0
    return speed

def emergency_stop():
    motor_left.speed(0)
    motor_right.speed(0)
    motor_left.disable()
    motor_right.disable()

def main():
    global MOTOR_DEADBAND, PID_KP, PID_KI, PID_KD

    print("[MAIN] Initializing BNO055 IMU...")
    imu_ok = False
    for attempt in range(5):
        try:
            if imu.begin():
                imu_ok = True
                break
        except Exception as e:
            print(f"[MAIN] IMU init attempt {attempt + 1}/5 error: {e}")
        time.sleep_ms(500)

    if not imu_ok:
        print("[MAIN] WARNING: BNO055 not found! Running in DIRECT DRIVE mode.")
        try:
            print("[MAIN] I2C scan:", [hex(a) for a in i2c.scan()])
        except:
            pass
        print("[MAIN] Motors will respond to PITCH as direct speed (no PID).")

    # Wait for initial calibration
    if imu_ok:
        print("[MAIN] Waiting for IMU calibration...")
        cal_start = time.ticks_ms()
        while time.ticks_diff(time.ticks_ms(), cal_start) < 5000:
            s, g, a, m = imu.calibration_status()
            print(f"[MAIN] Calibration: sys={s} gyro={g} accel={a} mag={m}")
            if g >= 2:
                print("[MAIN] Gyro calibrated — good enough to start!")
                break
            time.sleep_ms(500)

    # Create PID controller
    pid = PID(PID_KP, PID_KI, PID_KD)
    
    # Create Motor Velocity PID controllers (Low windup limit to prevent unstoppable runaways)
    left_pid = PID(VEL_KP, VEL_KI, VEL_KD, integral_limit=2.0)
    right_pid = PID(VEL_KP, VEL_KI, VEL_KD, integral_limit=2.0)

    # State
    target_pitch = 0.0
    yaw_offset = 0.0
    pid_active = True
    tumble_lockout = False

    # Serial input buffers
    usb_buf = ""
    uart_buf = ""

    # Polling for USB stdin
    poller = select.poll()
    poller.register(sys.stdin, select.POLLIN)

    last_telemetry = time.ticks_ms()
    prev_vel_time = time.ticks_ms()
    prev_left_enc = 0
    prev_right_enc = 0
    left_vel = 0.0
    right_vel = 0.0

    print("[MAIN] Control loop starting. Listening for commands...")
    print("[MAIN] Commands: <PITCH:x> <YAW:x> <STOP> <STATUS>")
    print("[MAIN] Tuning:   <KP:x> <KI:x> <KD:x> <DEADBAND:x>")

    while True:
        loop_start = time.ticks_ms()

        # ---- CALCULATE VELOCITY ----
        now_vel = time.ticks_ms()
        dt_vel_ms = time.ticks_diff(now_vel, prev_vel_time)
        if dt_vel_ms >= 50:  # Compute every ~50ms for smoother counts
            dt_vel_s = dt_vel_ms / 1000.0
            curr_left_enc = enc_left_count
            curr_right_enc = enc_right_count
            
            raw_left_vel = (curr_left_enc - prev_left_enc) / dt_vel_s
            raw_right_vel = (curr_right_enc - prev_right_enc) / dt_vel_s
            
            # Simple EMA filter to smooth discrete tick noise
            left_vel = (0.5 * raw_left_vel) + (0.5 * left_vel)
            right_vel = (0.5 * raw_right_vel) + (0.5 * right_vel)
            
            prev_left_enc = curr_left_enc
            prev_right_enc = curr_right_enc
            prev_vel_time = now_vel

        # ---- READ IMU ----
        current_pitch = 0.0
        gyro_data = (0.0, 0.0, 0.0)
        if imu_ok:
            try:
                current_pitch = imu.pitch()
                gyro_data = imu.gyro()
            except Exception:
                pass

        # ---- ANTI-TUMBLE CHECK ----
        if abs(current_pitch) > ANTI_TUMBLE_ANGLE and imu_ok:
            if not tumble_lockout:
                print(f"[SAFETY] ANTI-TUMBLE! Pitch {current_pitch:.1f}deg BRAKING!")
                tumble_lockout = True
            brake_dir = -1.0 if current_pitch > 0 else 1.0
            motor_left.speed(brake_dir * 0.3)
            motor_right.speed(brake_dir * 0.3)
        else:
            if tumble_lockout:
                print("[SAFETY] Pitch back in safe zone. Resuming PID.")
                tumble_lockout = False
                pid.reset()

            # ---- PID LOOP (IMU available) ----
            if pid_active and imu_ok:
                error = target_pitch - current_pitch
                pid_output = pid.update(error)

                # Map pitch PID to normalized target velocity
                base_speed = pid_output
                left_target = (base_speed + yaw_offset) * MAX_TICKS_PER_SEC
                right_target = (base_speed - yaw_offset) * MAX_TICKS_PER_SEC

                if abs(left_target) < 1.0:
                    left_power = 0.0
                    left_pid.reset()
                else:
                    left_ff = left_target / MAX_TICKS_PER_SEC
                    left_power = left_ff + left_pid.update(left_target - left_vel)
                
                if abs(right_target) < 1.0:
                    right_power = 0.0
                    right_pid.reset()
                else:
                    right_ff = right_target / MAX_TICKS_PER_SEC
                    right_power = right_ff + right_pid.update(right_target - right_vel)

                motor_left.speed(left_power)
                motor_right.speed(right_power)

            # ---- DIRECT DRIVE (no IMU) ----
            elif not imu_ok:
                # Map pitch directly to normalized velocity target: pitch/30 = target_speed_norm
                base_speed = target_pitch / 30.0
                base_speed = max(-1.0, min(1.0, base_speed))

                left_target = (base_speed + yaw_offset) * MAX_TICKS_PER_SEC
                right_target = (base_speed - yaw_offset) * MAX_TICKS_PER_SEC

                if abs(left_target) < 1.0:
                    left_power = 0.0
                    left_pid.reset()
                else:
                    left_ff = left_target / MAX_TICKS_PER_SEC
                    left_power = left_ff + left_pid.update(left_target - left_vel)
                
                if abs(right_target) < 1.0:
                    right_power = 0.0
                    right_pid.reset()
                else:
                    right_ff = right_target / MAX_TICKS_PER_SEC
                    right_power = right_ff + right_pid.update(right_target - right_vel)

                motor_left.speed(left_power)
                motor_right.speed(right_power)

        # ---- READ COMMANDS FROM USB (stdin) ----
        if poller.poll(0):
            ch = sys.stdin.read(1)
            if ch == '\n' or ch == '\r':
                if usb_buf:
                    result = parse_command(usb_buf)
                    if result:
                        cmd_type, cmd_val = result
                        if cmd_type == "PITCH":
                            target_pitch = cmd_val
                            pid.reset()
                            print(f"[CMD] Target pitch: {target_pitch:.1f}deg")
                        elif cmd_type == "YAW":
                            yaw_offset = cmd_val / 100.0
                            print(f"[CMD] Yaw offset: {yaw_offset:.3f}")
                        elif cmd_type == "STOP":
                            target_pitch = 0.0
                            yaw_offset = 0.0
                            pid.reset()
                            left_pid.reset()
                            right_pid.reset()
                            emergency_stop()
                            print("[CMD] EMERGENCY STOP")
                        elif cmd_type == "STATUS":
                            s, g, a, m = imu.calibration_status() if imu_ok else (0,0,0,0)
                            print(f"[STATUS] Pitch:{current_pitch:.1f} Target:{target_pitch:.1f} Yaw:{yaw_offset:.3f}")
                            print(f"[STATUS] Cal:s={s} g={g} a={a} m={m}")
                            print(f"[STATUS] Enc:L={enc_left_count} R={enc_right_count}")
                            print(f"[STATUS] PID:kp={PID_KP} ki={PID_KI} kd={PID_KD} db={MOTOR_DEADBAND}")
                        elif cmd_type == "DEADBAND":
                            MOTOR_DEADBAND = cmd_val
                            print(f"[CMD] Deadband: {MOTOR_DEADBAND}")
                        elif cmd_type == "KP":
                            PID_KP = cmd_val; pid.kp = cmd_val
                            print(f"[CMD] KP: {PID_KP}")
                        elif cmd_type == "KI":
                            PID_KI = cmd_val; pid.ki = cmd_val
                            print(f"[CMD] KI: {PID_KI}")
                        elif cmd_type == "KD":
                            PID_KD = cmd_val; pid.kd = cmd_val
                            print(f"[CMD] KD: {PID_KD}")
                    usb_buf = ""
            else:
                usb_buf += ch

        # ---- READ COMMANDS FROM UART (Pi Zero) ----
        if uart.any():
            data = uart.read()
            if data:
                uart_buf += data.decode('utf-8', 'ignore')
                while '\n' in uart_buf:
                    line, uart_buf = uart_buf.split('\n', 1)
                    line = line.strip()
                    uart.write(f"[UART-RX] {line}\n".encode('utf-8'))
                    result = parse_command(line)
                    if result:
                        cmd_type, cmd_val = result
                        if cmd_type == "PITCH":
                            target_pitch = cmd_val
                            pid.reset()
                        elif cmd_type == "YAW":
                            yaw_offset = cmd_val / 100.0
                        elif cmd_type == "STOP":
                            target_pitch = 0.0
                            yaw_offset = 0.0
                            pid.reset()
                            left_pid.reset()
                            right_pid.reset()
                            emergency_stop()

        # ---- TELEMETRY ----
        now = time.ticks_ms()
        if time.ticks_diff(now, last_telemetry) >= TELEMETRY_INTERVAL_MS:
            last_telemetry = now
            cal = imu.calibration_status() if imu_ok else (0,0,0,0)
            telemetry_str = (f"P:{current_pitch:+6.1f} T:{target_pitch:+6.1f} "
                             f"G:{gyro_data[1]:+6.1f} "
                             f"C:{cal[0]}{cal[1]}{cal[2]}{cal[3]} "
                             f"E:{enc_left_count}/{enc_right_count} V:{left_vel:.0f}/{right_vel:.0f}")
            print(telemetry_str)
            uart.write(b'[PICO_HEARTBEAT] I ALIVE!\n')
            uart.write((telemetry_str + "\n").encode('utf-8'))

        # ---- LOOP TIMING ----
        elapsed = time.ticks_diff(time.ticks_ms(), loop_start)
        if elapsed < LOOP_PERIOD_MS:
            time.sleep_ms(LOOP_PERIOD_MS - elapsed)


# ============================================================================
# ENTRY POINT
# ============================================================================
if __name__ == "__main__":
    time.sleep(1)
    try:
        main()
    except KeyboardInterrupt:
        emergency_stop()
        print("[MAIN] Interrupted. Motors stopped.")
    except Exception as e:
        emergency_stop()
        print(f"[MAIN] FATAL: {e}")
        import sys as _sys
        _sys.print_exception(e)
