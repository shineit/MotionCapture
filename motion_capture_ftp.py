#!/usr/bin/python

import time
import picamera
import picamera.array
import RPi.GPIO as GPIO
import ftplib, sys, getopt
import Image as img
import ConfigParser
import json, httplib
import re


def main(argv):
    # Configure FTP
    ftpHostname = "floccul.us"
    ftpUsername = "birdcam@floccul.us"
    
    # Use command line argument to try to login to FTP
    if len(argv) < 1:
        print '  Usage: ./motion_capture_ftp.py <FTP password>'
        sys.exit(2)
    try:
        ftpPassword = argv[0]
        ftp = ftplib.FTP(ftpHostname, ftpUsername, ftpPassword)
        print "  Successfully authenticated to FTP server"
    except ftplib.error_perm:
        print "  530 Login authentication failed"
        sys.exit()

    # Read config.ini
    Config = ConfigParser.ConfigParser()
    Config.read("config.ini")

    # Setup Parse (push notification service)
    try:    
        application_id = Config.get("Parse", "application_id")
        rest_api_key = Config.get("Parse", "rest_api_key")
        pushNotificationsEnabled = True
    except:
        pushNotificationsEnabled = False

    # Use BCM GPIO references instead of physical pin numbers
    GPIO.setmode(GPIO.BCM)

    # Define GPIO to use on Pi
    GPIO_LED = 22 # activity indicator
    GPIO_BUTTON = 27 # exit program button

    # Setup pins as input or output
    GPIO.setup(GPIO_LED, GPIO.OUT)
    GPIO.setup(GPIO_BUTTON, GPIO.IN, pull_up_down=GPIO.PUD_UP)

    # Initialize LED to off
    GPIO.output(GPIO_LED, GPIO.LOW)
        
    # Motion detection settings:
    # Threshold (how much a pixel has to change by to be marked as "changed")
    # Sensitivity (how many changed pixels before capturing an image)
    threshold = 25
    sensitivity = 25

    # File settings
    testWidth = 100
    testHeight = 75
    thumbWidth = 240
    thumbHeight = 180
    saveWidth = 1024
    saveHeight = 768

    # Limit how often push notifications are sent
    lastPushNotificationTime = -1
    pushNotificationDelay = 300000 # Milliseconds

    # Check for images to delete once a day
    lastImageDeleteTime = -1
    imageDeleteDelay = 86400000 # Milliseconds

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
        # Read button state, quit program if pressed
        button_state = GPIO.input(GPIO_BUTTON)
        if button_state == 0:
            GPIO.cleanup()
            ftp.quit()
            sys.exit()

        # Keep FTP session alive, and reconnect if needed
        try:
            ftp.voidcmd("NOOP")
        except:
            ftp = ftplib.FTP(ftpHostname, ftpUsername, ftpPassword)

        # Get the current epoch time in ms
        msTime = long(time.time() * 1000)

        # Delete old images
        if msTime - lastImageDeleteTime > imageDeleteDelay:
            print "  Deleting old images..."
            deleteImagesBefore(msTime - imageDeleteDelay, ftp)
            lastImageDeleteTime = msTime
            print "  Done deleting old images."

        # Get comparison image
        image2 = captureTestImage(camera, testWidth, testHeight)

        # If there was motion (images are different), save a larger image
        if isImageChanged(image1, image2, threshold, sensitivity) and isImageChanged(noMotionImage, image2, threshold, sensitivity):
            print "  Motion detected. Saving photo..."
            # Turn on LED
            GPIO.output(GPIO_LED, GPIO.HIGH)
            # Save large image
            localFileName = "Web/img/capture.jpg"
            saveImage(camera, saveWidth, saveHeight, localFileName)
            # Resize large image into thumbnail
            localThumbFileName = "Web/img/capture-thumb.jpg"
            largeImage = img.open(localFileName)
            largeImage.thumbnail((thumbWidth, thumbHeight), img.ANTIALIAS)
            largeImage.save(localThumbFileName)
            # Determine remote file names
            remoteFileName = 'img/image-' + str(msTime) + '.jpg'
            remoteThumbFileName = 'img/thumb-' + str(msTime) + '.jpg'
            print "  Uploading photo..."
            uploadFileUsingFTP(ftp, localFileName, remoteFileName)
            uploadFileUsingFTP(ftp, localThumbFileName, remoteThumbFileName)
            # Send a push notification
            if pushNotificationsEnabled and msTime - lastPushNotificationTime > pushNotificationDelay:
                print "  Sending push notification..."
                sendPushNotification(application_id, rest_api_key)
                lastPushNotificationTime = msTime
            # Turn off LED
            GPIO.output(GPIO_LED, GPIO.LOW)
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
    ftp.storbinary('STOR ' + remoteFileName + '.tmp', file)
    ftp.rename(remoteFileName + '.tmp', remoteFileName)
    file.close()

# Delete all the images before a certain epoch time (ms)
def deleteImagesBefore(epochTimeMs, ftp):
    files = ftp.nlst('img')
    regex = re.compile(r'^\w{5}-\d{13}.jpg$')
    images = filter(lambda i: regex.search(i), files)
    imagesToDelete = filter(lambda i: long(i[6:-4]) < epochTimeMs, images)
    map(lambda i: ftp.delete('img/' + i), imagesToDelete)

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

# Send a push notification to the Parse service (for iOS app)
def sendPushNotification(application_id, rest_api_key):
    connection = httplib.HTTPSConnection('api.parse.com', 443)
    connection.connect()
    connection.request('POST', '/1/push', json.dumps({
            "where": {},
            "data": {
                "alert": "Motion detected!",
                "badge": "Increment",
                "content-available": "1"
            }
        }), {
            "X-Parse-Application-Id": application_id,
            "X-Parse-REST-API-Key": rest_api_key,
            "Content-Type": "application/json"
        })
    return json.loads(connection.getresponse().read())

if __name__ == "__main__":
  main(sys.argv[1:])

