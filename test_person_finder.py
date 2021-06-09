# This is a demo of running face recognition on a Raspberry Pi.
# This program will print out the names of anyone it recognizes to the console.

# To run this, you need a Raspberry Pi 2 (or greater) with face_recognition and
# the picamera[array] module installed.
# You can follow this installation instructions to get your RPi set up:
# https://gist.github.com/ageitgey/1ac8dbe8572f3f533df6269dab35df65

import face_recognition
import picamera
import numpy as np
import pyrealsense2.pyrealsense2 as rs
import cv2

# Get a reference to the Raspberry Pi camera.
# If this fails, make sure you have a camera connected to the RPi and that you
# enabled your camera in raspi-config and rebooted first.
pipeline = rs.pipeline()
config = rs.config()
config.enable_stream(rs.stream.depth, 640, 480, rs.format.z16, 6)
config.enable_stream(rs.stream.color, 640, 480, rs.format.bgr8, 30)

print(f"{__file__} Starting streaming...")
pipeline.start(config)
print(f"{__file__} Camera ready.")

# Load a sample picture and learn how to recognize it.
print("Loading known face image(s)")
photo_path = "naveh_small.jpeg"
name = photo_path.split('_')[0]
obama_image = face_recognition.load_image_file(photo_path)
user_face_encoding = face_recognition.face_encodings(obama_image)[0]

align_to = rs.stream.color
align = rs.align(align_to)

# Initialize some variables
face_locations = []
face_encodings = []
if __name__=="__main__":
    while True:
        print("Capturing image.")
        # Grab a single frame of video from the RPi camera as a numpy array
        frames = pipeline.wait_for_frames()

        aligned_frames = align.process(frames)
        aligned_depth_frame = aligned_frames.get_depth_frame()
        color_frame = aligned_frames.get_color_frame()
        output = np.asanyarray(color_frame.get_data())

        # Find all the faces and face encodings in the current frame of video
        face_locations = face_recognition.face_locations(output)
        print("Found {} faces in image.".format(len(face_locations)))
        face_encodings = face_recognition.face_encodings(output, face_locations)

        location = None
        # Loop over each face found in the frame to see if it's someone we know.
        for i, face_encoding in enumerate(face_encodings):
            # See if the face is a match for the known face(s)
            match = face_recognition.compare_faces([user_face_encoding], face_encoding)
            if match[0]:
                location = face_locations[i]
                print(f"I found {name}")

        if location != None:
            # Display the results
            for (top, right, bottom, left), name in zip([location], [name]):

                # Draw a box around the face
                cv2.rectangle(output, (left, top), (right, bottom), (0, 0, 255), 2)

                # Draw a label with a name below the face
                cv2.rectangle(output, (left, bottom - 35), (right, bottom), (0, 0, 255), cv2.FILLED)
                font = cv2.FONT_HERSHEY_DUPLEX
                cv2.putText(output, name, (left + 6, bottom - 6), font, 1.0, (255, 255, 255), 1)

            # Display the resulting image

        cv2.imshow('Video', output)
        cv2.waitKey(5)
        
