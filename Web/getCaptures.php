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
    $filteredSortedFiles = array();
    $pattern = '/^image-\d{13}.jpg$/';
    foreach ($files as $fileName) {
        if (preg_match($pattern, $fileName)) {
            // Key/value pairs of file name and modified time
            $filteredSortedFiles[$fileName] = filemtime($dir . '/' . $fileName);
        }
    }

    // Sort the filtered list of files by modified time, descending
    arsort($filteredSortedFiles);
    $filteredSortedFiles = array_keys($filteredSortedFiles);

    // Extract the epoch time from the file name, and only keep maxnum images
    $images = array();
    $imageCount = 0;
    foreach ($filteredSortedFiles as $fileName) {
        if ($limit != -1 && $imageCount >= $limit) {
            break;
        }
        $epochTime = substr($fileName, 6, 13);
        // TODO: Also check for the thumbnail file, and only push image objects 
        // that have both, so that the thumbnail name isn't hardcoded
        $image = array("name" => "capture/".$fileName, "thumb" => "capture/thumb-".$epochTime.".jpg", "epochTime" => $epochTime);
        array_push($images, $image);
        $imageCount++;
    }

    return json_encode($images);
}

?>