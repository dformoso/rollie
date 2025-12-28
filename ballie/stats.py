import psutil
import socket
import struct
import subprocess
import os
import time
from smbus2 import SMBus

class SystemStats:
    def __init__(self):
        # PiSugar 3 I2C address
        self.PISUGAR_ADDR = 0x57
        self.bus = None
        try:
            self.bus = SMBus(1)
        except Exception as e:
            # print(f"Warning: Could not open I2C bus: {e}")
            pass

    def get_battery_socket(self):
        """
        Attempts to read battery from pisugar-server via Unix Socket.
        """
        sock_path = "/tmp/pisugar-server.sock"
        if not os.path.exists(sock_path):
            return None
            
        try:
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.settimeout(0.5)
                s.connect(sock_path)
                
                # Get Percentage
                s.sendall(b'get battery\n')
                data = s.recv(1024).decode().strip()
                # Expected: "battery: 89.0"
                if 'battery:' in data:
                    pct = float(data.split(':')[1])
                else:
                    return None

                # Get Charging Status
                s.sendall(b'get battery_charging\n')
                data_c = s.recv(1024).decode().strip()
                # Expected: "battery_charging: true" or similar
                charging = 'true' in data_c.lower()
                
                return {
                    "percent": pct,
                    "voltage": 0.0,
                    "charging": charging,
                    "error": False
                }
        except Exception as e:
            # print(f"Socket Battery Error: {e}")
            return None

    def get_battery(self):
        """
        Reads battery percentage and status.
        Priority: PiSugar Server Socket -> I2C Registers.
        """
        # Try Socket First
        bat_sock = self.get_battery_socket()
        if bat_sock:
            return bat_sock
            
        # Fallback to I2C
        if not self.bus:
            return {"percent": 0.0, "voltage": 0.0, "charging": False, "error": True}
        
        percent = 0.0
        is_charging = False
        error = False
        
        try:
            # Try 0x2A (PiSugar 3 Percentage) first
            try:
                percent = self.bus.read_byte_data(self.PISUGAR_ADDR, 0x2A)
            except:
                # Fallback to 0x22 or 0x04 if 0x2A fails
                try:
                    percent = self.bus.read_byte_data(self.PISUGAR_ADDR, 0x22)
                except:
                    percent = 0.0
                    error = True

            if percent > 100: percent = 100
                
            try:
                status_reg = self.bus.read_byte_data(self.PISUGAR_ADDR, 0x02)
                is_charging = (status_reg & 0x80) > 0
            except:
                is_charging = False
                
        except Exception as e:
            error = True
            
        return {
            "percent": float(percent),
            "voltage": 0.0, 
            "charging": is_charging,
            "error": error
        }

    def get_cpu(self):
        return psutil.cpu_percent()

    def get_temp(self):
        try:
            temp = psutil.sensors_temperatures()['cpu_thermal'][0].current
            return temp
        except:
            return 0.0

    def get_ram(self):
        return psutil.virtual_memory().percent

    def get_disk(self):
        return psutil.disk_usage('/').percent

    def get_ip(self):
        try:
            # Connect to a public DNS to find local IP used for routing
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            return ip
        except:
            return "--"

    def get_wifi(self):
        """
        Parses iwgetid for SSID and /proc/net/wireless for signal quality.
        """
        ssid = "--"
        signal_dbm = -100
        
        try:
            # Get SSID
            result = subprocess.check_output(["iwgetid", "-r"], text=True).strip()
            if result:
                ssid = result
        except:
            pass
            
        try:
            with open("/proc/net/wireless", "r") as f:
                lines = f.readlines()
                for line in lines:
                    if "wlan0" in line:
                        parts = line.split()
                        # Usually 4th field is level
                        if len(parts) >= 4:
                            dbm_str = parts[3].replace(".", "")
                            try:
                                signal_dbm = int(dbm_str)
                            except:
                                pass
        except:
            pass

        return {"ssid": ssid, "dbm": signal_dbm}

    def get_uptime(self):
        try:
            with open('/proc/uptime', 'r') as f:
                uptime_seconds = float(f.readline().split()[0])
            
            hours = int(uptime_seconds // 3600)
            minutes = int((uptime_seconds % 3600) // 60)
            return f"{hours}h{minutes}m"
        except:
            return "--"

    def get_all(self):
        wifi = self.get_wifi()
        bat = self.get_battery()
        
        return {
            "bat_percent": bat['percent'],
            "bat_charging": bat['charging'],
            "cpu_percent": self.get_cpu(),
            "cpu_temp": self.get_temp(),
            "ram_percent": self.get_ram(),
            "disk_percent": self.get_disk(),
            "ssid": wifi['ssid'],
            "wifi_dbm": wifi['dbm'],
            "ip": self.get_ip(),
            "uptime": self.get_uptime(),
            "time_str": time.strftime("%I:%M %p")
        }
