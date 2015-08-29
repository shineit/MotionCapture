//
//  ImageTableViewCell.swift
//  MotionCapture
//
//  Created by Jessica Yeh on 8/29/15.
//  Copyright (c) 2015 Yeh. All rights reserved.
//

import UIKit
import Alamofire

class ImageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var captureView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var imageUrl: NSURL? {
        willSet {
            self.activityIndicator.startAnimating()
            if let newImageUrl = newValue {
                Alamofire.request(.GET, newImageUrl).validate(contentType: ["image/*"]).responseImage({ (req, res, img, err) -> Void in
                    self.captureView.image = img
                    self.activityIndicator.stopAnimating()
                })
            } else {
                self.captureView.image = nil
                self.activityIndicator.stopAnimating()
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
