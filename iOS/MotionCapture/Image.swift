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
        var value: Int!, unit: String!
        switch seconds {
        case 0..<60:
            value = seconds
            unit = (value == 1) ? "second" : "seconds"
        case 60..<3600:
            value = seconds/60
            unit = (value == 1) ? "minute" : "minutes"
        case 3600..<86400:
            value = seconds/3600
            unit = (value == 1) ? "hour" : "hours"
        case 86400..<2592000:
            value = seconds/86400
            unit = (value == 1) ? "day" : "days"
        case 2592000..<31536000:
            value = seconds/2592000
            unit = (value == 1) ? "month" : "months"
        default:
            value = seconds/31536000
            unit = (value == 1) ? "year" : "years"
        }
        
        return "\(value) \(unit) ago"
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
