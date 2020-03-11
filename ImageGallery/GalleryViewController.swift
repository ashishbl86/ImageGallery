//
//  GalleryViewController.swift
//  ImageGallery
//
//  Created by Ashish Bansal on 15/12/18.
//  Copyright © 2018 Ashish Bansal. All rights reserved.
//

import UIKit

class GalleryViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, UICollectionViewDragDelegate, UICollectionViewDropDelegate, ImageThumbnailCellDelegate
{
    func deleteCell(withId cellIdForDeletion: Int) {
        guard let deletionItemIndex = cellList.firstIndex(of: cellIdForDeletion) else {return}
        cellList.remove(at: deletionItemIndex)
        cellIdToImageInfo.removeValue(forKey: cellIdForDeletion)
        let indexPathOfCellToBeDeleted = IndexPath(item: deletionItemIndex, section: 0)
        collectionView.deleteItems(at: [indexPathOfCellToBeDeleted])
    }
    
    var imageGalleryDocument: ImageGalleryDocument!
    
    private var cellList = [Int]() {
        didSet {
            emptyGalleryMessageLabel.isHidden = !cellList.isEmpty
        }
    }
    
    private var cellIdToImageInfo = [Int:ImageInfo]()
    
    private var cellIdFactory = 0
    
    private func getNextCellId() -> Int {
        cellIdFactory += 1
        return cellIdFactory
    }
    
    private func removeCell(withId id: Int) {
        if let cellLocation = cellList.firstIndex(of: id) {
            cellList.remove(at: cellLocation)
            collectionView.deleteItems(at: [IndexPath(item: cellLocation, section: 0)])
        }
    }
    
    override func viewDidLoad() {
        assert(imageGalleryDocument != nil, "Image gallery's document is not set")
        imageGalleryDocument.open { isOpenedSuccessfully in
            if isOpenedSuccessfully {
                self.prepareGallery()
            }
            else {
                self.dismiss(animated: true)
            }
        }
        collectionView.dragInteractionEnabled = true
    }
    
    private func prepareGallery() {
        title = imageGalleryDocument.localizedName
        for image in imageGalleryDocument.galleryImageInfo {
            let newCellId = getNextCellId()
            cellList.append(newCellId)
            cellIdToImageInfo[newCellId] = image
            collectionView.reloadData()
        }
    }
    
    @IBOutlet weak var emptyGalleryMessageLabel: UILabel!
    
    @IBAction func closeGallery(_ sender: UIBarButtonItem) {
        imageGalleryDocument.galleryImageInfo = cellList.compactMap{
            let imageInfo = cellIdToImageInfo[$0]
            return imageInfo?.allInfoAvailable ?? false ? imageInfo : nil
        }
        imageGalleryDocument.updateChangeCount(.done)
        imageGalleryDocument.close { _ in
            self.dismiss(animated: true)
        }
    }
    
    private func didReceiveImageInfo(for id: Int, url: URL) {
        if let imageUrl = url.imageURLString {
            if var imageInfo = cellIdToImageInfo[id] {
                imageInfo.urlString = imageUrl
                cellIdToImageInfo[id] = imageInfo
                updateCellIfFeasible(with: id)
            }
        }
        else {
            removeCell(withId: id)
        }
    }
    
    private func didReceiveImageInfo(for id: Int, aspectRatio: CGFloat) {
        if var imageInfo = cellIdToImageInfo[id] {
            imageInfo.aspectRatio = aspectRatio
            cellIdToImageInfo[id] = imageInfo
            updateCellIfFeasible(with: id)
        }
    }
    
    private func updateCellIfFeasible(with id: Int) {
        if let cellImageInfo = cellIdToImageInfo[id], cellImageInfo.allInfoAvailable {
            let cellLocation = cellList.firstIndex(of: id)!
            collectionView.reloadItems(at: [IndexPath(item: cellLocation, section: 0)])
        }
    }
    
