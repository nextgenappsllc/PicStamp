//
//  AlbumViewController.swift
//  Pic Stamp
//
//  Created by Jose Castellanos on 4/25/16.
//  Copyright © 2016 NextGen Apps LLC. All rights reserved.
//

import Foundation
import NGAEssentials
import NGAUI
import Photos

open class AlbumViewController: NGACollectionViewController{
    open let manager = PHImageManager.default()
    open var imageDictionary:[Int:UIImage] = [:]
    open  var photoAlbums:[PhotosFetchResult] = [] {didSet{reloadCollectionViewOnMainThread()}}
    open weak var delegate:AssetsPickerDelegate?
    open override var collectionViewCellClass: AnyClass? {get{return PhotoAlbumCell.self}}
    //MARK: view cycle
    open override func viewDidLoad() {
        super.viewDidLoad()
        title = "Albums"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.cancel, target: self, action: #selector(cancelButtonPressed))
        collectionView.backgroundColor = UIColor.darkGray
    }
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        checkAccessAndLoadAlbums()
    }
    //MARK: CollectionView
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {return photoAlbums.count}
    open override func numberOfSections(in: UICollectionView) -> Int {return 1}
    open override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.frameWidth * 0.95,height: collectionView.shortSide * 0.3)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        return UIEdgeInsetsMake(10, 0, 10, 0)
    }
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 10
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        cell.contentView.backgroundColor = UIColor(hexString: "eeeeee")
        cell.contentView.cornerRadius = 5
        cell.contentView.clipsToBounds = true
        guard let c = cell as? PhotoAlbumCell, let item = photoAlbums.itemAtIndex(indexPath.row) else{return cell}
        let image = imageDictionary[indexPath.row]
        if image == nil, let asset = item.result.firstObject {
            manager.requestImage(for: asset, targetSize: CGSize(width: 300, height:  300), contentMode: .aspectFit, options: nil){ (img, dict) -> Void in
                self.imageDictionary[indexPath.row] = img
                NGAExecute.performOnMainQueue {collectionView.reloadData()}
            }
        }
        c.fixedImageView.imageContentMode = .scaleAspectFill
        c.fixedImageView.imageView.clipsToBounds = true
        c.fixedImageView.image = image
        c.countLabel.text = item.result.count.toString()
        c.titleLabel.text = item.title
        let fontSize = NGADevice.emSize
        c.titleLabel.font = PicStampConfig.defaultBoldFont.withSize(fontSize)
        c.countLabel.font = PicStampConfig.defaultFont.withSize(fontSize * 0.9)
//        c.titleLabel.font = FontName.GurmukhiMN.withSize(fontSize)
//        c.countLabel.font = FontName.HelveticaNeueUltraLight.withSize(fontSize * 0.9)
        return cell
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: IndexPath) {
        guard let fetchResult = photoAlbums.itemAtIndex(indexPath.row)?.result else {return}
        let imagePicker = BatchImagePickerVC()
        imagePicker.fetchResult = fetchResult
        imagePicker.delegate = delegate
        navigationController?.pushViewController(imagePicker, animated: true)
    }

    //MARK: Actions
    open func cancelButtonPressed() {
        self.navigationController?.dismiss(animated: true){}
    }
    
    //MARK: Album load
    open func checkAccessAndLoadAlbums() {
        switch PHPhotoLibrary.authorizationStatus() {
        case .authorized:
            loadAlbums()
        default:
            PHPhotoLibrary.requestAuthorization(){s->Void in
                switch s {
                case .authorized:
                    self.loadAlbums()
                default:
                    self.navigationController?.dismiss(animated: true){}
                }
            }
        }
    }
    
    open func loadAlbums(){
        let results = PHAssetCollection.fetchTopLevelUserCollections(with: nil)
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        var a:[PhotosFetchResult] = []
        a.append(PhotosFetchResult(title: "All photos", result: PHAsset.fetchAssets(with: fetchOptions)))
        results.enumerateObjects({ (obj:PHCollection, i:Int, stop:UnsafeMutablePointer<ObjCBool>) -> Void in
            guard let assetCollection = obj as? PHAssetCollection else {return}
            let result = PHAsset.fetchAssets(in: assetCollection, options: fetchOptions)
            guard result.count > 0 else {return}
            a.append(PhotosFetchResult(title: assetCollection.localizedTitle ?? "Unknown album", result: result))
        })
        photoAlbums = a
    }
    
    //MARK: Helper Methods
    open func resizeImage(image:UIImage, to newSize:CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(x: 0,y: 0,width: newSize.width,height: newSize.height))
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return newImage
    }
}


open class PhotosFetchResult {
    var title:String
    var result:PHFetchResult<PHAsset>
    init(title:String,result:PHFetchResult<PHAsset>) {
        self.title = title
        self.result = result
    }
}



private class PhotoAlbumCell:NGACollectionViewCell {
    let fixedImageView = NGATapImageView()
    let titleLabel = NGATapLabelView()
    let countLabel = NGATapLabelView()
    fileprivate override func postInit() {
        super.postInit()
        setupLabels()
    }
    func setupLabels() {
        fixedImageView.alwaysTemplate = false
        titleLabel.fitFontToLabel = false
        countLabel.fitFontToLabel = false
        titleLabel.xRatio = 0.95
        fixedImageView.tapRecognizer = nil
        titleLabel.tapRecognizer = nil
        countLabel.tapRecognizer = nil
    }
    fileprivate override func setFramesForSubviews() {
        super.setFramesForSubviews()
        let countLabelRatio:CGFloat = 0.2
        let imageRatio:CGFloat = 0.3
        let titleRatio:CGFloat = 0.5
        fixedImageView.setSizeFromView(contentView, withXRatio: imageRatio, andYRatio: 1.0)
        titleLabel.setSizeFromView(contentView, withXRatio: titleRatio, andYRatio: 1.0)
        countLabel.setSizeFromView(contentView, withXRatio: countLabelRatio, andYRatio: 1.0)
        fixedImageView.left = 0 ; titleLabel.left = fixedImageView.right ; countLabel.left = titleLabel.right
        contentView.addSubviewsIfNeeded(fixedImageView, titleLabel, countLabel)
    }
    
}
