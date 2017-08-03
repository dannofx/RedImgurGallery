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
        self.maxConcurrentOperationCount = 4
        self.name = imageFileType.directoryName
    }
    
    func addDownload(imageItem: ImageItem, completionBlock: ClientCompletionBlock?) {
        if let operation = self.downloadsInProgress[imageItem.objectID] {
            operation.clientCompletionBlock = completionBlock
            return
        }
        let operation = ImageDownloadOperation(imageType: self.imageFileType, imageItem: imageItem)
        let objectID = operation.coreDataID
        self.downloadsInProgress[imageItem.objectID] = operation
        self.addOperation(operation)
        operation.clientCompletionBlock = completionBlock
        operation.completionBlock = { [weak self] in
            guard let operation = self?.downloadsInProgress.removeValue(forKey: objectID) else {
                return
            }
            DispatchQueue.main.async {
                operation.clientCompletionBlock?(operation.downloadStatus, operation.identifier, operation.coreDataID, operation.image)
            }
        }
        
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
