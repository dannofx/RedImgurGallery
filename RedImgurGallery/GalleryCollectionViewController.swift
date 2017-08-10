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
    @IBOutlet weak var messageView: MessageView!
    @IBOutlet weak var cancelButtonConstraint: NSLayoutConstraint!
    
    fileprivate var dataController: DataController!
    fileprivate var fetchedResultController: NSFetchedResultsController<ImageItem>!
    fileprivate var changeOperations: [BlockOperation]?
    fileprivate var downloadQueue: ImageDownloadQueue!
    fileprivate var downloadingPage: Bool!
    fileprivate var lastPage: Int!
    fileprivate var morePages: Bool!
    fileprivate let imageTypeToShow = ImageFileType.thumbnail
    fileprivate var selectedIndex: IndexPath!
    fileprivate var listDownloadTask: URLSessionDataTask?
    fileprivate var cancelButtonWidth: CGFloat!
    fileprivate var cellSize: CGSize!
    fileprivate weak var showingCarouselController: CarouselViewController?
    fileprivate var lastValidSearchTerm: String! {
        didSet {
            UserDefaults.standard.set(self.lastValidSearchTerm, forKey: StoredValues.lastSearchTerm)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Search text field appereance
        let searchImage = #imageLiteral(resourceName: "search").withRenderingMode(.alwaysTemplate)
        let searchImageView = UIImageView(image: searchImage)
        searchImageView.tintColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        self.searchTextField.leftViewMode = .always
        self.searchTextField.leftView = searchImageView
        self.searchTextField.delegate = self
        self.lastValidSearchTerm = self.loadLastValidSearchTerm()
        self.searchTextField.text = self.lastValidSearchTerm
        self.searchView.translatesAutoresizingMaskIntoConstraints = false
        self.setSearchViewFrame()
        // Cancel button appereance
        self.cancelEditionButton.layer.cornerRadius = 3.0
        self.cancelButtonWidth = self.cancelButtonConstraint.constant
        self.cancelButtonConstraint.constant = 0
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(viewDidRotate),
                                               name: NSNotification.Name.UIDeviceOrientationDidChange,
                                               object: nil)

        self.dataController = DataController()
        self.downloadQueue = ImageDownloadQueue(imageFileType: self.imageTypeToShow)
        self.fetchedResultController = self.dataController.createFeedFetchedResultController()
        
        self.fetchedResultController.delegate = self
        self.collectionView?.isPrefetchingEnabled = false
        self.calculateCellSize()
        
        self.downloadingPage = false
        self.lastPage = 0
        self.morePages = true
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        self.downloadQueue.cancelAllOperations()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == StoryboardSegue.detail {
            let carouselController = segue.destination as! CarouselViewController
            carouselController.fetchedResultsController = self.fetchedResultController
            carouselController.currentIndex = self.selectedIndex
            carouselController.carouselDelegate = self
            self.navigationController?.setNavigationBarHidden(false, animated: true)
            self.showingCarouselController = carouselController
        }
    }
    
    func viewDidRotate() {
        self.setSearchViewFrame()
        self.messageView.layoutSubviews()
        self.calculateCellSize()
        self.collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func reloadData(setDelegate: Bool = true) {
        self.collectionView?.contentOffset.y = 0
        self.fetchedResultController = self.dataController.createFeedFetchedResultController()
        self.collectionView?.reloadData()
        if (setDelegate) {
            self.fetchedResultController.delegate = self
        }
    }
    
    private func calculateCellSize() {
        let separationSpace: CGFloat = 5
        let cellMinimumSize: CGFloat = 100
        let totalWidth: CGFloat = self.view.frame.width
        if totalWidth < cellMinimumSize
        {
            self.cellSize = CGSize(width: totalWidth, height: totalWidth)
            return
        }
        let cellsNumber = Int(totalWidth / cellMinimumSize)
        let availableSpace = totalWidth - CGFloat(cellsNumber - 1) * separationSpace
        let cellSize = availableSpace / CGFloat(cellsNumber)
        self.cellSize = CGSize(width: cellSize, height: cellSize)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - Search field

extension GalleryCollectionViewController {
    
    func setSearchViewFrame() {
        var frame: CGRect = self.navigationController!.navigationBar.frame
        //frame.size.width = self.view.frame.width
        //frame.size.height = 44
        frame.origin = CGPoint(x: 0, y: 0)
        self.searchView.frame = frame
        self.searchView.layoutIfNeeded()
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
            self.messageView.configure(withStatus: .searching, searchTerm: searchTerm)
            self.listDownloadTask = self.downloadImageList(searchTerm,
                                                           page: 0,
                                                           completionBlock: processNewSearchItems(success:imageDataItems:forSearchTerm:page:))
            if (self.listDownloadTask == nil) {
                self.searchTextField.text = lastValidSearchTerm
            }
        }
    }
    
    @IBAction func cancelTextEdition(_ sender: Any) {
        if self.searchTextField.isEditing {
            self.searchTextField.resignFirstResponder()
        }
    }
    
    @IBAction func didBeginEdition(_ sender: UITextField) {
        self.fetchedResultController.delegate = nil
        self.beginSearchEdition()
    }
    
    @IBAction func didEndEdition(_ sender: UITextField) {
        self.exitSearchEdition()
    }
    
    func exitSearchEdition() {
        self.fetchedResultController.delegate = self
        self.searchTextField.text = self.lastValidSearchTerm
        UIView.animate(withDuration: 0.5) {
            self.cancelButtonConstraint.constant = 0
            self.messageView.isHidden = true
            self.searchView.layoutIfNeeded()
        }
    }
    
    func beginSearchEdition() {
        self.setSearchViewFrame()
        UIView.animate(withDuration: 0.5) {
            self.cancelButtonConstraint.constant = self.cancelButtonWidth
            self.searchView.layoutIfNeeded()
        }
    }
}

// MARK: - UITextFieldDelegate
extension GalleryCollectionViewController: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.searchTextField.resignFirstResponder()
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

// MARK: - UICollectionViewDataSource

extension GalleryCollectionViewController: UICollectionViewDelegateFlowLayout {
    
    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.fetchedResultController.sections!.count
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.fetchedResultController.sections!.first!.numberOfObjects
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThumbnailCollectionViewCell
        let imageItem = self.fetchedResultController.object(at: indexPath)
        var shouldDownload = false
        
        cell.configure(withImageItem: imageItem, shouldDownload: &shouldDownload)
        
        if (shouldDownload) {
            self.downloadQueue.addDownload(imageItem: imageItem, completionBlock: { [unowned self] (status, identifier, managedObjectID, image) in
                if status == .downloaded {
                    self.reloadCell(forObjectID: managedObjectID, image: image!)
                }
            })
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return self.cellSize
    }
}
// MARK: - UICollectionViewDelegate

extension GalleryCollectionViewController {
    
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.searchTextField.isEditing {
            self.searchTextField.resignFirstResponder()
        } else {
            self.selectedIndex = indexPath
            self.performSegue(withIdentifier: StoryboardSegue.detail, sender: self)
        }
        
    }
}

