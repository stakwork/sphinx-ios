//
//  SubscriptionFormViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

protocol SubscriptionFormDelegate: class {
    func shouldUpdate(contact: UserContact?)
}

class SubscriptionFormViewController: KeyboardEventsViewController {
    
    weak var delegate: SubscriptionFormDelegate?
    
    static func instantiate() -> SubscriptionFormViewController {
        let viewController = StoryboardScene.Subscription.subscriptionFormViewController.instantiate()
        return viewController
    }
    
    var isKeyboardVisible = false
    
    var formDataSource : SubscriptionFormDataSource!
    let subscriptionManager = SubscriptionManager.sharedInstance

    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var subscriptionTableView: UITableView!
    @IBOutlet weak var stateSwitch: UISwitch!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var deleteButton: UIButton!
    
    let kHeaderHeight: CGFloat = 62
    let kSubscribeButtonHeight: CGFloat = 112
    let kKeyboardAccessoryViewHeight: CGFloat = 42
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewTitle.addTextSpacing(value: 2)
        
        stateSwitch.isHidden = true
        stateLabel.isHidden = true
        stateSwitch.tintColor = UIColor.Sphinx.PrimaryGreen
        stateSwitch.onTintColor = UIColor.Sphinx.PrimaryGreen
        
        deleteButton.tintColorDidChange()
        
        setSubscriptionInfo()
        
        subscriptionTableView.registerCell(SubscriptionFormTableViewCell.self)
        subscriptionTableView.registerCell(SubscriptionFormButtonTableViewCell.self)
        
        formDataSource = SubscriptionFormDataSource(delegate: self, tableView: subscriptionTableView, subscription: subscriptionManager.contact?.getCurrentSubscription())
        subscriptionTableView.backgroundColor = UIColor.Sphinx.Body
        subscriptionTableView.delegate = formDataSource
        subscriptionTableView.dataSource = formDataSource
        subscriptionTableView.reloadData()
    }
    
    func setSubscriptionInfo() {
        if let subscription = subscriptionManager.contact?.getCurrentSubscription() {
            subscriptionManager.setValuesFrom(subscription: subscription)
            
            stateSwitch.isHidden = false
            stateLabel.isHidden = false
            deleteButton.isHidden = false
            
            stateLabel.text = subscription.isPaused() ? "paused.upper".localized : (subscription.hasEnded() ? "ended.upper".localized : "active.upper".localized)
            stateSwitch.setOn(subscription.isActive(), animated: false)
        }
    }
    
    @objc override func keyboardWillShow(_ notification: Notification) {
        isKeyboardVisible = true
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            let contentOffset = subscriptionTableView?.contentOffset ?? CGPoint.zero
            var contentInset:UIEdgeInsets = subscriptionTableView.contentInset
            contentInset.bottom = keyboardSize.height
            subscriptionTableView.contentInset = contentInset
            subscriptionTableView.contentOffset = contentOffset
        }
    }
    
    @objc override func keyboardWillHide(_ notification: Notification) {
        isKeyboardVisible = false
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        let contentOffset = subscriptionTableView?.contentOffset ?? CGPoint.zero
        subscriptionTableView.contentInset = contentInset
        subscriptionTableView.contentOffset = contentOffset
    }
    
    @IBAction func backButtonTouched() {
        if subscriptionManager.isFormEmpty() || subscriptionManager.contact?.getCurrentSubscription() != nil {
            self.navigationController?.popViewController(animated: true)
            return
        }
        
        AlertHelper.showTwoOptionsAlert(title: "warning".localized, message: "leave.lose.unsaved.changed".localized, confirm: {
            self.navigationController?.popViewController(animated: true)
        })
    }
}
