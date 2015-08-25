<?php
header('Access-Control-Allow-Origin: *');

$limit = $_GET['limit'];
if (!isset($limit)) $limit = -1;

echo getJsonForImages($limit);

// [ { "name": "image-1234567890.jpg", "thumb": "thumb-1234567890.jpg", "epochTime": 1234567890} ]
function getJsonForImages($limit = -1) {
    $dir = getcwd() . "/capture";
    $files = scandir($dir);

    // Filter list of files down to only images matching the correct name format
    $filteredImages = array();
    $filteredThumbs = array();
    $patternImage = '/^image-\d{13}.jpg$/';
    $patternThumb = '/^thumb-\d{13}.jpg$/';
    foreach ($files as $fileName) {
        if (preg_match($patternImage, $fileName)) {
            // Key/value pairs of file name and modified time
            $filteredImages[$fileName] = filemtime($dir . '/' . $fileName);
        } else if (preg_match($patternThumb, $fileName)) {
            // Key/value pairs of file name and modified time
            $filteredThumbs[$fileName] = filemtime($dir . '/' . $fileName);
        }
    }

    // Sort the filtered list of images by modified time, descending
    arsort($filteredImages);
    $sortedImages = array_keys($filteredImages);
    arsort($filteredThumbs);
    $sortedThumbs = array_keys($filteredThumbs);

    // Extract the epoch time from the file name, and only keep maxnum images
    $images = array();
    $imageCount = 0;
    foreach ($sortedImages as $imageName) {
        if ($limit != -1 && $imageCount >= $limit) {
            break;
        }
        $epochTime = substr($imageName, 6, 13);
        $thumbName = "thumb-".$epochTime.".jpg";
        if ($filteredThumbs[$thumbName]) {
            $image = array("name" => "capture/".$imageName, "thumb" => "capture/".$thumbName, "epochTime" => $epochTime);
            array_push($images, $image);
            $imageCount++;
        }
    }

    return json_encode($images);
}

?>