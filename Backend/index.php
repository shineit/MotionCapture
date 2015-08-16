<?php
header('Access-Control-Allow-Origin: *');
require 'vendor/autoload.php';

$app = new \Slim\Slim();

// [ { "name": "image-1234567890.jpg", "epochTime": 1234567890} ]
$app->get('/images', function () {
    $files = scandir(getcwd());
    $pattern = '/^image-\d{10}.jpg$/';
    $images = array();

    foreach ($files as $fileName) {
        if (preg_match($pattern, $fileName)) {
            $epochTime = intval(substr($fileName, 6, 10));
            $image = array("name" => $fileName, "epochTime" => $epochTime);
            array_push($images, $image);
        }
    }

    echo json_encode($images);

});

$app->run();

?>