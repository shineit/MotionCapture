//
//  ImageCollectionViewController.swift
//  MotionCapture
//
//  Created by Jessica Yeh on 8/20/15.
//  Copyright (c) 2015 Yeh. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ImageCollectionViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    
    let imagesModel = ImagesModel.sharedInstance
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var timeLabelContainer: UIView!
    var timeLabel: UILabel!
    var refreshTimer: NSTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        navigationController?.hidesBarsOnTap = true
        collectionView.scrollsToTop = true
        
        // Prevent weird margin at the top of collection view
        automaticallyAdjustsScrollViewInsets = false
        
        // Add blur and vibrancy effects to the time label
        let blurEffect = UIBlurEffect(style: .ExtraLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        timeLabelContainer.addSubview(blurView)
        addAutoLayoutToFillContainer(timeLabelContainer, subView: blurView)
        
        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: blurEffect))
        blurView.contentView.addSubview(vibrancyView)
        addAutoLayoutToFillContainer(blurView, subView: vibrancyView)
        
        timeLabel = UILabel()
        timeLabel.font = UIFont(name: "HelveticaNeue-Light", size: 24)
        timeLabel.textAlignment = .Center
        vibrancyView.contentView.addSubview(timeLabel)
        addAutoLayoutToFillContainer(vibrancyView, subView: timeLabel)
        
        loadImageList()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Subscribe to motion detection notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "controller:", name: "motionDetected", object: nil)
        
        // Check for new images every few seconds
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "loadImageList", userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        refreshTimer.invalidate()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func controller(notification: NSNotification) {
        if (notification.name == "motionDetected") {
            loadImageList()
        }
    }
    
    func loadImageList() {
        Alamofire.request(.GET, "\(Constants.hostname)/images/50")
            .responseJSON { _, _, json, _ in
                let images = JSON(json!)
                
                // Only proceed if the result is different than the current model
                if (images.count > 0 && self.imagesModel.images.count > 0) {
                    let oldFirstImageName = self.imagesModel.images[0].name
                    let newFirstImageName = images[0]["name"].stringValue
                    if (oldFirstImageName == newFirstImageName) {
                        return
                    }
                }
                
                self.imagesModel.clear()
                for (index: String, subJson: JSON) in images {
                    let name = subJson["name"].stringValue
                    let thumbName = subJson["thumb"].stringValue
                    let epochTime = subJson["epochTime"].doubleValue / 1000.0
                    let image = Image(name: name, thumbName: thumbName, epochTime: epochTime)
                    self.imagesModel.addImage(image)
                }
                self.imagesModel.sortByTime()
                self.collectionView.reloadData()
                self.updateTimeLabelText()
        }
    }
    
    // Update the time label with how long ago the top visible picture was taken
    func updateTimeLabelText() {
        let visibleItems = collectionView.indexPathsForVisibleItems()
        if (visibleItems.count > 0) {
            let topVisibleItem = visibleItems.reduce(visibleItems[0], combine: { $0.row < $1.row ? $0 : $1 }) as! NSIndexPath
            timeLabel.text = imagesModel.images[topVisibleItem.row].timeSince
        } else if (imagesModel.images.count > 0) {
            timeLabel.text = imagesModel.images[0].timeSince
        }
    }
    
    func addAutoLayoutToFillContainer(view: UIView, subView: UIView) {
        subView.setTranslatesAutoresizingMaskIntoConstraints(false)
        view.addConstraint(NSLayoutConstraint(item: subView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1.0, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: subView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1.0, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: subView, attribute: .Top, relatedBy: .Equal, toItem: view, attribute: .Top, multiplier: 1.0, constant: 0))
        view.addConstraint(NSLayoutConstraint(item: subView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1.0, constant: 0))
    }
    
    // Resize cells when orientation changes
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        
        coordinator.animateAlongsideTransition(nil, completion: { (UIViewControllerTransitionCoordinatorContext) -> Void in
            self.collectionView.collectionViewLayout.invalidateLayout()
        })
        
        super.viewWillTransitionToSize(size, withTransitionCoordinator: coordinator)
    }

    
    // MARK: UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // Return the number of items in the section
        return imagesModel.images.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("ImageCollectionViewCell", forIndexPath: indexPath) as! ImageCollectionViewCell
    
        // Configure the cell
        cell.imageUrl = imagesModel.images[indexPath.row].thumbUrl
    
        return cell
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            let width = collectionView.bounds.size.width
            let height = width * 0.75
            return CGSizeMake(width, height)
    }
    
    // MARK: UICollectionViewDelegate
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        updateTimeLabelText()
    }

}
