import time
try:
    from picamera2 import Picamera2
except ImportError:
    print("Picamera2 not found")
    exit(1)

print("Initializing Picamera2...")
picam2 = Picamera2()

print("Configuring...")
try:
    config = picam2.create_video_configuration(
        main={"size": (1920, 1080), "format": "YUV420"},
        lores={"size": (480, 270), "format": "YUV420"},
        controls={"FrameDurationLimits": (20000, 20000)}
    )
    print("Configuration created successfully.")
    print(config)
    picam2.configure(config)
    print("Configure successful.")
    picam2.start()
    print("Start successful.")
    time.sleep(2)
    picam2.stop()
    print("Stop successful.")
except Exception as e:
    print(f"Error: {e}")
