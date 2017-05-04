//
//  ProgressView.swift
//  Pic Stamp
//
//  Created by Jose Castellanos on 4/24/16.
//  Copyright © 2016 NextGen Apps LLC. All rights reserved.
//

import Foundation
import NGAEssentials
import NGAUI



open class LabelProgressView:NGAView {
    open let blurView = UIVisualEffectView(effect: UIBlurEffect(style: UIBlurEffectStyle.dark))
    open let progressLabel = UILabel()
    open let cancelButton = UIButton()
    open var cancelBlock:VoidBlock?
    open let scrollContentView = NGAScrollView()
    open var progressLabelFont:UIFont? {get{return progressLabel.font} set{progressLabel.font = newValue}}
    open var progressLabelTextColor:UIColor? {get{return progressLabel.textColor} set{progressLabel.textColor = newValue}}
    open var progressLabelTextAlignment:NSTextAlignment {get{return progressLabel.textAlignment} set{progressLabel.textAlignment = newValue}}
    open var progressText:String? {
        get {return progressLabel.text}
        set {
            guard progressLabel.text != newValue else {return}
            NGAExecute.performOnMainQueue() {
                self.progressLabel.text = newValue
                self.setProgressLabelFrame()
            }
        }
    }
    open var progressAttributtedText:NSAttributedString? {
        get {return progressLabel.attributedText}
        set {
            guard progressAttributtedText != newValue else {return}
            NGAExecute.performOnMainQueue() {
                self.progressLabel.attributedText = newValue
                self.setProgressLabelFrame()
            }
        }
    }
    
    open var cancelButtonImage:UIImage? {didSet{cancelButton.setImage(cancelButtonImage, for: .normal)}}
    open var cancelButtonTitle:String? {didSet {if cancelButtonImage == nil {cancelButton.setTitle(cancelButtonTitle ?? "Cancel", for: .normal)}}}
    
    open override func postInit() {
        super.postInit()
        backgroundColor = UIColor.clear
        addSubview(blurView)
        blurView.contentView.addSubview(scrollContentView)
        scrollContentView.isScrollEnabled = true
        progressLabel.numberOfLines = 0
        progressLabelTextColor = UIColor.white
        progressLabelFont = PicStampConfig.defaultBoldFont.withSize(22.0)
        progressLabelTextAlignment = NSTextAlignment.center
//        progressLabel.lineBreakMode = NSLineBreakMode.ByTruncatingMiddle
        scrollContentView.addSubview(progressLabel)
        cancelButtonTitle = "Cancel"
        cancelButton.addTarget(self, action: #selector(cancelButtonPressed), for: UIControlEvents.touchUpInside)
        cancelButton.sizeToFit()
        scrollContentView.addSubview(cancelButton)
    }
    
    open override func setFramesForSubviews() {
        blurView.frame = bounds
        scrollContentView.frame = bounds
        setProgressLabelFrame()
    }
    
    
    
    open func setProgressLabelFrame() {
        progressLabel.frameWidth = frameWidth
        progressLabel.sizeToFitY()
        progressLabel.placeViewInView(view: self, andPosition: NGARelativeViewPosition.alignCenterX)
        progressLabel.top = bounds.height * 0.1
        cancelButton.placeViewInView(view: self, andPosition: NGARelativeViewPosition.alignCenterX)
        cancelButton.top = progressLabel.bottom + 20
        scrollContentView.fitContentSizeHeightToBottom()
    }
    
    open func cancelButtonPressed() {
        removeFromSuperview()
        cancelBlock?()
    }
}















