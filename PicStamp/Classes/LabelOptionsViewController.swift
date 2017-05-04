//
//  LabelOptionsViewController.swift
//  FrameworkTestApp
//
//  Created by Jose Castellanos on 5/4/16.
//  Copyright © 2016 NextGen Apps LLC. All rights reserved.
//

import Foundation
import Eureka
import NGAEssentials
import NGAUI
import SQLite


public protocol LabelOptionsViewControllerDelegate:class {
    func labelOptionViewControllerFinished(index:Int?, labelOption:LabelOption)
}



open class LabelOptionsViewController:FormViewController {
    open weak var labelOptionsDelegate:LabelOptionsViewControllerDelegate?
    open var labelOption:LabelOption = LabelOption() {
        didSet{
            tableView?.reloadData()
        }
    }
    open var labelOptionIndex:Int?
    open var gpsAvailable = true
    open var timestampAvailable = true
    open var needsLabelPosition = false
    open var needsName = false
    open var nameMustBeUnique = true
    open var labelName:String?
    open override func viewDidLoad() {
        super.viewDidLoad()
        setupForm()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed))
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        title = "Label Options"
    }
    open func setupForm() {
       form = Form()
            +++ contentSection()
            +++ alignmentSection()
            +++ textColorSection()
            +++ backgroundColorSection()
    }
    
    open func contentSection() -> Section {
        return Section()
            <<< TextRow("custom text") { [weak self] in
                $0.title = "Custom Text"
                $0.value = self?.labelOption.text
            }
            <<< SwitchRow("gps") { [weak self] in
                $0.title = "GPS"
                $0.value = self?.labelOption.gps
                $0.disabled = Condition.function(["gps"], { (form) -> Bool in
                    return !(self?.gpsAvailable ?? true)
                })
            }
            <<< SwitchRow("timestamp") { [weak self] in
                $0.title = "Timestamp"
                $0.value = self?.labelOption.timestamp
                $0.disabled = Condition.function(["timestamp"], { (form) -> Bool in
                    return !(self?.timestampAvailable ?? true)
                })
        }
    }
    
    open func alignmentSection() -> Section {
        let section = Section()
            <<< AlertRow<String>("text alignment") { [weak self] in
                $0.title = "Text alignment"
                let opts:[PictureLabelSettings.TextAlignment] = [.Left,.Center,.Right]
                $0.options = opts.mapToNewArray(){element in element.rawValue}
                $0.value = self?.labelOption.textAlignment.rawValue
        }
        guard needsLabelPosition else {return section}
        section <<< AlertRow<String>("label position") { [weak self] in
            $0.title = "Label position"
            let opts:[PictureLabelSettings.LabelPosition] = [.TopLeft,.TopRight,.BottomLeft,.BottomRight]
            $0.options = opts.mapToNewArray(){e in e.rawValue}
            $0.value = self?.labelOption.labelPosition.rawValue
        }
        return section
    }
    
    open func textColorSection() -> Section {
        let section = Section()
            <<< LabelRow("text color label"){
                $0.title = "Text Color"
            }
            <<< SliderRow("rt") { [weak self] in
                $0.title = "Red"
                $0.minimumValue = 0
                $0.maximumValue = 1
                $0.steps = 50
                $0.value = self?.labelOption.textColor.redComponent.toFloat()
                }.onChange(){[weak self] (row) in
                    self?.form.rowBy(tag: "text color")?.updateCell()
                    let r = self?.form.rowBy(tag: "background color")
                    if let form = self?.form, let condition = r?.hidden, case Condition.function(_, let hidden) = condition , !hidden(form) {
                        r?.updateCell()
                    }
                }.cellUpdate() {cell, row in
                    cell.titleLabel.textColor = .red
            }
            <<< SliderRow("gt") { [weak self] in
                $0.title = "Green"
                $0.minimumValue = 0
                $0.maximumValue = 1
                $0.steps = 50
                $0.value = self?.labelOption.textColor.greenComponent.toFloat()
                }.onChange(){[weak self] (row) in
                    self?.form.rowBy(tag: "text color")?.updateCell()
                    let r = self?.form.rowBy(tag: "background color")
                    if let form = self?.form, let condition = r?.hidden, case Condition.function(_, let hidden) = condition , !hidden(form) {
                        r?.updateCell()
                    }
                }.cellUpdate() {cell, row in
                    cell.titleLabel.textColor = .green
            }
            <<< SliderRow("bt") { [weak self] in
                $0.title = "Blue"
                $0.minimumValue = 0
                $0.maximumValue = 1
                $0.steps = 50
                $0.value = self?.labelOption.textColor.blueComponent.toFloat()
                }.onChange(){[weak self] (row) in
                    self?.form.rowBy(tag: "text color")?.updateCell()
                    let r = self?.form.rowBy(tag: "background color")
                    if let form = self?.form, let condition = r?.hidden, case Condition.function(_, let hidden) = condition , !hidden(form) {
                        r?.updateCell()
                    }
                }.cellUpdate() {cell, row in
                    cell.titleLabel.textColor = .blue
            }
            <<< LabelRow("text color"){
                $0.title = "Sample Text"
                }.cellUpdate(){[weak self](cell, row) in
                    let color = self?.formTextColor()
                    cell.textLabel?.textColor = color
                    let breakpoint:CGFloat = 0.75
                    let avg = color?.rgbAverage() ?? 0
                    if avg > breakpoint {
                        cell.backgroundColor = .black
                    } else {
                        cell.backgroundColor = .white
                    }
        }
        
        return section
    }
    
    open func backgroundColorSection() -> Section {
        let section = Section()
            <<< SwitchRow("background") { [weak self] in
                $0.title = "Background Color"
                $0.value = self?.labelOption.backgroundColor != UIColor.clear
            }
            <<< SliderRow("rb") { [weak self] in
                $0.title = "Red"
                $0.minimumValue = 0
                $0.maximumValue = 1
                $0.steps = 50
                $0.value = self?.labelOption.backgroundColor.redComponent.toFloat()
                $0.hidden = Condition.function(["background"], { (form) -> Bool in
                    return !(form.rowBy(tag: "background")?.baseValue as? Bool  ?? false)
                })
                }.onChange(){ (row) in
                    row.cell.formViewController()?.form.rowBy(tag: "background color")?.updateCell()
                }.cellUpdate() {cell, row in
                    cell.titleLabel.textColor = .red
            }
            <<< SliderRow("gb") { [weak self] in
                $0.title = "Green"
                $0.minimumValue = 0
                $0.maximumValue = 1
                $0.steps = 50
                $0.value = self?.labelOption.backgroundColor.greenComponent.toFloat()
                $0.hidden = Condition.function(["background"], { (form) -> Bool in
                    return !(form.rowBy(tag: "background")?.baseValue as? Bool  ?? false)
                })
                }.onChange(){ (row) in
                    row.cell.formViewController()?.form.rowBy(tag: "background color")?.updateCell()
                }.cellUpdate() {cell, row in
                    cell.titleLabel.textColor = .green
            }
            <<< SliderRow("bb") { [weak self] in
                $0.title = "Blue"
                $0.minimumValue = 0
                $0.maximumValue = 1
                $0.steps = 50
                $0.value = self?.labelOption.backgroundColor.blueComponent.toFloat()
                $0.hidden = Condition.function(["background"], { (form) -> Bool in
                    return !(form.rowBy(tag: "background")?.baseValue as? Bool  ?? false)
                })
                }.onChange(){ (row) in
                    row.cell.formViewController()?.form.rowBy(tag: "background color")?.updateCell()
                }.cellUpdate() {cell, row in
                    cell.titleLabel.textColor = .blue
            }
            <<< LabelRow("background color"){
                $0.title = "Sample Text"
                $0.hidden = Condition.function(["background"], { (form) -> Bool in
                    return !(form.rowBy(tag: "background")?.baseValue as? Bool  ?? false)
                })
                }.cellUpdate(){[weak self](cell, row) in
                    cell.backgroundColor = self?.formBackgroundColor()
                    cell.textLabel?.textColor = self?.formTextColor()
        }
        return section
    }
    
    open func formBackgroundColor() -> UIColor {
        let rRow:SliderRow? = form.rowBy(tag: "rb")
        let gRow:SliderRow? = form.rowBy(tag: "gb")
        let bRow:SliderRow? = form.rowBy(tag: "bb")
        let r = rRow?.value?.toCGFloat() ?? 0
        let g = gRow?.value?.toCGFloat() ?? 0
        let b = bRow?.value?.toCGFloat() ?? 0
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    open func formTextColor() -> UIColor {
        let rRow:SliderRow? = form.rowBy(tag: "rt")
        let gRow:SliderRow? = form.rowBy(tag: "gt")
        let bRow:SliderRow? = form.rowBy(tag: "bt")
        let r = rRow?.value?.toCGFloat() ?? 0
        let g = gRow?.value?.toCGFloat() ?? 0
        let b = bRow?.value?.toCGFloat() ?? 0
        return UIColor(red: r, green: g, blue: b, alpha: 1.0)
    }
    
    open func validateName(name:String?) -> Bool {
        let name = name ?? labelName
        return String.isNotEmpty(name) && LabelOptionModel(filter: LabelOptionModel.name == name) == nil
    }
    
    open func doneButtonPressed() {
        if needsName {
            var textField:UITextField?
            flash(title: "Save Preset", message: "Do you want to save the preset\(labelOption.name?.prependIfNotNil(" named ").surround(prefix: "\"", postfix: "\"") ?? "")?",textFieldConfigurator: {t in
                t.text = self.labelOption.name
                textField = t
                }, cancelTitle: "Cancel", actions: UIAlertAction(title: "Save", style: .default, handler: { (action) in
                    if String.isNotEmpty(textField?.text) {
                        let name = textField?.text?.trim()
                        let labelOptions = LabelOptionModel.filteredLabelOptions(filters: [LabelOptionModel.name == name])
                        if labelOptions.count == 0 || (self.labelOption.id != nil && labelOptions.count == 1 && labelOptions.first?.id == self.labelOption.id) {
                            self.labelOption.name = name
                            self.submit()
                        } else {
                            self.flash(title: "Error", message: "The name \(name?.surround(prefix: "\"", postfix: "\" ") ?? "") that you chose is already taken. Please try a different name.", cancelTitle: "Ok", actions: [UIAlertAction(title: "Try again", style: .default, handler: { (action) in
                                self.doneButtonPressed()
                            })])
                        }
                    } else {
                        self.flash(title: "Error", message: "You must enter a name for this preset in order to save it for future use.", cancelTitle: "Ok", actions: [UIAlertAction(title: "Try again", style: .default, handler: { (action) in
                            self.doneButtonPressed()
                        })])
                    }
                    
                }))
        }else {
            submit()
        }
        
    }
    
    open func submit() {
        labelOption.updateFromFormValues(formValues: form.values())
        if needsName {let _ = labelOption.save()}
        navigationController?.popViewController(animated: true)
        labelOptionsDelegate?.labelOptionViewControllerFinished(index: labelOptionIndex,labelOption: labelOption)
    }
    
    
    
    
    
    open func flash(title:String?, message:String?, textFieldConfigurator:((UITextField) -> Void)? = nil, cancelTitle:String?, actions:UIAlertAction?...) {
        NGAExecute.performOnMainQueue() { () -> Void in
            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
            if let textFieldConfigurator = textFieldConfigurator {alertController.addTextField(configurationHandler: textFieldConfigurator)}
            let cancelBlock:AlertActionBlock = {(action:UIAlertAction) -> Void in }
            let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.cancel, handler: cancelBlock)
            alertController.addAction(cancelAction)
            for action in actions {if let action = action {alertController.addAction(action)}}
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
//    func flash(title title:String?, message:String?, cancelTitle:String?, actions:[UIAlertAction]?) {
//        NGAExecute.performOnMainQueue() { () -> Void in
//            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
//            let cancelBlock:AlertActionBlock = {(action:UIAlertAction) -> Void in }
//            let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel, handler: cancelBlock)
//            alertController.addAction(cancelAction)
//            if let actions = actions {for action in actions {alertController.addAction(action)}}
//            self.present(alertController, animated: true, completion: nil)
//        }
//    }
}



