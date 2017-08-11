//
//  ThumbnailCollectionViewCell.swift
//  RedImgurGallery
//
//  Created by Danno on 7/27/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class ThumbnailCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var imageView: UIImageView!
    private var identifier = ""
    var localLoadWorkItem: DispatchWorkItem?

    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(withImageItem imageItem: ImageItem, shouldDownload: inout Bool) {
        if imageItem.identifier == nil {
            return
        }
        self.imageView.image = nil
        self.identifier = imageItem.identifier!
        let imageExists = imageItem.thumbnailExists()
        if imageExists {
            self.loadLocalImage()
            shouldDownload = false
        } else {
            self.imageView.image = nil
            shouldDownload = true
        }
    }
    
    func loadImage(_ image: UIImage) {
        self.imageView.image = nil
        self.loadLocalImage(image: image, animated: true)
    }
    
    private func loadLocalImage(image: UIImage? = nil, animated: Bool = false) {
        if let existingItem = self.localLoadWorkItem, !existingItem.isCancelled{
            existingItem.cancel()
        }
        let workItem = DispatchWorkItem(flags: .inheritQoS, block: {
            var loadedImage: UIImage!
            if let receivedImage = image {
                loadedImage = receivedImage
            } else {
                guard let diskImage = ImageItem.loadImage(forIdentifier: self.identifier, type: .thumbnail) else {
                    return
                }
                loadedImage = diskImage
            }
            loadedImage = loadedImage.forceLoad()
            DispatchQueue.main.async {
                if animated {
                    UIView.transition(with: self,
                                      duration: 0.3,
                                      options: .transitionCrossDissolve,
                                      animations: {
                                        self.imageView.image = image
                    })
                } else {
                    self.imageView.image = loadedImage
                }
            }
        })
        DispatchQueue.global(qos: .userInteractive).async(execute: workItem)
        self.localLoadWorkItem = workItem
    }
    
    deinit {
    }
}
