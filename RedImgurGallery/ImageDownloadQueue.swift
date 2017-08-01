//
//  DownloadImageQueue.swift
//  RedImgurGallery
//
//  Created by Danno on 7/27/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

class ImageDownloadQueue: OperationQueue {
    fileprivate(set) var imageFileType: ImageFileType
    fileprivate(set) var downloadsInProgress: [NSManagedObjectID: ImageDownloadOperation]
    
    init(imageFileType: ImageFileType) {
        self.imageFileType = imageFileType
        self.downloadsInProgress = [:]
        super.init()
        self.maxConcurrentOperationCount = 5
        self.name = imageFileType.directoryName
    }
    
    func addDownload(imageItem: ImageItem, completionBlock: ((_ status: ImageDownloadStatus, _ identifier: String, _ objectID: NSManagedObjectID, _ image: UIImage?) -> Void)?) {
        if self.downloadsInProgress[imageItem.objectID] != nil {
            return
        }
        let operation = ImageDownloadOperation(imageType: self.imageFileType, imageItem: imageItem)
        self.downloadsInProgress[imageItem.objectID] = operation
        let objectID = operation.coreDataID
        operation.completionBlock = { [unowned self] in
            guard let operation = self.downloadsInProgress.removeValue(forKey: objectID) else {
                return
            }
            DispatchQueue.main.async {
                completionBlock?(operation.downloadStatus, operation.identifier, operation.coreDataID, operation.image)
            }
        }
        self.addOperation(operation)
    }
    
    func cancelDownload(imageItem: ImageItem) {
        if let operation = self.downloadsInProgress[imageItem.objectID] {
            operation.cancel()
            self.downloadsInProgress.removeValue(forKey: imageItem.objectID)
        }
    }
    
    override func cancelAllOperations() {
        self.downloadsInProgress.removeAll()
        super.cancelAllOperations()
    }

}
