//
//  ImageOperation.swift
//  RedImgurGallery
//
//  Created by Danno on 7/26/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

enum ImageDownloadStatus {
    case notStarted
    case downloading
    case downloaded
    case cancelled
    case failed
}

class ImageDownloadOperation: Operation {
    
    fileprivate(set) var downloadStatus: ImageDownloadStatus
    fileprivate(set) var image: UIImage?
    let imageType: ImageFileType
    let identifier: String
    let coreDataID: NSManagedObjectID
    
    
    init(imageType: ImageFileType, imageItem: ImageItem) {
        self.imageType = imageType
        self.identifier = imageItem.identifier!
        self.coreDataID = imageItem.objectID
        self.downloadStatus = .notStarted
        super.init()
    }
    
    override func main() {
        if self.isCancelled {
            self.downloadStatus = .cancelled
            return
        }
        self.downloadStatus = .downloading
        let url = self.imageType.getInternetURL(forId: identifier)
        do {
            let data = try Data(contentsOf: url)
            if self.isCancelled {
                self.downloadStatus = .cancelled
                return
            }
            guard let image = UIImage(data: data) else {
                print("Image download failed for \(identifier)")
                self.downloadStatus = .failed
                return
            }
            self.image = image
            self.downloadStatus = .downloaded
            ImageItem.saveImageFile(image: image, forIdentifier: self.identifier, type: self.imageType)
        } catch {
            self.downloadStatus = .failed
            print("Error retrieving data for \(identifier): \(error.localizedDescription)")
        }
    }
    
    deinit {
        print("Dealloc")
    }

}
