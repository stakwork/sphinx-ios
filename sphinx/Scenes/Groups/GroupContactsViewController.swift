//
//  GroupContactsViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class GroupContactsViewController: CommonGroupContactsViewController {
    
    weak var delegate: NewContactVCDelegate?
    
    static func instantiate(delegate: NewContactVCDelegate?, chat: Chat? = nil) -> GroupContactsViewController {
        let viewController = StoryboardScene.Groups.groupContactsViewController.instantiate()
        viewController.delegate = delegate
        viewController.chat = chat
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
    }
    
    func configureView() {
        let existingGroup = (chat != nil)
        titleLabel.text = existingGroup ? "add.contacts".localized : "select.contacts".localized
        nextButton.setTitle(existingGroup ? "done.upper".localized : "next.upper".localized, for: .normal)
    }
    
    override func getContactsToShow() -> [UserContact] {
        if let chat = chat {
            let existingContactIds = chat.getContacts().map { return $0.id }
            return UserContact.getAllExcluding(ids: existingContactIds).filter { !$0.isOwner && !$0.shouldBeExcluded() }
        } else {
            return UserContact.getAll().filter { !$0.isOwner && !$0.shouldBeExcluded() }
        }
    }
    
    override func getExistingContacts() -> [UserContact] {
        return chat?.getContacts().filter { !$0.isOwner } ?? []
    }
    
    override func getTableTitle() -> String {
        return "contacts.upper".localized
    }
    
    @IBAction func nextButtonTouched() {
        groupsManager.setContactIds(contactIds: selectedContactIds)
        
        if let _ = chat {
            addMembers()
            return
        }
        
        let groupNameVC = GroupNameViewController.instantiate(delegate: delegate)
        self.navigationController?.pushViewController(groupNameVC, animated: true)
    }
    
    func addMembers() {
        let (valid, params) = groupsManager.getAddMembersParams()
        
        guard let chat = chat, valid else {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            return
        }
        
        loading = true
        
        API.sharedInstance.addMembers(id: chat.id, params: params, callback: { chatJson in
            if let chat = Chat.insertChat(chat: chatJson) {
                self.delegate?.shouldReloadChat?(chat: chat)
            }
            AlertHelper.showAlert(title: "generic.success.title".localized, message: "member.join.soon".localized, completion: {
                self.backButtonTouched()
            })
        }, errorCallback: {
            self.loading = false
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
        })
    }
    
    @IBAction func backButtonTouched() {
        if let navigationController = self.navigationController, navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
        } else {
            self.dismiss(animated: true)
        }
    }
}
