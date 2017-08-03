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
    
    func resizeImage(inMaxSize maxSize: CGSize) -> UIImage {
        if self.size.width <= maxSize.width && self.size.height <= maxSize.height {
            return self // The image already has an allowed size
        }
        let widthFactor = maxSize.width / self.size.width
        let heightFactor = maxSize.height / self.size.height
        let factor = min(widthFactor, heightFactor)
        let newSize = CGSize(width: self.size.width * factor, height: self.size.height * factor)
        return self.resizeImage(newSize: newSize)
    }
    
    func resizeImage(newSize: CGSize) -> UIImage {
        if self.size == newSize {
            return self
        }
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0);
        self.draw(in: CGRect(x: 0, y: 0, width: newSize.width, height: newSize.height))
        guard let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext() else {
            UIGraphicsEndImageContext()
            return self // failed
        }
        UIGraphicsEndImageContext()
        return newImage
    }
    
    
    func cropAndResizeInSquare(sideLength: CGFloat) -> UIImage?{
        let originalImageSize = self.size
        let baseSide = min(originalImageSize.width, originalImageSize.height)
        let newSize = CGSize.init(width: baseSide, height: baseSide)
        let newX = (originalImageSize.width - baseSide) / 2
        let newY = (originalImageSize.height - baseSide) / 2
        let newRect = CGRect.init(origin: CGPoint.init(x: newX, y: newY), size: newSize)
        guard let imageRef = self.cgImage else {
            return nil
        }
        guard let croppedImageRef = imageRef.cropping(to: newRect) else {
            return nil
        }
        var croppedImage = UIImage(cgImage: croppedImageRef, scale: self.scale, orientation: self.imageOrientation)
        croppedImage = croppedImage.resizeImage(newSize: CGSize(width: sideLength, height: sideLength))
        return croppedImage
    }
}
