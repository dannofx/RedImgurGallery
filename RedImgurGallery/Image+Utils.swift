//
//  Image+CoreDataProperties.swift
//  RedImgurGallery
//
//  Created by Danno on 7/26/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

class ImageFileManager {
    
    private static var directoriesExistence: [String: Bool] = [:]
    
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    static func writeImage(image: UIImage, toFile fileURL: URL) {
        guard let data = UIImagePNGRepresentation(image) else {
        return
        }
        try? data.write(to: fileURL)
    }
    
    static func loadImage(fromFile fileURL: URL) -> UIImage? {
        return UIImage(contentsOfFile: fileURL.absoluteString)
    }
    
    static func prepareToWrite(inDirectory directory: URL) {
        if let existence = directoriesExistence[directory.absoluteString] {
            if !existence {
                createDirectory(directory: directory)
            }
        } else {
            let mustCreate = !checkIfDirectoryExists(directory: directory.absoluteString)
            if mustCreate {
                createDirectory(directory: directory)
            }
        }
        
        directoriesExistence[directory.absoluteString] = true
        
    }
    
    static func removeAllFiles(inDirectory directory: URL) {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: directory)
        directoriesExistence[directory.absoluteString] = false
    }
    
    static func createDirectory(directory: URL) {
        let fileManager = FileManager.default
        try? fileManager.createDirectory(at: directory,
                                    withIntermediateDirectories: true,
                                    attributes: nil)
    }
    
    static func checkIfDirectoryExists(directory: String) -> Bool {
        let fileManager = FileManager.default
        var exists: Bool = false
        var isDir : ObjCBool = false
        exists = fileManager.fileExists(atPath: directory, isDirectory: &isDir)
        
        if exists && isDir.boolValue {
            try? fileManager.removeItem(atPath: directory)
            return false
        }
        return exists
    }
    
}

enum ImageFileType {
    case full
    case thumbnail
    
    var directoryPath: URL {
        var directoryName: String!
        switch self {
        case .full:
            directoryName = "full"
        case .thumbnail:
            directoryName = "thumb"
        }
        
        return ImageFileManager.documentsDirectory.appendingPathComponent(directoryName)
    }
    
    var urlFormat: String {
        switch self {
        case .full:
            return URLPath.imageFormat
        case .thumbnail:
            return URLPath.thumbnailImageFormat
        }
    }
    
    func getLocalFilePath(forId identifier: String) -> URL {
        return self.directoryPath.appendingPathComponent(identifier)
    }
    
    func getInternetURL(forId identifier: String) -> URL {
        let urlString = String(format: self.urlFormat, identifier)
        return URL(string: urlString)!
    }
    
    func removeAllLocalFiles() {
        ImageFileManager.removeAllFiles(inDirectory: self.directoryPath)
    }
    
}

extension Image {

    func saveImageFile(image: UIImage, forType type: ImageFileType) {
        ImageFileManager.prepareToWrite(inDirectory: ImageFileType.full.directoryPath)
        ImageFileManager.writeImage(image: image, toFile: type.getLocalFilePath(forId: self.identifier!))
    }
    
    func loadImage(forType type: ImageFileType) -> UIImage? {
        return ImageFileManager.loadImage(fromFile: type.getLocalFilePath(forId: self.identifier!))
    }
    

}
