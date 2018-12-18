//
//  AppDelegate.swift
//  PhotoBrowser
//
//  Created by Zhouqi Mo on 12/22/14.
//  Copyright (c) 2014 Zhouqi Mo. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import FastImageCache

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, FICImageCacheDelegate {
    
    var window: UIWindow?
    lazy var coreDataStack = CoreDataStack()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        FastImageCacheHelper.setUp(self)
        let navController = window!.rootViewController as! UINavigationController
        let photoBrowserCollectionViewController = navController.topViewController as! PhotoBrowserCollectionViewController
        photoBrowserCollectionViewController.coreDataStack = coreDataStack
        
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        coreDataStack.saveContext()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        coreDataStack.saveContext()
    }
    
    //MARK: FICImageCacheDelegate
    
    func imageCache(_ imageCache: FICImageCache!, wantsSourceImageFor entity: FICEntity!, withFormatName formatName: String!, completionBlock: FICImageRequestCompletionBlock!) {
        if let entity = entity as? PhotoInfo {
            let imageURL = entity.sourceImageURL(withFormatName: formatName)
            let request = URLRequest(url: imageURL)
            
            entity.request = Alamofire.request(.GET, request).validate(contentType: ["image/*"]).responseImage() {
                (_, _, result) in
                switch result {
                case .success(let image):
                    completionBlock(image)
                case .failure:
                    break;
                }
            }
        }
    }
    
    func imageCache(_ imageCache: FICImageCache!, cancelImageLoadingFor entity: FICEntity!, withFormatName formatName: String!) {
        
        if let entity = entity as? PhotoInfo, let request = entity.request {
            request.cancel()
            entity.request = nil
            //debugPrint("be canceled:\(entity.UUID)")
        }
    }
    
    func imageCache(_ imageCache: FICImageCache!, shouldProcessAllFormatsInFamily formatFamily: String!, for entity: FICEntity!) -> Bool {
        return true
    }
    
    func imageCache(_ imageCache: FICImageCache!, errorDidOccurWithMessage errorMessage: String!) {
        debugPrint("errorMessage" + errorMessage)
    }
}

