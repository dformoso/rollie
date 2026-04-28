#!/usr/bin/env python3
"""
Rollie Mk. I — Keyboard Motor Control

Runs on the dev machine (connected to Pico via USB serial).
Reads keyboard input and sends angle commands to the Pico.

Controls:
  W / ↑     = Pitch forward  (roll forward)
  S / ↓     = Pitch backward (roll backward)
  A / ←     = Yaw left       (differential turn)
  D / →     = Yaw right      (differential turn)
  Space     = Stop (level)
  +/-       = Increase/decrease pitch increment
  R         = Request status
  Q         = Quit

The Pico interprets:
  <PITCH:xx>  → target pitch angle (degrees)
  <YAW:xx>    → differential steering offset
  <STOP>      → emergency stop, target = 0°
"""

import sys
import os
import time
import termios
import tty
import select
import signal
import serial

# Configuration
SERIAL_PORT = "/dev/ttyACM0"
HIDE_TELEMETRY = True

if len(sys.argv) > 1:
    args = sys.argv[1:]
    for arg in args:
        val = arg.lower()
        if val == '--show-telemetry':
            HIDE_TELEMETRY = False
        elif val in ['usb', '/dev/ttyacm0']:
            SERIAL_PORT = "/dev/ttyACM0"
        elif val in ['serial', 'serial0', '/dev/serial0']:
            SERIAL_PORT = "/dev/serial0"
        elif not val.startswith('--'):
            SERIAL_PORT = val

BAUD_RATE = 9600

# Arrow key escape sequences
ARROW_UP    = '\x1b[A'
ARROW_DOWN  = '\x1b[B'
ARROW_RIGHT = '\x1b[C'
ARROW_LEFT  = '\x1b[D'


def get_key(timeout=0.05):
    """Read a single keypress (including arrow keys). Non-blocking."""
    if select.select([sys.stdin], [], [], timeout)[0]:
        ch = sys.stdin.read(1)
        if ch == '\x1b':
            # Could be an escape sequence (arrow key)
            if select.select([sys.stdin], [], [], 0.01)[0]:
                ch += sys.stdin.read(1)
                if select.select([sys.stdin], [], [], 0.01)[0]:
                    ch += sys.stdin.read(1)
        return ch
    return None


def main():
    # Open serial port
    try:
        ser = serial.Serial(SERIAL_PORT, BAUD_RATE, timeout=0.05)
        print(f"[SERIAL] Connected to {SERIAL_PORT} at {BAUD_RATE} baud")
    except Exception as e:
        print(f"[ERROR] Cannot open {SERIAL_PORT}: {e}")
        print("  Make sure the Pico is connected and permissions are set:")
        print(f"  sudo chmod a+rw {SERIAL_PORT}")
        sys.exit(1)

    # Wait for Pico boot
    time.sleep(0.5)

    # Set terminal to raw mode for single-keypress reading
    old_settings = termios.tcgetattr(sys.stdin)

    pitch = 0.0
    yaw = 0.0
    pitch_step = 0.5  # degrees per keypress

    try:
        tty.setraw(sys.stdin.fileno())

        # Flush any leftover input from previous SSH session
        while select.select([sys.stdin], [], [], 0)[0]:
            sys.stdin.read(1)

        # Print instructions AFTER entering raw mode and flushing
        sys.stdout.write("\r\n")
        sys.stdout.write("=" * 60 + "\r\n")
        sys.stdout.write("  ROLLIE KEYBOARD CONTROL\r\n")
        sys.stdout.write("=" * 60 + "\r\n")
        sys.stdout.write(f"  W/Up = Forward    S/Down = Backward\r\n")
        sys.stdout.write(f"  A/Left = Turn Left  D/Right = Turn Right\r\n")
        sys.stdout.write(f"  Space = STOP     +/- = Adjust step (current: {pitch_step} deg)\r\n")
        sys.stdout.write(f"  R = Status       Q/Ctrl-C = Quit\r\n")
        sys.stdout.write("=" * 60 + "\r\n")
        sys.stdout.write("\r\n")
        sys.stdout.flush()

        while True:
            # Read serial output from Pico (telemetry)
            if ser.in_waiting:
                line = ser.readline().decode('utf-8', errors='ignore').strip()
                if line:
                    if HIDE_TELEMETRY and ("[PICO_HEARTBEAT]" in line or "P: " in line):
                        continue
                    # Move cursor to start, clear line, print, then restore
                    sys.stdout.write(f"\r\033[K[PICO] {line}\r\n")
                    sys.stdout.flush()

            # Read keyboard
            key = get_key()
            if key is None:
                continue

            cmd = None

            if key in ('w', 'W') or key == ARROW_UP:
                pitch = min(pitch + pitch_step, 30.0)
                cmd = f"<PITCH:{pitch:.1f}>"

            elif key in ('s', 'S') or key == ARROW_DOWN:
                pitch = max(pitch - pitch_step, -30.0)
                cmd = f"<PITCH:{pitch:.1f}>"

            elif key in ('a', 'A') or key == ARROW_LEFT:
                yaw = max(round(yaw - 1.0, 1), -50.0)
                cmd = f"<YAW:{yaw:.1f}>"

            elif key in ('d', 'D') or key == ARROW_RIGHT:
                yaw = min(round(yaw + 1.0, 1), 50.0)
                cmd = f"<YAW:{yaw:.1f}>"

            elif key == ' ':
                pitch = 0.0
                yaw = 0.0
                cmd = "<STOP>"

            elif key == '+' or key == '=':
                pitch_step = min(round(pitch_step + 0.1, 1), 20.0)
                sys.stdout.write(f"\r\033[K[CTRL] Pitch step: {pitch_step}°\r\n")
                sys.stdout.flush()

            elif key == '-' or key == '_':
                pitch_step = max(round(pitch_step - 0.1, 1), 0.1)
                sys.stdout.write(f"\r\033[K[CTRL] Pitch step: {pitch_step}°\r\n")
                sys.stdout.flush()

            elif key in ('r', 'R'):
                cmd = "<STATUS>"

            elif key in ('q', 'Q', '\x03'):  # Q or Ctrl-C
                # Send stop before quitting
                ser.write(b"<STOP>\n")
                sys.stdout.write("\r\033[K[CTRL] Quitting...\r\n")
                sys.stdout.flush()
                break

            if cmd:
                ser.write((cmd + "\n").encode())
                sys.stdout.write(f"\r\033[K[SEND] {cmd}  "
                                 f"(pitch={pitch:+.1f}° yaw={yaw:+.1f}°)\r\n")
                sys.stdout.flush()

    except KeyboardInterrupt:
        ser.write(b"<STOP>\n")
    finally:
        # Restore terminal
        termios.tcsetattr(sys.stdin, termios.TCSADRAIN, old_settings)
        ser.close()
        print("\n[CTRL] Serial closed. Motors stopped.")


if __name__ == "__main__":
    main()
