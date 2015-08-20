//
//  AlamofireExtensions.swift
//  MotionCapture
//
//  Created by Jessica Yeh on 8/20/15.
//  Copyright (c) 2015 Yeh. All rights reserved.
//

import Foundation
import Alamofire

extension Alamofire.Request {
    public static func imageResponseSerializer() -> GenericResponseSerializer<UIImage> {
        return GenericResponseSerializer { request, response, data in
            if data == nil {
                return (nil, nil)
            }
            
            let image = UIImage(data: data!, scale: UIScreen.mainScreen().scale)
            
            return (image, nil)
        }
    }
    
    public func responseImage(completionHandler: (NSURLRequest, NSHTTPURLResponse?, UIImage?, NSError?) -> Void) -> Self {
        return response(responseSerializer: Request.imageResponseSerializer(), completionHandler: completionHandler)
    }
}