import pyrealsense2.pyrealsense2 as rs
import face_recognition
import numpy as np
import bluetooth
import random

from bluetooth import BluetoothSocket as socket
from queue import Empty
from time import sleep


# HC05 config
hc_05_bt_addr = "00:15:83:35:7F:5D"
# BT config
sock = socket(bluetooth.RFCOMM)
port = 1
sock.connect((hc_05_bt_addr,port))


def person_finder(queue):
    # Get a reference to the Raspberry Pi camera.
    # If this fails, make sure you have a camera connected to the RPi and that you
    # enabled your camera in raspi-config and rebooted first.
    pipeline = rs.pipeline()
    config = rs.config()
    config.enable_stream(rs.stream.depth, 424, 240, rs.format.z16, 6)
    config.enable_stream(rs.stream.color, 424, 240, rs.format.bgr8, 30)
    print(f"{__file__} Starting streaming...")
    pipeline.start(config)
    print(f"{__file__} Camera ready.")

    # Load a sample picture and learn how to recognize it.
    print(f"{__file__} Loading known face image(s)")
    oded_image = face_recognition.load_image_file("oded_small.jpg")
    oded_face_encoding = face_recognition.face_encodings(oded_image)[0]

    # Initialize some variables
    face_locations = []
    face_encodings = []
    face_names = ["oded"]
    should_work = False
    msg = None
    print(f"{__file__} Person finder service finished calibrating")

    align_to = rs.stream.color
    align = rs.align(align_to)

    while True:
        # print("I'm not dead, another loop iteration")
        try:
            msg = queue.get_nowait()
            print(f"{__file__} I got message: {msg}")
            if msg == "ON":
                print(f"{__file__} Starting person finder algorithm")
                should_work = True
            elif msg == "OFF":
                print(f"{__file__} Stopping person finder algorithm")
                should_work = False
            sleep(1.5)
        except Empty:
            if should_work:
                print(f"{__file__} Capturing image.")
                # Grab a single frame of video from the RPi camera as a numpy array
                frames = pipeline.wait_for_frames()

                aligned_frames = align.process(frames)
                aligned_depth_frame = aligned_frames.get_depth_frame()
                color_frame = aligned_frames.get_color_frame()

                if not aligned_depth_frame or not color_frame:
                    print('invalid frames')
                    continue

                depth_frame = aligned_depth_frame
                color_image = np.asanyarray(color_frame.get_data())

                # Find all the faces and face encodings in the current frame of video
                face_locations = face_recognition.face_locations(color_image)
                print(f"{__file__} Found {len(face_locations)} faces in image")
                face_encodings = face_recognition.face_encodings(color_image, face_locations)

                # Loop over each face found in the frame to see if it's someone we know.
                for i, face_encoding in enumerate(face_encodings):
                    # See if the face is a match for the known face(s)
                    match = face_recognition.compare_faces([oded_face_encoding], face_encoding)
                    name = "<Unknown Person>"

                    if match[0]:
                        name = "Oded"
                        top, right, bottom, left = face_locations[i]
                        print(f"{__file__} I see {name}!")
                        print(f"{__file__} Oded's coords in the image is left={left} top={top} right={right} bottom={bottom}")
                        x_coord, y_coord = ((left + right) / 2, (top + bottom) / 2)
                        z_coord = depth_frame.get_distance(int(x_coord), int(y_coord))
                        print(f'oded\'s face center is at {(x_coord, y_coord, z_coord)} [(px, px, m)]]')
                        sock.send(chr(get_angle(x_coord=x_coord, y_coord=y_coord, z_coord=z_coord)).encode())

            sleep(1.5)

            # for (top, right, bottom, left) in face_locations:
            #
            #     # Draw a box around the face
            #     cv2.rectangle(color_image, (left, top), (right, bottom), (0, 0, 255), 2)
            #
            #     # Draw a label with a name below the face
            #     cv2.rectangle(color_image, (left, bottom - 35), (right, bottom), (0, 0, 255), cv2.FILLED)
            #
            #     # Display the resulting image
            # cv2.imshow('Video', color_image)


def get_angle(x_coord, y_coord, z_coord):
    # TODO implement
    return int(random.uniform(0, 180.0))
