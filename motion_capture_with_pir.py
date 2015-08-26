#!/usr/bin/python

 # Import required Python libraries
import RPi.GPIO as GPIO
import picamera
import ftplib, time, sys, getopt
import json, httplib
import re


def main(argv):
    # Configure FTP
    ftpHostname = "floccul.us"
    ftpUsername = "birdcam@floccul.us"
    lastFtpKeepAliveTime = -1
    ftpKeepAliveTimeout = 300000 # milliseconds
    
    # Use command line argument to try to login to FTP
    if len(argv) < 1:
        print '  Usage: ./motion_capture_with_pir.py <FTP password>'
        sys.exit(2)
    try:
        ftpPassword = argv[0]
        ftp = ftplib.FTP(ftpHostname, ftpUsername, ftpPassword)
        print "  Successfully authenticated to FTP server"
    except ftplib.error_perm:
        print "  530 Login authentication failed"
        sys.exit()
    
    # Use BCM GPIO references instead of physical pin numbers
    GPIO.setmode(GPIO.BCM)
   
    # Define GPIO to use on Pi
    GPIO_PIR = 17 # PIR motion sensor
    GPIO_LED = 22 # activity indicator
    GPIO_BUTTON = 27 # exit program button

    # Setup pins as input or output
    GPIO.setup(GPIO_PIR, GPIO.IN)
    GPIO.setup(GPIO_LED, GPIO.OUT)
    GPIO.setup(GPIO_BUTTON, GPIO.IN, pull_up_down=GPIO.PUD_UP)

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

    # Check for images to delete once a week
    lastImageDeleteTime = -1
    imageDeleteDelay = 86400000 * 7 # Milliseconds

    # Start the camera
    print "  Starting camera..."
    camera = picamera.PiCamera()
    camera.vflip = True
    time.sleep(2)

    pirCurrentState  = 0
    pirPreviousState = 0
   
    try:
   
        print "Waiting for PIR to settle ..."

        # Loop until PIR output is 0
        while GPIO.input(GPIO_PIR)==1:
            pirCurrentState = 0

        print "  Ready"

        # Loop until users quits with CTRL-C, or presses button
        while True:
            # Read button state, quit program if pressed
            buttonState = GPIO.input(GPIO_BUTTON)
            if buttonState == 0:
                terminate()

            # Keep FTP session alive, and reconnect if needed
            if msTime - lastFtpKeepAliveTime > ftpKeepAliveTimeout:
                print "  Keeping FTP session alive..."
                try:
                    ftp.voidcmd("NOOP")
                except:
                    ftp = ftplib.FTP(ftpHostname, ftpUsername, ftpPassword)
                lastFtpKeepAliveTime = msTime

            # Delete old images
            if msTime - lastImageDeleteTime > imageDeleteDelay:
                print "  Deleting old images..."
                deleteImagesBefore(msTime - imageDeleteDelay, ftp)
                lastImageDeleteTime = msTime
                print "  Done deleting old images."

            # Read PIR state
            pirCurrentState = GPIO.input(GPIO_PIR)

            if pirCurrentState == 1 and pirPreviousState == 0:
                # PIR is triggered
                print "  Motion detected. Saving photos..."

                # Get the current epoch time in ms
                msTime = long(time.time() * 1000)

                # Turn on LED
                GPIO.output(GPIO_LED, GPIO.HIGH)
                # Save large image
                localFileName = "Web/capture/capture.jpg"
                saveImage(camera, saveWidth, saveHeight, localFileName)
                # Resize large image into thumbnail
                localThumbFileName = "Web/capture/capture-thumb.jpg"
                largeImage = img.open(localFileName)
                largeImage.thumbnail((thumbWidth, thumbHeight), img.ANTIALIAS)
                largeImage.save(localThumbFileName)
                # Determine remote file names
                remoteFileName = 'capture/image-' + str(msTime) + '.jpg'
                remoteThumbFileName = 'capture/thumb-' + str(msTime) + '.jpg'
                # Upload photos
                print "  Uploading photos..."
                uploadFileUsingFTP(ftp, localFileName, remoteFileName)
                uploadFileUsingFTP(ftp, localThumbFileName, remoteThumbFileName)
                # Send a push notification
                if pushNotificationsEnabled and msTime - lastPushNotificationTime > pushNotificationDelay:
                    print "  Sending push notification..."
                    sendPushNotification(application_id, rest_api_key)
                    lastPushNotificationTime = msTime

                # Record previous state
                pirPreviousState = 1
            elif pirCurrentState == 0 and pirPreviousState == 1:
                # PIR has returned to ready state
                print "  Ready"
                # Turn off LED
                GPIO.output(GPIO_LED, GPIO.LOW)
                # Record previous state
                pirPreviousState = 0

            # Wait for 100 milliseconds
            time.sleep(0.1)

    except KeyboardInterrupt:
        terminate()

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
    files = ftp.nlst('capture')
    regex = re.compile(r'^\w{5}-\d{13}.jpg$')
    images = filter(lambda i: regex.search(i), files)
    imagesToDelete = filter(lambda i: long(i[6:-4]) < epochTimeMs, images)
    map(lambda i: ftp.delete('capture/' + i), imagesToDelete)

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

def terminate(ftp):
    global ftp

    print "  Quit"
    # Reset GPIO settings
    GPIO.cleanup()
    # Quit FTP session
    ftp.quit()
    sys.exit()
    return


if __name__ == "__main__":
  main(sys.argv[1:])
