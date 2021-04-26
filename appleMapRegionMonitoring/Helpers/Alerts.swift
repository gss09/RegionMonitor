//
//  Alerts.swift
//  appleMapRegionMonitoring
//
//  Created by GSS on 2021-04-25.
//

import Foundation
import UIKit

class Alerts{
    static let shared = Alerts()
    //MARK: - Alert without action
    
    func displayAlertWithoutAction(title: String,alertTitle:String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: alertTitle, style: .default, handler: { (action) in
            
        }))
        if let window = UIApplication.shared.windows.first, let viewController = window.rootViewController{
            viewController.present(alert, animated: true, completion: nil)
        }
    }
    
    
}
