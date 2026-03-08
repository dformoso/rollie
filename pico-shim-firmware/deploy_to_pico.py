import serial
import time
import sys
import os

PORT = '/dev/ttyACM0'
BAUD = 115200

def send_command(ser, cmd, wait=0.1):
    ser.write((cmd + '\r\n').encode())
    time.sleep(wait)
    return ser.read_all().decode(errors='ignore')

def write_file(ser, filename, content):
    print(f"Writing {filename}...")
    send_command(ser, f"f = open('{filename}', 'w')")
    # Write in chunks to avoid REPL buffer overflow
    lines = content.split('\n')
    for line in lines:
        # Escape single quotes and backslashes
        escaped = line.replace('\\', '\\\\').replace("'", "\\'")
        send_command(ser, f"f.write('{escaped}\\n')", wait=0.05)
    send_command(ser, "f.close()")
    print(f"Done writing {filename}")

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 deploy_to_pico.py <dir_with_firmware>")
        sys.exit(1)

    dir_path = sys.argv[1]
    files_to_send = ['boot.py', 'main.py', 'bno055_minimal.py']

    try:
        ser = serial.Serial(PORT, BAUD, timeout=1)
        print(f"Connected to {PORT}")

        # Interrupt running script
        ser.write(b'\x03\x03')
        time.sleep(0.5)
        print("Interrupted Pico")

        # Enter raw REPL or just use normal REPL for simplicity
        # Normal REPL is fine for small files
        
        for fname in files_to_send:
            fpath = os.path.join(dir_path, fname)
            if os.path.exists(fpath):
                with open(fpath, 'r') as f:
                    content = f.read()
                write_file(ser, fname, content)
            else:
                print(f"Warning: {fname} not found in {dir_path}")

        # Reset Pico
        print("Resetting Pico...")
        ser.write(b'\x04')
        time.sleep(0.5)
        ser.close()
        print("Deployment finished.")

    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
