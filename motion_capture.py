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
GPIO_LED = 22
GPIO_BUTTON = 13

# Create an instance of PiCamera class and configure
camera = picamera.PiCamera()
camera.resolution = (1024, 768)
 
print "Motion Capture (CTRL-C to exit)"

# Setup pins as input or output
GPIO.setup(GPIO_PIR, GPIO.IN)
GPIO.setup(GPIO_LED, GPIO.OUT)
GPIO.setup(GPIO_BUTTON, GPIO.IN)
 
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


def terminate():
  print "  Quit"
  # Reset GPIO settings
  GPIO.cleanup()
  # Close FTP session
  session.quit()
  return
 
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
    if button_down_count > 200:
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
 
    # Wait for 10 milliseconds
    time.sleep(0.01)
 
except KeyboardInterrupt:
  terminate()
