//
//  FastImageCacheHelper.swift
//  PhotoBrowser
//
//  Created by Zhouqi Mo on 1/2/15.
//  Copyright (c) 2015 Zhouqi Mo. All rights reserved.
//

import Foundation
import UIKit
import FastImageCache

let KMPhotoImageFormatFamily = "KMPhotoImageFormatFamily"
let KMSmallImageFormatName = "KMSmallImageFormatName"
let KMBigImageFormatName = "KMBigImageFormatName"

var KMSmallImageSize: CGSize {
    let column = UI_USER_INTERFACE_IDIOM() == .pad ? 4 : 3
    let width = floor((UIScreen.main.bounds.size.width - CGFloat(column - 1)) / CGFloat(column))
    return CGSize(width: width, height: width)
}

var KMBigImageSize: CGSize {
    let width = UIScreen.main.bounds.size.width * 2
    return CGSize(width: width, height: width)
}

class FastImageCacheHelper {
    
    class func setUp(_ delegate: FICImageCacheDelegate) {
        var imageFormats = [AnyObject]()
        let squareImageFormatMaximumCount = 400;
        let smallImageFormat = FICImageFormat(name: KMSmallImageFormatName, family: KMPhotoImageFormatFamily, imageSize: KMSmallImageSize, style: .style32BitBGRA, maximumCount: squareImageFormatMaximumCount, devices: [.phone, .pad], protectionMode: .none)
        imageFormats.append(smallImageFormat!)
        
        let bigImageFormat = FICImageFormat(name: KMBigImageFormatName, family: KMPhotoImageFormatFamily, imageSize: KMBigImageSize, style: .style32BitBGRA, maximumCount: squareImageFormatMaximumCount, devices: [.phone, .pad], protectionMode: .none)
        imageFormats.append(bigImageFormat!)
        
        let sharedImageCache = FICImageCache.shared()
        sharedImageCache?.delegate = delegate
        sharedImageCache?.setFormats(imageFormats)
    }
}
