# MotionCapture
Use your Raspberry Pi Camera as a cheap security system to detect motion and take photos.

## Pi Python Script
There are three versions of the camera script for the Pi. All three versions use GPIO for a LED that indicates activity and a button that quits the program. The pins for GPIO can be configured in the code.

1. *motion_capture.py* - 
This version uses the camera for detecting motion. It saves all images to the Pi's disk.
In the future, it will occasionally check the image folder for old images to purge.

2. *motion_capture_ftp.py* - 
This version uses the camera for detecting motion. It uploads the images to a remote FTP server. FTP server config is done in the code.

3. *motion_capture_with_pir.py* - 
This version uses the PIR motion sensor for detecting motion. It uploads the images to a remote FTP server. FTP server config is done in the code.
This was the first version I wrote, so it's currently a little out of date and doesn't have some of the relevant features that are found in motion_capture.py.

## REST API
There is a REST endpoint for retreiving a JSON array with the list of images. The code is found in `Web/getCaptures.php`. There is an optional `limit` parameter that can be used to limit the number of results. Here is an example of the JSON:

```
GET /getCaptures.php?limit=2
```
```json
[
    {
        "name": "image-1439995525769.jpg",
        "thumb": "thumb-1439995525769.jpg",
        "epochTime": 1439995525769
    },
    {
        "name": "image-1439995517971.jpg",
        "thumb": "thumb-1439995517971.jpg",
        "epochTime": 1439995517971
    }
]
```

Note: I intentially don't have the endpoint URL be something like /getCaptures?limit=2, since I don't want it to depend on the server having URL rewriting enabled.

## iOS Client
<img src="https://raw.githubusercontent.com/JessicaYeh/MotionCapture/master/Screenshots/screenshot-iOS.png" alt="Screenshot of iOS Client" height="250"/>

There is an iOS app for viewing captured photos. It supports push notifications that are sent from the Python script whenever motion is detected. It also sends the notifications to a Microsoft Band if you have one connected.

I used Parse to handle the push notification backend for me. To configure Parse push notifications in the Python script, create a file named *config.ini* in the repo root with:
```
[Parse]
application_id=<application id>
rest_api_key=<rest api key>
```
Where you replace <application id> with your Parse application ID and <rest api key> with your Parse application's REST API key.

## Web Client
There is a web client to view the captured photos on the web.

## Other Info
If you would like to use anything from this project, and something is confusing, feel free to request more documentation and I will write it in this readme.

## Credits
- Paul Tynes from The Noun Project (https://thenounproject.com/term/webcam/5490/)
