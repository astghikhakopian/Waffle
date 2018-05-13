//
//  ImageCache.swift
//  Waffle
//
//  Created by Ben on 4/19/18.
//

import Foundation

class MyImageCache
{
    static let sharedCache: NSCache = { () -> NSCache<AnyObject, AnyObject> in
        let cache = NSCache<AnyObject, AnyObject>()
        cache.name = "MyImageCache"
        cache.countLimit = 200 // Max 200 images in memory.
        cache.totalCostLimit = 20*1024*1024 // Max 20MB used.
        return cache
    }()
}
