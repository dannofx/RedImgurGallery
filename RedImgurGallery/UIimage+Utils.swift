//
//  Uiimage+Utils.swift
//  RedImgurGallery
//
//  Created by Danno on 8/1/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

extension UIImage {
    
    func forceLoad() -> UIImage {
        guard let imageRef = self.cgImage else {
            return self //failed
        }
        let width = imageRef.width
        let height = imageRef.height
        let colourSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        guard let imageContext = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * 4, space: colourSpace, bitmapInfo: bitmapInfo) else {
            return self //failed
        }
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        imageContext.draw(imageRef, in: rect)
        if let outputImage = imageContext.makeImage() {
            let cachedImage = UIImage(cgImage: outputImage)
            return cachedImage
        }
        return self //failed
    }
    

}
