import bluetooth
import multiprocessing
import os
import time
import pyrebase

from bluetooth import BluetoothSocket as socket
from segmented_person_finder import person_finder

# BT config
server_sock = socket(bluetooth.RFCOMM)
port = bluetooth.PORT_ANY
server_sock.bind(("", port))
server_sock.listen(1)

# MP config
queue = multiprocessing.Queue()

person_finder_process = multiprocessing.Process(target=person_finder, args=(queue,))

#  Firebase config
config = {
  "apiKey": "AIzaSyD13Vy9h8KrFWDMG4-dZwcJhkxgJvk7smk",
  "authDomain": "smart-ac-e68d3.firebaseapp.com",
  "databaseURL": "https://smart-ac-e68d3-default-rtdb.europe-west1.firebasedatabase.app/",
  "storageBucket": "smart-ac-e68d3.appspot.com"
}

path_to_user_photo = "user.jpg"
user_photo_download_path = "user_small.jpg"

firebase = pyrebase.initialize_app(config)


def wait_for_connection():
    print(f"Smart AC orchestrator: Waiting for client to connect")
    client_sock, address = server_sock.accept()
    print(f"Smart AC orchestrator: Accepted connection from {address}")
    return client_sock, address

def get_user_photo_from_firebase():
    try:
        firebase_storage_client = firebase.storage()
        firbase_storage_child = firebase_storage_client.child(path_to_user_photo)
        firebase_download_response = firbase_storage_child.download(user_photo_download_path)
        return firebase_download_response
    except Exception as e:
        print(f"Smart AC orchestrator: Failed to acess firebase. The error was {e}")

if __name__ == '__main__':
    print(f"Smart AC orchestrator: Starting orchestrator process")

    print(f"Attempting to download user photo from firebase")
    firebase_download_response = get_user_photo_from_firebase()

    while not os.path.exists(user_photo_download_path):
        time.sleep(1)

    print(f"Sucessfully downloaded user photo from firebase")

    print(f"Smart AC orchestrator: Starting person finder process")
    person_finder_process.start()

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
