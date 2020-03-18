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
    
    let imageView = UIImageView()
    @IBOutlet weak var scrollViewWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollViewHeight: NSLayoutConstraint!
    
    var navigationControllerHidesBarOnTapDefaultValue = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.minimumZoomScale = 1
        scrollView.maximumZoomScale = 3
        imageView.image = imageForFullscreen
        imageView.contentMode = .scaleAspectFit
        scrollView.addSubview(imageView)
        
        navigationControllerHidesBarOnTapDefaultValue = navigationController?.hidesBarsOnTap ?? false
        navigationController?.hidesBarsOnTap = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        navigationController?.hidesBarsOnTap = navigationControllerHidesBarOnTapDefaultValue
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    var lastViewSizeAtLayoutSubviews = CGRect.zero
    var contentAreaPrepared = false
    
    override func viewWillLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if !contentAreaPrepared {
            let sizeForImageView = computeSizeOf(imageForFullscreen!.size, toFitIn: view.bounds.size, withScaleFactor: scrollView.zoomScale)
            imageView.frame = CGRect(origin: CGPoint.zero, size: sizeForImageView)
            scrollView.contentSize = sizeForImageView
            contentAreaPrepared = true
        }
        
        if view.bounds != lastViewSizeAtLayoutSubviews {
            lastViewSizeAtLayoutSubviews = view.bounds
            scrollViewWidth.constant = scrollView.contentSize.width
            scrollViewHeight.constant = scrollView.contentSize.height
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if (scrollView.zoomScale == 1) {
            scrollView.contentOffset = CGPoint.zero
        }
        view.backgroundColor = (navigationController?.isNavigationBarHidden ?? false) ? .black : .white
        scrollView.backgroundColor = view.backgroundColor
    }
    
    private func computeSizeOf(_ sizeOfItemToFit: CGSize, toFitIn sizeOfFrameFitIn: CGSize, withScaleFactor scaleFactor: CGFloat) -> CGSize {
        let aspectRatioOfItem = sizeOfItemToFit.aspectRatio
        let aspectRatioOfFrame = sizeOfFrameFitIn.aspectRatio
        
        var sizeFittingForItem = CGSize.zero
        
        if aspectRatioOfItem >= aspectRatioOfFrame {
            sizeFittingForItem.width = sizeOfFrameFitIn.width
            sizeFittingForItem.height = sizeOfFrameFitIn.width / aspectRatioOfItem
        }
        else {
            sizeFittingForItem.height = sizeOfFrameFitIn.height
            sizeFittingForItem.width = sizeOfFrameFitIn.height * aspectRatioOfItem
        }
        
        sizeFittingForItem.width *= scaleFactor
        sizeFittingForItem.height *= scaleFactor
        
        return sizeFittingForItem
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        scrollViewWidth.constant = scrollView.contentSize.width
        scrollViewHeight.constant = scrollView.contentSize.height
    }
}

extension CGSize {
    var aspectRatio: CGFloat {
        return width/height
    }
}