//struct PictureLabelSettings {
//    enum TextAlignment:String {
//        case Left, Center, Right
//    }
//    
//    enum LabelPosition:String {
//        case TopLeft = "Top left"
//        case TopRight = "Top right"
//        case BottomLeft = "Bottom left"
//        case BottomRight = "Bottom right"
//    }
//}
//
//
//
//
//class LabelOption {
//    var name:String?
//    var text:String?
//    var timestamp:Bool = false
//    var gps:Bool = false
//    var textColor:UIColor = UIColor.blackColor()
//    var backgroundColor:UIColor = UIColor.clearColor()
//    var labelPosition:PictureLabelSettings.LabelPosition = .TopLeft
//    var textAlignment:PictureLabelSettings.TextAlignment = .Left
//    init() {}
//    init(formValues:[String:Any?]) {
//        updateFromFormValues(formValues)
//    }
//    func updateFromFormValues(formValues:[String:Any?]) {
//        text = formValues.stringForKey("custom text")
//        timestamp =? formValues.boolForKey("timestamp")
//        gps =? formValues.boolForKey("gps")
//        labelPosition =? PictureLabelSettings.LabelPosition(raw: formValues.stringForKey("label position"))
//        textAlignment =? PictureLabelSettings.TextAlignment(raw: formValues.stringForKey("text alignment"))
//        textColor = UIColor(red: (formValues.valueForKey("rt") as? Float)?.toCGFloat() ?? 0,
//                            green: (formValues.valueForKey("gt") as? Float)?.toCGFloat() ?? 0,
//                            blue: (formValues.valueForKey("bt") as? Float)?.toCGFloat() ?? 0,
//                            alpha: 1.0)
//        backgroundColor = formValues.boolForKey("background") ?? false ?
//            UIColor(red: (formValues.valueForKey("rb") as? Float)?.toCGFloat() ?? 0,
//                    green: (formValues.valueForKey("gb") as? Float)?.toCGFloat() ?? 0,
//                    blue: (formValues.valueForKey("bb") as? Float)?.toCGFloat() ?? 0,
//                    alpha: 1.0) :
//            .clearColor()
//    }
//}





