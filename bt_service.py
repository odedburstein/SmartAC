import bluetooth
from bluetooth import BluetoothSocket as socket

server_sock = socket(bluetooth.RFCOMM)
port = bluetooth.PORT_ANY
server_sock.bind(("", port))
server_sock.listen(1)


def wait_for_connection():
    print('Waiting for client to connect')
    client_sock, address = server_sock.accept()
    print(f"Accepted connection from {address}")
    return client_sock, address


if __name__ == '__main__':
    client_sock, address = wait_for_connection()
    while True:
        try:
            # Recieved messages from android are encoded
            recieved_msg = (client_sock.recv(1024)).decode()

            if recieved_msg == 'ON':
                print("Doing work")
            elif recieved_msg == 'OFF':
                print("Stopping work")
            elif recieved_msg == 'EXIT':
                print("Going to sleep forever")
                break
        except bluetooth.btcommon.BluetoothError as e:
            print(f"Something went wrong with the connection. Attempting to reconnect")
            print(f"The error was {e}")
            client_sock, address = wait_for_connection()
