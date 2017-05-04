//
//  Snap.swift
//  MCM
//
//  Created by Jose Castellanos on 1/7/15.
//  Copyright (c) 2015 NextGen Apps LLC. All rights reserved.
//

import Foundation
import Photos
import NGAEssentials
import NGAUI



public protocol NGAImageRequestProtocol:class {
    func imagePicked(img:UIImage?, info: SwiftDictionary?)
    func imageAssetsPicked(assets:[PHAsset]?)
    
}

public protocol BatchPickerDelegate: class{
    func batchPicker(picker:BatchImagePickerVC, didFinishPickingWithAssets assets:NSArray)
}


open class BatchImagePickerVC: NGACollectionViewController {
    
    open weak var delegate:AssetsPickerDelegate?
    open var fetchResult:PHFetchResult<PHAsset>?
    open let imageManager = PHCachingImageManager()
    
    open override var collectionViewCellClass:AnyClass? {
        get {return NGAPhotoCollectionViewCell.self}
    }
    
    
    open var assets = NSMutableArray()
    
    open var selectedIndexes:NSMutableArray = NSMutableArray()
    
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.contentView.backgroundColor = UIColor.white
        self.navigationItem.title = "Photos"
        collectionView.allowsMultipleSelection = true
        
        
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.done, target: self, action: #selector(selectPhotos))
        self.navigationItem.rightBarButtonItem = doneButton
        
        
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        collectionView.frame = contentView.bounds
        
        reloadCollectionViewOnMainThread()
    }
    
    open override func didRotate(from fromInterfaceOrientation: UIInterfaceOrientation) {
        self.collectionView.frame = self.contentView.bounds
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    open override func setFramesForSubviews() {
        super.setFramesForSubviews()
        
        reloadCollectionViewOnMainThread()
    }
    
    
    //MARK:override  collection view
    
    open override func numberOfSections(in: UICollectionView) -> Int {
        return 1
    }
    
    open override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return fetchResult?.count ?? 0
    }
    
    open override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath)
        if let photoCell = cell as? NGAPhotoCollectionViewCell {
            photoCell.imageManager = imageManager
            //            if indexPath.row < assets.count {photoCell.asset = assets[indexPath.row] as? ALAsset}
            if indexPath.row < fetchResult?.count ?? 0 {photoCell.photo = fetchResult?.object(at: indexPath.row)}
            if selectedIndexes.contains(indexPath.row) {
                let selectedIndex = self.selectedIndexes.index(of: indexPath.row)
                photoCell.selectionNumber = selectedIndex + 1
                //                photoCell.selected = true
                collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
                photoCell.isSelected = true
            } else {
                collectionView.deselectItem(at: indexPath, animated: false)
                photoCell.isSelected = false
            }
            
        }
        
        return cell
    }
    
    open override func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var cellSize = CGSize.zero
        cellSize.width = landscape ? contentView.frameWidth / 6 : contentView.frameWidth / 4
        cellSize.height = cellSize.width
        
        
        return cellSize
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAtIndex section: Int) -> UIEdgeInsets {
        
        
        return UIEdgeInsetsMake(0, 0, 0, 0)
    }
    
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        
        return 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: IndexPath) {
        if !selectedIndexes.contains(indexPath.row) {selectedIndexes.add(indexPath.row)}
        reloadCollectionViewOnMainThread()
    }
    
    open func collectionView(_ collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: IndexPath) {
        selectedIndexes.remove(indexPath.row)
        reloadCollectionViewOnMainThread()
    }
    
    //MARK: Actions
    open func selectPhotos() {
        var assets:[PHAsset] = []
        for object in selectedIndexes {
            guard let i = object as? Int else {continue}
            assets.appendIfNotNil(fetchResult?.object(at: i))
            
        }
        self.navigationController?.dismiss(animated: true, completion: { () -> Void in
           self.delegate?.assetsPicked(assets: assets)
        })
        
    }
    
    
    
    //MARK: Helper methods
//    func reverseArray(array:NSMutableArray) -> NSMutableArray
//    {
//        let reversedArray = NSMutableArray(capacity: array.count)
//        let enumerator = array.reverseObjectEnumerator()
//        while let object:AnyObject = enumerator.nextObject()
//        {
//            reversedArray.addObject(object)
//        }
//        
//        return reversedArray
//        
//        
//    }
    
    
}




open class NGAPhotoCollectionViewCell: NGACollectionViewCell {
    
    open lazy var photoImageView:UIImageView = {
        let tempImageView = UIImageView()
        tempImageView.contentMode = UIViewContentMode.scaleAspectFill
        //        tempImageView.frame = self.contentView.frame
        tempImageView.clipsToBounds = true
        //        self.contentView.addSubview(tempImageView)
        return tempImageView
    }()
    
    open lazy var selectedView:UIView = {
        let tempView = UIView()
        tempView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        //        tempView.frame = self.contentView.frame
        return tempView
    }()
    
    open lazy var selectedLabel:UILabel = {
        let label = UILabel(frame: self.contentView.frame)
        label.textColor = UIColor.white
        label.textAlignment = NSTextAlignment.center
        let fontSize = self.contentView.frame.size.width / 4
        label.font = UIFont(name: "Verdana-Bold", size: fontSize)
        return label;
    }()
    
    
    
    open weak var imageManager:PHCachingImageManager?
    open var requestID:PHImageRequestID?
    
    open var photo:PHAsset? {
        didSet{
            if photo != oldValue {
                let p = photo
                requestID = imageManager?.requestImage(for: photo!, targetSize: CGSize(width: 200, height:  200), contentMode: .aspectFit, options: nil, resultHandler: { (img:UIImage?, dict:SwiftDictionary?) -> Void in
                    if p == self.photo {
                        self.photoImageView.image = img
                    }
                })
            }
            
        }
    }
    
    open var selectionNumber:Int? {
        didSet{
            if selectionNumber != nil {
                selectedLabel.text = "\(selectionNumber!)"
            }
        }
    }
    
    open override var isSelected:Bool{
        didSet{
            if isSelected{
                contentView.addSubview(selectedView)
                //                self.contentView.layer.borderWidth = 5
                contentView.addSubview(selectedLabel)
                if selectionNumber != nil {
                    selectedLabel.text = "\(selectionNumber!)"
                }
            }
            else{
                selectedView.removeFromSuperview()
                selectedLabel.removeFromSuperview()
                //                self.contentView.layer.borderWidth = 0
            }
            
        }
    }
    
    
    open override func setFramesForSubviews() {
        super.setFramesForSubviews()
        photoImageView.frame = contentView.bounds
        selectedView.frame = contentView.bounds
        selectedLabel.frame = contentView.bounds
        selectedLabel.font = UIFont(name: "Verdana-Bold", size: contentView.frame.size.width / 4)
        contentView.addSubviewIfNeeded(photoImageView)
        contentView.clipsToBounds = true
    }
    
    
}













