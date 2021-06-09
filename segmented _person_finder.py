import bluetooth
import face_recognition
import math
import numpy as np
import pyrealsense2.pyrealsense2 as rs

from bluetooth import BluetoothSocket as socket
from queue import Empty
from time import sleep, time


# HC05 config
hc_05_bt_addr = "00:15:83:35:7F:5D"
# BT config
sock = socket(bluetooth.RFCOMM)
port = 1
sock.connect((hc_05_bt_addr,port))

# user photo config
user_photo_path = "naveh_small.jpeg"
user_name = user_photo_path.split("_")[0]



# person finder config
FRAME_WIDTH = 640
FRAME_HEIGHT = 480
SEG_PARAMETER = 10
FRAME_SEGMENT = FRAME_WIDTH/SEG_PARAMETER
ANGLE_RANGE = 120
ANGLE_PER_SEGMENT = ANGLE_RANGE/SEG_PARAMETER
MAX_DISTANCE_ALLOWED = 3.5
PERSON_FINDER_DELAY = 1.5

def person_finder(queue):
    # Get a reference to the Raspberry Pi camera.
    # If this fails, make sure you have a camera connected to the RPi and that you
    # enabled your camera in raspi-config and rebooted first.

    person_found = False
    person_present = False
    is_user_close=True
    MAX_ABSENCE_ALLOWED = 1000 * 60 * 5
    ABSENCE_TIMER = 0
    FAR_TIMER = 0

    pipeline = rs.pipeline()
    config = rs.config()
    config.enable_stream(rs.stream.depth, FRAME_WIDTH, FRAME_HEIGHT, rs.format.z16, 6)
    config.enable_stream(rs.stream.color, FRAME_WIDTH, FRAME_HEIGHT, rs.format.bgr8, 30)
    print(f"Segmented Person Finder: Starting streaming")
    pipeline.start(config)
    print(f"Segmented Person Finder: Camera ready")

    # Load a sample picture and learn how to recognize it.
    print(f"Segmented Person Finder: Loading known face image(s)")
    user_image = face_recognition.load_image_file(user_photo_path)
    user_face_encoding = face_recognition.face_encodings(user_image)[0]

    # Initialize some variables
    face_locations = []
    face_encodings = []
    face_names = [user_name]
    should_work = False
    msg = None
    print(f"Segmented Person Finder: Person finder service finished calibrating")

    align_to = rs.stream.color
    align = rs.align(align_to)

    while True:
        # print("I'm not dead, another loop iteration")
        try:
            msg = queue.get_nowait()
            print(f"Segmented Person Finder: I got message: {msg}")
            if msg == "ON":
                print(f"Segmented Person Finder: Starting person finder algorithm")
                should_work = True
            elif msg == "OFF":
                print(f"Segmented Person Finder: Stopping person finder algorithm")
                should_work = False
            sleep(1.5)
        except Empty:
            if should_work:
                print(f"Segmented Person Finder: Capturing image")
                # Grab a single frame of video from the RPi camera as a numpy array
                frames = pipeline.wait_for_frames()

                aligned_frames = align.process(frames)
                aligned_depth_frame = aligned_frames.get_depth_frame()
                color_frame = aligned_frames.get_color_frame()

                if not aligned_depth_frame or not color_frame:
                    print("Segmented Person Finder: Invalid frames")
                    continue

                depth_frame = aligned_depth_frame
                color_image = np.asanyarray(color_frame.get_data())

                # Find all the faces and face encodings in the current frame of video
                face_locations = face_recognition.face_locations(color_image)
                print(f"Segmented Person Finder: Found {len(face_locations)} faces in image")
                face_encodings = face_recognition.face_encodings(color_image, face_locations)

                user_location_in_frame = find_user_location_in_frame(face_encodings, user_face_encoding, face_locations)

                if user_location_in_frame:
                    user_present = True
                    ABSENCE_TIMER = 0
                    x_coord, y_coord, z_coord = get_face_coordinates(user_location_in_frame, depth_frame)
                    if z_coord >= MAX_DISTANCE_ALLOWED:
                        if is_user_close:
                            is_user_close = False
                            FAR_TIMER = time()
                        else:
                            total_far_time = time() - FAR_TIMER
                            if total_far_time > MAX_ABSENCE_ALLOWED:
                                # TODO: shut down AC
                                print("person is far for more than 5 minutes!")

                    else: # z_coord < 3.5 m
                        is_user_close = True
                        FAR_TIMER = 0
                        angle = get_angle(x_coord=x_coord, y_coord=y_coord, z_coord=z_coord)
                        send_angle_to_hc05(angle)

                else:
                    if user_present:
                        user_present = False
                        ABSENCE_TIMER = time()
                    else:
                        total_absence_time = time()-ABSENCE_TIMER
                        if total_absence_time > MAX_ABSENCE_ALLOWED:
                            #TODO: shut down AC
                            print("person is gone for more than 5 minutes!")

            sleep(PERSON_FINDER_DELAY)


def send_angle_to_hc05(angle: float):
    angle_str = str(angle)
    angle_str_len = str(len(angle_str))
    sock.send(angle_str_len.encode())
    sock.send(angle_str.encode())

def get_angle(x_coord, y_coord, z_coord):
    user_segment = math.ceil(x_coord/FRAME_SEGMENT)
    desired_angle = ANGLE_PER_SEGMENT*user_segment
    return desired_angle

def get_face_coordinates(face_location, depth_frame):
    top, right, bottom, left = face_location
    print(f"Segmented Person Finder: I see {user_name}!")
    print(f"Segmented Person Finder: {user_name}'s coords in the image is left={left} top={top} right={right} bottom={bottom}")
    x_coord, y_coord = ((left + right) / 2, (top + bottom) / 2)
    z_coord = depth_frame.get_distance(int(x_coord), int(y_coord))
    print(f'{user_name}\'s face center is at {(x_coord, y_coord, z_coord)}')
    return x_coord, y_coord, z_coord

def find_user_location_in_frame(face_encodings, user_face_encoding, face_locations):
    # Loop over each face found in the frame to see if it's someone we know.
    for i, face_encoding in enumerate(face_encodings):
        # See if the face is a match for the known face(s)
        match = face_recognition.compare_faces([user_face_encoding], face_encoding)
        is_user_in_current_frame = match[0]
        if is_user_in_current_frame:
            return face_locations[i]
    return None
