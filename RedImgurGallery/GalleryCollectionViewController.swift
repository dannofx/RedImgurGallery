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
    
    @IBOutlet weak var searchView: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var cancelEditionButton: UIButton!
    @IBOutlet weak var messageView: UIView!
    @IBOutlet weak var messageLabel: UILabel!
    
    fileprivate var dataController: DataController!
    fileprivate var fetchedResultController: NSFetchedResultsController<ImageItem>!
    fileprivate var changeOperations: [BlockOperation]?
    fileprivate var downloadQueue: ImageDownloadQueue!
    fileprivate let imageTypeToShow = ImageFileType.thumbnail
    fileprivate var selectedIndex: IndexPath!
    fileprivate var listDownloadTask: URLSessionDataTask?
    fileprivate var lastValidSearchTerm: String! {
        didSet {
            UserDefaults.standard.set(self.lastValidSearchTerm, forKey: StoredValues.lastSearchTerm)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.searchTextField.delegate = self
        self.lastValidSearchTerm = self.loadLastValidSearchTerm()
        self.searchTextField.text = self.lastValidSearchTerm
        self.setSearchViewWidth()
        
        NotificationCenter.default.addObserver(self, selector: #selector(viewDidRotate), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        self.dataController = DataController()
        self.downloadQueue = ImageDownloadQueue(imageFileType: self.imageTypeToShow)
        self.fetchedResultController = self.dataController.createFeedFetchedResultController()
        
        self.fetchedResultController.delegate = self
        self.collectionView?.isPrefetchingEnabled = false
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == StoryboardSegue.detail {
            let carouselController = segue.destination as! CarouselViewController
            carouselController.fetchedResultsController = self.fetchedResultController
            carouselController.currentIndex = self.selectedIndex
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    func viewDidRotate() {
        self.setSearchViewWidth()
    }
    
    func reloadData(setDelegate: Bool = true) {
        self.collectionView?.contentOffset.y = 0
        self.fetchedResultController = self.dataController.createFeedFetchedResultController()
        self.collectionView?.reloadData()
        if (setDelegate) {
            self.fetchedResultController.delegate = self
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARk: Search field

extension GalleryCollectionViewController {
    
    func setSearchViewWidth() {
        var frame: CGRect = self.searchView.frame
        frame.size.width = self.view.frame.width
        self.searchView.frame = frame
    }
    func loadLastValidSearchTerm() -> String {
        return (UserDefaults.standard.value(forKey: StoredValues.lastSearchTerm) as? String) ?? ""
    }
    
    @IBAction func didTextChanged(_ sender: UITextField) {
        if !sender.isEditing {
            return
        }
        if let searchTerm = sender.text, searchTerm != "" {
            if let listDownloadTask = self.listDownloadTask {
                listDownloadTask.cancel()
            }
            self.listDownloadTask = self.downloadImageList(searchTerm)
            self.messageView.isHidden = true
            if (self.listDownloadTask == nil) {
                self.searchTextField.text = lastValidSearchTerm
            }
        }
    }
    
    @IBAction func cancelTextEdition(_ sender: Any) {
        if self.searchTextField.isEditing {
            self.exitSearchEdition()
        }
    }
    
    @IBAction func didBeginEdition(_ sender: UITextField) {
        self.fetchedResultController.delegate = nil
        self.beginSearchEdition()
    }
    
    func exitSearchEdition() {
        self.searchTextField.resignFirstResponder()
        self.cancelEditionButton.isHidden = true
        self.messageView.isHidden = true
        self.fetchedResultController.delegate = self
        self.searchTextField.text = self.lastValidSearchTerm
    }
    
    func beginSearchEdition() {
        self.cancelEditionButton.isHidden = false
    }
}

// MARK: - UITextFieldDelegate
extension GalleryCollectionViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.exitSearchEdition()
        return false
    }

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = string
        let existingChars = self.searchTextField.text?.characters.count ?? 0
        if (existingChars + text.characters.count) > 21 {
            return false
        }
        let characterSet = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_"))
        let range = text.rangeOfCharacter(from: characterSet.inverted)
        return range == nil
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
        if imageItem.identifier == nil
        {
            return cell
        }
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
        if self.searchTextField.isEditing {
            self.exitSearchEdition()
        } else {
            self.selectedIndex = indexPath
            self.performSegue(withIdentifier: StoryboardSegue.detail, sender: self)
        }
        
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
                self.collectionView?.deleteItems(at: [indexPath])
                self.collectionView?.insertItems(at: [newIndexPath])
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
    func downloadImageList(_ searchTerm: String) -> URLSessionDataTask? {
        
        let urlString = String(format: URLPath.imageListFormat, searchTerm)
        guard let url = URL(string: urlString) else {
            return nil
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
                self.processReceivedSearchItems(imagesData, forSearchTerm: searchTerm)
                
            } catch {
                print("Error: \(error.localizedDescription)")
            }
            
            
        }
        task.resume()
        return task
    }
    
    func processReceivedSearchItems(_ imageDataItems:[[String: Any]], forSearchTerm searchTerm: String) {
        // Check if there is data to set up
        if imageDataItems.count == 0 {
            DispatchQueue.main.async {
                self.messageView.isHidden = false
                self.messageLabel.text = "No images found for: \(self.searchTextField.text ?? "")"
            }
            
            return
        }
        // Cancel the thumbnails downloads for the previous search term
        self.downloadQueue.cancelAllOperations()
        // Remove cached images for the previous term
        ImageFileType.thumbnail.removeAllLocalFiles()
        ImageFileType.full.removeAllLocalFiles()
        // Process the new data
        self.dataController.deleteAllImageItems(){ (success) in
            if success {
                self.dataController.insertImageItemDataArray(dataArray: imageDataItems){ (success, error) in
                    if success {
                        self.lastValidSearchTerm = searchTerm
                        if !self.searchTextField.isEditing {
                            self.searchTextField.text = self.lastValidSearchTerm
                        }
                    }
                    self.reloadData(setDelegate: false)
                }
            } else {
                self.reloadData(setDelegate: false)
            }
        }
    }
}
