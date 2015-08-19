#!/usr/bin/python

 # Import required Python libraries
import RPi.GPIO as GPIO
import picamera
import ftplib, time, sys, getopt

def main(argv):
  global session
   
  print "Motion Capture (CTRL-C to exit)"
  
  # Use command line argument to try to login to FTP
  if len(argv) < 1:
    print 'Usage: ./motion_capture_with_pir.py <FTP password>'
    sys.exit(2)
  try:
    session = ftplib.FTP('floccul.us', 'birdcam@floccul.us', argv[0])
    print "Successfully authenticated to FTP server"
  except ftplib.error_perm:
    print "530 Login authentication failed"
    sys.exit()
    
  # Use BCM GPIO references
  # instead of physical pin numbers
  GPIO.setmode(GPIO.BCM)
   
  # Define GPIO to use on Pi
  GPIO_PIR = 17
  GPIO_LED = 22
  GPIO_BUTTON = 27

  # Create an instance of PiCamera class and configure
  camera = picamera.PiCamera()
  camera.resolution = (1024, 768)
  camera.vflip = True

  # Setup pins as input or output
  GPIO.setup(GPIO_PIR, GPIO.IN)
  GPIO.setup(GPIO_LED, GPIO.OUT)
  GPIO.setup(GPIO_BUTTON, GPIO.IN, pull_up_down=GPIO.PUD_UP)
   
  Current_State  = 0
  Previous_State = 0
   
  try:
   
    print "Waiting for PIR to settle ..."
   
    # Loop until PIR output is 0
    while GPIO.input(GPIO_PIR)==1:
      Current_State  = 0
   
    print "  Ready"

    button_down_count = 0
   
    # Loop until users quits with CTRL-C, or presses button
    while True :

      # Read button state
      button_state = GPIO.input(GPIO_BUTTON)
      if button_state == 1:
        button_down_count = 0
      else:
        button_down_count += 1

      # Quit if the button is held down for longer than 2 sec
      if button_down_count > 20:
        terminate()
   
      # Read PIR state
      Current_State = GPIO.input(GPIO_PIR)
   
      if Current_State==1 and Previous_State==0:
        # PIR is triggered, turn on indicator LED
        print "  Motion detected!"
        GPIO.output(GPIO_LED, GPIO.HIGH)
        # Take a photo with the camera
        camera.capture("image.jpg")
        print "  Photo captured."
        # Upload the photo to the server
        file = open('image.jpg', 'rb')
        ts = long(time.time() * 1000)
        filename = 'image-' + str(ts) + '.jpg'
        session.storbinary('STOR ' + filename, file)
        file.close()
        print "  Photo uploaded as " + filename
        # Record previous state
        Previous_State=1
      elif Current_State==0 and Previous_State==1:
        # PIR has returned to ready state
        print "  Ready"
        # Turn off indicator LED
        GPIO.output(GPIO_LED, GPIO.LOW)
        # Record previous state
        Previous_State=0
   
      # Wait for 100 milliseconds
      time.sleep(0.1)
   
  except KeyboardInterrupt:
    terminate()


def terminate():
  global session
  
  print "  Quit"
  # Reset GPIO settings
  GPIO.cleanup()
  # Close FTP session
  session.quit()
  return


if __name__ == "__main__":
  main(sys.argv[1:])
