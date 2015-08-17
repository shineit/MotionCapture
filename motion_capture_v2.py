#!/usr/bin/python

import time
import picamera
import picamera.array
import ftplib, sys, getopt


def main(argv):
    # Configure FTP
    ftpHostname = "floccul.us"
    ftpUsername = "birdcam@floccul.us"
    
    # Use command line argument to try to login to FTP
    if len(argv) < 1:
        print '  Usage: ./motion_capture_v2.py <FTP password>'
        sys.exit(2)
    try:
        ftp = ftplib.FTP(ftpHostname, ftpUsername, argv[0])
        print "  Successfully authenticated to FTP server"
    except ftplib.error_perm:
        print "  530 Login authentication failed"
        sys.exit()
    
    # Motion detection settings:
    # Threshold (how much a pixel has to change by to be marked as "changed")
    # Sensitivity (how many changed pixels before capturing an image)
    threshold = 25
    sensitivity = 25

    # File settings
    testWidth = 100
    testHeight = 75
    saveWidth = 1024
    saveHeight = 768

    # Start the camera
    print "  Starting camera..."
    camera = picamera.PiCamera()
    camera.vflip = True
    time.sleep(2)

    # Get first image
    image1 = captureTestImage(camera, testWidth, testHeight)

    # Always store the most recent image with no motion
    noMotionImage = image1
    noMotionCount = 0

    print "  Ready."

    while True:
        # Get comparison image
        image2 = captureTestImage(camera, testWidth, testHeight)

        # If there was motion (images are different), save a larger image
        if isImageChanged(image1, image2, threshold, sensitivity) and isImageChanged(noMotionImage, image2, threshold, sensitivity):
            print "  Motion detected. Saving photo..."
            localFileName = "capture.jpg"
            saveImage(camera, saveWidth, saveHeight, localFileName)
            ts = long(time.time() * 1000)
            remoteFileName = 'image-' + str(ts) + '.jpg'
            print "  Uploading photo..."
            uploadFileUsingFTP(ftp, localFileName, remoteFileName)
            print "  Ready."
        else:
            noMotionCount += 1
            if noMotionCount >= 10:
                noMotionImage = image2
                noMotionCount = 0

        # Swap comparison images
        image1 = image2

        # Slight delay to not take too many pictures
        time.sleep(1)


# Capture a small test image (for motion detection) and return as pixel array
def captureTestImage(camera, width, height):
    camera.resolution = (width, height)
    with picamera.array.PiRGBArray(camera) as stream:
        camera.capture(stream, format='rgb')
        return stream.array

# Save an image from the camera to a file
def saveImage(camera, width, height, name):
    camera.resolution = (width, height)
    camera.capture(name)

# Upload a file to the FTP server
def uploadFileUsingFTP(ftp, localFileName, remoteFileName):
    file = open(localFileName, 'rb')
    ftp.storbinary('STOR ' + remoteFileName, file)
    file.close()

# Return whether or not the two images are different
def isImageChanged(imgArray1, imgArray2, threshold, sensitivity):
    # Check that the two arrays are the same size
    if len(imgArray1) != len(imgArray2) and len(imgArray1[0]) != len(imgArray2[0]):
        return False
    
    # Count the number of changed pixels
    changedPixels = 0
    for x in xrange(0, len(imgArray1)):
        for y in xrange(0, len(imgArray1[0])):
            # Just check green channel as it's the highest quality channel
            pixdiff = abs(int(imgArray1[x,y][1]) - int(imgArray2[x,y][1]))
            if pixdiff > threshold:
                changedPixels += 1
                if changedPixels > sensitivity:
                    return True
    return False


if __name__ == "__main__":
  main(sys.argv[1:])
