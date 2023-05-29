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
    @IBOutlet weak var headerView: NewChatHeaderView!
    
    var contact: UserContact?
    var chat: Chat?
    
    var contactResultsController: NSFetchedResultsController<UserContact>!
    var chatResultsController: NSFetchedResultsController<Chat>!
    
    var contactsService: ContactsService!
    var chatViewModel: ChatViewModel!
    
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    static func instantiate(
        contactId: Int? = nil,
        chatId: Int? = nil
    ) -> NewChatViewController {
        let viewController = StoryboardScene.Chat.newChatViewController.instantiate()
        
        if let chatId = chatId {
            viewController.chat = Chat.getChatWith(id: chatId)
        }
        
        if let contactId = contactId {
            viewController.contact = UserContact.getContactWith(id: contactId)
        }
        
        viewController.contactsService = ContactsService()
        viewController.chatViewModel = ChatViewModel()
        
        viewController.popOnSwipeEnabled = true
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayouts()
        setDelegates()
        setupData()
        configureFetchResultsController()
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
    
    func setupData() {
        headerView.configureHeaderWith(
            chat: self.chat,
            contact: self.contact,
            andDelegate: self
        )
        
        updateChatInfo()
    }
    
    func setDelegates() {
        bottomView.setDelegates(messageFieldDelegate: self)
    }

    @IBAction func dismissButtonTouched(_ sender: Any) {
        contact?.nickname = "Tom Sim"
        contact?.managedObjectContext?.saveContext()
        
        self.view.endEditing(true)
    }
}
