//
//  SearchHeaderView.swift
//  RedImgurGallery
//
//  Created by Danno on 8/9/17.
//  Copyright © 2017 Daniel Heredia. All rights reserved.
//

import UIKit

class SearchHeaderView: UIView {
    
    @IBOutlet weak var cancelSearchButton: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var separatorView: UIView!
    @IBOutlet weak var messageView: MessageView!
    
    fileprivate var searchTextFieldHeight: CGFloat!
    fileprivate var cancelSearchButtonHeight: CGFloat!
    fileprivate var separatorViewHeight: CGFloat!
    fileprivate var messageViewHeight: CGFloat!
    fileprivate var cancelSearchButtonWidth: CGFloat!
    
    fileprivate var showingCancelButton: Bool

    required init?(coder aDecoder: NSCoder) {
        showingCancelButton = false
        super.init(coder: aDecoder)
    }

    override func awakeFromNib() {
        self.searchTextFieldHeight = self.searchTextField.frame.height
        self.cancelSearchButtonHeight = self.cancelSearchButton.frame.height
        self.separatorViewHeight = self.separatorView.frame.height
        self.messageViewHeight = self.messageView.frame.height
        self.cancelSearchButtonWidth = self.cancelSearchButton.frame.width
        self.cancelSearchButton.layer.cornerRadius = 3.0
        
        let searchImage = #imageLiteral(resourceName: "search").withRenderingMode(.alwaysTemplate)
        let searchImageView = UIImageView(image: searchImage)
        searchImageView.tintColor = #colorLiteral(red: 0.4666666687, green: 0.7647058964, blue: 0.2666666806, alpha: 1)
        self.searchTextField.leftViewMode = .always
        self.searchTextField.leftView = searchImageView
        self.translatesAutoresizingMaskIntoConstraints = false

    }
    
    func updateLayout(superViewSize: CGSize? = nil) {
        
        let mainFrame = self.frame
        let superSize: CGSize!
        if superViewSize == nil {
            superSize = mainFrame.size
        } else {
            superSize = superViewSize!
        }
        self.frame = CGRect(origin: CGPoint(x: 0, y: 0), size: superSize)
        let padding: CGFloat = 12.0
        self.adjustCancelButton()
        self.separatorView.frame = CGRect(x: -padding,
                                          y: superSize.height - self.separatorViewHeight ,
                                          width: superSize.width + padding,
                                          height: self.separatorViewHeight)
        self.messageView.frame = CGRect(x: -padding,
                                        y: superSize.height,
                                        width: superSize.width + padding,
                                        height: self.messageViewHeight)
        self.messageView.updateLayout()
    }
    
    func showCancelOptions(_ show: Bool) {
        if showingCancelButton == show {
            return
        }
        showingCancelButton = show
        UIView.animate(withDuration: 0.5) { 
            self.adjustCancelButton()
        }
    }
    
    private func adjustCancelButton() {
        let mainFrame = self.frame
        let padding: CGFloat!
        let buttonLength: CGFloat!
        if showingCancelButton {
            buttonLength = self.cancelSearchButtonWidth
            padding = mainFrame.width * 0.05
        } else {
            buttonLength = 0
            padding = 0
        }
        self.searchTextField.frame = CGRect(x: 0,
                                             y: mainFrame.height/2 - self.searchTextFieldHeight/2,
                                             width: (mainFrame.width - buttonLength - padding),
                                             height: min(self.searchTextFieldHeight, mainFrame.height))
        self.cancelSearchButton.frame = CGRect(x: self.searchTextField.frame.origin.x + self.searchTextField.frame.width,
                                               y: self.searchTextField.frame.midY - self.cancelSearchButtonHeight/2,
                                               width: buttonLength,
                                               height: self.cancelSearchButtonHeight)
    }

}
