//
//  SourceSelectorViewController.swift
//  Pic Stamp
//
//  Created by Jose Castellanos on 4/24/16.
//  Copyright © 2016 NextGen Apps LLC. All rights reserved.
//

import Foundation
import NGAEssentials
import NGAUI
import Photos





public protocol AssetsPickerDelegate: class{
    func assetsPicked(assets:[PHAsset])
}

open class SourceSelecterViewController: NGACollectionViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate, AssetsPickerDelegate {
    open override var collectionViewCellClass:AnyClass? {get {return SourceCell.self}}
    //MARK: properties
    open var cameraButton:UIButton?
    open var photoLibraryButton:UIButton?
    open weak var imageRequester:NGAImageRequestProtocol?
    open var singleImageCallBack:((UIViewController, UIImage?, SwiftDictionary?) -> Void)?
    open var singlePhotoSelect:Bool = false
    open var forceCustomizations:Bool = false
    open var cellTypes:[SourceCellType] = [] {didSet{reloadCollectionViewOnMainThread()}}
    //MARK: view cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.backgroundColor = UIColor.darkGray
        collectionView.alwaysBounceVertical = true
        navigationItem.title = "Pic Stamp"
    }
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkAvailableSourceTypes()
    }
    //MARK: setup
    open func checkAvailableSourceTypes(){
        var c:[SourceCellType] = []
        if UIImagePickerController.isSourceTypeAvailable(.photoLibrary) {
            c.append(.Library)
            if !singlePhotoSelect {c.append(.Batch)}
        }
        if UIImagePickerController.isSourceTypeAvailable(.camera) {c.append(.Camera)}
        cellTypes = c
    }
    
    
    //MARK: View Controllers
    open func imagePickerViewController(type:UIImagePickerControllerSourceType) -> UIViewController {
        let imagePicker = CameraPicker()
        imagePicker.sourceType = type
        imagePicker.delegate = self
        return imagePicker
    }
    
    open func batchViewController() -> UIViewController{
        let imagePicker = AlbumViewController()
        imagePicker.delegate = self
        return imagePicker
    }
    
    open func labelImageViewController() -> LabelImageViewController {
        return LabelImageViewController()
    }
    
    open func labelPresetsViewController() -> LabelPresetsViewController {
        return LabelPresetsViewController()
    }
    
    //MARK: actions
    open func goToPicker(type:UIImagePickerControllerSourceType) {
        self.present(imagePickerViewController(type: type), animated: true){}
    }
    open func cameraButtonPressed() {
        switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
        case .authorized:
            goToPicker(type: .camera)
        case .notDetermined:
            AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo){b -> Void in
                if b {self.goToPicker(type: .camera)} else {self.flashPermissionsErrorFor(type: "camera")}
            }
        default:
            flashPermissionsErrorFor(type: "camera")
        }
    }
    open func libraryButtonPressed() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            goToPicker(type: .photoLibrary)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization() {s->Void in
                switch s {
                case .authorized:
                    self.goToPicker(type: .photoLibrary)
                default:
                    self.flashPermissionsErrorFor(type: "photos")
                }
            }
        default:
            flashPermissionsErrorFor(type: "photos")
        }
    }
    open func goToBatchViewController() {
        let navVC = UINavigationController(rootViewController: batchViewController())
        self.present(navVC, animated: true){}
    }
    open func batchButtonPressed(){
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            goToBatchViewController()
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization() {s->Void in
                switch s {
                case .authorized:
                    self.goToBatchViewController()
                default:
                    self.flashPermissionsErrorFor(type: "photos")
                }
            }
        default:
            flashPermissionsErrorFor(type: "photos")
        }
        
    }
    //MARK: CollectionViewDelegate and CollectionViewDataSource
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {return cellTypes.count}
    open override func numberOfSections(in: UICollectionView) -> Int {return 1}
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        cell.contentView.backgroundColor = UIColor(hexString: "eeeeee")
        cell.contentView.cornerRadius = 5
        cell.contentView.clipsToBounds = true
        guard let c = cell as? SourceCell, let type = cellTypes.itemAtIndex(indexPath.row) else {return cell}
        c.fixedImageView.image = imageForCellType(type)
        c.titleLabel.text  = textForCellType(type)
        c.fixedImageView.imageView.clipsToBounds = true
        let fontSize = NGADevice.emSize
        c.titleLabel.font = PicStampConfig.defaultBoldFont.withSize(fontSize)
        c.sideLabel.font = PicStampConfig.defaultFont.withSize(fontSize)
        return cell
    }
    
    open func imageForCellType(_ type:SourceCellType) -> UIImage? {
        switch type {
        case .Batch:
            return PicStampConfig.imageNamed("Batch.png")
        case .Camera:
            return  PicStampConfig.imageNamed("Camera.png")
        case .Library:
            return PicStampConfig.imageNamed("PhotoLibrary.png")
        }
    }
    
    open func textForCellType(_ type:SourceCellType) -> String? {
        switch type {
        case .Batch:
            return "Pick and label multiple photos at once"
        case .Camera:
            return  "Take and label a photo from your camera"
        case .Library:
            return "Choose a single photo from your library to label"
        }
    }
    
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: IndexPath) {
        guard let type = cellTypes.itemAtIndex(indexPath.row) else {return}
        switch type {
        case .Batch:
            batchButtonPressed()
        case .Camera:
            cameraButtonPressed()
        case .Library:
            libraryButtonPressed()
        }
    }
    open override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frameWidth * 0.95,height: collectionView.shortSide * 0.3)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10, 0, 10, 0)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {return 10}
    
    //MARK: Imagepicker controller delegate
    
    open func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as? UIImage
        var latitude:String?
        var longitude:String?
        var dateTaken:Date?
        if let url = info[UIImagePickerControllerReferenceURL] as? URL, let asset =  PHAsset.fetchAssets(withALAssetURLs: [url as URL], options: nil).firstObject {
            let location = asset.location
            latitude = location?.coordinate.latitudeString(true)
            longitude = location?.coordinate.longitudeString(true)
            dateTaken = asset.creationDate
        } else if let cameraPicker = picker as? CameraPicker,let location = cameraPicker.locationManager.location {
            dateTaken = Date()
            latitude = location.coordinate.latitudeString(true)
            longitude = location.coordinate.longitudeString(true)
        }
        let dateString = dateTaken?.toStyledString(dateStyle: .medium, timeStyle: .medium)
        picker.dismiss(animated: true){ () -> Void in
            if !self.forceCustomizations && (self.imageRequester != nil || self.singleImageCallBack != nil) {
                if self.imageRequester != nil {
                    self.popViewController()
                    self.imageRequester?.imagePicked(img: image, info: (dateTaken == nil ? nil : ["takenDate": dateTaken!]))
                } else {
                    self.popViewController()
                    self.singleImageCallBack?(self, image, nil)
                }
            } else {
                let nextVC = self.labelImageViewController()
                nextVC.image = image
                nextVC.coordinateString = latitude?.appendIfNotNil(longitude, separator: ", ")
                nextVC.dateString = dateString
                //// delegate
                let imageCallback:((UIImage?) -> Void)? = self.imageRequester == nil && self.singleImageCallBack == nil ? nil : { [weak self](img:UIImage?) -> Void in
                    guard let s = self else {return}
                    if s.imageRequester != nil {
                        s.popViewController()
                        s.imageRequester?.imagePicked(img: img, info: nil)
                    } else if s.singleImageCallBack != nil  {
                        s.popViewController()
                        s.singleImageCallBack?(s, img, nil)
                    }
                }
                nextVC.imageCallBack = imageCallback
                let navVC = UINavigationController(rootViewController: nextVC)
                navVC.title = "Add a label"
                self.present(navVC, animated: true){}
            }
        }
    }
    
    open func assetsPicked(assets: [PHAsset]) {
        if let delegate = imageRequester {
            self.popViewController()
            delegate.imageAssetsPicked(assets: assets)
        } else {
            if assets.count > 0 {
                let nextVC = labelPresetsViewController()
                nextVC.photos = assets
                let navVC = UINavigationController(rootViewController: nextVC)
                self.present(navVC, animated: true){}
            }
        }
    }
    
    open func flashPermissionsErrorFor(type:String?) {
        let type = type ?? "this"
        var action:UIAlertAction?;let app = UIApplication.shared
        if let url = UIApplicationOpenSettingsURLString.url , app.canOpenURL(url) {
            action = UIAlertAction(title: "Go to settings", style: .default, handler: {a->Void in app.openURL(url)})
        }
        flash(title: "Error",
              message: "The app does not have permission to access \(type). Please enable access in settings.",
              cancelTitle: "Ok",
              actions: action)
    }
    
}