    private lazy var originalCellWidth: CGFloat = {
        if let collectionViewLayout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            return collectionViewLayout.itemSize.width
        }
        return 0
    }()
    
    private var cellSizeScaleFactor: CGFloat = 1
    private var minimumWidthOfCell: CGFloat = 100
    
    @IBOutlet weak var collectionView: UICollectionView! {
        didSet {
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.dragDelegate = self
            collectionView.dropDelegate = self
            
            let pinchRecognizer = UIPinchGestureRecognizer(target: self, action: #selector(pinchPerformed(recognizer:)))
            collectionView.addGestureRecognizer(pinchRecognizer)
        }
    }
    
    @objc private func pinchPerformed(recognizer: UIPinchGestureRecognizer) {
        switch recognizer.state {
        case .changed, .ended:
            cellSizeScaleFactor *= recognizer.scale
            recognizer.scale = 1
            collectionView.collectionViewLayout.invalidateLayout()
        default:
            break
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return cellList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ImageThumbnail", for: indexPath)
        if let thumbnailCell = cell as? ImageThumbnailCollectionViewCell {
            let cellId = cellList[indexPath.item]
            thumbnailCell.cellId = cellId
            thumbnailCell.imageUrl = cellIdToImageInfo[cellId]?.urlString
            thumbnailCell.delegate = self
            thumbnailCell.cellState = getCellState(atIndexPath: indexPath)
            return thumbnailCell
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        if selectModeEnabled {
            return []
        }
        
        session.localContext = collectionView
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        return [dragItem]
    }
    
    func collectionView(_ collectionView: UICollectionView, canHandle session: UIDropSession) -> Bool {
        if selectModeEnabled {
            return false
        }
        
        let canAcceptDragFromOutside = session.canLoadObjects(ofClass: NSURL.self) && session.canLoadObjects(ofClass: UIImage.self)
        var canAcceptDragFromWithin = false
        if let dragOriginView = session.localDragSession?.localContext as? UICollectionView, dragOriginView == collectionView {
            canAcceptDragFromWithin = true
        }
        
        return canAcceptDragFromOutside || canAcceptDragFromWithin
    }
    
    func collectionView(_ collectionView: UICollectionView, dropSessionDidUpdate session: UIDropSession, withDestinationIndexPath destinationIndexPath: IndexPath?) -> UICollectionViewDropProposal {
        var dragOriginatedFromItself = false
        if let dragOriginView = session.localDragSession?.localContext as? UICollectionView, dragOriginView == collectionView {
            dragOriginatedFromItself = true
        }
        return UICollectionViewDropProposal(operation: dragOriginatedFromItself ? .move : .copy, intent: .insertAtDestinationIndexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, performDropWith coordinator: UICollectionViewDropCoordinator) {
        for item in coordinator.items {
            if let sourceIndexPath = item.sourceIndexPath {
                let movedCellId = cellList.remove(at: sourceIndexPath.item)
                cellList.insert(movedCellId, at: coordinator.destinationIndexPath!.item)
                collectionView.moveItem(at: sourceIndexPath, to: coordinator.destinationIndexPath!)
                coordinator.drop(item.dragItem, toItemAt: coordinator.destinationIndexPath!)
            }
            else {
                let droppedImageCellId = getNextCellId()
                let droppedItemIndexPath = coordinator.destinationIndexPath ?? getLastIndexPath(of: collectionView)
                cellList.insert(droppedImageCellId, at: droppedItemIndexPath.item)
                cellIdToImageInfo[droppedImageCellId] = ImageInfo()
                
                item.dragItem.itemProvider.loadObject(ofClass: NSURL.self) { [weak self] (data, error) in
                    DispatchQueue.main.async {
                        if let url = data as? URL {
                            self?.didReceiveImageInfo(for: droppedImageCellId, url: url)
                        }
                    }
                }
                
                item.dragItem.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (data, error) in
                    DispatchQueue.main.async {
                        if let image = data as? UIImage {
                            let imageAspectRatio = image.size.height/image.size.width
                            self?.didReceiveImageInfo(for: droppedImageCellId, aspectRatio: imageAspectRatio)
                        }
                    }
                }
                
                collectionView.insertItems(at: [droppedItemIndexPath])
                coordinator.drop(item.dragItem, toItemAt: droppedItemIndexPath)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let cellId = cellList[indexPath.item]
        let cellAspectRatio = cellIdToImageInfo[cellId]?.aspectRatio ?? 1
        let cellWidth = (originalCellWidth * cellSizeScaleFactor).bounded(byLowerBound: minimumWidthOfCell, upperBound: collectionView.bounds.width) //min(originalCellWidth * cellSizeScaleFactor, collectionView.bounds.width)
        let cellHeight = cellAspectRatio * cellWidth
        return CGSize(width: cellWidth, height: cellHeight)
    }
    
    private func getLastIndexPath(of collectionView: UICollectionView) -> IndexPath {
        return IndexPath(item: collectionView.numberOfItems(inSection: 0), section: 0)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedCell = collectionView.cellForItem(at: indexPath), let selectedImageCell = selectedCell as? ImageThumbnailCollectionViewCell else {fatalError()}
        
        switch selectedImageCell.cellState {
        case .selectionModeOff:
            if let selectedCellImage = selectedImageCell.imageView.image {
                performSegue(withIdentifier: "ShowFullscreenImage", sender: selectedCellImage)
            }
            
        case .selectionModeOn:
            selectedImageCell.cellState = .selected
            cellsSelectedForDeletion.append(indexPath)
            
        case .selected:
            selectedImageCell.cellState = .selectionModeOn
            cellsSelectedForDeletion.removeAll { $0 == indexPath }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowFullscreenImage" {
            if let selectedImage = sender as? UIImage, let fullscreenViewController = segue.destination as? GalleryImageFullscreenController {
                fullscreenViewController.imageForFullscreen = selectedImage
            }
        }
    }
    
    //MARK: Deletion of multiple items.
    
    var cellsSelectedForDeletion = [IndexPath]() {
        didSet {
            updateToolbarItems()
        }
    }
    
    var selectModeEnabled = false {
        didSet {
            selectModeToggled()
        }
    }
    
    private func updateToolbarItems() {
        if cellsSelectedForDeletion.isEmpty {
            selectedItemsLabel.title = "Select Items"
            deleteButton.isEnabled = false
        }
        else {
            selectedItemsLabel.title = "\(cellsSelectedForDeletion.count) item(s) selected"
            deleteButton.isEnabled = true
        }
    }
    
    private func selectModeToggled() {
        switch selectModeEnabled {
        case true:
            selectItemsButton.title = "Cancel"
            toolbar.isHidden = false
            collectionView.visibleCells.forEach { collectionViewCell in
                if let imageThumbnailCell = collectionViewCell as? ImageThumbnailCollectionViewCell {
                    imageThumbnailCell.cellState = .selectionModeOn
                }
            }
        case false:
            selectItemsButton.title = "Select"
            cellsSelectedForDeletion.removeAll()
            toolbar.isHidden = true
            collectionView.visibleCells.forEach { collectionViewCell in
                if let imageThumbnailCell = collectionViewCell as? ImageThumbnailCollectionViewCell {
                    imageThumbnailCell.cellState = .selectionModeOff
                }
            }
        }
    }
    
    @IBOutlet weak var selectItemsButton: UIBarButtonItem!
    @IBAction func selectItemsForDeletion(_ sender: UIBarButtonItem) {
        selectModeEnabled.toggle()
    }
    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var selectedItemsLabel: UIBarButtonItem! {
        didSet {
            let titleTextAttributes = [NSAttributedString.Key.foregroundColor:UIColor.black]
            selectedItemsLabel.setTitleTextAttributes(titleTextAttributes, for: .disabled)
        }
    }
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    @IBAction func deleteSelectedImages(_ sender: UIBarButtonItem) {
        //Sorting in decreasing order as items in array should be deleted in decreasing order of index.
        //Deletion otherwise will result in shifting of indexes and can throw out of range exception.
        
        cellsSelectedForDeletion.sort { (lhs, rhs) in
            return lhs.item > rhs.item
        }
        cellsSelectedForDeletion.forEach { indexPath in
            let removedCellId = cellList.remove(at: indexPath.item)
            cellIdToImageInfo.removeValue(forKey: removedCellId)
        }
        collectionView.deleteItems(at: cellsSelectedForDeletion)
        selectModeEnabled.toggle()
    }
    
    private func getCellState(atIndexPath indexPath: IndexPath) -> ImageThumbnailCollectionViewCell.CellState {
        switch selectModeEnabled {
        case true:
            let cellSelectedForDeletion = cellsSelectedForDeletion.contains(indexPath)
            return cellSelectedForDeletion ? .selected : .selectionModeOn
        case false:
            return .selectionModeOff
        }
    }
}

extension URL {
    var imageURLString: String? {
        // check to see if there is an embedded imgurl reference
        for query in query?.components(separatedBy: "&") ?? [] {
            let queryComponents = query.components(separatedBy: "=")
            if queryComponents.count == 2 {
                if queryComponents[0] == "imgurl", let urlString = queryComponents[1].removingPercentEncoding {
                    return urlString
                }
            }
        }
        return nil
    }
}

extension UICollectionView {
    func reloadVisibleCells() {
        reloadItems(at: indexPathsForVisibleItems)
    }
}

extension CGFloat {
    func bounded(byLowerBound lowerBound: CGFloat, upperBound: CGFloat) -> CGFloat {
        precondition(lowerBound <= upperBound, "Bound values are invalid. Lower bound is more than upper bound")
        
        if self < lowerBound {
            return lowerBound
        }
        
        if self > upperBound {
            return upperBound
        }
        
        return self
    }
}

//extension Array {
//    subscript(safe index: Array.Index) -> Element? {
//        return indices.contains(index) ? self[index] : nil
//    }
//}

//Model should be just a list of unique identifiers
//Have a dictionary of the unique ids to image info i.e. aspect ratio and URL
//Cell should only have the URL
//On dropping of data, create a new id and pass it to the provider's completion handlers
    //Also add the unique id to the model, tell the collection view about new cell and finish the drop animation
//provider completion closure will call methods of controller in main queue when their data gets available. Ideally it should be in the background queue but as all background queues are concurrent, check the synchronization so that both completion closures don't delete each other's data.
//Controller will receive the data and for each element receive, it will check if the image info is complete. (For this, add computed var in the image info struct)
//If complete, then check if the item is still visible, if yes then call the reload item OR try to directly also call the reload item and see if the item is reloaded even if it's not visible
//Thats it
