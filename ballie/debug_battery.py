import time
from stats import SystemStats

s = SystemStats()
print("Starting Battery Debug...")
print(f"I2C Bus: {s.bus}")
history_len = 0

while True:
    bat = s.get_battery()
    history_len = len(s.bat_history)
    min_val = min(s.bat_history) if s.bat_history else 0
    
    print(f"Pct: {bat['percent']:.2f}% | Charging: {bat['charging']} | History Len: {history_len} | Min Val: {min_val:.2f} | Error: {bat['error']}")
    time.sleep(0.5)
