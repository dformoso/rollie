import random

bat_history = []
BAT_HISTORY_LEN = 3000

print("Simulating 100 steps...")
for i in range(60): # 30 seconds @ 0.5s
    # Simulate noisy input: 80 +/- 2
    raw = 80.0 + random.uniform(-2, 2)
    
    bat_history.append(raw)
    if len(bat_history) > BAT_HISTORY_LEN:
        bat_history.pop(0)

    curr_avg = sum(bat_history) / len(bat_history)
    min_val = min(bat_history)
    
    percent = (curr_avg + (min_val * 100)) / 101
    
    print(f"Index {i}: Raw={raw:.2f} | Min={min_val:.2f} | Avg={curr_avg:.2f} | Output={percent:.2f}")

