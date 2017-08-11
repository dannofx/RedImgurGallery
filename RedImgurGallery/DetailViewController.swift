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
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var upvotesLabel: UILabel!

    weak var downloadQueue: ImageDownloadQueue!
    var index: IndexPath!
    var image: UIImage!
    var localLoadWorkItem: DispatchWorkItem?
    lazy var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d, yyyy HH:mm"
        formatter.locale = Locale.init(identifier: "en_US_POSIX")
        return formatter
    }()
    var imageItem: ImageItem! {
        didSet {
            self.loadImageItem()
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadImageItem()
    }
    
    func loadImageItem() {
        self.loadImage()
        if self.isViewLoaded {
            self.titleLabel.text = self.imageItem.title
            self.upvotesLabel.text = "Views: \(self.imageItem.views)"
            let date = Date.init(timeIntervalSince1970: self.imageItem.datetime)
            self.dateLabel.text = self.dateFormatter.string(from: date)
        }
    }
    
    func loadImage() {
        self.setPreviewImage()
        if let image = self.imageItem.loadImage(forType: .full) {
            self.setFullImage(image: image)
        } else {
            self.downloadQueue.addDownload(imageItem: self.imageItem) { (status, identifier, objectID, image) in
                if let image = image, identifier == self.imageItem.identifier{
                    self.setFullImage(image: image, animate: true)
                }
            }
        }
    }
    
    func setFullImage(image: UIImage, animate: Bool = false) {
        if let existingItem = self.localLoadWorkItem, !existingItem.isCancelled{
                existingItem.cancel()
        }
        
        let workItem = DispatchWorkItem(flags: .inheritQoS) {
            self.image = image.forceLoad()
            if self.isViewLoaded {
                DispatchQueue.main.async {
                    if animate {
                        UIView.transition(with: self.view,
                                          duration: 0.3,
                                          options: .transitionCrossDissolve,
                                          animations: {
                                            self.imageView.image = self.image
                        })
                    } else {
                        self.imageView.image = self.image
                    }
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
    
    @IBAction func openInBrowser(_ sender: Any) {
        guard let imageLink = self.imageItem.link else {
            print("There is no link to open in browser")
            return
        }
        guard let url = URL(string: imageLink) else {
            print("There is no URL to open in browser")
            return
        }
        UIApplication.shared.open(url,
                                  options: [:],
                                  completionHandler: nil)
    }
    

}
