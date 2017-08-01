//
//  CarouselViewController.swift
//  RedImgurGallery
//
//  Created by Danno on 7/28/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

class CarouselViewController: UIPageViewController {
    
    var fetchedResultsController: NSFetchedResultsController<ImageItem>!
    var currentIndex: IndexPath!
    var indexToShow: IndexPath!
    fileprivate let imageTypeToShow = ImageFileType.full
    fileprivate var downloadQueue: ImageDownloadQueue!


    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.dataSource = self
        self.indexToShow = self.currentIndex
        self.downloadQueue = ImageDownloadQueue(imageFileType: self.imageTypeToShow)
        self.loadCurrentController()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    @IBAction func finish(_ sender: Any) {
        self.loadCurrentController()
    }
    
    func createController(forIndex index: IndexPath) -> DetailViewController {
        let detailController = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.detail) as! DetailViewController
        detailController.index = index
        detailController.downloadQueue = self.downloadQueue
        detailController.imageItem = self.fetchedResultsController.object(at: index)
        print("TITLE \(detailController.imageItem.title)")
        return detailController
    }
    
    func loadCurrentController() {
        let detailViewController = self.createController(forIndex: self.currentIndex)
        self.setViewControllers([detailViewController], direction: .forward, animated: false, completion: nil)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
}

// MARK: - Page View Controller Data Source

extension CarouselViewController: UIPageViewControllerDataSource {
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        var row = self.currentIndex.row
        row -= 1
        if row >= 0 {
            let newIndex = IndexPath.init(row: row, section: 0)
            return self.createController(forIndex: newIndex)
        } else {
            return nil
        }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var row = self.currentIndex.row
        row += 1
        if row < self.fetchedResultsController.sections![0].numberOfObjects {
            let newIndex = IndexPath.init(row: row, section: 0)
            return self.createController(forIndex: newIndex)
        } else {
            return nil
        }
    }
}

// MARK: - Page View Controller Delegate

extension CarouselViewController: UIPageViewControllerDelegate {
    
    public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        if let index = (pendingViewControllers[0] as! DetailViewController).index {
            self.indexToShow = index
        }
    }
    public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if (self.indexToShow != self.currentIndex) {
            self.currentIndex =  self.indexToShow
        }
    }
}
