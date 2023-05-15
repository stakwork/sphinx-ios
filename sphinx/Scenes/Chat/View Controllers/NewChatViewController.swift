//
//  NewChatViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 10/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData

class NewChatViewController: NewKeyboardHandlerViewController {
    
    @IBOutlet weak var bottomView: NewChatAccessoryView!
    @IBOutlet weak var headerView: ChatHeaderView!
    
    var contact: UserContact?
    var chat: Chat?
    
    var contactsService: ContactsService!
    
    static func instantiate(
        contactObjectId: NSManagedObjectID? = nil,
        chatObjectId: NSManagedObjectID? = nil
    ) -> NewChatViewController {
        let viewController = StoryboardScene.Chat.newChatViewController.instantiate()
        
        if let chatObjectId = chatObjectId {
            viewController.chat = CoreDataManager.sharedManager.getObjectWith(objectId: chatObjectId)
        }
        
        if let contactObjectId = contactObjectId {
            viewController.contact = CoreDataManager.sharedManager.getObjectWith(objectId: contactObjectId)
        }
        
        viewController.contactsService = ContactsService()
        viewController.popOnSwipeEnabled = true
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayouts()
        
        headerView.configureWith(
            chat: self.chat,
            contact: self.contact,
            delegate: self
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        headerView.checkRoute()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    func setupLayouts() {
        headerView.superview?.bringSubviewToFront(headerView)
        
        bottomView.addShadow(location: .top, color: UIColor.black, opacity: 0.1)
        headerView.addShadow(location: .bottom, color: UIColor.black, opacity: 0.1)
    }

    @IBAction func dismissButtonTouched(_ sender: Any) {
        self.view.endEditing(true)
    }
}
