//
//  ImageDisplayViewControllerAnimationHandler.swift
//  ImageGallery
//
//  Created by Ashish Bansal on 13/03/20.
//  Copyright © 2020 Ashish Bansal. All rights reserved.
//

import UIKit

class ImageDisplayViewControllerAnimationHandler: NSObject, UIViewControllerAnimatedTransitioning {
    
    let transitionDuration: Double
    
    enum AnimationType {
        case showFullscreen, showThumbnails
    }
    
    private var animationType: AnimationType
    
    init(animationType: AnimationType) {
        self.animationType = animationType
        
        switch animationType {
        case .showFullscreen:
            transitionDuration = 0.5
        case .showThumbnails:
            transitionDuration = 0.3
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return transitionDuration
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        let fromVC = transitionContext.viewController(forKey: .from)
        let toVC = transitionContext.viewController(forKey: .to)
        
        let galleryVC: GalleryViewController!
        let fullscreenImageVC: GalleryImageFullscreenController!
        
        switch animationType {
        case .showFullscreen:
            galleryVC = fromVC as? GalleryViewController
            fullscreenImageVC = toVC as? GalleryImageFullscreenController
            
        case .showThumbnails:
            galleryVC = toVC as? GalleryViewController
            fullscreenImageVC = fromVC as? GalleryImageFullscreenController
        }
        
        if galleryVC == nil || fullscreenImageVC == nil {
            transitionContext.completeTransition(true)
            return
        }
        
        let toView = transitionContext.view(forKey: .to)!
        transitionContext.containerView.addSubview(toView)
        toView.layoutIfNeeded() //Required else frame info extracted from toView will not be correct. And this call has to be made after adding as the subview to container view
        
        if animationType == .showFullscreen {
            toView.isHidden = true
        }

        guard let thumbnailCellIndexPathInvolvedInTransition = galleryVC.collectionView.indexPathsForSelectedItems?.first else {
            transitionContext.completeTransition(true)
            return
        }
        
        guard let thumbnailCellInvolvedInTransition = galleryVC.collectionView.cellForItem(at: thumbnailCellIndexPathInvolvedInTransition)  else {
            transitionContext.completeTransition(true)
            return
        }
        
        let thumbnailImageFrameInContainer = transitionContext.containerView.convert(thumbnailCellInvolvedInTransition.bounds, from: thumbnailCellInvolvedInTransition)
        
        let blankView = UIView()
        blankView.backgroundColor = fullscreenImageVC.view.backgroundColor
        
        switch animationType {
        case .showFullscreen:
            blankView.frame = thumbnailImageFrameInContainer
        case .showThumbnails:
            blankView.frame = fullscreenImageVC.view.frame
        }
        
        transitionContext.containerView.addSubview(blankView)
        
        let fullscreenImageFrameInContainer = transitionContext.containerView.convert(fullscreenImageVC.imageView.bounds, from: fullscreenImageVC.imageView)
        let fullscreenImageSnapshot = fullscreenImageVC.imageView.snapshotView(afterScreenUpdates: animationType == .showFullscreen ? true : false)!
        fullscreenImageSnapshot.frame = fullscreenImageFrameInContainer
        
        let scaleFactorX = thumbnailImageFrameInContainer.width/fullscreenImageFrameInContainer.width
        let scaleFactorY = thumbnailImageFrameInContainer.height/fullscreenImageFrameInContainer.height
        let transformForFullscreenImageSizeToThumbnailSize = CGAffineTransform(scaleX: scaleFactorX, y: scaleFactorY)

        switch animationType {
        case .showFullscreen:
            fullscreenImageSnapshot.center = thumbnailImageFrameInContainer.center
            fullscreenImageSnapshot.transform = transformForFullscreenImageSizeToThumbnailSize
        case .showThumbnails:
            break
        }

        transitionContext.containerView.addSubview(fullscreenImageSnapshot)
        
        var dampingRatioForAnimation = CGFloat.zero
        
        //Intention is that the appearance of fullscreen should be a bit springy but from fullscreen back to thumbnail should be smooth
        switch self.animationType {
        case .showFullscreen:
            dampingRatioForAnimation = 0.75
        case .showThumbnails:
            dampingRatioForAnimation = 1.0
        }

        let transitionAnimation = UIViewPropertyAnimator(duration: transitionDuration, dampingRatio: dampingRatioForAnimation) { [unowned self] in
            switch self.animationType {
            case .showFullscreen:
                fullscreenImageSnapshot.center = fullscreenImageFrameInContainer.center
                fullscreenImageSnapshot.transform = CGAffineTransform.identity
                blankView.frame = fullscreenImageVC.view.frame
                
            case .showThumbnails:
                fullscreenImageSnapshot.center = thumbnailImageFrameInContainer.center
                fullscreenImageSnapshot.transform = transformForFullscreenImageSizeToThumbnailSize
                blankView.frame = thumbnailImageFrameInContainer
            }
        }

        transitionAnimation.addCompletion { _ in
            toView.isHidden = false //Redundant in case of .showThumbnails animation. As isHidden is already false for that.
            blankView.removeFromSuperview()
            fullscreenImageSnapshot.removeFromSuperview()
            transitionContext.completeTransition(true)
        }

        transitionAnimation.startAnimation()
    }
}
