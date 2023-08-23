//
//  SubscriptionManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class SubscriptionManager {
    
    class var sharedInstance : SubscriptionManager {
        struct Static {
            static let instance = SubscriptionManager()
        }
        return Static.instance
    }
    
    struct SubscriptionQR {
        var nickname : String? = nil
        var imgurl : String? = nil
        var pubKey : String? = nil
        var amount : Int? = nil
        var interval : String? = nil
        var endNumber : Int? = nil
        var endDate : Date? = nil
    }
    
    enum AmountOptions: Int {
        case amount500
        case amount1000
        case amount2000
        case customAmount
    }
    
    let presetAmounts = [500, 1000, 2000]
    
    enum IntervalOptions: Int {
        case day
        case week
        case month
    }
    
    let presetIntervals = ["daily", "weekly", "monthly"]
    let presetIntervalUnits = ["day", "week", "month"]
    
    enum EndRuleOptions: Int {
        case makeXPayments
        case limitDate
    }
    
    var amountIndexSelected: Int?
    var intervalIndexSelected: Int?
    var endRuleIndexSelected: Int?
    var customAmount: Int?
    var paymentsCount: Int?
    var endDate: Date?
    
    var contact: UserContact?
    
    func resetValues() {
        amountIndexSelected = nil
        intervalIndexSelected = nil
        endRuleIndexSelected = nil
        customAmount = nil
        paymentsCount = nil
        endDate = nil
        contact = nil
    }
    
    func isFormEmpty() -> Bool {
        if amountIndexSelected == nil && intervalIndexSelected == nil && endRuleIndexSelected == nil {
            return true
        }
        return false
    }
    
    func setValuesFrom(subscription: Subscription) {
        if let amount = subscription.amount?.intValue {
            if let indexOf = presetAmounts.index(of: amount) {
                amountIndexSelected = indexOf
            } else{
                amountIndexSelected = AmountOptions.customAmount.rawValue
                customAmount = amount
            }
        }
        
        if subscription.endNumber > 0 {
            paymentsCount = subscription.endNumber
            endRuleIndexSelected = EndRuleOptions.makeXPayments.rawValue
        } else if let endD = subscription.endDate {
            endDate = endD
            endRuleIndexSelected = EndRuleOptions.limitDate.rawValue
        }
        
        if let cron = subscription.cron {
            let interval = Subscription.parseCron(cron: cron)
            if let indexOf = presetIntervals.index(of: interval) {
                intervalIndexSelected = indexOf
            }
        }
    }
    
    func setValuesFrom(subscriptionQR: SubscriptionQR) -> Bool {
        var valid = true
        
        guard let _ = subscriptionQR.pubKey else {
            return false
        }
        
        if let amount = subscriptionQR.amount {
            if let indexOf = presetAmounts.index(of: amount) {
                amountIndexSelected = indexOf
            } else{
                amountIndexSelected = AmountOptions.customAmount.rawValue
                customAmount = amount
            }
        } else {
            valid = false
        }
        
        if let interval = subscriptionQR.interval {
            if let indexOf = presetIntervalUnits.index(of: interval) {
                intervalIndexSelected = indexOf
            }
        } else {
            valid = false
        }
    
        if let endNumber = subscriptionQR.endNumber {
            paymentsCount = endNumber
            endRuleIndexSelected = EndRuleOptions.makeXPayments.rawValue
        } else if let endD = subscriptionQR.endDate {
            endDate = endD
            endRuleIndexSelected = EndRuleOptions.limitDate.rawValue
        } else {
            valid = false
        }
        
        return valid
    }
    
    func setValueFrom(subscriptionString: String) -> (Bool, SubscriptionQR) {
        var subscriptionQR = SubscriptionQR()
        let imageComponents = subscriptionString.components(separatedBy: "imgurl=")
        if imageComponents.count > 0 {
            if imageComponents.count > 1 {
                if let imageUrl = String(imageComponents[1]).decodeUrl() {
                    subscriptionQR.imgurl = imageUrl.base64Decoded
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
                                subscriptionQR.amount = a
                            }
                        case "publicKey":
                            subscriptionQR.pubKey = value
                        case "name":
                            subscriptionQR.nickname = value
                        case "interval":
                            subscriptionQR.interval = getIntervalUnit(interval: value)
                        case "endNumber":
                            if let eN = Int(value) {
                                subscriptionQR.endNumber = eN
                            }
                        case "endDate":
                            subscriptionQR.endDate = Date.getDateFromString(dateString: value, format: "dd/MM/yyyy")
                        default:
                            break
                        }
                    }
                }
            }
        }
        return (setValuesFrom(subscriptionQR: subscriptionQR), subscriptionQR)
    }
    
    func getIntervalUnit(interval: String) -> String {
        if let indexOf = presetIntervals.index(of: interval) {
            return presetIntervalUnits[indexOf]
        }
        return ""
    }
    
    func isFormValid() -> Bool {
        guard let amountIndex = amountIndexSelected else {
            return false
        }
        
        guard let _ = intervalIndexSelected else {
            return false
        }
        
        guard let endRuleIndex = endRuleIndexSelected else {
            return false
        }
        
        if amountIndex == AmountOptions.customAmount.rawValue {
            guard let _ = customAmount else {
                return false
            }
        }
        
        if endRuleIndex == EndRuleOptions.makeXPayments.rawValue {
            guard let _ = paymentsCount else {
                return false
            }
        } else if endRuleIndex == EndRuleOptions.limitDate.rawValue {
            guard let _ = endDate else {
                return false
            }
        }
        
        return true
    }
    
    func getAmount() -> Int? {
        if let amount = amountIndexSelected {
            if let customA = customAmount, amount == AmountOptions.customAmount.rawValue {
                return customA
            } else if presetAmounts.count > amount {
                return presetAmounts[amount]
            }
        }
        return nil
    }
    
    func getInterval() -> String? {
        if let interval = intervalIndexSelected {
            return presetIntervals[interval]
        }
        return nil
    }
    
    func getEndDate() -> String? {
        if let endRuleIndex = endRuleIndexSelected {
            if let endDate = endDate, endRuleIndex == EndRuleOptions.limitDate.rawValue {
                return endDate.getStringFromDate(format: "MMM dd, yyyy")
            }
        }
        return nil
    }
    
    func getEndNumber() -> Int? {
        if let endRuleIndex = endRuleIndexSelected {
            if let paymentsCount = paymentsCount, endRuleIndex == EndRuleOptions.makeXPayments.rawValue {
                return paymentsCount
            }
        }
        return nil
    }
    
    func getSubscriptionParams() -> [String : AnyObject] {
        var parameters = [String : AnyObject]()
        
        if let amount = getAmount() {
            parameters["amount"] = amount as AnyObject?
        }
        
        if let interval = getInterval() {
            parameters["interval"] = interval as AnyObject?
        }
        
        if let contact = contact {
            parameters["contact_id"] = contact.id as AnyObject?
        }
        
        if let chat = contact?.getChat() {
            parameters["chat_id"] = chat.id as AnyObject?
        }
        
        if let endDate = getEndDate() {
            parameters["endDate"] = endDate as AnyObject?
        } else if let paymentsC = getEndNumber() {
            parameters["endNumber"] = paymentsC as AnyObject?
        }
        
        return parameters
    }
    
    func createOrEditSubscription(completion: @escaping (Subscription?, String) -> ()) {
        if let subscription = contact?.getCurrentSubscription(), subscription.id >= 0 {
            editSubscription(subscription: subscription, completion: completion)
            return
        }
        
        let params = getSubscriptionParams()
        
        API.sharedInstance.createSubscription(parameters: params, callback: { subscription in
            if let subscription = Subscription.insertSubscription(subscription: subscription) {
                completion(subscription, "")
            }
        }, errorCallback: {
            completion(nil, "generic.error.message".localized)
        })
    }
    
    func editSubscription(subscription: Subscription, completion: @escaping (Subscription?, String) -> ()) {
        let params = getSubscriptionParams()
        
        API.sharedInstance.editSubscription(id: subscription.id, parameters: params, callback: { subscription in
            if let subscription = Subscription.insertSubscription(subscription: subscription) {
                completion(subscription, "")
            }
        }, errorCallback: {
            completion(nil, "generic.error.message".localized)
        })
    }
    
    func deleteSubscription(completion: @escaping (Bool) -> ()) {
        if let subscription = contact?.getCurrentSubscription(), subscription.id >= 0 {
            API.sharedInstance.deleteSubscription(id: subscription.id, callback: { success in
                if success {
                    self.deleteLocalSubscription(subscription: subscription)
                }
                completion(success)
            })
        }
    }
    
    func toggleSubscriptionState(active: Bool, completion: @escaping (Subscription?, String) -> ()) {
        if let subscription = contact?.getCurrentSubscription() {
            let subscriptionId = subscription.id
            let route = active ? "restart" : "pause"
            
            API.sharedInstance.toggleSubscriptionState(route: route, id: subscriptionId, callback: { s in
                if let subscription = Subscription.insertSubscription(subscription: s) {
                    completion(subscription, "")
                }
            }, errorCallback: {
                completion(nil, "generic.error.message".localized)
            })
        }
    }
    
    func deleteLocalSubscription(subscription: Subscription) {
        if let contact = subscription.contact {
            contact.removeFromSubscription(subscription)
            
            CoreDataManager.sharedManager.deleteObject(object: subscription)
        }
    }
    
    //Navigate methods
    func goToSubscriptionDetails(
        vc: UIViewController
    ) -> Bool {
        if let subscriptionQuery = UserDefaults.Keys.subscriptionQuery.get(defaultValue: ""), subscriptionQuery != "" {
            UserDefaults.Keys.subscriptionQuery.removeValue()
            resetValues()
            
            let (valid, subscription) = setValueFrom(subscriptionString: subscriptionQuery)
            
            if let delegate = vc as? QRCodeScannerDelegate, valid {
                
                let subscriptionDetailsVC = SubscriptionDetailsViewController.instantiate(
                    subscriptionQR: subscription,
                    delegate: delegate
                )
                vc.presentNavigationControllerWith(vc: subscriptionDetailsVC)
                
                return true
            }
        }
        return false
    }
}
