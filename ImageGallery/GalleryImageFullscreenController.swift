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
        scrollViewWidth.constant = view.bounds.width/2
        scrollViewHeight.constant = view.bounds.height/2
        scrollView.minimumZoomScale = calculateMinimumZoomScale()
        scrollView.maximumZoomScale = scrollView.minimumZoomScale * 3
        imageView.image = imageForFullscreen
    }
    
    func calculateMinimumZoomScale() -> CGFloat {
        if let imageSize = imageForFullscreen?.size {
            let scaleXValue = view.bounds.width/imageSize.width
            let scaleYValue = view.bounds.height/imageSize.height
            return min(scaleXValue, scaleYValue)
        }
        
        return 0.5
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewWidth.constant = scrollView.contentSize.width
        scrollViewHeight.constant = scrollView.contentSize.height
    }
    
    override func viewWillAppear(_ animated: Bool) {
        view.layoutIfNeeded()
        scrollView.zoom(to: imageView.bounds, animated: false)
    }
}
