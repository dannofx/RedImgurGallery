//
//  ImageOperation.swift
//  RedImgurGallery
//
//  Created by Danno on 7/26/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class ImageOperation: Operation {
    
    let imageType: ImageFileType
    let identifier: String
    
    init(imageType: ImageFileType, identifier: String) {
        self.imageType = imageType
        self.identifier = identifier
        super.init()
    }
    
    override func main() {
        if self.isCancelled {
            return
        }

        let url = self.imageType.getInternetURL(forId: identifier)
        do {
            let data = try Data(contentsOf: url)
            guard let image = UIImage(data: data) else {
                print("Image download failed for \(identifier)")
                return
            }
            hay que setear status para que el receiver pueda guardar
        } catch {
            print("Error retrieving data for \(identifier): \(error.localizedDescription)")
        }
    }

}
