 # Import required Python libraries
import RPi.GPIO as GPIO
import time
import picamera
import ftplib
 
# Use BCM GPIO references
# instead of physical pin numbers
GPIO.setmode(GPIO.BCM)
 
# Define GPIO to use on Pi
GPIO_PIR = 17

# Create an instance of PiCamera class and configure
camera = picamera.PiCamera()
camera.resolution = (1024, 768)
 
print "PIR Module Test (CTRL-C to exit)"

# Set pin as input
GPIO.setup(GPIO_PIR,GPIO.IN)      # Echo
 
Current_State  = 0
Previous_State = 0

# Open an FTP session
logged_in = False
while not logged_in :
  password = raw_input("  Enter the FTP password: ")
  try:
    session = ftplib.FTP('floccul.us', 'birdcam@floccul.us', password)
    logged_in = True
    break
  except ftplib.error_perm:
    print "  530 Login authentication failed"

 
try:
 
  print "Waiting for PIR to settle ..."
 
  # Loop until PIR output is 0
  while GPIO.input(GPIO_PIR)==1:
    Current_State  = 0
 
  print "  Ready"
 
  # Loop until users quits with CTRL-C
  while True :
 
    # Read PIR state
    Current_State = GPIO.input(GPIO_PIR)
 
    if Current_State==1 and Previous_State==0:
      # PIR is triggered
      print "  Motion detected!"
      # Take a photo with the camera
      camera.capture("image.jpg")
      print "  Photo captured."
      # Upload the photo to the server
      file = open('image.jpg', 'rb')
      ts = int(time.time())
      session.storbinary('STOR image-' + str(ts) + '.jpg', file)
      file.close()
      print "  Photo uploaded."
      # Record previous state
      Previous_State=1
    elif Current_State==0 and Previous_State==1:
      # PIR has returned to ready state
      print "  Ready"
      Previous_State=0
 
    # Wait for 10 milliseconds
    time.sleep(0.01)
 
except KeyboardInterrupt:
  print "  Quit"
  # Reset GPIO settings
  GPIO.cleanup()
  # Close FTP session
  session.quit()
