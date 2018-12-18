//
//  CoreDataStack.swift
//  PhotoBrowser
//
//  Created by Zhouqi Mo on 1/3/15.
//  Copyright (c) 2015 Zhouqi Mo. All rights reserved.
//

import Foundation
import CoreData

class CoreDataStack {
    
    var context:NSManagedObjectContext
    var psc:NSPersistentStoreCoordinator
    var model:NSManagedObjectModel
    var store:NSPersistentStore?
    
    init() {
        
        let bundle = Bundle.main
        let modelURL =
        bundle.url(forResource: "PhotoBrowser", withExtension:"momd")
        model = NSManagedObjectModel(contentsOf: modelURL!)!
        
        psc = NSPersistentStoreCoordinator(managedObjectModel:model)
        
        context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = psc
        
        let documentsURL = applicationDocumentsDirectory()
        let storeURL =
        documentsURL.appendingPathComponent("PhotoBrowser.sqlite")
        
        let options =
        [NSMigratePersistentStoresAutomaticallyOption: true]
        
        do {
            try store = psc.addPersistentStore(ofType: NSSQLiteStoreType,
                configurationName: nil,
                at: storeURL,
                options: options)
        } catch {
            debugPrint("Error adding persistent store: \(error)")
            abort()
        }
        
    }
    
    func saveContext() {
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                debugPrint("Could not save: \(error)")
            }
        }
    }
    
    func applicationDocumentsDirectory() -> URL {
        
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1]
    }
    
}
