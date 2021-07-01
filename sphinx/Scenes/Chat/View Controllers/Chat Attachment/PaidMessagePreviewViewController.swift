//
//  PaidMessagePreviewViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/04/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class PaidMessagePreviewViewController: UIViewController {
    
    @IBOutlet weak var previewTableView: UITableView!
    @IBOutlet weak var loadingLabel: UILabel!
    @IBOutlet weak var tableViewHeightConstraint: NSLayoutConstraint!
    
    var message: TransactionMessage? = nil
    var messageRow: TransactionMessageRow? = nil
    
    static func instantiate() -> PaidMessagePreviewViewController {
        let viewController = StoryboardScene.Chat.paidMessagePreviewViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePreview()
        configureMessageRow(text: "", price: 0)
    }
    
    func configurePreview() {
        previewTableView.registerCell(PaidMessageSentTableViewCell.self)
        previewTableView.delegate = self
        previewTableView.dataSource = self
    }
    
    func configureMessageRow(text: String, price: Int) {
        let isMessageEmpty = text.isEmpty
        previewTableView.isHidden = isMessageEmpty
        loadingLabel.isHidden = !isMessageEmpty
        
        if isMessageEmpty {
            return
        }
        
        let managedContext = CoreDataManager.sharedManager.persistentContainer.viewContext
        
        if message == nil {
            message = TransactionMessage(context: managedContext)
        }
        message!.messageContent = text
        message!.encrypted = false
        message!.senderId = UserData.sharedInstance.getUserId()
        message!.date = Date()
        message!.uploadingObject = AttachmentObject(data: Data(), mediaKey: "", type: .Text, paidMessage: text, price: price)
        message!.type = TransactionMessage.TransactionMessageType.attachment.rawValue
        message!.mediaType = "sphinx/text"
        
        if messageRow == nil {
            messageRow = TransactionMessageRow(message: message)
        }
        
        previewTableView.reloadData()
        resizeTableView()
    }
    
    func removeProvisionalMessage() {
        if let message = message {
            CoreDataManager.sharedManager.deleteObject(object: message)
        }
    }
    
    func resizeTableView() {
        previewTableView.layoutIfNeeded()
        tableViewHeightConstraint.constant = previewTableView.contentSize.height + 17
        previewTableView.superview?.layoutIfNeeded()
    }
}

extension PaidMessagePreviewViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return getRowHeight()
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return getRowHeight()
    }
    
    func getRowHeight() -> CGFloat {
        if let messageRow = self.messageRow {
            return PaidMessageSentTableViewCell.getRowHeight(messageRow: messageRow)
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let messageRow = self.messageRow {
            let sender = UserContact.getOwner()

            if let cell = cell as? PaidMessageSentTableViewCell {
                cell.configureMessageRow(messageRow: messageRow, contact: sender, chat: nil)
            }
        }
    }
}

extension PaidMessagePreviewViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PaidMessageSentTableViewCell", for: indexPath) as! PaidMessageSentTableViewCell
        return cell
    }
}
