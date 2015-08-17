//
//  ImageViewController.swift
//  MotionCapture
//
//  Created by Jessica Yeh on 2/28/15.
//  Copyright (c) 2015 Yeh. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    var imageIndex: Int = 0
    var imageURL: NSURL? {
        didSet {
            image = nil
            if view.window != nil {
                fetchImage()
            }
        }
    }
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    private func fetchImage() {
        if let url = imageURL {
            spinner?.startAnimating()
            let qos = Int(QOS_CLASS_USER_INITIATED.value)
            dispatch_async(dispatch_get_global_queue(qos, 0), { () -> Void in
                let imageData = NSData(contentsOfURL: url)
                dispatch_async(dispatch_get_main_queue(), {
                    if url == self.imageURL {
                        if imageData != nil {
                            self.image = UIImage(data: imageData!)
                        } else {
                            self.image = nil
                        }
                    }
                })
            })
        }
    }
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.contentSize = imageView.frame.size
            scrollView.delegate = self
        }
    }
    
    func updateZoom() {
        if let image = imageView.image {
            scrollView.minimumZoomScale = min(scrollView.bounds.size.width / image.size.width, scrollView.bounds.size.height / image.size.height)
            scrollView.zoomScale = scrollView.minimumZoomScale
            scrollView.maximumZoomScale = 1.0
        }
    }
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    private var imageView = UIImageView()
    
    private var image: UIImage? {
        get { return imageView.image }
        set {
            imageView.image = newValue
            imageView.sizeToFit()
            scrollView?.contentSize = imageView.frame.size
            spinner?.stopAnimating()
            updateZoom()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.addSubview(imageView)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if image == nil {
            fetchImage()
        }
    }
    
//    func scrollViewDidZoom(scrollView: UIScrollView) {
//        if (scrollView.zoomScale == scrollView.minimumZoomScale) {
//            // Not zoomed, so disable scrolling so swipe gesture works
//            scrollView.scrollEnabled = false
//        } else {
//            scrollView.scrollEnabled = true
//        }
//    }
    
    @IBAction func swipeImage(sender: UISwipeGestureRecognizer) {
        let imageCount = ImagesModel.sharedInstance.images.count
        var newImageIndex: Int?
        
        if sender.direction == .Left {
            newImageIndex = imageIndex + 1
        } else if sender.direction == .Right {
            newImageIndex = imageIndex - 1
        }
        
        if let newImageIndex = newImageIndex {
            if newImageIndex != imageIndex &&
                newImageIndex >= 0 &&
                newImageIndex < imageCount {
                    let newImage = ImagesModel.sharedInstance.images[newImageIndex]
                    imageURL = newImage.url
                    title = newImage.formattedTime
                    imageIndex = newImageIndex
            }
        }
    }
    
}
