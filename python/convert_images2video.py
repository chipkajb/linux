import cv2
import numpy as np
import glob
import pdb
import argparse

parser = argparse.ArgumentParser()
parser.add_argument("image_dir", type=str, help="path to image directory (ex. ~/images)")
parser.add_argument("ext", type=str, help="image file extension (ex. jpg)")
parser.add_argument("out", type=str, help="output video, must be avi (ex. out.avi)")
parser.add_argument("fps", type=int, help="output fps (ex. 20)")
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
    img_array.append(img)
    print("Processing frame " + str(count) + "/" + str(len(images)-1))
    count = count + 1

print("")
print("Saving video to: " + out)
print("")
outVideo = cv2.VideoWriter(out,cv2.VideoWriter_fourcc(*'DIVX'), fps, size)
count = 0

for i in range(len(img_array)):
    outVideo.write(img_array[i])
    print("Processing frame " + str(count) + "/" + str(len(img_array)-1))
    outVideo.release()
