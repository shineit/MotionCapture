//
//  Image.swift
//  MotionCapture
//
//  Created by Jessica Yeh on 8/15/15.
//  Copyright (c) 2015 Yeh. All rights reserved.
//

import UIKit

class Image {
    
    var name: String
    var url: NSURL {
        return NSURL(string: "\(Constants.hostname)/\(name)")!
    }
    var thumbName: String
    var thumbUrl: NSURL {
        return NSURL(string: "\(Constants.hostname)/\(thumbName)")!
    }
    var epochTime: Double
    var formattedTime: String {
        let date = NSDate(timeIntervalSince1970: epochTime)
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "eee h:mm:ss a" // Mon 5:12:34 PM
        return dateFormatter.stringFromDate(date)
    }
    var timeSince: String {
        let seconds = Int(NSDate().timeIntervalSince1970 - epochTime)
        switch seconds {
        case 0..<60:
            return "\(seconds) seconds ago"
        case 60..<3600:
            return "\(seconds/60) minutes ago"
        case 3600..<86400:
            return "\(seconds/3600) hours ago"
        case 86400..<2592000:
            return "\(seconds/86400) days ago"
        case 2592000..<31536000:
            return "\(seconds/2592000) months ago"
        default:
            return "\(seconds/31536000) years ago"
        }
    }
    
    init(name: String, thumbName: String, epochTime: Double) {
        self.name = name
        self.thumbName = thumbName
        self.epochTime = epochTime
    }
    
    class func sorterForTime(this: Image, that: Image) -> Bool {
        return this.epochTime > that.epochTime
    }
}
