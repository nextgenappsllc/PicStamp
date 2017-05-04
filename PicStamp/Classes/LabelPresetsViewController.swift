//
//  LabelPresetsViewController.swift
//  Pic Stamp
//
//  Created by Jose Castellanos on 5/31/16.
//  Copyright © 2016 NextGen Apps LLC. All rights reserved.
//

import Foundation
import NGAEssentials
import NGAUI
import Photos



open class LabelPresetsViewController: NGACollectionViewController,LabelOptionsViewControllerDelegate {
    open var progressView:LabelProgressView? {
        didSet {
            if oldValue != progressView {
                NGAExecute.performOnMainQueue {
                    oldValue?.removeFromSuperview()
                    self.progressView?.frame = self.contentView.bounds
                    self.contentView.addSubviewIfNeeded(self.progressView)
                }
            }
            
        }
    }
    open lazy var addButton:UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addButtonPressed))
    }()
    open lazy var cancelButton:UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
    }()
    open lazy var editButton:UIBarButtonItem = {
        UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editButtonPressed))
    }()
    open var labelOptions:[LabelOption] = [] {
        didSet {
            reloadCollectionViewOnMainThread()
        }
    }
    open var photos:[PHAsset] = []
    open var albumName = "Pic Stamp"
    open var cellsEditing = false
    open var cellFont = PicStampConfig.defaultFont
    open var cellWidth:CGFloat {get{return collectionView.frameWidth * 0.95}}
    open var cancel = false
    open override func registerClasses() {
        collectionView.registerCellClasses(["Cell": LabelPresetsCell.self])
    }
    
    open override func setup() {
        super.setup()
        title = "Choose label preset"
        navigationItem.leftBarButtonItem = cancelButton
        navigationItem.rightBarButtonItems = [addButton, editButton]
        collectionView.alwaysBounceVertical = true
        cellFont = cellFont.withSize(NGADevice.remSizeFor(collectionView))
        collectionView.backgroundColor = UIColor.darkGray
    }
    
    
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        labelOptions = LabelOptionModel.allLabelOptions()
        if labelOptions.count == 0 {
            flashDirections()
        }
        
    }
    
    open func flashDirections() {
        flash(title: "Directions", message: "You currently have no saved presets. Simply tap the plus sign in the top right to configure options and then save it for future use by pressing done and naming it something unique. Saved ones will appear here. You can then tap a saved preset and all the pictures will be labeled according to those options.", cancelTitle: "Ok")
    }
    
    open override func setFramesForSubviews() {
        super.setFramesForSubviews()
        progressView?.frame = contentView.bounds
    }
    
    open func labelOptionViewControllerFinished(index:Int?, labelOption:LabelOption) {
        if let index = index {
            labelOptions =  labelOptions.safeSet(index, toElement: labelOption)
        } else {
            labelOptions = labelOptions.appendIfNotNil(labelOption)
        }
    }
    
    open override func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return labelOptions.count
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        guard let c = cell as? LabelPresetsCell, let labelOption = labelOptions.itemAtIndex(indexPath.row) else {return cell}
        c.editing = cellsEditing
        c.textLabel.font = cellFont
        c.textLabel.text = labelOption.name
        c.contentView.backgroundColor = UIColor(hexString: "eeeeee")
        c.editButton.callBack = {[weak self] in
            guard let labelOption = self?.labelOptions.itemAtIndex(indexPath.row) else {return}
            let nextVC = LabelOptionsViewController()
            nextVC.labelOptionsDelegate = self
            nextVC.labelOption = labelOption
            nextVC.labelOptionIndex = indexPath.row
            nextVC.needsLabelPosition = true
            nextVC.needsName = true
            self?.pushToViewController(nextVC)
            
        }
        c.deleteButton.callBack = {[weak self] in
            self?.flash(title: "Confirm delete", message: "Are you sure you want to delete \(labelOption.name?.surround(prefix: "\"", postfix: "\"") ?? "this label preset")?", cancelTitle: "Cancel", actions: UIAlertAction(title: "Delete", style: .destructive, handler: { (action) in
                guard labelOption.delete(), let s = self else {return}
                s.labelOptions.safeRemove(indexPath.row)
                s.reloadCollectionViewOnMainThread()
            }))

        }
        return c
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: IndexPath) {
        promptForPhotosProcess(indexPath: indexPath)
        
    }
    
    
    
    
    open override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: cellWidth, height:  heightForIndexPath(indexPath: indexPath))
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 10, left: 0, bottom: 10, right: 0)
    }
    
    open func heightForIndexPath(indexPath:IndexPath) -> CGFloat {
        let minimum:CGFloat = 50
        guard let labelOption = labelOptions.itemAtIndex(indexPath.row) else {return minimum}
        let label = UILabel()
        label.numberOfLines = 0
        let width:CGFloat = max((cellWidth - (40 * (cellsEditing ? 2 : 1))) * 0.97,0)
        label.frameSize = CGSize(width: width, height:  minimum)
        label.text = labelOption.name
        label.font = cellFont
        label.sizeToFitY()
        return max(label.frameHeight + 10, minimum)
    }
    
    open func addButtonPressed() {
        let nextVC = LabelOptionsViewController()
        nextVC.labelOptionsDelegate = self
        nextVC.needsLabelPosition = true
        nextVC.needsName = true
        pushToViewController(nextVC)
        
        
    }
    
    open func editButtonPressed() {
        cellsEditing = !cellsEditing
        collectionView.collectionViewLayout.invalidateLayout()
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            for cell in self.collectionView.visibleCells {
                if let c = cell as? LabelPresetsCell {
                    let indexPath = self.collectionView.indexPath(for: c) ?? IndexPath(item: 0, section: 0)
                    c.frameSize = self.collectionView(self.collectionView, layout: self.collectionView.collectionViewLayout, sizeForItemAt: indexPath)
                    c.editing = self.cellsEditing
                }
            }
            }) { (b) in
                self.collectionView.reloadData()
        }
    }
    
    open func cancelButtonPressed() {
        cancel = true
        dismiss(animated: true, completion: nil)
    }
    
    open func photoAlbum() -> PHAssetCollection? {
        let opts = PHFetchOptions()
        opts.predicate = NSPredicate(format: "title = %@", albumName)
        var album = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: opts).firstObject
        guard album == nil else {return album}
        let _ = try? PHPhotoLibrary.shared().performChangesAndWait() {
            let request = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumName)
            album =? request.placeholderForCreatedAssetCollection
        }
        return album ?? PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: opts).firstObject
    }
    
    open func promptForPhotosProcess(indexPath:IndexPath) {
        let compressAction = UIAlertAction(title: "Compress", style: .default, handler: {a in
            self.processPhotos(labelOption: self.labelOptions.itemAtIndex(indexPath.row), compressTo: 1024)
        })
        let fullSizeAction = UIAlertAction(title: "Original", style: .default, handler: {a in
            self.processPhotos(labelOption: self.labelOptions.itemAtIndex(indexPath.row))
        })
        flash(title: "Export Options", message: "Please select if you would like the image to be compressed or original quality before processing your image batch with the selected label option.", cancelTitle: "Cancel", actions: compressAction, fullSizeAction)
    }
    
    open func processPhotos(labelOption:LabelOption?, compressTo:CGFloat? = nil) {
        guard let labelOption = labelOption else {return}
        self.disableButtons()
        var completed = 0
        var retrieved = 0
        let count = photos.count
        if progressView == nil && count > 0 {
            progressView = LabelProgressView()
            progressView?.progressText = "Processing..."
            progressView?.cancelButtonTitle = "Stop"
            progressView?.cancelButton.setTitleColor(UIColor(hexString:"3385ff"), for: .normal)
            progressView?.cancelBlock = {[weak self] in
                self?.cancel = true
                self?.enableButtons()
                self?.progressView = nil
            }
        }
        let opts = PHImageRequestOptions()
        opts.isNetworkAccessAllowed = true
        opts.isSynchronous = true
        DispatchQueue(label: "BatchPictureQueue", qos: .background, attributes: [], autoreleaseFrequency: .inherit, target: nil).async { [weak self] in
            defer {
                self?.progressView = nil
                self?.cancel = false
                self?.enableButtons()
            }
            guard let photos = self?.photos else {return}
            for photo in photos {
                if self?.cancel ?? false {break}
                var txt = ""
                if labelOption.timestamp {
                    let date = photo.creationDate
                    let dateString = date?.toStyledString(dateStyle: .medium, timeStyle: .medium)
                    txt = txt.appendIfNotNil(dateString, separator: "\n")
                }
                if labelOption.gps {
                    let coordinate = photo.location?.coordinate
                    let coordinateString = coordinate?.latitudeString(true).appendIfNotNil(coordinate?.longitudeString(true), separator: ", ")
                    txt = txt.appendIfNotNil(coordinateString, separator: "\n")
                }
                if String.isNotEmpty(labelOption.text) {txt = txt.appendIfNotNil(labelOption.text, separator: "\n")}
                txt = txt.trim()
                self?.progressView?.progressText = "Retrieving \(retrieved + 1) of \(count)..."
                PHImageManager.default().requestImageData(for: photo, options: opts){ (data, dataUTI, orientation, info) in
                    autoreleasepool {
                        self?.progressView?.progressText = "Processing \(retrieved + 1) of \(count)..."
                        retrieved = retrieved + 1
                        guard let finalImage = self?.createImageWithOption(image: compressTo == nil ? data?.toImage() : data?.toImage()?.compressTo(compressTo!), labelText: txt, labelOption: labelOption) else {
                            completed = completed + 1
                            return
                        }
                        self?.progressView?.progressText = "Saving \(completed + 1) of \(count)..."
                        self?.processImage(image: finalImage)
                        self?.progressView?.progressText = "Saved \(completed + 1) of \(count)..."
                        if completed + 1 >= count {
                            NGAExecute.performOnMainQueue {self?.completedPhotoProcessing()}
                        }
                        completed = completed + 1
                    }
                    
                    
                }
                
            }
            
        }
        
        
    }
    
    open func processImage(image:UIImage?) {
        saveImageToAlbum(image: image)
    }
    
    open func saveImageToAlbum(image:UIImage?) {
        guard let image = image else {return}
        var placeHolder:PHObjectPlaceholder?
        let _ = try? PHPhotoLibrary.shared().performChangesAndWait(){
            let assetRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
            placeHolder = assetRequest.placeholderForCreatedAsset
        }
        if let placeHolder = placeHolder, let album = photoAlbum() {
            let _ = try? PHPhotoLibrary.shared().performChangesAndWait() {
                let albumRequest = PHAssetCollectionChangeRequest(for: album)
                let arr = [placeHolder]
                albumRequest?.addAssets(arr as NSFastEnumeration)
            }
            
        }
    }
    open func completedPhotoProcessing() {
        navigationController?.dismiss(animated: true, completion: {})
    }
    
    
    
    open func createImageWithOption(image:UIImage?,labelText:String?,labelOption:LabelOption?) -> UIImage? {
        var finalImage:UIImage?
        autoreleasepool {
            guard let image = image , image.size.width > 0, let labelOption = labelOption else {return}
            let width = image.size.width
            let scale = image.size.width / width
            let imageFrame = CGRect(x: 0,y: 0,width: image.size.width,height: image.size.height)
            let scaledFrame = CGRect(x: 0,y: 0,width: imageFrame.size.width * scale,height: imageFrame.size.height * scale)
            let position = labelOption.labelPosition
            let label = UILabel()
            label.text = labelText
            switch labelOption.textAlignment {
            case .Center:
                label.textAlignment = .center
            case .Left:
                label.textAlignment = .left
            case .Right:
                label.textAlignment = .right
            }
            label.numberOfLines = 0
            label.textColor = labelOption.textColor
            label.backgroundColor = labelOption.backgroundColor
            label.font = label.font.withSize(NGADevice.remSizeFor(scaledFrame.size))
            label.sizeToFit()
            let x:CGFloat = position == .BottomLeft || position == .TopLeft ? 0 : image.size.width - label.frameWidth
            let y:CGFloat = position == .BottomLeft || position == .BottomRight ? image.size.height - label.frameHeight : 0
            label.frameOrigin = CGPoint(x: x,y: y)
            let labelImage = label.toImage()
            UIGraphicsBeginImageContext(image.size)
            image.draw(in: imageFrame)
            labelImage?.draw(in: label.frame)
            finalImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
        return finalImage
    }
    
    
    open func disableButtons() {
        addButton.isEnabled = false
    }
    
    open func enableButtons() {
        addButton.isEnabled = true
    }
    
    
}





