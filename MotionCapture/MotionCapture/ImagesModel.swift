//
//  ImagesModel.swift
//  MotionCapture
//
//  Created by Jessica Yeh on 8/15/15.
//  Copyright (c) 2015 Yeh. All rights reserved.
//

import UIKit

public typealias Image = (name: String, time: Int)

class ImagesModel {
   
    static let sharedInstance = ImagesModel()
    
    private(set) var images = [Image]()
    
    private init() {
        println("Created ImagesModel")
    }
    
    func addImage(image: Image) {
        images.append(image)
    }
    
    func clear() {
        images.removeAll()
    }

}
