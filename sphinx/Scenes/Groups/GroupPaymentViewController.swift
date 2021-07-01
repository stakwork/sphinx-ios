//
//  GroupPaymentViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 26/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

@objc protocol GroupPaymentVCDelegate: class {
    @objc optional func willDismissPresentedView(paymentCreated: Bool)
}

class GroupPaymentViewController: CommonGroupContactsViewController {

    weak var delegate: GroupPaymentVCDelegate?
    weak var paymentViewdelegate: PaymentInvoiceDelegate?
    var viewModel: ChatViewModel!
     
    static func instantiate(rootViewController : RootViewController, baseVC: UIViewController, viewModel: ChatViewModel, chat: Chat) -> GroupPaymentViewController {
        let viewController = StoryboardScene.Groups.groupPaymentViewController.instantiate()
        viewController.rootViewController = rootViewController
        viewController.viewModel = viewModel
        viewController.chat = chat
        
        if let delegate = baseVC as? GroupPaymentVCDelegate {
            viewController.delegate = delegate
        }
        if let paymentViewdelegate = baseVC as? PaymentInvoiceDelegate {
            viewController.paymentViewdelegate = paymentViewdelegate
        }

        return viewController
    }
     
    override func getContactsToShow() -> [UserContact] {
        return chat.getContacts().filter { !$0.isOwner && !$0.shouldBeExcluded() }
    }
    
    override func getExistingContacts() -> [UserContact] {
        return []
    }
    
    override func getTableTitle() -> String {
        return "group.members.upper".localized
    }
     
    @IBAction func nextButtonTouched() {
        groupsManager.setContactIds(contactIds: selectedContactIds)
        let contacts = groupsManager.getSelectedContacts(contacts: getContactsToShow())
        
        let viewController = CreateInvoiceViewController.instantiate(contacts: contacts, chat: chat, viewModel: ChatViewModel(), delegate: paymentViewdelegate, paymentMode: CreateInvoiceViewController.paymentMode.send, rootViewController: rootViewController)
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
     
    @IBAction func closeButtonTouched() {
        delegate?.willDismissPresentedView?(paymentCreated: false)
        self.dismiss(animated: true, completion: nil)
    }
}
