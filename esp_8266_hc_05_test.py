import bluetooth
import random
import time
from bluetooth import BluetoothSocket as socket

#devices = bluetooth.discover_devices()

# HC05 config
hc_05_bt_addr = "00:15:83:35:7F:5D"
# BT config
sock = socket(bluetooth.RFCOMM)
port = 1
sock.connect((hc_05_bt_addr,port))

angle = 180

if __name__ == '__main__':
    while True:
        try:
            sent_angle = chr(180-angle)
            sock.send(sent_angle.encode())
            print(f"I've successfully sent {angle} to HC-05")
            angle = 180-angle
            time.sleep(1.5)
        except bluetooth.btcommon.BluetoothError as e:
            print(f"{__file__} Something went wrong with the connection. Attempting to reconnect")
            print(f"{__file__} The error was {e}")
        except Exception as e:
            print(f"{__file__} Something went wrong in general")
            print(f"{__file__} The error was {e}")
            break
