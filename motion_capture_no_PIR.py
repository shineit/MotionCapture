#!/usr/bin/python

import StringIO
import subprocess
import os
import time
from datetime import datetime
from PIL import Image

# Motion detection settings:
# Threshold (how much a pixel has to change by to be marked as "changed")
# Sensitivity (how many changed pixels before capturing an image)
# ForceCapture (whether to force an image to be captured every forceCaptureTime seconds)
threshold = 10
sensitivity = 20

# File settings
saveWidth = 1280
saveHeight = 960

# Capture a small test image (for motion detection)
def captureTestImage():
    command = "raspistill -w %s -h %s -t 750 -e bmp -o -" % (100, 75)
    imageData = StringIO.StringIO()
    imageData.write(subprocess.check_output(command, shell=True))
    imageData.seek(0)
    im = Image.open(imageData)
    buffer = im.load()
    imageData.close()
    return im, buffer

# Save a full size image to disk
def saveImage(width, height):
    time = datetime.now()
    filename = "capture-%04d%02d%02d-%02d%02d%02d.jpg" % (time.year, time.month, time.day, time.hour, time.minute, time.second)
    subprocess.call("raspistill -w 1296 -h 972 -t 0 -e jpg -q 15 -o %s" % filename, shell=True)
    print "Captured %s" % filename
        
# Get first image
image1, buffer1 = captureTestImage()

# Reset last capture time
lastCapture = time.time()

while (True):
    # Get comparison image
    image2, buffer2 = captureTestImage()

    # Count changed pixels
    changedPixels = 0
    for x in xrange(0, 100):
        for y in xrange(0, 75):
            # Just check green channel as it's the highest quality channel
            pixdiff = abs(buffer1[x,y][1] - buffer2[x,y][1])
            if pixdiff > threshold:
                changedPixels += 1
       
    # Save an image if pixels changed
    if changedPixels > sensitivity:
        lastCapture = time.time()
        saveImage(saveWidth, saveHeight)
    
    # Swap comparison buffers
    image1 = image2
    buffer1 = buffer2
