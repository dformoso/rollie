import time
import sys
import os
import signal
import numpy as np
from stats import SystemStats
from PIL import Image, ImageDraw, ImageFont

# Import WhisPlay driver
try:
    from WhisPlay import WhisPlayBoard
except ImportError:
    print("Error: WhisPlay.py not found. Please ensure it is in the same directory.")
    sys.exit(1)

# Import Picamera2
try:
    from picamera2 import Picamera2, H264Encoder
except ImportError:
    try:
        from picamera2 import Picamera2
        # Fallback/Older version checking if needed, but H264Encoder is standard
        # If it fails, maybe 'encoders' module?
        from picamera2.encoders import H264Encoder
    except ImportError:
        print("Warning: H264Encoder not directly found. Assuming Picamera2.H264Encoder exists or handled.")
        from picamera2 import Picamera2
        # Mock or rely on main scope if it was attached
        
except Exception as e:
    print(f"Error importing picamera2: {e}")
    sys.exit(1)

# Configuration
WIDTH = 240
HEIGHT = 280
FPS = 30

def signal_handler(sig, frame):
    print("\nExiting...")
    raise KeyboardInterrupt

signal.signal(signal.SIGINT, signal_handler)

# Helper for large fonts
def get_font(size):
    try:
        return ImageFont.truetype("/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf", size)
    except:
        return ImageFont.load_default()

