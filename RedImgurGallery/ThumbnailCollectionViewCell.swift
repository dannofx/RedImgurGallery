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
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func configure(withImageItem imageItem: ImageItem, shouldDownload: inout Bool) {
        if imageItem.identifier == nil
        {
            return
        }
        self.imageView.image = nil
        if let imageFile = imageItem.loadImage(forType: .thumbnail) {
            shouldDownload = false
            self.imageView.image = imageFile
        } else {
            self.imageView.image = nil
            shouldDownload = true
        }
    }
    
    func loadImage(_ image: UIImage) {
        self.imageView.image = nil
        UIView.transition(with: self,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: {
                            self.imageView.image = image
        })
    }
    deinit {
    }
}
