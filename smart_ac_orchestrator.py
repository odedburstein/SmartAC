import bluetooth
import multiprocessing

from bluetooth import BluetoothSocket as socket
from person_finder import person_finder

# BT config
server_sock = socket(bluetooth.RFCOMM)
port = bluetooth.PORT_ANY
server_sock.bind(("", port))
server_sock.listen(1)

# MP config
queue = multiprocessing.Queue()

person_finder_process = multiprocessing.Process(target=person_finder, args=(queue,))
person_finder_process.start()

def wait_for_connection():
    print(f"Smart AC orchestrator: Waiting for client to connect")
    client_sock, address = server_sock.accept()
    print(f"Smart AC orchestrator: Accepted connection from {address}")
    return client_sock, address


if __name__ == '__main__':
    client_sock, address = wait_for_connection()
    while True:
        try:
            # Recieved messages from android are encoded
            recieved_msg = (client_sock.recv(1024)).decode()
            if recieved_msg == 'ON':
                print(f"Smart AC orchestrator: Doing work")
                queue.put('ON')
            elif recieved_msg == 'OFF':
                print(f"Smart AC orchestrator: Stopping work")
                queue.put('OFF')
            elif recieved_msg == 'EXIT':
                queue.put('EXIT')
                print(f"Smart AC orchestrator: Going to sleep forever")
                break
        except bluetooth.btcommon.BluetoothError as e:
            print(f"Smart AC orchestrator: Something went wrong with the connection. Attempting to reconnect")
            print(f"Smart AC orchestrator: The error was {e}")
            client_sock, address = wait_for_connection()
        except Exception as e:
            print(f"Smart AC orchestrator: Something went wrong in general")
            print(f"Smart AC orchestrator: The error was {e}")
            break
