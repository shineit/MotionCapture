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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Do any additional setup after loading the view.
        loadImageList()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func loadImageList() {
        Alamofire.request(.GET, "http://birdcam.floccul.us/images/25")
            .responseJSON { _, _, json, _ in
                let images = JSON(json!)
                self.imagesModel.clear()
                for (index: String, subJson: JSON) in images {
                    let name = subJson["name"].stringValue
                    let thumbName = subJson["thumb"].stringValue
                    let epochTime = subJson["epochTime"].doubleValue / 1000.0
                    let image = Image(name: name, thumbName: thumbName, epochTime: epochTime)
                    self.imagesModel.addImage(image)
                }
                self.imagesModel.sortByTime()
                self.collectionView?.reloadData()
        }
    }
    
    // Resize cells when orientation changes
    

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

}
