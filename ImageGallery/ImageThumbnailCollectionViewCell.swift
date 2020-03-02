//
//  ImageThumbnailCollectionViewCell.swift
//  ImageGallery
//
//  Created by Ashish Bansal on 15/12/18.
//  Copyright © 2018 Ashish Bansal. All rights reserved.
//

import UIKit

class ImageThumbnailCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator(setTo: .off)
        }
    }
    
    var imageUrl: String?
    {
        didSet {
            activityIndicator(setTo: .on)
            imageView.image = nil
            if let urlString = imageUrl {
                fetchImage(with: urlString)
            }
        }
    }
    
    enum ActivityIndicatorState {
        case on, off
    }
    
    private func activityIndicator(setTo state: ActivityIndicatorState) {
        switch state {
        case .on:
            if activityIndicator.isAnimating == false {
                activityIndicator.startAnimating()
            }
            if activityIndicator.isHidden {
                activityIndicator.isHidden = false
            }
        case .off:
            if activityIndicator.isAnimating == true {
                activityIndicator.stopAnimating()
            }
            if activityIndicator.isHidden == false {
                activityIndicator.isHidden = true
            }
        }
    }
    
    private func fetchImage(with urlString: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            if let imageUrl = URL(string: urlString) {
                if let imageData = try? Data(contentsOf: imageUrl){
                    if let image = UIImage(data: imageData) {
                        DispatchQueue.main.async { [weak self] in
                            if self?.imageUrl == urlString {
                                self?.activityIndicator(setTo: .off)
                                self?.imageView.image = image
                            }
                        }
                    }
                }
            }
        }
    }
}
