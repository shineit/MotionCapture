var baseUrl = 'http://birdcam.floccul.us/';
var imagesNode;

window.onload = function() {
    imagesNode = document.getElementById('images');

    var xhr = new XMLHttpRequest();
    xhr.open("GET", baseUrl + "images", true);
    xhr.onreadystatechange = function() {
        if (xhr.readyState === 4 && xhr.status === 200) {
            var response = JSON.parse(xhr.responseText);
            var imageArgs;
            for (var i = 0, len = response.length; i < len; i++) {
                imageArgs = response[i];
                imageArgs.count = i+1;
                addImage(imageArgs);
            }
        }
    }
    xhr.send();
}

function addImage(args) {
    var div = document.createElement('div');
    div.setAttribute('data-count', args.count);
    div.setAttribute('data-timestamp', getFormattedDate(args.epochTime) + ' • ' + timeSince(args.epochTime) + ' ago');
    div.className = 'imageContainer';
    var img = document.createElement('img');
    img.src = baseUrl + args.name;
    div.appendChild(img);
    imagesNode.appendChild(div);
};

function getFormattedDate(time) {
    var date = new Date(time);
    var options = {
        weekday: "short",
        month: "short",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit"
    };
    return date.toLocaleTimeString("en-us", options);
};

function timeSince(date) {
    var seconds = Math.floor((new Date() - date) / 1000);
    var interval = Math.floor(seconds / 31536000);
    if (interval > 1) {
        return interval + " years";
    }
    interval = Math.floor(seconds / 2592000);
    if (interval > 1) {
        return interval + " months";
    }
    interval = Math.floor(seconds / 86400);
    if (interval > 1) {
        return interval + " days";
    }
    interval = Math.floor(seconds / 3600);
    if (interval > 1) {
        return interval + " hours";
    }
    interval = Math.floor(seconds / 60);
    if (interval > 1) {
        return interval + " minutes";
    }
    return Math.floor(seconds) + " seconds";
}