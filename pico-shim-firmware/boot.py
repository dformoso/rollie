"""
Ballie Mk. I — Pico Boot Script (boot.py)
Initializes UART for communication with Pi Zero (future) and dev machine (now).
No WiFi — pure serial communication.
"""

import machine
import time

# Initialize UART0 on GP0 (TX) / GP1 (RX) for Pi Zero communication
# Detaching REPL from UART0 is recommended if using for custom communication
import os
try:
    os.dupterm(None, 1)
except:
    pass

uart = machine.UART(0, baudrate=9600, tx=machine.Pin(0), rx=machine.Pin(1))


print("=" * 50)
print("[BOOT] Ballie Mk. I — Pico Angle Controller")
print("[BOOT] UART0 initialized: GP0 (TX) / GP1 (RX)")
print("[BOOT] Baudrate: 9600")
print("=" * 50)
