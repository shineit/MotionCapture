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

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        Alamofire.request(.GET, "http://birdcam.floccul.us/images")
            .responseJSON { _, _, json, _ in
                let images = JSON(json!)
                ImagesModel.sharedInstance.clear()
                for (index: String, subJson: JSON) in images {
                    let name = subJson["name"].stringValue
                    let epochTime = subJson["epochTime"].intValue
                    ImagesModel.sharedInstance.addImage((name: name, time: epochTime))
                }
                self.tableView.reloadData()
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        return ImagesModel.sharedInstance.images.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ImageNameCell", forIndexPath: indexPath) as! UITableViewCell

        // Configure the cell...
        let image = ImagesModel.sharedInstance.images[indexPath.row]
        cell.textLabel?.text = image.name
        cell.detailTextLabel?.text = "\(image.time)"

        return cell
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let ivc = segue.destinationViewController as? ImageViewController {
            let path = self.tableView.indexPathForSelectedRow()!
            let imageName = ImagesModel.sharedInstance.images[path.row].name
            ivc.imageURL = NSURL(string: "http://birdcam.floccul.us/\(imageName)")
            ivc.title = imageName
        }
    }

}
