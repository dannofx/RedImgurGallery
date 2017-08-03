//
//  Image+CoreDataProperties.swift
//  RedImgurGallery
//
//  Created by Danno on 7/26/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

extension ImageItem {

    func saveImageFile(image: UIImage, forType type: ImageFileType) {
        ImageItem.saveImageFile(image: image, forIdentifier: self.identifier!, type: type)
    }
    
    func loadImage(forType type: ImageFileType) -> UIImage? {
        return ImageItem.loadImage(forIdentifier: self.identifier!, type: type)
    }
    
    class func saveImageFile(image: UIImage, forIdentifier identifier: String, type: ImageFileType) {
        ImageFileManager.prepareToWrite(inDirectory: type.directoryPath)
        ImageFileManager.writeImage(image: image, toFile: type.getLocalFilePath(forId: identifier))
    }
    
    class func loadImage(forIdentifier identifier: String, type: ImageFileType) -> UIImage? {
        let image = ImageFileManager.loadImage(fromFile: type.getLocalFilePath(forId: identifier))
        return image
    }
    
    class func thumbnailExists(identifier: String) -> Bool {
        return ImageFileManager.checkIfFileExists(filePath: ImageFileType.thumbnail.getLocalFilePath(forId: identifier).path)
    }
}
