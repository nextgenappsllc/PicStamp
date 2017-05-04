//
//  Config.swift
//  Pods
//
//  Created by Jose Castellanos on 4/28/17.
//
//

import Foundation

class PicStampConfig {
    static var defaultFont = UIFont.systemFont(ofSize: UIFont.systemFontSize)
    static var defaultBoldFont = UIFont.boldSystemFont(ofSize: UIFont.systemFontSize)
    static var bundle:Bundle? {
        get{
            let bundle = Bundle(for: PicStampConfig.self)
            let path = bundle.path(forResource: "PicStamp", ofType: "bundle")
            if let path = path {return Bundle(path: path)}
            return nil
        }
    }
    
    class func imageNamed(_ name:String) -> UIImage? {
        return UIImage(named: name, in: bundle, compatibleWith: nil)
    }
}
