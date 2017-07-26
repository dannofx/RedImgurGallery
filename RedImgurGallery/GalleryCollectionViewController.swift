//
//  GalleryCollectionViewController.swift
//  RedImgurGallery
//
//  Created by Danno on 7/25/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

private let reuseIdentifier = "Cell"

class GalleryCollectionViewController: UICollectionViewController {
    
    var dataController: DataController!

    override func viewDidLoad() {
        super.viewDidLoad()
        dataController = DataController()
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes
        self.collectionView!.register(UICollectionViewCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        self.downloadImageList()
    }
    
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
                print("An error occurred: \(error.localizedDescription)")
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
                print("JSON data \(imagesData)")
                self.dataController.insertImageDataArray(dataArray: imagesData, completion: { (success, error) in
                    print("Success?! \(success)")
                })
                
            } catch {
                print("Error: \(error.localizedDescription)")
            }
            
            
        }
        
        task.resume()
    }
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        return 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath)
    
        // Configure the cell
    
        return cell
    }

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */

}
