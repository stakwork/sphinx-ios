//
//  PaidMessagePreviewViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class PaidMessagePreviewViewController: UIViewController {
    
    @IBOutlet weak var previewTableView: UITableView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    var message: TransactionMessage? = nil
    var chat: Chat! = nil
    var messageTableCellState: MessageTableCellState? = nil
    
    static func instantiate() -> PaidMessagePreviewViewController {
        let viewController = StoryboardScene.Chat.paidMessagePreviewViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configurePreview()
        configureMessageWith(text: "", andPrice: 0)
    }

    func configurePreview() {
        previewTableView.registerCell(NewMessageTableViewCell.self)
        previewTableView.delegate = self
        previewTableView.dataSource = self
    }

    func configureMessageWith(
        text: String,
        andPrice price: Int
    ) {
        let isMessageEmpty = text.isEmpty
        previewTableView.isHidden = isMessageEmpty
        loadingLabel.isHidden = !isMessageEmpty

        if isMessageEmpty {
            return
        }
        
        guard let owner = UserContact.getOwner() else {
            return
        }

        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        if chat == nil {
            chat = Chat(context: managedContext)
        }
        
        chat.createdAt = Date()

        if message == nil {
            message = TransactionMessage(context: managedContext)
        }
        
        let mediaTokenPrice = "amt=\(price)&ttl=undefined".base64Encoded ?? ""
        
        message!.messageContent = text
        message!.encrypted = false
        message!.senderId = UserData.sharedInstance.getUserId()
        message!.date = Date()
        message!.type = TransactionMessage.TransactionMessageType.attachment.rawValue
        message!.mediaType = "sphinx/text"
        message!.mediaToken = "test.test.test.test.\(mediaTokenPrice)"
        
        messageTableCellState = MessageTableCellState(
            message: message,
            chat: chat,
            owner: owner,
            contact: nil,
            tribeAdmin: nil,
            separatorDate: nil,
            bubbleState: MessageTableCellState.BubbleState.Isolated,
            invoiceData: (false, false)
        )

        previewTableView.rowHeight = UITableView.automaticDimension
        previewTableView.estimatedRowHeight = 200.0
        previewTableView.reloadData()
        resizeTableView()
    }

    func removeProvisionalMessage() {
        if let message = message {
            CoreDataManager.sharedManager.deleteObject(object: message)
        }
        if let chat = chat {
            CoreDataManager.sharedManager.deleteObject(object: chat)
        }
    }

    func resizeTableView() {
        previewTableView.layoutIfNeeded()
        tableViewHeightConstraint.constant = previewTableView.contentSize.height + 17
        previewTableView.superview?.layoutIfNeeded()
    }
}

extension PaidMessagePreviewViewController : UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewMessageTableViewCell", for: indexPath) as! NewMessageTableViewCell
        
        if let messageTableCellState = messageTableCellState {
            cell.configureWith(
                messageCellState: messageTableCellState,
                mediaData: nil,
                threadOriginalMsgMediaData: nil,
                tribeData: nil,
                linkData: nil,
                botWebViewData: nil,
                uploadProgressData: nil,
                delegate: nil,
                searchingTerm: nil,
                indexPath: indexPath
            )
        }
        
        return cell
    }
}
