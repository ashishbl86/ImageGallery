//
//  GalleryImageFullscreenController.swift
//  ImageGallery
//
//  Created by Ashish Bansal on 11/03/19.
//  Copyright © 2019 Ashish Bansal. All rights reserved.
//

import UIKit

class GalleryImageFullscreenController: UIViewController, UIScrollViewDelegate {

    var imageForFullscreen: UIImage?
    
    @IBOutlet weak var scrollView: UIScrollView! {
        didSet {
            scrollView.delegate = self
        }
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        scrollView.minimumZoomScale = 0.2
        scrollView.maximumZoomScale = 3
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewWidth.constant = scrollView.contentSize.width
        scrollViewHeight.constant = scrollView.contentSize.height
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.zoom(to: imageView.bounds, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let image = imageForFullscreen {
            imageView.image = image
        }
    }
}