def draw_lightning(draw, x, y, size, color):
    # Simple lightning bolt polygon
    # Points relative to x,y center-ish
    points = [
        (x + 2, y), 
        (x - 3, y + size//2), 
        (x - 1, y + size//2), 
        (x - 4, y + size), 
        (x + 1, y + size//2), 
        (x + 4, y + size//2)
    ]
    draw.polygon(points, fill=color)

def draw_globe(draw, x, y, size, color):
    # Circle
    draw.ellipse([x, y, x+size, y+size], outline=color, width=1)
    # Equator
    draw.line([x, y+size//2, x+size, y+size//2], fill=color, width=1)
    # Meridian
    draw.arc([x+size//4, y, x+size*0.75, y+size], 0, 360, fill=color, width=1)

def draw_thermo(draw, x, y, size, color):
    # Bulb
    bx = x + size//2
    draw.ellipse([bx-3, y+size-6, bx+3, y+size], fill=color)
    # Stem
    draw.line([bx, y, bx, y+size-3], fill=color, width=2)
    
import socket
import threading
import subprocess
import shutil
from datetime import datetime

# ... existing imports ...

# Global State
is_paused = False
is_recording = False
recording_process = None
recording_filename_base = None
pending_action = None # 'record', 'pause'

# Thread-safe trigger
def trigger_action(action):
    global pending_action
    pending_action = action

# Button Logic
press_start_time = 0

def handle_whisplay_press():
    global press_start_time
    press_start_time = time.time()
    # print("Button Pressed")

def handle_whisplay_release():
    global press_start_time
    duration = time.time() - press_start_time
    # print(f"Button Released (Duration: {duration:.2f}s)")
    
    if duration > 0.5: # Long Press (> 0.5s) -> PAUSE
        trigger_action('pause')
    else: # Short Press -> RECORD
        trigger_action('record')

# Actual Logic (Run in Main Loop)
def _do_toggle_record(picam2, config):
    global is_recording, recording_process, recording_filename_base
    
    rec_dir = os.path.join(os.path.dirname(__file__), 'recordings')
    os.makedirs(rec_dir, exist_ok=True)
    
    if not is_recording:
        # START
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        recording_filename_base = os.path.join(rec_dir, f"rec_{timestamp}")
        print(f"Starting Recording: {recording_filename_base}...")
        
        try:
            picam2.start_recording(H264Encoder(), recording_filename_base + ".h264")
        except Exception as e:
            print(f"Video Record Fail: {e}")
            return

        # Start Audio
        cmd = ["arecord", "-D", "hw:0,0", "-f", "S16_LE", "-r", "44100", "-c", "2", recording_filename_base + ".wav"]
        try:
            recording_process = subprocess.Popen(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except Exception as e:
            print(f"Audio Record Fail: {e}")
            try: picam2.stop_recording()
            except: pass
            return
            
        is_recording = True
        print("Recording Started.")
        
    else:
        # STOP
        print("Stopping Recording...")
        is_recording = False
        
        # STOP AUDIO FIRST
        if recording_process:
            recording_process.terminate()
            recording_process.wait()
            recording_process = None
            
        # HARD RESET CAMERA to prevent freeze
        # Stop everything, re-init.
        print("Resetting Camera Pipeline...")
        try:
            picam2.stop_recording()
        except: pass
        
        try:
            picam2.stop()
            # Re-configure and Restart
            # We assume config is valid.
            # Small delay to let hardware settle?
            time.sleep(0.5)
            picam2.configure(config)
            picam2.start()
        except Exception as e:
            print(f"Camera Reset Failed: {e}")
            
        # Mux (Low Priority)
        print("Muxing Video/Audio...")
        vid = recording_filename_base + ".h264"
        aud = recording_filename_base + ".wav"
        out = recording_filename_base + ".mp4"
        
        # Use 'nice' to prevent CPU starvation
        mux_cmd = [
            "nice", "-n", "19",
            "ffmpeg", "-y", "-framerate", str(FPS),
            "-i", vid, "-i", aud, 
            "-c:v", "copy", "-c:a", "aac", out
        ]
        
        def mux_thread():
            try:
                subprocess.run(mux_cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                print(f"Saved: {out}")
                if os.path.exists(vid): os.remove(vid)
                if os.path.exists(aud): os.remove(aud)
            except Exception as e:
                print(f"Muxing Failed: {e}")

        try:
            t = threading.Thread(target=mux_thread)
            t.start()
        except:
            pass

def _do_toggle_pause(board):
    global is_paused
    is_paused = not is_paused
    print(f"Pause Toggled -> {is_paused}")
    if is_paused:
        board.fill_screen(0)

# ... (Draw functions untouched) ...


def draw_recording_indicator(draw, width, height_limit):
    # Red Dot in top right or center?
    # Top center
    cx, cy = width // 2, 10
    rad = 4
    # Blink logic handled by main loop? Or just static dot for now.
    # Blinking: Use time
    if int(time.time() * 2) % 2 == 0:
        draw.ellipse([cx-rad, cy-rad, cx+rad, cy+rad], fill=(255, 0, 0))


# ... (Original draw_big_stats kept but modified for Colors) ...
def draw_big_stats(draw, stats, width, height_limit):
    # ...
    # FIX COLORS for Battery
    c_cyan = (0, 255, 255)
    c_green = (57, 255, 20)
    c_warn = (255, 165, 0)
    
    # ... existing font loading ...
    font_row1 = get_font(12)
    font_row2 = get_font(14)
    font_small = get_font(10)
    
    pad_corner = 28
    y_crs = 5
    
    pct = stats.get('bat_percent', 0)
    charging = stats.get('bat_charging', False)
    
    # Yellow charging
    bat_col = c_green if pct > 20 else c_warn
    if charging: bat_col = (255, 255, 0)

    bat_x = pad_corner
    bat_w = 32
    bat_h = 16
    
    # Outline
    draw.rectangle([bat_x, y_crs, bat_x + bat_w, y_crs + bat_h], outline=bat_col, width=2)
    draw.rectangle([bat_x + bat_w, y_crs + 4, bat_x + bat_w + 3, y_crs + 12], fill=bat_col)
    
    fill_w = int((bat_w - 4) * (pct / 100.0))
    if fill_w > 0:
        draw.rectangle([bat_x + 2, y_crs + 2, bat_x + 2 + fill_w, y_crs + bat_h - 2], fill=bat_col)
        
    if charging:
        # Black outline for visibility on Yellow
        draw_lightning(draw, bat_x + bat_w//2, y_crs + 2, bat_h-4, (0,0,0)) 
    
    # ... Rest of drawing logic similar to previous ...
    # Re-implementing the rest briefly to ensure context is valid
    
    draw.text((bat_x + bat_w + 5, y_crs), f"{int(pct)}%", font=font_row1, fill=c_cyan)
    
    wifi_x_end = width - pad_corner
    dbm = stats.get('wifi_dbm', -100)
    bars = 0
    if dbm > -50: bars = 5
    elif dbm > -60: bars = 4
    elif dbm > -70: bars = 3
    elif dbm > -80: bars = 2
    elif dbm > -90: bars = 1
    
    bar_w, gap, max_h = 4, 2, 16
    for i in range(5):
        h = 4 + (i * 3)
        x_pos = wifi_x_end - ((5-i) * (bar_w + gap))
        col = c_green if (i < bars) else (60, 60, 60)
        draw.rectangle([x_pos, y_crs + (max_h - h), x_pos + bar_w, y_crs + max_h], fill=col)
        
    ssid = stats.get('ssid', '--')
    ss_w = draw.textbbox((0,0), ssid, font=font_row1)[2]
    draw.text((wifi_x_end - (5 * (bar_w + gap)) - 5 - ss_w, y_crs), ssid, font=font_row1, fill=c_cyan)
    
    # Recording Indicator
    if is_recording:
        draw_recording_indicator(draw, width, height_limit)
        
    y_crs += 22
    
    # Row 2
    bar_h, label_w = 8, 40
    chart_w = width - (pad_corner*2) - label_w
    chart_x = pad_corner + label_w
    
    # CPU
    draw.text((pad_corner, y_crs-3), "CPU", font=font_row2, fill=c_cyan)
    draw.rectangle([chart_x, y_crs, chart_x + chart_w, y_crs + bar_h], fill=(30, 30, 30))
    draw.rectangle([chart_x, y_crs, chart_x + int(chart_w * (stats.get('cpu_percent', 0)/100)), y_crs + bar_h], fill=c_green)
    y_crs += 14
    
    # RAM
    draw.text((pad_corner, y_crs-3), "RAM", font=font_row2, fill=c_cyan)
    draw.rectangle([chart_x, y_crs, chart_x + chart_w, y_crs + bar_h], fill=(30, 30, 30))
    draw.rectangle([chart_x, y_crs, chart_x + int(chart_w * (stats.get('ram_percent', 0)/100)), y_crs + bar_h], fill=c_cyan)
    y_crs += 14
    
    # DSK
    draw.text((pad_corner, y_crs-3), "DSK", font=font_row2, fill=c_cyan)
    draw.rectangle([chart_x, y_crs, chart_x + chart_w, y_crs + bar_h], fill=(30, 30, 30))
    draw.rectangle([chart_x, y_crs, chart_x + int(chart_w * (stats.get('disk_percent', 0)/100)), y_crs + bar_h], fill=(100, 100, 255))
    y_crs += 16
    
    # Row 3
    time_str = stats.get('time_str', '--:--')
    c_text = (220, 220, 200)
    
    draw_globe(draw, pad_corner, y_crs+2, 12, c_text)
    draw.text((pad_corner + 16, y_crs), stats.get('ip', '..'), font=font_small, fill=c_text)
    
    temp = stats.get('cpu_temp', 0)
    temp_str = f"{temp:.0f}C"
    t_w = draw.textbbox((0,0), temp_str, font=font_small)[2]
    draw.text((width - pad_corner - t_w, y_crs), temp_str, font=font_small, fill=c_text)
    draw_thermo(draw, width - pad_corner - t_w - 14, y_crs+2, 12, c_text)
    
    time_w = draw.textbbox((0,0), time_str, font=get_font(13))[2]
    draw.text(((width - time_w)//2, y_crs + 12), time_str, font=get_font(13), fill=c_cyan)


def main():
    global is_paused
    
    # Initialize WhisPlay Board
    print("Initializing WhisPlay Board...")
    board = WhisPlayBoard()
    board.set_backlight(100)
    board.fill_screen(0)
    
    print("Initializing System Stats...")
    sys_stats = SystemStats()
    try:
        current_stats = sys_stats.get_all()
    except:
        current_stats = {}
    last_stat_time = time.time()

    print("Initializing Camera...")
    picam2 = Picamera2()
    
    # Configure camera for video capture
    # main: RGB for display
    # loares: YUV for H264 encoder (recording)
    config = picam2.create_video_configuration(
        main={"size": (640, 480), "format": "RGB888"},
        lores={"size": (640, 480), "format": "YUV420"}
    )
    picam2.configure(config)
    picam2.start()

    # Register Button Callbacks (Short=Record, Long=Pause)
    board.on_button_press(handle_whisplay_press)
    board.on_button_release(handle_whisplay_release)

    print(f"Camera started.")
    print(f"Short Press: Record | Long Press (>0.5s): Pause")
    
    try:
        while True:
            # Handle Actions (Thread Safe)
            global pending_action
            if pending_action:
                act = pending_action
                pending_action = None # Reset
                
                if act == 'record':
                    _do_toggle_record(picam2, config)
                elif act == 'pause':
                    _do_toggle_pause(board)
            
            # Stats (0.5s)
            if time.time() - last_stat_time > 0.5:
                current_stats = sys_stats.get_all()
                last_stat_time = time.time()
                
            if is_paused:
                board.fill_screen(0)
                time.sleep(0.1) 
                continue

            # Capture & Display
            try:
                # Add timeout protection? No effortless way.
                # If muxing makes it lag, 'nice' should help.
                image = picam2.capture_array()
            except Exception as e:
                time.sleep(0.01)
                continue

            pil_img = Image.fromarray(image)
            pil_img = pil_img.rotate(180)
            
            img_w, img_h = pil_img.size
            scale = min(WIDTH / img_w, HEIGHT / img_h)
            new_w, new_h = int(img_w * scale), int(img_h * scale)
            try:
                resample = Image.Resampling.BILINEAR
            except:
                resample = Image.BILINEAR
            pil_img = pil_img.resize((new_w, new_h), resample)
            
            final_img = Image.new("RGB", (WIDTH, HEIGHT), (0, 0, 0))
            offset_x = (WIDTH - new_w) // 2
            offset_y = HEIGHT - new_h
            final_img.paste(pil_img, (offset_x, offset_y))
            
            draw = ImageDraw.Draw(final_img)
            draw_big_stats(draw, current_stats, WIDTH, offset_y)
            
            # Common Render ...
            image = np.array(final_img)
            r = image[:, :, 0]
            g = image[:, :, 1]
            b = image[:, :, 2]
            rgb565 = (((r.astype(np.uint16) & 0xF8) << 8) | ((g.astype(np.uint16) & 0xFC) << 3) | (b.astype(np.uint16) >> 3))
            high_byte = (rgb565 >> 8) & 0xFF
            low_byte = rgb565 & 0xFF
            pixel_data = np.dstack((high_byte, low_byte)).flatten().tolist()
            board.draw_image(0, 0, WIDTH, HEIGHT, pixel_data)

    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"Error: {e}")
    finally:
        print("Cleaning up...")
        if is_recording:
            # Emergency stop recording
            try:
                picam2.stop_recording()
                if recording_process: recording_process.terminate()
            except:
                pass
        try:
             picam2.stop()
        except:
             pass
        board.cleanup()

if __name__ == "__main__":
    main()
