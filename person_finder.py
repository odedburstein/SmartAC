# This is a demo of running face recognition on a Raspberry Pi.
# This program will print out the names of anyone it recognizes to the console.

# To run this, you need a Raspberry Pi 2 (or greater) with face_recognition and
# the picamera[array] module installed.
# You can follow this installation instructions to get your RPi set up:
# https://gist.github.com/ageitgey/1ac8dbe8572f3f533df6269dab35df65

import pyrealsense2.pyrealsense2 as rs
import numpy as np
import cv2
import face_recognition
import picamera
import numpy as np

# Get a reference to the Raspberry Pi camera.
# If this fails, make sure you have a camera connected to the RPi and that you
# enabled your camera in raspi-config and rebooted first.
pipeline = rs.pipeline()
config = rs.config()
config.enable_stream(rs.stream.color, 1280, 720, rs.format.bgr8, 30)

print("[INFO] Starting streaming...")
pipeline.start(config)
print("[INFO] Camera ready.")

# Load a sample picture and learn how to recognize it.
print("Loading known face image(s)")
oded_image = face_recognition.load_image_file("oded_small.jpg")
oded_face_encoding = face_recognition.face_encodings(oded_image)[0]

# Initialize some variables
face_locations = []
face_encodings = []
face_names = ["oded"]
while True:
    print("Capturing image.")
    # Grab a single frame of video from the RPi camera as a numpy array
    frames = pipeline.wait_for_frames()
    color_frame = frames.get_color_frame()

    color_image = np.asanyarray(color_frame.get_data())

    # Find all the faces and face encodings in the current frame of video
    face_locations = face_recognition.face_locations(color_image)
    print("Found {} faces in image.".format(len(face_locations)))
    face_encodings = face_recognition.face_encodings(color_image, face_locations)

    # Loop over each face found in the frame to see if it's someone we know.
    for face_encoding in face_encodings:
        # See if the face is a match for the known face(s)
        match = face_recognition.compare_faces([oded_face_encoding], face_encoding)
        name = "<Unknown Person>"

        if match[0]:
            name = "Oded"

        print("I see someone named {}!".format(name))

    for (top, right, bottom, left) in face_locations:

        # Draw a box around the face
        cv2.rectangle(color_image, (left, top), (right, bottom), (0, 0, 255), 2)

        # Draw a label with a name below the face
        cv2.rectangle(color_image, (left, bottom - 35), (right, bottom), (0, 0, 255), cv2.FILLED)

        # Display the resulting image
    cv2.imshow('Video', color_image)