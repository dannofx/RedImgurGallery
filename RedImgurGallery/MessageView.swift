//
//  MessageView.swift
//  RedImgurGallery
//
//  Created by Danno on 8/8/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

enum MessageViewStatus {
    case error
    case noImages
    case searching
    case found
}

class MessageView: UIView {
    
    @IBOutlet weak var textLabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!

    func configure(withStatus status: MessageViewStatus, searchTerm: String = "") {
        if(self.isHidden) {
            self.backgroundColor = UIColor.clear
        }
        UIView.animate(withDuration: 0.5) {
            self.isHidden = false
            switch status {
            case .error:
                self.backgroundColor = #colorLiteral(red: 0.9294117647, green: 0.2352941176, blue: 0.3725490196, alpha: 1)
                self.textLabel.text = "Error loading: \(searchTerm)"
                self.activityView.stopAnimating()
                self.activityView.isHidden = true
            case .noImages:
                self.backgroundColor = #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1)
                self.textLabel.text = "No images for: \(searchTerm)"
                self.activityView.stopAnimating()
                self.activityView.isHidden = true
            case .searching:
                self.backgroundColor = #colorLiteral(red: 0.2392156869, green: 0.6745098233, blue: 0.9686274529, alpha: 1)
                self.textLabel.text = "Searching images for: \(searchTerm)"
                self.activityView.startAnimating()
                self.activityView.isHidden = false
            case .found:
                self.backgroundColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
                self.textLabel.text = "Images found for: \(searchTerm)"
                self.activityView.stopAnimating()
                self.activityView.isHidden = true
                
            }
        }
    }

}
