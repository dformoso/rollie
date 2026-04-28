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
FPS = 50

# User configuration — copy rollie/config.py.example to rollie/config.py and fill in your values
try:
    from config import USER_IP, USER_NAME, USER_PASS, DEST_DIR
except ImportError:
    print("Error: config.py not found. Copy config.py.example to config.py and fill in your values.")
    sys.exit(1)

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
import serial

# Serial Configuration for Pico
SERIAL_PORT = "/dev/serial0"
SERIAL_BAUD = 9600
pico_serial = None
try:
    pico_serial = serial.Serial(SERIAL_PORT, SERIAL_BAUD, timeout=0)
    print(f"Opened Serial Port: {SERIAL_PORT}")
except Exception as e:
    print(f"Warning: Could not open {SERIAL_PORT} - {e}")

# YUV420 to RGB Conversion Helper
def yuv420_to_rgb(yuv_data, width, height):
    # YUV420 (I420/NV12/NV21) comes as 1.5x height
    # We assume I420 (Planar: Y full, U quarter, V quarter) or NV12 from Picamera2 default
    # Picamera2 capture_array usually returns valid buffer structure but might be planar concatenation
    # Actually, for Picamera2, capture_array with "format='YUV420'" returns I420 usually.
    
    # Extract Y
    y = yuv_data[:height, :width]
    
    # Extract UV
    # I420: Y (w*h) + U (w/2 * h/2) + V (w/2 * h/2)
    # But often U and V are flattened or structured. 
    # Let's handle generic conversion assuming standard memory layout.
    
    # Fast path: try to use OpenCV if it existed, but it doesn't.
    # Manual NumPy with slicing to handle strided buffers (padding):
    # DIAGNOSIS V2: User reported yellow line at right edge.
    # Implies previous "Packed Side-by-Side" (0..240, 240..480) was close but mismatched.
    # Hardware likely aligns planes to 32 bytes (256 bytes for 512 stride).
    # Stride = 512. Width/2 = 240.
    # U: 0..240. (Padding 240..256).
    # V: 256..496. (Padding 496..512).
    
    stride = yuv_data.shape[1]
    
    # 1. Extract Y Plane (using slice to ignore stride padding)
    Y = yuv_data[:height, :width].astype(np.float32)
    
    # 2. Extract UV Planes (Planar I420: U then V)
    uv_h = height // 2
    uv_w = width // 2
    
    # Slice UV rows
    UV_view = yuv_data[height:, :]
    
    # Flatten to treat as sequential blocks
    UV_flat = UV_view.flatten()
    
    # Split into U and V (equal size)
    # Total UV bytes = stride * uv_h
    # U bytes = (stride * uv_h) / 2
    # V bytes = (stride * uv_h) / 2
    sz = UV_flat.size // 2
    
    U_flat = UV_flat[:sz]
    V_flat = UV_flat[sz:]
    
    # Reshape to (uv_h, stride // 2)
    # Note: Stride in Y is for full width. Chroma stride is usually half Y stride.
    chroma_stride = stride // 2
    
    U_full = U_flat.reshape((uv_h, chroma_stride))
    V_full = V_flat.reshape((uv_h, chroma_stride))
    
    # Crop to valid width
    U_part = U_full[:, :uv_w].astype(np.float32)
    V_part = V_full[:, :uv_w].astype(np.float32)

    # Upsample (Repeat rows x2, Repeat cols x2)
    U = U_part.repeat(2, axis=0).repeat(2, axis=1)
    V = V_part.repeat(2, axis=0).repeat(2, axis=1)
    
    # Adjust for center
    U -= 128
    V -= 128
    
    # Standard BT.601 conversion
    R = Y + 1.402 * V
    G = Y - 0.344136 * U - 0.714136 * V
    B = Y + 1.772 * U
    
    # Clip and cast
    R = np.clip(R, 0, 255).astype(np.uint8)
    G = np.clip(G, 0, 255).astype(np.uint8)
    B = np.clip(B, 0, 255).astype(np.uint8)
    
    # Stack
    rgb = np.dstack((R, G, B))
    return rgb

