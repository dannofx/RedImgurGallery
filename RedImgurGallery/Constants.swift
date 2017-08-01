//
//  Constants.swift
//  RedImgurGallery
//
//  Created by Danno on 7/25/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import Foundation

struct URLPath {
    static let imageListFormat = "https://api.imgur.com/3/gallery/r/%@/time/all/0"
    static let thumbnailImageFormat = "https://i.imgur.com/%@b.jpg"
    static let imageFormat = "https://i.imgur.com/%@.jpg"
}

struct HTTPHeaderName {
    static let authorization = "Authorization"
}

struct JSONKey {
    static let data = "data"
    static let title = "title"
    static let id = "id"
    static let datetime = "datetime"
    static let link = "link"
    static let views = "views"
    static let type = "type"
}

struct StoryboardSegue {
    static let detail = "detail"
}

struct StoryboardID {
    static let detail = "detail"
}

enum ImageError: Error {
    case coreData
    case duplicatedBatch
}
