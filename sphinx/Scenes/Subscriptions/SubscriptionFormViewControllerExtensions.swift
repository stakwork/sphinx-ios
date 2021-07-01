//
//  SubscriptionFormViewControllerExtensions.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

extension SubscriptionFormViewController : SubscriptionFormDataSourceDelegate {
    
    func shouldShowAlert(title: String, text: String) {
        AlertHelper.showAlert(title: title, message: text)
    }
    
    func toggleSubscriptionState(active: Bool) {
        view.isUserInteractionEnabled = false
        
        subscriptionManager.toggleSubscriptionState(active: active, completion: { subscription, message in
            if let subscription = subscription {
                self.delegate?.shouldUpdate(contact: subscription.contact)
                self.setSubscriptionInfo()
                self.view.isUserInteractionEnabled = true
            } else if message != "" {
                self.shouldShowAlert(title: "generic.error.title".localized, text: "generic.error.message".localized)
                self.setSubscriptionInfo()
                self.view.isUserInteractionEnabled = true
            }
        })
    }
    
    func didTapSubscribeButton() {
        view.endEditing(true)
        view.isUserInteractionEnabled = false
        
        if subscriptionManager.isFormValid() {
            createOrEditSubscription()
        } else {
            subscriptionFailed(title: "generic.error.title".localized, message: "subscription.fields.required".localized)
        }
    }
    
    func createOrEditSubscription() {
        subscriptionManager.createOrEditSubscription(completion: { subscription, message in
            if let subscription = subscription {
                self.subscriptionSucceded(subscription: subscription)
            } else if message != "" {
                self.subscriptionFailed(title: "generic.error.title".localized, message: message)
            }
        })
    }
    
    @IBAction func deleteButtonTouched() {
        AlertHelper.showTwoOptionsAlert(title: "confirm".localized, message: "confirm.delete.subscription".localized, confirm: {
            self.subscriptionManager.deleteSubscription(completion: { success in
                if success {
                    self.navigationController?.popViewController(animated: true)
                } else {
                    AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
                }
            })
        })
    }
    
    @IBAction func stateSwitchChanged(_ sender: Any) {
        if let switchControl = sender as? UISwitch {
            if switchControl.isOn {
                stateLabel.text = "active.upper".localized
            } else {
                stateLabel.text = "paused.upper".localized
            }
            toggleSubscriptionState(active: switchControl.isOn)
        }
    }
    
    func subscriptionFailed(title: String, message: String, success: Bool = false) {
        DispatchQueue.main.async {
            self.view.isUserInteractionEnabled = true
            self.formDataSource.reloadSubscribeButtonRow()
            self.shouldShowAlert(title: title, text: message)
        }
    }
    
    func subscriptionSucceded(subscription: Subscription) {
        delegate?.shouldUpdate(contact: subscription.contact)
        self.navigationController?.popViewController(animated: true)
    }
}
