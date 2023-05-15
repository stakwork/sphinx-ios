//
//  InvoiceManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class InvoiceManager {
    
    class var sharedInstance : InvoiceManager {
        struct Static {
            static let instance = InvoiceManager()
        }
        return Static.instance
    }
    
    struct InvoiceDetails {
        var name : String? = nil
        var imgurl : String? = nil
        var secret : String? = nil
        var amount : Int? = nil
    }
    
    var currentInvoiceDetails : InvoiceDetails? = nil
    
    func resetValues() {
        currentInvoiceDetails = nil
    }
    
    func isInvoiceDetailsValid() -> Bool {
        guard let invoiceDetails = currentInvoiceDetails else {
            return false
        }
        
        guard let _ = invoiceDetails.name else {
            return false
        }
        
        guard let _ = invoiceDetails.amount else {
            return false
        }
        
        return true
    }
    
    func setValueFrom(invoiceDetailsString: String) -> (Bool, InvoiceDetails) {
        var invoiceDetails = InvoiceDetails()
        let imageComponents = invoiceDetailsString.components(separatedBy: "imgurl=")
        if imageComponents.count > 0 {
            if imageComponents.count > 1 {
                if let imageUrl = String(imageComponents[1]).decodeUrl() {
                    invoiceDetails.imgurl = imageUrl.base64Decoded
                }
            }
            
            let subscriptionComponents = String(imageComponents[0]).split(separator: "&")
            for component in subscriptionComponents {
                let elements = component.split(separator: "=")
                if elements.count == 2 {
                    let key = String(elements[0])
                    if let value = String(elements[1]).decodeUrl() {
                        switch(key) {
                        case "amount":
                            if let a = Int(value) {
                                invoiceDetails.amount = a
                            }
                        case "secret":
                            invoiceDetails.secret = value
                        case "name":
                            invoiceDetails.name = value
                        default:
                            break
                        }
                    }
                }
            }
        }
        currentInvoiceDetails = invoiceDetails
        
        return (isInvoiceDetailsValid(), invoiceDetails)
    }
    
    func goToCreateInvoiceDetails(
        vc: UIViewController,
        delegate: PaymentInvoiceDelegate? = nil
    ) -> Bool {
        
        if let invoiceQuery = UserDefaults.Keys.invoiceQuery.get(defaultValue: ""), invoiceQuery != "" {
            UserDefaults.Keys.invoiceQuery.removeValue()
            resetValues()
            
            let (valid, invoiceDetails) = setValueFrom(invoiceDetailsString: invoiceQuery)
            if valid {
                let createInvoiceDetailsVC = CreateInvoiceDetailsViewController.instantiate(invoiceDetails: invoiceDetails, delegate: delegate)
                vc.presentNavigationControllerWith(vc: createInvoiceDetailsVC)
                return true
            }
        }
        return false
    }
}
