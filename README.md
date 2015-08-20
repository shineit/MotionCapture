# MotionCapture

Use your Raspberry Pi Camera to take photos of motion in an area.

The Python script runs on the Raspberry Pi to continuously look for motion in the camera, and take and upload a photo when there's motion. It uploads one large image, and one thumbnail image.

The backend PHP script is used for creating a REST endpoint to get a JSON array with the list of images:
```
GET /images/{max}
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

Included are two client programs for viewing the saved images. One is a web Javascript client and the other is an iOS app.

To configure Parse push notifications in the Python script, create a file named *config.ini* in the repo root with:
```
[Parse]
application_id=<application id>
rest_api_key=<rest api key>
```
Where you replace <application id> with your Parse application ID and <rest api key> with your Parse application's REST API key.

## Future Features

- Modified Python script that only saves images to the Pi instead of uploading, and the Pi would function as the whole backend server.
- Option in Python script to limit the number of images saved in a time frame in case there's a lot of motion in one period of time.
- Microsoft Band notification for detected motion

## Credits

- Paul Tynes from The Noun Project (https://thenounproject.com/term/webcam/5490/)
