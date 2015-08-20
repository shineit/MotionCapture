//
//  ImageCollectionViewCell.swift
//  MotionCapture
//
//  Created by Jessica Yeh on 8/20/15.
//  Copyright (c) 2015 Yeh. All rights reserved.
//

import UIKit
import Alamofire

class ImageCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var imageUrl: NSURL? {
        willSet {
            activityIndicator.startAnimating()
            if let newImageUrl = newValue {
                Alamofire.request(.GET, newImageUrl).validate(contentType: ["image/*"]).responseImage({ (req, res, img, err) -> Void in
                    self.imageView.image = img
                    self.activityIndicator.stopAnimating()
                })
            } else {
                imageView.image = nil
                self.activityIndicator.stopAnimating()
            }
        }
    }
    
//    override func awakeFromNib() {
//        super.awakeFromNib()
//        var visualEffectView = UIVisualEffectView(effect: UIBlurEffect(style: .Light)) as UIVisualEffectView
//        visualEffectView.frame = timeLabel.bounds
//        timeLabel.addSubview(visualEffectView)
//    }

}
