//
//  DocumentBrowserViewController.swift
//  ImageGallery_Persistent
//
//  Created by Ashish Bansal on 10/04/19.
//  Copyright © 2019 Ashish Bansal. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate, UIViewControllerTransitioningDelegate {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
        //allowsDocumentCreation = false
        allowsPickingMultipleItems = false
        
        //if UIDevice.current.userInterfaceIdiom == .pad {
        template = try? FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("Untitled.json")
        if let template = template {
            let jsonString = #"[{"urlString":"https:\/\/cosmos-images2.imgix.net\/file\/spina\/photo\/14772\/GettyImages-691120979.jpg?ixlib=rails-2.1.4&auto=format&ch=Width%2CDPR&fit=max&w=835","aspectRatio":0.74903474903474898},{"urlString":"https:\/\/www.sciencemag.org\/sites\/default\/files\/styles\/inline__450w__no_aspect\/public\/NationalGeographic_1561927_16x9.jpg?itok=q7LvZb-6","aspectRatio":0.56000000000000005},{"urlString":"https:\/\/www.drusillas.co.uk\/images\/whats-on-card\/redpanda-profile-400x400-984.jpg","aspectRatio":0.62323943661971826},{"urlString":"https:\/\/cdn.britannica.com\/s:900x675\/80\/140480-131-28E57753.jpg","aspectRatio":0.74903474903474898},{"urlString":"https:\/\/img.jakpost.net\/c\/2018\/11\/28\/2018_11_28_59557_1543397471._large.jpg","aspectRatio":0.66909090909090907}]"#
            let sampleData = Data(jsonString.utf8)
            allowsDocumentCreation = FileManager.default.createFile(atPath: template.path, contents: sampleData)
        }
        //}
    }
    
    var template: URL?
    
    // MARK: UIDocumentBrowserViewControllerDelegate
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
        importHandler(template, .copy)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
        guard let sourceURL = documentURLs.first else { return }
        
        // Present the Document View Controller for the first document that was picked.
        // If you support picking multiple items, make sure you handle them all.
        presentDocument(at: sourceURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
        // Present the Document View Controller for the new newly created document
        presentDocument(at: destinationURL)
    }
    
    func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
        // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
    }
    
    // MARK: Document Presentation
    
    var currentlyPresentedDocumentUrl: URL!
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transitionAnimator = transitionController(forDocumentAt: currentlyPresentedDocumentUrl)
        transitionAnimator.targetView = presented.view.snapshotView(afterScreenUpdates: false)
        return transitionAnimator
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let transitionAnimator = transitionController(forDocumentAt: currentlyPresentedDocumentUrl)
        transitionAnimator.targetView = dismissed.view.snapshotView(afterScreenUpdates: false)
        return transitionAnimator
    }
    
    func presentDocument(at documentURL: URL) {
        currentlyPresentedDocumentUrl = documentURL
        let storyBoard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyBoard.instantiateViewController(withIdentifier: "ImageGallery")
        if let imageGalleryNVC = viewController as? UINavigationController, let imageGalleryVC = imageGalleryNVC.viewControllers.first as? GalleryViewController {
            imageGalleryNVC.transitioningDelegate = self
            imageGalleryVC.imageGalleryDocument = ImageGalleryDocument(fileURL: documentURL)
            imageGalleryNVC.modalPresentationStyle = .fullScreen
            present(imageGalleryNVC, animated: true)
        }
    }
}
