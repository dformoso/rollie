import time
import sys
import os
import signal
import numpy as np
from PIL import Image

# Import WhisPlay driver
try:
    from WhisPlay import WhisPlayBoard
except ImportError:
    print("Error: WhisPlay.py not found. Please ensure it is in the same directory.")
    sys.exit(1)

# Import Picamera2
try:
    from picamera2 import Picamera2
except Exception as e:
    print(f"Error importing picamera2: {e}")
    import traceback
    traceback.print_exc()
    sys.exit(1)

# Configuration
WIDTH = 240
HEIGHT = 280
FPS = 30

def signal_handler(sig, frame):
    print("\nExiting...")
    raise KeyboardInterrupt

signal.signal(signal.SIGINT, signal_handler)

def main():
    # Initialize WhisPlay Board
    print("Initializing WhisPlay Board...")
    board = WhisPlayBoard()
    board.set_backlight(100) # Turn on backlight
    board.fill_screen(0) # Clear screen (black)

    # Initialize Camera
    print("Initializing Camera...")
    picam2 = Picamera2()
    
    # Configure camera for video capture
    # Use a standard aspect ratio like 640x480 for the sensor to get full FOV
    config = picam2.create_video_configuration(main={"size": (640, 480), "format": "RGB888"})
    picam2.configure(config)
    picam2.start()

    print(f"Camera started. Displaying full FOV on {WIDTH}x{HEIGHT} screen (bottom aligned, rotated 180)...")
    
    try:
        while True:
            # Capture image as numpy array
            image = picam2.capture_array()

            # Image processing
            pil_img = Image.fromarray(image)
            
            # Software Rotation (robust)
            pil_img = pil_img.rotate(180)
            
            # Calculate scaling to fit "EVERYTHING" (Letterbox style) - fit into width OR height
            img_w, img_h = pil_img.size
            
            # Calculate scale to fit strictly inside the screen dimensions (contain)
            scale_w = WIDTH / img_w
            scale_h = HEIGHT / img_h
            scale = min(scale_w, scale_h)
            
            new_w = int(img_w * scale)
            new_h = int(img_h * scale)
            
            # Use Resampling.BILINEAR or just BILINEAR depending on PIL version
            try:
                resample_method = Image.Resampling.BILINEAR
            except AttributeError:
                resample_method = Image.BILINEAR
                
            pil_img = pil_img.resize((new_w, new_h), resample_method)
            
            # Create a black background (240x280)
            final_img = Image.new("RGB", (WIDTH, HEIGHT), (0, 0, 0))
            
            # Paste image at the BOTTOM
            # (WIDTH - new_w) // 2 centers it horizontally
            # (HEIGHT - new_h) is the offset for the bottom
            offset_x = (WIDTH - new_w) // 2
            offset_y = HEIGHT - new_h
            final_img.paste(pil_img, (offset_x, offset_y))
            
            # Convert back to numpy for RGB565 conversion
            image = np.array(final_img)

            # Convert RGB888 to RGB565 with Numpy optimization
            # RGB565: RRRRRGGG GGGBBBBB
            r = image[:, :, 0]
            g = image[:, :, 1]
            b = image[:, :, 2]

            # Cast to uint16 to prevent overflow during bitwise operations
            rgb565 = (
                ((r.astype(np.uint16) & 0xF8) << 8) |
                ((g.astype(np.uint16) & 0xFC) << 3) |
                (b.astype(np.uint16) >> 3)
            )

            # Split into high and low bytes
            high_byte = (rgb565 >> 8) & 0xFF
            low_byte = rgb565 & 0xFF

            # Stack and flatten to get [H, L, H, L, ...] sequence
            # dstack makes (H, W, 2), flatten makes (H*W*2,)
            pixel_data = np.dstack((high_byte, low_byte)).flatten().tolist()

            # Display
            board.draw_image(0, 0, WIDTH, HEIGHT, pixel_data)

    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"Error: {e}")
    finally:
        print("Cleaning up...")
        picam2.stop()
        board.cleanup()

if __name__ == "__main__":
    main()
