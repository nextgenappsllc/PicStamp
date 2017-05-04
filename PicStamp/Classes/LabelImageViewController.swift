//
//  AddLabelViewController.swift
//  Pic Stamp
//
//  Created by Jose Castellanos on 4/25/16.
//  Copyright © 2016 NextGen Apps LLC. All rights reserved.
//

import Foundation
import NGAEssentials
import NGAUI

open class LabelImageViewController:NGAViewController, LabelOptionsViewControllerDelegate, UIDocumentInteractionControllerDelegate {
    open let imageView:UIImageView = TouchForwardingImageView()
    open let pictureLabel = UILabel()
    open var labelOption:LabelOption? {didSet{setupLabel()}}
    open var image:UIImage? {didSet{imageView.image = image}}
    open var coordinateString:String? {didSet{if String.isEmptyOrNil(coordinateString){coordinateString = nil}}}
    open var dateString:String? {didSet{if String.isEmptyOrNil(dateString){dateString = nil}}}
    open var showCustomString:Bool {get{return String.isNotEmpty(labelOption?.text)}}
    open var showLabel:Bool {get{return String.isNotEmpty(pictureLabel.text)}}
    open var imageCallBack:((UIImage?) -> Void)?
    open override func postInit() {
        super.postInit()
        contentView.backgroundColor = UIColor.darkGray
        imageView.contentMode = .scaleAspectFit
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed))
        navigationItem.rightBarButtonItems = barItems()
        pictureLabel.numberOfLines = 0
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        (imageView as? TouchForwardingImageView)?.touchDelegate = self
        
    }
    
    open func barItems() -> [UIBarButtonItem] {
        return [UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(exportButtonPressed)),
                UIBarButtonItem(title: "Label", style: .plain, target: self, action: #selector(goToLabelOptionsVC))]
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        imageView.image = image
    }
    open override func setFramesForSubviews() {
        super.setFramesForSubviews()
        imageView.frameSize = imageView.sizeToFitImage(contentView.frameSize)
        imageView.placeViewInView(view: contentView, andPosition: .alignCenter)
        contentView.addSubviewIfNeeded(imageView)
        setLabelFrame()
    }
    open func cancelButtonPressed(){
        self.navigationController?.dismiss(animated:true){}
    }
    
    open func exportButtonPressed() {
        if let callback = imageCallBack, let image = createImage() {
            dismiss(animated: true){callback(image)}
        } else {goToPreviewController()}
    }
    
    open func goToLabelOptionsVC() {
        let vc = LabelOptionsViewController()
        vc.labelOptionsDelegate = self
        vc.gpsAvailable = coordinateString != nil
        vc.timestampAvailable = dateString != nil
        vc.needsLabelPosition = false
        if let l = labelOption {vc.labelOption = l}
        pushToViewController(vc)
    }
    
    open func goToPreviewController() {
        
        if let finalImage = createImage(), let imagePath = tempFolderPath().stringByAddingPathComponent("savedImage.jpeg"),let imageURL = imagePath.fileUrl {
            let imageData = finalImage.toJPEGData()
            try? imageData?.write(to:imageURL, options: .atomic)
            let documentVC = UIDocumentInteractionController(url: imageURL)
            documentVC.name = "Preview and Export"
            documentVC.delegate = self
            documentVC.presentPreview(animated: true)
        }
    }
    
    open func setupLabel() {
        pictureLabel.textAlignment = labelTextAlignment()
        pictureLabel.textColor = labelOption?.textColor
        pictureLabel.backgroundColor = labelOption?.backgroundColor
        setLabelText()
        setLabelFrame()
        if showLabel {
            imageView.addSubview(pictureLabel)
        } else {
            pictureLabel.removeFromSuperview()
        }
        
    }
    
    open func setLabelFrame() {
        pictureLabel.frameSize = CGSize.zero
        pictureLabel.font = pictureLabel.font.withSize(NGADevice.remSizeFor(imageView.frameSize))
        pictureLabel.sizeToFitText()
        if pictureLabel.frameWidth > imageView.frameWidth {pictureLabel.frameWidth = imageView.frameWidth}
        if pictureLabel.frameHeight > imageView.frameHeight {pictureLabel.frameHeight = imageView.frameHeight}
        constrainLabelToImageViewBounds()
    }
    
    open func constrainLabelToImageViewBounds() {
        if pictureLabel.top < 0 {
            pictureLabel.top = 0
        }
        if pictureLabel.bottom > imageView.frameHeight {
            pictureLabel.top = imageView.frameHeight - pictureLabel.frameHeight
        }
        if pictureLabel.left < 0 {
            pictureLabel.left = 0
        }
        if pictureLabel.right > imageView.frameWidth {
            pictureLabel.left = imageView.frameWidth - pictureLabel.frameWidth
        }
        
    }
    
    
    open func setLabelText() {
        pictureLabel.text = labelText()
    }
    
    open func labelTextAlignment() -> NSTextAlignment {
        guard let align = labelOption?.textAlignment else {return .left}
        switch align {
        case .Center:
            return .center
        case .Left:
            return .left
        case .Right:
            return .right
        }
    }
    
    open func labelText() -> String {
        var txt = ""
        if labelOption?.timestamp ?? false {txt = txt.appendIfNotNil(dateString, separator: "\n")}
        if labelOption?.gps ?? false {txt = txt.appendIfNotNil(coordinateString, separator: "\n")}
        if showCustomString {txt = txt.appendIfNotNil(labelOption?.text, separator: "\n")}
        return txt.trim()
    }
    
    open func labelOptionViewControllerFinished(index:Int?,labelOption: LabelOption) {
        self.labelOption = labelOption
    }
    
    //MARK: Image Creation
    
    open func createImage() -> UIImage?{
        guard imageView.frameWidth > 0, let image = image else {return nil}
        let scale = image.size.width / imageView.frameWidth
        let imageFrame = CGRect(x:0,y: 0,width: image.size.width,height: image.size.height)
        let x = pictureLabel.frameOriginX * scale
        let y = pictureLabel.frameOriginY  * scale
        let label = UILabel()
        label.text = pictureLabel.text
        label.numberOfLines = pictureLabel.numberOfLines
        label.textColor = pictureLabel.textColor
        label.backgroundColor = pictureLabel.backgroundColor
        label.font = pictureLabel.font.withSize(pictureLabel.font.pointSize * scale)
        label.sizeToFit()
        label.frameOrigin = CGPoint(x: x,y: y)
        let labelImage = label.toImage()
        UIGraphicsBeginImageContext(image.size)
        image.draw(in: imageFrame)
        labelImage?.draw(in: label.frame)
        let finalImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return finalImage
        
    }
    
    //MARK: touches
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        if pictureLabel.isDescendant(of: imageView){
            if let touch = touches.first {handleTouch(touch: touch)}
        }
        
        
    }
    
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        super.touchesBegan(touches, with: event)
        if pictureLabel.isDescendant(of: imageView){
            if let touch = touches.first {handleTouch(touch: touch)}
        }
    }
    
    
    open func handleTouch(touch:UITouch) {
        let xPad:CGFloat = 10;let yPad:CGFloat = 30
        let touchZone = CGRect(x: pictureLabel.frameOriginX - xPad ,y: pictureLabel.frameOriginY - yPad ,width: pictureLabel.frameWidth + xPad * 2,height: pictureLabel.frameHeight + yPad * 2)
        let touchLocation = touch.location(in: imageView)
        if touchZone.contains(touchLocation) {
            let allowedRect = CGRect(x: pictureLabel.frame.size.width / 2,y: pictureLabel.frame.size.height / 2,width: imageView.frameWidth - pictureLabel.frame.size.width,height: imageView.frameHeight - pictureLabel.frame.size.height)
            if allowedRect.contains(touchLocation){
                pictureLabel.center = touchLocation
            }
            else {
                let x,y:CGFloat
                if touchLocation.y < allowedRect.origin.y {
                    y = allowedRect.origin.y
                } else if touchLocation.y > (allowedRect.origin.y + allowedRect.size.height) {
                    y = allowedRect.origin.y + allowedRect.size.height
                }else {
                    y = touchLocation.y
                }
                if touchLocation.x < allowedRect.origin.x {
                    x = allowedRect.origin.x
                } else if touchLocation.x > (allowedRect.origin.x + allowedRect.size.width) {
                    x = allowedRect.origin.x + allowedRect.size.width
                }
                else {
                    x = touchLocation.x
                }
                pictureLabel.center = CGPoint(x: x,y: y)
            }
        }
    }
    //MARK: document intercation controller delegate
    open func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    open func tempFolderPath() -> String {
        return tempSubDirectoryWithName(name: "DocPreview")
    }
    
    open func tempSubDirectoryWithName(name:String?) -> String {
        let temp = NSTemporaryDirectory()
        guard String.isNotEmpty(name), let path = temp.stringByAddingPathComponent(name) else {return temp}
        if !FileManager.default.fileExists(atPath: path) {_ = try? FileManager.default.createDirectory(atPath: path, withIntermediateDirectories: false, attributes: nil)}
        return path
    }
}


open class TouchForwardingImageView:UIImageView {
    open weak var touchDelegate:UIViewController?
    public override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = true
    }
    
    public convenience init() {
        self.init(frame:CGRect.zero)
    }
    
    public required convenience init?(coder aDecoder: NSCoder) {
        self.init(frame:CGRect.zero)
    }
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Notify it's delegate about touched
        touchDelegate?.touchesBegan(touches, with: event)
        super.touchesBegan(touches, with: event)
        
    }
    
    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?)  {
        // Notify it's delegate about touched
        touchDelegate?.touchesMoved(touches, with: event)
        super.touchesMoved(touches, with: event)
    }
    
    
    open override func touchesEnded(_
        touches: Set<UITouch>, with event: UIEvent?) {
        //        super.touchesEnded(touches, withEvent: event)
        touchDelegate?.touchesEnded(touches, with: event)
        super.touchesEnded(touches, with: event)
        //        nextResponder()?.touchesEnded(touches, withEvent: event)
    }
}




