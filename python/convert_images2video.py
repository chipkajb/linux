import cv2
import numpy as np
import glob
import pdb
import argparse
import pdb

parser = argparse.ArgumentParser()
parser.add_argument("--image_dir", type=str, required=True, help="path to image directory (ex. ~/images)")
parser.add_argument("--ext", type=str, required=True, help="image file extension (ex. jpg)")
parser.add_argument("--out", type=str, required=True, help="output video (ex. out.avi)")
parser.add_argument("--fps", type=int, required=True, help="output fps (ex. 20)")
args = parser.parse_args()

image_dir = args.image_dir
ext = args.ext
out = args.out
fps = args.fps

img_array = []
images = glob.glob(image_dir + '/*.' + ext)
images.sort()
count = 0
for filename in images:
    img = cv2.imread(filename)
    height, width, layers = img.shape
    size = (width,height)
    if count == 0:
        #  outVideo = cv2.VideoWriter(out, cv2.VideoWriter_fourcc(*"MJPG"), fps, size) # Python 3.x
        outVideo = cv2.VideoWriter(out, cv2.cv.CV_FOURCC(*"MJPG"), fps, size) # Python 2.x
    outVideo.write(img)
    print("Writing frame " + str(count))
    count = count + 1

outVideo.release()
print("\nSaved video to: " + out)
