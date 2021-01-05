import cv2
import numpy as np
import glob
import argparse
import os
from pdb import set_trace as bp

# parse arguments
parser = argparse.ArgumentParser()
parser.add_argument("--in_video", type=str, required=True, help="input video (ex. video.avi)")
parser.add_argument("--out_image_dir", type=str, required=True, \
                    help="path to output image directory (ex. ~/images)")
parser.add_argument("--ext", type=str, required=True, help="image file extension (ex. png)")
args = parser.parse_args()

# set input parameters
image_dir = args.out_image_dir
ext = args.ext
video = args.in_video

# make output image directory
os.system('mkdir ' + image_dir + ' 2> /dev/null')

# open video
cap = cv2.VideoCapture(video)

count = 0
while(cap.isOpened()):
    ret, frame = cap.read()

    if ret:
        # save frame
        img_file = image_dir + '/' + str(count).zfill(8) + '.' + ext
        cv2.imwrite(img_file, frame)

        # show frame
        cv2.imshow('frame', frame)
        if cv2.waitKey(1) & 0xFF == ord('q'):
            break
    else:
        break

    count += 1

cap.release()
cv2.destroyAllWindows()

