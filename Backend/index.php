<?php
header('Access-Control-Allow-Origin: *');
require 'vendor/autoload.php';

$app = new \Slim\Slim();

// Redirect index.php to index.html
$app->get('/', function () use ($app) {
    $app->redirect("index.html");
});

// [ { "name": "image-1234567890.jpg", "epochTime": 1234567890} ]
$app->get('/images(/:maxNum)', function ($maxNum = -1) {
    $dir = getcwd();
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
        if ($maxNum != -1 && $imageCount >= $maxNum) {
            break;
        }
        $epochTime = intval(substr($fileName, 6, 13));
        $image = array("name" => $fileName, "epochTime" => $epochTime);
        array_push($images, $image);
        $imageCount++;
    }

    echo json_encode($images);
});

$app->run();

?>