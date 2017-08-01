//
//  GalleryCollectionViewController.swift
//  RedImgurGallery
//
//  Created by Danno on 7/25/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

private let reuseIdentifier = "thumbnail"

class GalleryCollectionViewController: UICollectionViewController {
    
    fileprivate var dataController: DataController!
    fileprivate var fetchedResultController: NSFetchedResultsController<ImageItem>!
    fileprivate var changeOperations: [BlockOperation]?
    fileprivate var downloadQueue: ImageDownloadQueue!
    fileprivate let imageTypeToShow = ImageFileType.thumbnail
    fileprivate var selectedIndex: IndexPath!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.dataController = DataController()
        self.downloadQueue = ImageDownloadQueue(imageFileType: self.imageTypeToShow)
        self.fetchedResultController = self.dataController.createFeedFetchedResultController()
        
        self.fetchedResultController.delegate = self
        self.collectionView?.isPrefetchingEnabled = false
        
        //self.dataController.deleteAllImageItems()
        //ImageFileType.thumbnail.removeAllLocalFiles()
        //ImageFileType.full.removeAllLocalFiles()
        self.downloadImageList()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == StoryboardSegue.detail {
            let navController = segue.destination as! UINavigationController
            let carouselController = navController.viewControllers.first as! CarouselViewController
            carouselController.fetchedResultsController = self.fetchedResultController
            carouselController.currentIndex = self.selectedIndex
        }
    }
}

// MARK: UICollectionViewDataSource

extension GalleryCollectionViewController {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchedResultController.sections!.count
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedResultController.sections!.first!.numberOfObjects
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThumbnailCollectionViewCell
        let imageItem = self.fetchedResultController.object(at: indexPath)
        if let imageFile = imageItem.loadImage(forType: self.imageTypeToShow) {
            cell.imageView.image = imageFile
        } else {
            cell.imageView.image = nil
            self.downloadQueue.addDownload(imageItem: imageItem, completionBlock: { [unowned self] (status, identifier, managedObjectID, image) in
                if status == .downloaded {
                    self.reloadCell(forObjectID: managedObjectID, image: image!)
                }
            })
        }
        
        return cell
    }
}

// MARK: UICollectionViewDelegate

extension GalleryCollectionViewController {
    
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedIndex = indexPath
        self.performSegue(withIdentifier: StoryboardSegue.detail, sender: self)
        
    }
    
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }
    
    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        
    }
}

// MARK: - Fetched Result Controller Delegate

extension GalleryCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.changeOperations = []
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        var operation: BlockOperation
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            operation = BlockOperation { [unowned self] in
                self.collectionView?.insertItems(at: [newIndexPath])
            }
        case .delete:
            guard let indexPath = indexPath else { return }
            operation = BlockOperation { [unowned self] in
                self.collectionView?.deleteItems(at: [indexPath])
            }
        case .update:
            guard let newIndexPath = newIndexPath else { return }
            operation = BlockOperation { [unowned self] in
                self.collectionView?.reloadItems(at: [newIndexPath])
            }
        case .move:
            guard let indexPath = indexPath else { return }
            guard let newIndexPath = newIndexPath else { return }
            operation = BlockOperation { [unowned self] in
                self.collectionView?.moveItem(at: indexPath, to: newIndexPath)
            }
        }
        changeOperations?.append(operation)
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        guard var changeOperations = self.changeOperations else {
            return
        }
        self.collectionView?.performBatchUpdates({
            changeOperations.forEach { $0.start() }
        }, completion: { (success) in
            changeOperations.removeAll()
            self.changeOperations = nil
        })
    }
}

// MARK: - Collection view utils

extension GalleryCollectionViewController {
    func reloadCell(forObjectID objectID: NSManagedObjectID, image: UIImage) {
        guard let collectionView = self.collectionView else {
            return
        }
        let imageItem = self.dataController.viewContext.object(with: objectID)
        guard let indexPath = self.fetchedResultController.indexPath(forObject: imageItem as! ImageItem) else {
            return
        }
        if let cell = collectionView.cellForItem(at: indexPath) as? ThumbnailCollectionViewCell {
            cell.imageView.image = image
        }
    }
}


// MARK: - Metadata image download

extension GalleryCollectionViewController {
    func downloadImageList() {
        
        let urlString = String(format: URLPath.imageListFormat, "dogs")
        guard let url = URL(string: urlString) else {
            return
        }
        
        let request = NSMutableURLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue(ImgurCredentials.clientID, forHTTPHeaderField: HTTPHeaderName.authorization)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                return
            }
            
            guard let response = response else{
                print("Error: There is no response")
                return
            }
            if let responseCode = (response as? HTTPURLResponse)?.statusCode, responseCode != 200 {
                print("Error: The web service call was not successful (code:\(responseCode))")
                return
            }
            
            guard let data = data else {
                print("Error: There is o data to decode")
                return
            }
            
            do {
                guard let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else{
                    print("Error: JSON structure not recognized.")
                    return
                }
                guard let imagesData = jsonData[JSONKey.data] as? [[String: Any]] else {
                    print("Error: JSON structure not recognized ('data' not found or not valid).")
                    return
                }
                self.dataController.insertImageItemDataArray(dataArray: imagesData, completion: { (success, error) in
                    print("Success?! \(success)")
                })
                
            } catch {
                print("Error: \(error.localizedDescription)")
            }
            
            
        }
        task.resume()
    }
}
