//
//  DataController.swift
//  RedImgurGallery
//
//  Created by Danno on 7/25/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

class DataController: NSObject {
    let persistentContainer: NSPersistentContainer
    var viewContext: NSManagedObjectContext {
        return self.persistentContainer.viewContext
    }
    
    override init() {
        persistentContainer = NSPersistentContainer(name: "ImgurModel")
        super.init()
        persistentContainer.loadPersistentStores { (description, error) in
            if let error = error {
                print("Error: Error loading CoreData model \(error.localizedDescription)")
            }
        }
        self.persistentContainer.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    func insertImageDataArray(dataArray: [[String: Any]], completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        self.persistentContainer.performBackgroundTask { (context) in
            var batchChecked = false
            for imageData in dataArray {
                if !self.checkIfValidImageData(data: imageData) {
                    continue
                }
                
                if !batchChecked {
                    let id = imageData[JSONKey.id] as! String
                    if let _ = self.findImage(withId: id, context: context) {
                        // An image exists, is a repeated batch
                        self.viewContext.perform {
                            completion(false, ImageError.duplicatedBatch)
                        }
                        return
                    }
                    batchChecked = true
                }
                
                self.insertImageData(data: imageData, context: context)
            }
            
            self.viewContext.perform {
                completion(false, nil)
            }
        }
        
    }
    
    func checkIfValidImageData(data: [String: Any]) -> Bool {
        guard let _ = data[JSONKey.title] as? String else {
            return false
        }
        guard let _ = data[JSONKey.id] as? String else {
            return false
        }
        guard let _ = data[JSONKey.datetime] as? TimeInterval else {
            return false
        }
        guard let _ = data[JSONKey.views] as? Int64 else {
            return false
        }
        guard let _ = data[JSONKey.link] as? String else {
            return false
        }
        
        guard let type = data[JSONKey.type] as? String else {
            return false
        }
        
        if type != "image/jpeg" && type != "image/png" {
            return false
        }
        
        return true
    }
    
    func insertImageData(data: [String: Any], context: NSManagedObjectContext) {
        context.automaticallyMergesChangesFromParent = true
        let image = NSEntityDescription.insertNewObject(forEntityName: String(describing: Image.self), into: context) as! Image
        image.title = data[JSONKey.title] as? String
        image.id = data[JSONKey.id] as? String
        image.datetime = data[JSONKey.datetime] as! TimeInterval
        image.views = data[JSONKey.views] as! Int64
        image.link = data[JSONKey.link] as? String
    }
    
    func findImage(withId id: String, context: NSManagedObjectContext) -> Image? {
        let fetchRequest: NSFetchRequest<Image> = Image.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "id == \(id)")
        fetchRequest.resultType = NSFetchRequestResultType.managedObjectResultType
        do  {
            let results = try context.fetch(fetchRequest)
            return results.count > 0 ? results.first! : nil
        } catch {
            print("Error fetching blocked user result")
            return nil
        }
    }
    
    func saveContext() {
        let context = persistentContainer.viewContext
        _ = saveContext(context: context)
    }
    
    func saveContext(context: NSManagedObjectContext) {
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                fatalError("Failure to save context: \(error)")
            }
        }
    }
}