// MARK: - Scroll view delegate

extension GalleryCollectionViewController {
    
    public override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let collectionView = self.collectionView else {
            return
        }
        if (collectionView.bounds.maxY >= collectionView.contentSize.height) {
            self.loadMoreItems()
        }
    }

}

// MARK: - Carousel View Controller Delegate

extension GalleryCollectionViewController: CarouselViewControllerDelegate {
    
    func carouselViewControllerDidReachLastItem(_ carouselController: CarouselViewController) {
        self.loadMoreItems()
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
            cell.loadImage(image)
        }
    }
    
    func loadMoreItems() {
        if !self.downloadingPage && self.morePages{
            self.downloadingPage = true
            self.lastPage = self.lastPage + 1
            self.listDownloadTask = self.downloadImageList(self.lastValidSearchTerm,
                                                           page: self.lastPage,
                                                           completionBlock: processPageSearchItems(success:imageDataItems:forSearchTerm:page:))
        }
    }
}

// MARK: - Data image download

extension GalleryCollectionViewController {
    func downloadImageList(_ searchTerm: String, page: Int = 0, completionBlock: @escaping (_ success: Bool, _ imageDataItems:[[String: Any]]?, _ searchTerm: String, _ page: Int) -> Void) -> URLSessionDataTask? {
        
        let urlString = String(format: URLPath.imageListFormat, searchTerm, page)
        guard let url = URL(string: urlString) else {
            completionBlock(false, nil, searchTerm, page)
            return nil
        }
        
        let request = NSMutableURLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue(ImgurCredentials.clientID, forHTTPHeaderField: HTTPHeaderName.authorization)
        
        let task = URLSession.shared.dataTask(with: request as URLRequest) { (data, response, error) in
            if let error = error {
                print("Error: \(error.localizedDescription)")
                completionBlock(false, nil, searchTerm, page)
                return
            }
            
            guard let response = response else{
                print("Error: There is no response")
                completionBlock(false, nil, searchTerm, page)
                return
            }
            if let responseCode = (response as? HTTPURLResponse)?.statusCode, responseCode != 200 {
                print("Error: The web service call was not successful (code:\(responseCode))")
                completionBlock(false, nil, searchTerm, page)
                return
            }
            
            guard let data = data else {
                print("Error: There is o data to decode")
                completionBlock(false, nil, searchTerm, page)
                return
            }
            
            do {
                guard let jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any] else{
                    print("Error: JSON structure not recognized.")
                    completionBlock(false, nil, searchTerm, page)
                    return
                }
                guard let imagesData = jsonData[JSONKey.data] as? [[String: Any]] else {
                    print("Error: JSON structure not recognized ('data' not found or not valid).")
                    completionBlock(false, nil, searchTerm, page)
                    return
                }
                completionBlock(true, imagesData, searchTerm, page)
            } catch {
                print("Error: \(error.localizedDescription)")
                completionBlock(false, nil, searchTerm, page)
            }
            
            
        }
        task.resume()
        return task
    }
    
    func processNewSearchItems(success: Bool, imageDataItems:[[String: Any]]?, forSearchTerm searchTerm: String, page: Int) {
        // If there was a page download, it was cancelled.
        self.downloadingPage = false
        self.lastPage = page
        self.morePages = true
        if !success {
            DispatchQueue.main.async {
                self.messageView.configure(withStatus: .error, searchTerm: searchTerm)
            }
        }
        // Check if there is data to set up
        guard let imageDataItems = imageDataItems, imageDataItems.count > 0 else{
            DispatchQueue.main.async {
                self.messageView.configure(withStatus: .noImages, searchTerm: searchTerm)
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
                self.dataController.insertImageItemDataArray(dataArray: imageDataItems){ (success, inserted, error) in
                    DispatchQueue.main.async {
                        if success {
                            self.lastValidSearchTerm = searchTerm
                            if !self.searchTextField.isEditing {
                                self.searchTextField.text = self.lastValidSearchTerm
                            }
                            self.messageView.configure(withStatus: .found, searchTerm: searchTerm)
                        } else {
                            self.messageView.configure(withStatus: .error, searchTerm: searchTerm)
                        }
                        self.reloadData(setDelegate: false)
                        print("New search results added: \(success)")
                    }
                }
            } else {
                self.reloadData(setDelegate: false)
                self.messageView.configure(withStatus: .error, searchTerm: searchTerm)
            }
        }
    }
    
    func processPageSearchItems(success: Bool, imageDataItems:[[String: Any]]?, forSearchTerm searchTerm: String, page: Int) {
        self.downloadingPage = false
        if !success {
            return
        }
        guard let imageDataItems = imageDataItems, imageDataItems.count > 0 else{
            print("No more pages to load")
            return
        }
        self.lastPage = page
        self.dataController.insertImageItemDataArray(dataArray: imageDataItems){ (success, inserted, error) in
            self.morePages = success && inserted > 0
            DispatchQueue.main.async {
                self.showingCarouselController?.loadControllers()
            }
            print("More page results added: \(success)")
        }
    }
}
