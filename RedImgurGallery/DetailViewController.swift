//
//  DetailViewController.swift
//  RedImgurGallery
//
//  Created by Danno on 7/28/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class DetailViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    weak var downloadQueue: ImageDownloadQueue!
    var index: IndexPath!
    var image: UIImage!
    var localLoadWorkItem: DispatchWorkItem?
    var imageItem: ImageItem! {
        didSet {
            self.loadImage()
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        //self.titleLabel.text = self.imageItem.title
        self.loadImage()

    }
    
    func loadImage() {
        self.setPreviewImage()
        if let image = self.imageItem.loadImage(forType: .full) {
            self.setFullImage(image: image)
        } else {
            self.downloadQueue.addDownload(imageItem: self.imageItem) { (status, identifier, objectID, image) in
                if let image = image, identifier == self.imageItem.identifier{
                    self.setFullImage(image: image)
                }
            }
        }
    }
    
    func setFullImage(image: UIImage) {
        if let existingItem = self.localLoadWorkItem, !existingItem.isCancelled{
                existingItem.cancel()
        }
        
        let workItem = DispatchWorkItem(flags: .inheritQoS) {
            self.image = image.forceLoad()
            if self.isViewLoaded {
                DispatchQueue.main.async {
                    self.imageView.image = self.image
                }
            }
        }
        
        DispatchQueue.global(qos: .userInitiated).async(execute: workItem)
        self.localLoadWorkItem = workItem
    }
    
    func setPreviewImage() {
        if self.isViewLoaded {
            self.imageView.image = self.imageItem.loadImage(forType: .thumbnail)
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
