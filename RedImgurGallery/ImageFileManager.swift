//
//  ImageFileManager.swift
//  RedImgurGallery
//
//  Created by Danno on 7/27/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class ImageFileManager {
    
    private static var directoriesExistence: [String: Bool] = [:]
    
    static var documentsDirectory: URL {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        let documentsDirectory = paths[0]
        return documentsDirectory
    }
    
    static func writeImage(image: UIImage, toFile fileURL: URL) {
        guard let data = UIImageJPEGRepresentation(image, 0.8) else {
            return
        }
        try! data.write(to: fileURL)
    }
    
    static func loadImage(fromFile fileURL: URL) -> UIImage? {
        return UIImage(contentsOfFile: fileURL.path)
    }
    
    static func prepareToWrite(inDirectory directory: URL) {
        if let existence = directoriesExistence[directory.path] {
            if !existence {
                createDirectory(directory: directory)
                directoriesExistence[directory.path] = true
            }
        } else {
            let mustCreate = !checkIfDirectoryExists(directory: directory.path)
            if mustCreate {
                createDirectory(directory: directory)
            }
            directoriesExistence[directory.path] = true
        }
    }
    
    static func removeAllFiles(inDirectory directory: URL) {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: directory)
        directoriesExistence[directory.path] = false
    }
    
    static func createDirectory(directory: URL) {
        let fileManager = FileManager.default
        try! fileManager.createDirectory(at: directory,
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
