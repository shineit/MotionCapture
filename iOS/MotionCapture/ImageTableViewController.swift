//
//  ImageTableViewController.swift
//  MotionCapture
//
//  Created by Jessica Yeh on 8/29/15.
//  Copyright (c) 2015 Yeh. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ImageTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    let imagesModel = ImagesModel.sharedInstance
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var timeLabelContainer: UIView!
    var timeLabel: UILabel!
    var refreshTimer: NSTimer!
    var updateTimeLabelTimer: NSTimer!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        navigationController?.hidesBarsOnTap = true
        tableView.scrollsToTop = true
        tableView.contentInset = UIEdgeInsetsMake(44, 0, 0, 0)
        
        // Allow row heights based on auto layout
        tableView.estimatedRowHeight = 200.0
        
        // Add blur and vibrancy effects to the time label
        let blurEffect = UIBlurEffect(style: .ExtraLight)
        let blurView = UIVisualEffectView(effect: blurEffect)
        timeLabelContainer.addSubview(blurView)
        addAutoLayoutToFillContainer(timeLabelContainer, subView: blurView)
        
        let vibrancyView = UIVisualEffectView(effect: UIVibrancyEffect(forBlurEffect: blurEffect))
        blurView.contentView.addSubview(vibrancyView)
        addAutoLayoutToFillContainer(blurView, subView: vibrancyView)
        
        timeLabel = UILabel()
        timeLabel.text = "Loading..."
        timeLabel.font = UIFont(name: "HelveticaNeue-Light", size: 24)
        timeLabel.textAlignment = .Center
        vibrancyView.contentView.addSubview(timeLabel)
        addAutoLayoutToFillContainer(vibrancyView, subView: timeLabel)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        loadImageList()
        
        // Subscribe to motion detection notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "controller:", name: "motionDetected", object: nil)
        
        // Check for new images every few seconds
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "loadImageList", userInfo: nil, repeats: true)
        
        // Update the time label every second
        updateTimeLabelTimer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: "updateTimeLabelText", userInfo: nil, repeats: true)
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
        refreshTimer.invalidate()
        updateTimeLabelTimer.invalidate()
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
        Alamofire.request(.GET, "\(Constants.hostname)/getCaptures.php?limit=50")
            .responseJSON { _, _, json, err in
                if (err == nil) {
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
                    self.tableView.reloadData()
                    self.tableView.beginUpdates()
                    self.tableView.endUpdates()
                    self.updateTimeLabelText()
                }
        }
    }
    
    // Update the time label with how long ago the top visible picture was taken
    func updateTimeLabelText() {
        let visibleItems = tableView.indexPathsForVisibleRows()
        if (visibleItems?.count > 0) {
            let topVisibleItem = visibleItems!.reduce(visibleItems![0], combine: { $0.row < $1.row ? $0 : $1 }) as! NSIndexPath
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
    
    func scrollViewDidScroll(scrollView: UIScrollView) {
        updateTimeLabelText()
    }
    
    // MARK: - UITableViewDataSource
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imagesModel.images.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ImageTableViewCell", forIndexPath: indexPath) as! ImageTableViewCell
        
        // Configure the cell
        cell.imageUrl = imagesModel.images[indexPath.row].thumbUrl
        
        return cell
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
