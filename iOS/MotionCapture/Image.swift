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
    var epochTime: Double
    var formattedTime: String {
        let date = NSDate(timeIntervalSince1970: epochTime)
        var dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "eee h:mm:ss a" // Mon 5:12:34 PM
        return dateFormatter.stringFromDate(date)
    }
    
    init(name: String, epochTime: Double) {
        self.name = name
        self.epochTime = epochTime
    }
    
    class func sorterForTime(this: Image, that: Image) -> Bool {
        return this.epochTime > that.epochTime
    }
}
