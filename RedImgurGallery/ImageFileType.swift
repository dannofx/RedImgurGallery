//
//  ImageFileType.swift
//  RedImgurGallery
//
//  Created by Danno on 7/27/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

enum ImageFileType {
    case full
    case thumbnail
    
    var directoryName: String {
        switch self {
        case .full:
            return "full"
        case .thumbnail:
            return "thumb"
        }
    }
    
    var directoryPath: URL {
        let directoryName = self.directoryName
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
    
    var maxSize: CGSize {
        switch self {
        case .full:
            return CGSize(width: 2000, height: 2000)
        case .thumbnail:
            return CGSize(width: 170, height: 170)
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