open class LabelPresetsCell:NGACollectionViewCell {
    open let textLabel = UILabel()
    open let editButton = NGATapImageView()
    open let deleteButton = NGATapImageView()
    open var editing:Bool = false {didSet{if editing != oldValue {setFramesForSubviews()}}}
    open override func postInit() {
        super.postInit()
        textLabel.numberOfLines = 0
        editButton.recognizeTapOnWholeContainer = false
        deleteButton.recognizeTapOnWholeContainer = false
        editButton.image = UIImage(named: "EditIcon.png")
        deleteButton.image = UIImage(named: "TrashIcon.png")
        deleteButton.imageTintColor = UIColor.red
        contentView.addSubviewsIfNeeded(textLabel, editButton, deleteButton)
        contentView.cornerRadius = 5
        contentView.clipsToBounds = true
    }
    
    open override func setFramesForSubviews() {
        super.setFramesForSubviews()
        let multiplier:CGFloat = editing ? 2 : 1
        let buttonWidth:CGFloat = 40
        editButton.left = frameWidth - (buttonWidth * multiplier)
        editButton.frameHeight = 25
        editButton.frameWidth = buttonWidth
        editButton.placeViewInView(view: contentView, andPosition: .alignCenterY)
        deleteButton.frameSize = editButton.frameSize
        deleteButton.top = editButton.top
        deleteButton.left = editButton.right
        deleteButton.alpha = editing.toInt().toCGFloat()
        let width = editButton.left * 0.97
        let gap = (editButton.left - width) / 2
        textLabel.frameWidth = width
        textLabel.frameHeight = frameHeight
        textLabel.left = gap
        textLabel.top = 0
        

    }
    
    
    
}








