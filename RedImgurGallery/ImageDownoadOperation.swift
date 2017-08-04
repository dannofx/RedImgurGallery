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

typealias ClientCompletionBlock = (_ status: ImageDownloadStatus, _ identifier: String, _ objectID: NSManagedObjectID, _ image: UIImage?) -> Void

class ImageDownloadOperation: Operation {
    
    fileprivate(set) var downloadStatus: ImageDownloadStatus
    fileprivate(set) var image: UIImage?
    let imageType: ImageFileType
    let identifier: String
    let coreDataID: NSManagedObjectID
    var clientCompletionBlock: ClientCompletionBlock?
    
    
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
            guard var image = UIImage(data: data) else {
                print("Image download failed for \(identifier)")
                self.downloadStatus = .failed
                return
            }
            image = image.resizeImage(inMaxSize: self.imageType.maxSize)
            if self.isCancelled {
                self.downloadStatus = .cancelled
                return
            }
            self.image = image
            self.downloadStatus = .downloaded
            ImageItem.saveImageFile(image: image, forIdentifier: self.identifier, type: self.imageType)
            self.createThumbnailIfNecessary(image: image)

        } catch {
            self.downloadStatus = .failed
            print("Error retrieving data for \(identifier): \(error.localizedDescription)")
        }
    }
    
    private func createThumbnailIfNecessary(image: UIImage) {
        if self.imageType == .full {
            let thumbnailExists = ImageItem.thumbnailExists(identifier: self.identifier)
            if !thumbnailExists {
                guard let thumbImage = image.cropAndResizeInSquare(sideLength: ImageFileType.thumbnail.maxSize.width) else {
                    return
                }
                ImageItem.saveImageFile(image: thumbImage, forIdentifier: self.identifier, type: .thumbnail)
            }
        }
    }
}
