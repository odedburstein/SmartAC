import bluetooth
import firebase_admin
import multiprocessing
import os
import time
import pyrebase

from bluetooth import BluetoothSocket as socket
#from firebase_admin import storage
from segmented_person_finder import person_finder

# BT config
server_sock = socket(bluetooth.RFCOMM)
port = bluetooth.PORT_ANY
server_sock.bind(("", port))
server_sock.listen(1)

# MP config
queue = multiprocessing.Queue()

person_finder_process = multiprocessing.Process(target=person_finder, args=(queue,))

path_to_user_photo = "user.jpg"
user_photo_download_path = "user_small.jpg"

# firebase config

firebase_config = {
  'apiKey': "AIzaSyD13Vy9h8KrFWDMG4-dZwcJhkxgJvk7smk",
  'authDomain': "smart-ac-e68d3.firebaseapp.com",
  'projectId': "smart-ac-e68d3",
  'storageBucket': "smart-ac-e68d3.appspot.com",
  'messagingSenderId': "35189564918",
  'appId': "1:35189564918:web:6b429e270002978844d3d7",
    'databaseURL': 'https://smart-ac-e68d3-default-rtdb.europe-west1.firebasedatabase.app/'
}

firebase = pyrebase.initialize_app(firebase_config)
storage = firebase.storage()

def wait_for_connection():
    print(f"Smart AC orchestrator: Waiting for client to connect")
    client_sock, address = server_sock.accept()
    print(f"Smart AC orchestrator: Accepted connection from {address}")
    return client_sock, address

def get_user_photo_from_firebase():
    try:
        firebase_download_response = storage.child(path_to_user_photo).download(user_photo_download_path)

        return firebase_download_response
    except Exception as e:
        print(f"Smart AC orchestrator: Failed to acess firebase. The error was {e}")

if __name__ == '__main__':
    print(f"Smart AC orchestrator: Starting orchestrator process")

    print(f"Smart AC orchestrator: Attempting to download user photo from firebase")
    firebase_download_response = get_user_photo_from_firebase()

    while not os.path.exists(user_photo_download_path):
        time.sleep(1)

    person_finder_process.start()

    print(f"Smart AC orchestrator: Sucessfully downloaded user photo from firebase")

    print(f"Smart AC orchestrator: Starting person finder process")


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
            elif recieved_msg == "REFRESH_FACE":
                firebase_download_response = get_user_photo_from_firebase()
                print(f"Smart AC orchestrator: Changing user face")
                queue.put('REFRESH_FACE')
            elif recieved_msg == "REFRESH_POSITION":
                print(f"Smart AC orchestrator: Changing ac position")
                queue.put('REFRESH_POSITION')
            elif recieved_msg == 'EXIT':
                person_finder_process.kill()
                queue.close()
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