# ... existing imports ...

# Global State
is_paused = False
is_recording = False
demo_mode_active = False
recording_process = None
recording_filename_base = None
pending_action = None # 'record', 'demo_toggle'

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
    
    if duration > 0.5: # Long Press (> 0.5s) -> DEMO TOGGLE
        trigger_action('demo_toggle')
    else: # Short Press -> RECORD
        trigger_action('record')

# Actual Logic (Run in Main Loop)
def _do_toggle_demo():
    global demo_mode_active, pico_serial
    demo_mode_active = not demo_mode_active
    print(f"Demo Mode Toggled -> {demo_mode_active}")
    
    cmd = b"<PITCH:30.0>\n" if demo_mode_active else b"<STOP>\n"
    
    if pico_serial is not None:
        try:
            pico_serial.write(cmd)
            print(f"Sent to Pico: {cmd.strip().decode()}")
        except Exception as e:
            print(f"Error sending to Pico: {e}")
            # Try to reconnect
            try:
                pico_serial.close()
                pico_serial = serial.Serial(SERIAL_PORT, SERIAL_BAUD, timeout=0)
                pico_serial.write(cmd)
            except:
                pass
    else:
        print(f"Mocking sent to Pico: {cmd.strip().decode()}")

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
                
                # Copy to User System
                print(f"Copying to {USER_IP}...")
                copy_cmd = [
                    "sshpass", "-p", USER_PASS,
                    "scp", "-o", "StrictHostKeyChecking=no",
                    out, f"{USER_NAME}@{USER_IP}:{DEST_DIR}/"
                ]
                try:
                    subprocess.run(copy_cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                    print("Copy Successful.")
                except Exception as e:
                     print(f"Copy Failed: {e}")
            except Exception as e:
                print(f"Muxing Failed: {e}")

        try:
            t = threading.Thread(target=mux_thread)
            t.start()
        except:
            pass

# ... (Draw functions untouched) ...


def draw_status_badge(draw, width, video_bottom_y, is_recording):
    # Badge Logic
    # Position: Centered, some padding below video
    badge_w = 60
    badge_h = 24
    pad_top = 5
    
    cx = width // 2
    y = video_bottom_y + pad_top
    
    # Coordinates
    x0 = cx - badge_w // 2
    y0 = y
    x1 = cx + badge_w // 2
    y1 = y + badge_h
    
    # Color & Text
    if is_recording:
        fill_col = (255, 0, 0) # Red
        text = "REC"
    else:
        fill_col = (57, 255, 20) # Green (same as accent)
        text = "LIVE"
        
    # Draw Rounded Rect
    draw.rounded_rectangle([x0, y0, x1, y1], radius=8, fill=fill_col)
    
    # Draw Text
    font = get_font(12)
    # text dimensions
    try:
        bb = draw.textbbox((0,0), text, font=font)
        tw = bb[2] - bb[0]
        th = bb[3] - bb[1]
    except:
        tw, th = 20, 10
        
    text_x = x0 + (badge_w - tw) // 2
    # Vertically center approx
    text_y = y0 + (badge_h - th) // 2 - 2
    
    draw.text((text_x, text_y), text, font=font, fill=(255, 255, 255))


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
    
    # Row 3 (Network)
    
    # 3.1 Local IP
    local_ip = stats.get('ip', '..')
    draw.text((pad_corner, y_crs), f"LOCAL: {local_ip}", font=font_small, fill=c_cyan)
    
    # CPU Temp (Right Aligned on Local Line)
    temp = stats.get('cpu_temp', 0)
    temp_str = f"{temp:.0f}C"
    c_text = (220, 220, 200)
    t_w = draw.textbbox((0,0), temp_str, font=font_small)[2]
    draw.text((width - pad_corner - t_w, y_crs), temp_str, font=font_small, fill=c_text)
    draw_thermo(draw, width - pad_corner - t_w - 14, y_crs+2, 12, c_text)
    
    y_crs += 12
    
    # 3.2 Server IP
    # Global 'server_status' is updated by background thread
    # 0=Disc(Red), 1=Conn(Green), 2=Copy(Blue)
    try:
        status = server_status.get('state', 0)
    except:
        status = 0
        
    srv_col = c_cyan
    status_text = "ERR"
    icon_col = (255, 0, 0) # Red
    
    if status == 1: 
        status_text = "OK"
        icon_col = c_green
    elif status == 2: 
        status_text = "COPY"
        icon_col = (0, 100, 255) # Blue
    elif status == 0:
        status_text = "ERR"
        icon_col = (255, 0, 0)
    
    draw.text((pad_corner, y_crs), f"SERVER: {USER_IP}", font=font_small, fill=srv_col)
    
    # Status Text (Right Aligned)
    st_w = draw.textbbox((0,0), status_text, font=font_small)[2]
    draw.text((width - pad_corner - st_w, y_crs), status_text, font=font_small, fill=icon_col)

# Server Monitor Thread
server_status = {'state': 0} # 0=Disc, 1=Conn, 2=Copy

def monitor_server_thread():
    while True:
        try:
            # 1. Check Copying (scp/rsync)
            # pgrep returns 0 if found
            res = subprocess.call(["pgrep", "-f", "scp|rsync"], stdout=subprocess.DEVNULL)
            is_copying = (res == 0)
            
            if is_copying:
                server_status['state'] = 2
            else:
                # 2. Ping Server (Timeout 1s)
                # -c 1 = 1 packet, -W 1 = 1 sec timeout
                param = "-n" if sys.platform.lower()=='win32' else "-c"
                cmd = ["ping", param, "1", "-W", "1", USER_IP]
                res = subprocess.call(cmd, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
                
                if res == 0:
                    server_status['state'] = 1
                else:
                    server_status['state'] = 0
                    
        except:
             server_status['state'] = 0
             
        time.sleep(1.0)


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
    # main: YUV 1080p for H264 encoder (recording). High Res.
    # lores: YUV 480x270 for display (16:9). Low Res. REQUIRED to be YUV by Picamera2/Hardware.
    config = picam2.create_video_configuration(
        main={"size": (1920, 1080), "format": "YUV420"},
        lores={"size": (480, 270), "format": "YUV420"},
        controls={
            "FrameDurationLimits": (20000, 20000)
        }
    )
    picam2.configure(config)
    picam2.start()

    # Register Button Callbacks (Short=Record, Long=Demo Toggle)
    board.on_button_press(handle_whisplay_press)
    board.on_button_release(handle_whisplay_release)

    print(f"Camera started.")
    print(f"Short Press: Record | Long Press (>0.5s): Demo Toggle (Motors)")

    # Start Server Monitor
    try:
        t_srv = threading.Thread(target=monitor_server_thread, daemon=True)
        t_srv.start()
    except:
        pass
    
    try:
        while True:
            # Handle Actions (Thread Safe)
            global pending_action
            if pending_action:
                act = pending_action
                pending_action = None # Reset
                
                if act == 'record':
                    _do_toggle_record(picam2, config)
                elif act == 'demo_toggle':
                    _do_toggle_demo()
            
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
                # Capture from "lores" (low res YUV) for display
                image_yuv = picam2.capture_array("lores")
                
                # Convert YUV to RGB
                # We know config is 480x270. 
                # image_yuv has stride (e.g. 512). Pass explicit 480 width to crop stride.
                image = yuv420_to_rgb(image_yuv, 480, 270)
            except Exception as e:
                # print(f"Capture Error: {e}")
                time.sleep(0.01)
                continue

            pil_img = Image.fromarray(image)
            # pil_img = pil_img.rotate(180) # Disabled by user request
            
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
            # offset_y = HEIGHT - new_h # Old bottom align
            offset_y = 110 # Fixed top align below stats (110 = 90 + gap)
            
            final_img.paste(pil_img, (offset_x, offset_y))
            
            draw = ImageDraw.Draw(final_img)
            # Stats (pass 0 as y limit, not used effectively inside but kept for sig)
            draw_big_stats(draw, current_stats, WIDTH, 0)
            
            # Status Badge
            draw_status_badge(draw, WIDTH, offset_y + new_h, is_recording)
            
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
