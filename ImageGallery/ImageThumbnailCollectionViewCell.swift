//
//  ImageThumbnailCollectionViewCell.swift
//  ImageGallery
//
//  Created by Ashish Bansal on 15/12/18.
//  Copyright © 2018 Ashish Bansal. All rights reserved.
//

import UIKit

protocol ImageThumbnailCellDelegate {
    func deleteCell(withId: Int)
}

class ImageThumbnailCollectionViewCell: UICollectionViewCell, UIContextMenuInteractionDelegate {
    
    enum CellState {
        case selectionModeOff, selectionModeOn, selected
    }
    
    var cellState = CellState.selectionModeOff {
        didSet {
            updateCellState()
        }
    }
    
    private func updateCellState() {
        switch cellState {
        case .selectionModeOff:
            selectionOverlayView.isHidden = true
            checkboxUncheckedImageView.isHidden = true
            checkboxCheckedImageView.isHidden = true
            
        case .selectionModeOn:
            selectionOverlayView.isHidden = true
            checkboxUncheckedImageView.isHidden = false
            checkboxCheckedImageView.isHidden = true
            
        case .selected:
            selectionOverlayView.isHidden = false
            checkboxCheckedImageView.isHidden = false
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupContextMenuInteraction()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupContextMenuInteraction()
    }
    
    private func setupContextMenuInteraction() {
        let contextMenuInteraction = UIContextMenuInteraction(delegate: self)
        addInteraction(contextMenuInteraction)
    }
    
    private var destinationViewForContextMenuActionDelete: UIView!
    
    private func createDestinationViewForContextMenuActionDelete() {
        destinationViewForContextMenuActionDelete = snapshotView(afterScreenUpdates: true)!
        
        destinationViewForContextMenuActionDelete.contentMode = .scaleAspectFit
        destinationViewForContextMenuActionDelete.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(destinationViewForContextMenuActionDelete)
        contentView.sendSubviewToBack(destinationViewForContextMenuActionDelete)
        NSLayoutConstraint.activate([
            destinationViewForContextMenuActionDelete.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            destinationViewForContextMenuActionDelete.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            destinationViewForContextMenuActionDelete.widthAnchor.constraint(equalToConstant: contentView.bounds.width/20),
            destinationViewForContextMenuActionDelete.heightAnchor.constraint(equalToConstant: contentView.bounds.height/20)
        ])
    }
    
    var deleteContextMenuInvoked = false
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, configurationForMenuAtLocation location: CGPoint) -> UIContextMenuConfiguration? {
        
        if cellState != .selectionModeOff {
            return nil
        }
        
        let trashImage = UIImage(systemName: "trash")
        let deleteAction = UIAction(title: "Delete", image: trashImage, identifier: nil, discoverabilityTitle: nil, attributes: .destructive, state: .off) { _ in
            self.deleteContextMenuInvoked = true
            if let cellId = self.cellId {
                self.delegate?.deleteCell(withId: cellId)
            }
        }
        
        let contextMenu = UIMenu(title: "", image: nil, identifier: nil, options: .destructive, children: [deleteAction])
        return UIContextMenuConfiguration(identifier: nil, previewProvider: nil) { suggestedActions in
            contextMenu
        }
    }
    
    func contextMenuInteraction(_ interaction: UIContextMenuInteraction, previewForDismissingMenuWithConfiguration configuration: UIContextMenuConfiguration) -> UITargetedPreview? {
        if deleteContextMenuInvoked {
            deleteContextMenuInvoked = false
            return UITargetedPreview(view: destinationViewForContextMenuActionDelete)
        }
        
        return nil
    }
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView! {
        didSet {
            activityIndicator(setTo: .off)
        }
    }
    
    var delegate: ImageThumbnailCellDelegate?
    var cellId: Int?    
    var imageUrl: String?
    {
        didSet {
            activityIndicator(setTo: .on)
            imageView.image = nil
            if let urlString = imageUrl {
                fetchImage(with: urlString)
            }
            
            if let destinationViewForDelete = destinationViewForContextMenuActionDelete {
                destinationViewForDelete.removeFromSuperview()
                destinationViewForContextMenuActionDelete = nil
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
                                self?.createDestinationViewForContextMenuActionDelete()
                            }
                        }
                    }
                }
            }
        }
    }
    
    //MARK: Related to selection of cell
    @IBOutlet weak var selectionOverlayView: UIView!
    @IBOutlet weak var checkboxUncheckedImageView: UIImageView!
    @IBOutlet weak var checkboxCheckedImageView: UIImageView!
    
    
}
