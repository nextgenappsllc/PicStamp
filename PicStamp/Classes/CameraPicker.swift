//
//  ImagePicker.swift
//  Pic Stamp
//
//  Created by Jose Castellanos on 4/24/16.
//  Copyright © 2016 NextGen Apps LLC. All rights reserved.
//

import Foundation
import NGAEssentials
import CoreLocation

open class CameraPicker: UIImagePickerController, CLLocationManagerDelegate {
    
    open let locationManager = CLLocationManager()
    
    open override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if self.sourceType == UIImagePickerControllerSourceType.camera{
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
    }
    
    
    open func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        switch CLLocationManager.authorizationStatus() {
        case .restricted,.denied:
            var action:UIAlertAction? = nil;let app = UIApplication.shared
            if let url = UIApplicationOpenSettingsURLString.url , app.canOpenURL(url) {
                action = UIAlertAction(title: "Go to Settings", style: .default, handler: {a->Void in app.openURL(url)})
            }
            flash(title: "Error",
                  message: "The app does not have permission to get your location. Please enable this in settings.",
                  cancelTitle: "Ok",
                  actions: action)
        default:
            flash(title: "Error",
                  message: "Your location cannot be determined right now. You will not be able to tag a location to this photo.",
                  cancelTitle: "Ok")
        }
        
    }
    
    
//    //MARK: Pop up
//    func flash(title title:String?, message:String?, cancelTitle:String?, actions:UIAlertAction?...) {
//        NGAExecute.performOnMainQueue() { () -> Void in
//            let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
//            let cancelBlock:(UIAlertAction) -> Void = {(action:UIAlertAction) -> Void in }
//            let cancelAction = UIAlertAction(title: cancelTitle, style: UIAlertActionStyle.Cancel, handler: cancelBlock)
//            alertController.addAction(cancelAction)
//            for action in actions {if let action = action {alertController.addAction(action)}}
//            self.present(alertController, animated: true, completion: nil)
//        }
//    }
    
    
    
}
