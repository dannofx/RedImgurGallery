//
//  CarouselViewController.swift
//  RedImgurGallery
//
//  Created by Danno on 7/28/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit
import CoreData

protocol CarouselViewControllerDelegate: class {
    func carouselViewControllerDidReachLastItem(_ carouselController: CarouselViewController)
}

class CarouselViewController: UIPageViewController {
    
    var fetchedResultsController: NSFetchedResultsController<ImageItem>!
    var currentIndex: IndexPath!
    var indexToShow: IndexPath!
    fileprivate let preloadedControllersSize = 2 //for each side
    fileprivate let imageTypeToShow = ImageFileType.full
    fileprivate var downloadQueue: ImageDownloadQueue!
    fileprivate var pageControllers: [Int: DetailViewController]!
    var carouselDelegate: CarouselViewControllerDelegate?


    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        self.dataSource = self
        self.indexToShow = self.currentIndex
        self.downloadQueue = ImageDownloadQueue(imageFileType: self.imageTypeToShow)
        self.loadControllers()
    }
    
    func createPageControllers() {
        let totalSize = self.preloadedControllersSize * 2 + 1
        pageControllers = [Int: DetailViewController]()
        for i in 0..<totalSize {
            let controller = self.createController()
            pageControllers[i] = controller
        }
        self.refreshControllers(forMainIndex: self.currentIndex, forceReaload: true)
    }
    
    func loadControllers() {
        self.createPageControllers()
        self.loadCurrentController()
    }
    
    func refreshControllers(forMainIndex mainIndex: IndexPath, forceReaload: Bool = false) {
        
        let fetchedElements = self.fetchedResultsController.sections![0].numberOfObjects
        let index = mainIndex.row
        var min = index - preloadedControllersSize
        var max = index + preloadedControllersSize
        if max >= fetchedElements {
            min -= fetchedElements - max + 1
            max = fetchedElements - 1
        }
        if min < 0 {
            max += min * -1
            if max >= fetchedElements {
                max = fetchedElements - 1
            }
            min = 0
        }
        var freeControllers = self.pageControllers.filter { pair in pair.key < min || pair.key > max }
        for i in min...max {
            if self.pageControllers[i] == nil {
                let pair = freeControllers.first!
                self.pageControllers[i] = pair.value
                self.pageControllers.removeValue(forKey: pair.key)
                freeControllers.removeFirst()
                self.configureController(pair.value, forIndex: i)
            } else if forceReaload && i < fetchedElements {
                self.configureController(self.pageControllers[i]!, forIndex: i)
            }
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        print("Running low on memory!")
    }

    func createController() -> DetailViewController {
        let detailController = self.storyboard?.instantiateViewController(withIdentifier: StoryboardID.detail) as! DetailViewController
        detailController.downloadQueue = self.downloadQueue
        return detailController
    }
    
    func configureController(_ detailController: DetailViewController, forIndex index: Int) {
        let indexPath = IndexPath(row: index, section: 0)
        detailController.downloadQueue = self.downloadQueue
        detailController.index = indexPath
        detailController.imageItem = self.fetchedResultsController.object(at: indexPath)
    }
    
    func loadCurrentController() {
        if let detailViewController = self.pageControllers[self.currentIndex.row] {
            self.setViewControllers([detailViewController], direction: .forward, animated: false, completion: nil)
        }
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
            return self.pageControllers[row]
        } else {
            return nil
        }
    }
    
    public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        var row = self.currentIndex.row
        row += 1
        if row < self.fetchedResultsController.sections![0].numberOfObjects {
            return self.pageControllers[row]
        } else {
            // If this happens, the end was reached, so a search for more images should start
            self.carouselDelegate?.carouselViewControllerDidReachLastItem(self)
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
            self.refreshControllers(forMainIndex: self.currentIndex)
        }
    }
}