open class SourceCell:NGACollectionViewCell {
    open let fixedImageView = NGATapImageView()
    open let imageContainer = NGAContainerView()
    open let titleLabel = NGATapLabelView()
    open let sideLabel = NGATapLabelView()
    open override func postInit() {
        super.postInit()
        setupLabels()
    }
    open func setupLabels() {
        imageContainer.viewToSize = fixedImageView
        imageContainer.setEqualRatio(0.95)
        fixedImageView.alwaysTemplate = false
        titleLabel.fitFontToLabel = false
        titleLabel.constrainFontToLabel = false
        sideLabel.fitFontToLabel = false
        titleLabel.xRatio = 0.95
        for v in [fixedImageView, titleLabel, sideLabel] {v.tapRecognizer = nil}
        fixedImageView.clipsToBounds = true
        fixedImageView.imageTintColor = UIColor(hexString: "003366")
        fixedImageView.circular = true
        fixedImageView.imageView.clipsToBounds = true
        sideLabel.text = ">"
    }
    
    open override func setFramesForSubviews() {
        super.setFramesForSubviews()
        imageContainer.frameSize = contentView.shortSide.toEqualSize()
        imageContainer.top = 0
        imageContainer.left = 0
        titleLabel.frameHeight = contentView.frameHeight
        titleLabel.top = 0
        titleLabel.left = imageContainer.right
        sideLabel.frameHeight = contentView.frameHeight
        sideLabel.frameWidth = contentView.frameWidth * 0.2
        titleLabel.right = contentView.frameWidth - sideLabel.frameWidth
        sideLabel.left = titleLabel.right
        contentView.addSubviewsIfNeeded(imageContainer, titleLabel, sideLabel)
        
    }
}

public enum SourceCellType {case Library, Camera, Batch}







