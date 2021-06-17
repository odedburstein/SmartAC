import bluetooth
import face_recognition
import os
import math
import numpy as np
import tinytuya
import pyrealsense2.pyrealsense2 as rs

from bluetooth import BluetoothSocket as socket
# from google.cloud import firestore
from queue import Empty
from time import sleep, time


# HC05 config
hc_05_bt_addr = "00:15:83:35:7F:5D"
# BT config
sock = socket(bluetooth.RFCOMM)
port = 1
sock.connect((hc_05_bt_addr,port))

# Smart life config
device_id = 'bfc0abb82b329ea855fskr'
local_key = 'e6bbfb0a598346ec'
device_ip = '192.168.0.117'

# user photo config
user_photo_path = "user_small.jpg"
user_name = user_photo_path.split("_")[0]

# distance path
user_distance_download_path = "user_distance.txt"


#  Firebase config
cred_path = 'smart-ac-e68d3-firebase-adminsdk-5kqb5-b93d49fd08.json'
os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = cred_path
bucket_name = "smart-ac-e68d3.appspot.com"

# person finder config
FRAME_WIDTH = 640
FRAME_HEIGHT = 480
SEG_PARAMETER = 10
FRAME_SEGMENT = FRAME_WIDTH/SEG_PARAMETER
ANGLE_RANGE = 120
ANGLE_PER_SEGMENT = ANGLE_RANGE/SEG_PARAMETER
MAX_DISTANCE_ALLOWED = 3.5
SMART_AC_POSITION = 150
PERSON_FINDER_DELAY = 1.5
SMART_AC_TURN_OFF_DELAY = 5
SMART_AC_TURN_ON_DELAY = 1
MAX_ABSENCE_ALLOWED = 60 * 5

def person_finder(queue):

    user_present = True
    is_user_close=True
    ABSENCE_TIMER = 0
    FAR_TIMER = 0

    print(f"Segmented Person Finder: InSLEEitializing intel realsense camera")
    pipeline = rs.pipeline()
    config = rs.config()
    config.enable_stream(rs.stream.depth, 640, 480, rs.format.z16, 30)
    config.enable_stream(rs.stream.color, 640, 480, rs.format.bgr8, 30)
    pipeline.start(config)
    print(f"Segmented Person Finder: Camera ready")

    print(f"Segmented Person Finder: Initializing smart plug client")
    smart_plug = tinytuya.OutletDevice(device_id, device_ip, local_key)
    smart_plug.set_version(3.3)
    print(f"Segmented Person Finder: Smart plug ready")

    # Load a sample picture and learn how to recognize it.
    print(f"Segmented Person Finder: Loading user image")
    user_face_encoding = get_user_face_encoding()


    # Initialize some variables
    face_locations = []
    face_encodings = []
    face_names = [user_name]
    should_work = True
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
            elif msg == "REFRESH_FACE":
                print(f"Segmented Person Finder: Changing user face encoding")
                user_face_encoding = get_user_face_encoding()
            elif msg == "REFRESH_POSITION":
                print(f"Segmented Person Finder: Updating Smart AC position")
                set_smart_ac_position()
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
                is_smart_ac_active = get_is_smart_ac_active(smart_plug)
                if user_location_in_frame:
                    if not is_smart_ac_active:
                        smart_plug.turn_on(switch=1)
                        sleep(SMART_AC_TURN_ON_DELAY)
                    user_present = True
                    ABSENCE_TIMER = 0
                    x_coord, y_coord, z_coord = get_face_coordinates(user_location_in_frame, depth_frame)
                    if z_coord >= MAX_DISTANCE_ALLOWED:
                        if is_user_close:
                            print("Segmented Person Finder: The user is temporarily not close")
                            is_user_close = False
                            FAR_TIMER = time()
                        else:
                            total_far_time = time() - FAR_TIMER
                            if total_far_time > MAX_ABSENCE_ALLOWED:
                                smart_plug.turn_off(switch=1)
                                print("Segmented Person Finder: The user  is far for more than 6 minutes! Shutting down Smart AC")
                                sleep(SMART_AC_TURN_OFF_DELAY)

                    else: # z_coord < 3.5 m
                        is_user_close = True
                        FAR_TIMER = 0
                        angle = get_angle(x_coord=x_coord, y_coord=y_coord, z_coord=z_coord)
                        send_angle_to_hc05(angle)

                else:
                    if user_present:
                        print("Segmented Person Finder: The user is temporarily not present")
                        user_present = False
                        ABSENCE_TIMER = time()
                    else:
                        print(f"absence timer is {ABSENCE_TIMER}")
                        total_absence_time = time()-ABSENCE_TIMER
                        print(f"total_absence_time is {total_absence_time}")
                        if total_absence_time > MAX_ABSENCE_ALLOWED:
                            smart_plug.turn_off(switch=1)
                            print("Segmented Person Finder: The user is not present for more than 5 minutes! Shutting down Smart AC")
                            sleep(SMART_AC_TURN_OFF_DELAY)
            sleep(1.5)


def send_angle_to_hc05(angle: float):
    angle_str = str(angle)
    angle_str_len = str(len(angle_str))
    sock.send(angle_str_len.encode())
    sock.send(angle_str.encode())

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

def translate(value, leftMin=0, leftMax=3, rightMin=5, rightMax=30):
    # Figure out how 'wide' each range is
    leftSpan = leftMax - leftMin
    rightSpan = rightMax - rightMin

    # Convert the left range into a 0-1 range (float)
    valueScaled = float(value - leftMin) / float(leftSpan)

    # Convert the 0-1 range into a value in the right range.
    return math.ceil(rightMin + (valueScaled * rightSpan))


def get_angle(x_coord, y_coord, z_coord):
    z__cord = min(z_coord,1)
    global FRAME_WIDTH
    global SMART_AC_POSITION
    SEG_PARAMETER = translate(z__cord)
    FRAME_SEGMENT = FRAME_WIDTH / SEG_PARAMETER

    user_segment = math.ceil(x_coord / FRAME_SEGMENT)

    if SMART_AC_POSITION >= 0:
        ANGLE_RANGE = translate(SMART_AC_POSITION,0,150,180,90)
    else:
        ANGLE_RANGE = translate(SMART_AC_POSITION, -150, 0, 90, 180)

    ANGLE_PER_SEGMENT = ANGLE_RANGE / SEG_PARAMETER

    desired_angle = math.ceil(ANGLE_RANGE-(ANGLE_PER_SEGMENT * user_segment))
    if desired_angle < 2*ANGLE_PER_SEGMENT:
        desired_angle = math.ceil(2*ANGLE_PER_SEGMENT)
    if desired_angle > ANGLE_RANGE-2*ANGLE_PER_SEGMENT:
        desired_angle = math.ceil(ANGLE_RANGE-2*ANGLE_PER_SEGMENT)
    return desired_angle

def get_is_smart_ac_active(smart_plug):
    is_active = smart_plug.status().get('dps').get('1')
    return is_active

def get_user_face_encoding():
    user_image = face_recognition.load_image_file(user_photo_path)
    user_face_encoding = face_recognition.face_encodings(user_image)[0]
    return user_face_encoding

def set_smart_ac_position():
    global SMART_AC_POSITION
    with open(user_distance_download_path, mode='r') as distance_file:
        distance = distance_file.read()
    SMART_AC_POSITION = int(distance)
