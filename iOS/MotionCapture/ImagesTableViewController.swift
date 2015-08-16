//
//  ImagesTableViewController.swift
//  MotionCapture
//
//  Created by Jessica Yeh on 8/15/15.
//  Copyright (c) 2015 Yeh. All rights reserved.
//

import UIKit
import Alamofire
import SwiftyJSON

class ImagesTableViewController: UITableViewController {

    let imagesModel = ImagesModel.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Setup pull to refresh
        refreshControl?.addTarget(self, action: "loadImageList", forControlEvents: UIControlEvents.ValueChanged)
        
        loadImageList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func showLoadingSpinner() {
        // Need to force the table offset when programmatically showing the refresh control
        if (tableView.contentOffset.y == 0.0) {
            tableView.setContentOffset(CGPointMake(0.0, -64.0), animated: true)
            refreshControl?.beginRefreshing()
        }
    }
    
    func loadImageList() {
        showLoadingSpinner()
        
        Alamofire.request(.GET, "http://birdcam.floccul.us/images")
            .responseJSON { _, _, json, _ in
                let images = JSON(json!)
                self.imagesModel.clear()
                for (index: String, subJson: JSON) in images {
                    let name = subJson["name"].stringValue
                    let epochTime = subJson["epochTime"].doubleValue
                    let image = Image(name: name, epochTime: epochTime)
                    self.imagesModel.addImage(image)
                }
                self.imagesModel.sortByTime()
                self.tableView.reloadData()
                self.refreshControl?.endRefreshing()
        }
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return imagesModel.images.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ImageNameCell", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...
        let image = imagesModel.images[indexPath.row]
        cell.textLabel?.text = image.formattedTime

        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let ivc = segue.destinationViewController as? ImageViewController {
            let path = self.tableView.indexPathForSelectedRow()!
            let image = imagesModel.images[path.row]
            ivc.imageURL = NSURL(string: "http://birdcam.floccul.us/\(image.name)")
            ivc.title = image.formattedTime
        }
    }

}
