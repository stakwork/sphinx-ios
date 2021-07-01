//
//  Library
//
//  Created by Tomas Timinskas on 09/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

protocol ChatListDataSourceDelegate: class {
    func didTapChatRow(object: ChatListCommonObject)
    func didTapAddNewContact()
    func didTapCreateGroup()
}

class ChatListDataSource : NSObject {
    weak var delegate: ChatListDataSourceDelegate?
    var tableView : UITableView!
    var chatListObjects = [ChatListCommonObject]()
    
    init(tableView: UITableView, delegate: ChatListDataSourceDelegate) {
        super.init()
        self.tableView = tableView
        self.delegate = delegate
    }
    
    func setDataAndReload(chatListObjects: [ChatListCommonObject]) {
        self.chatListObjects = chatListObjects
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()
    }
    
    func updateContactAndReload(object: ChatListCommonObject) {
        var contactRowIndex:Int? = nil
        
        guard let contact = object as? UserContact else {
            return
        }
        contact.image = nil
        
        for (index, o) in  chatListObjects.enumerated() {
            let c = (o as? UserContact) ?? (o as? Chat)?.getContact()
            if let c = c {
                var isContactToReplace = false

                if let pk = c.publicKey, let cpk = contact.publicKey, pk != "" && pk == cpk {
                    isContactToReplace = true
                } else if let i = c.invite, let cI = contact.invite, let iS = i.inviteString, let cIS = cI.inviteString {
                    if iS == cIS {
                        isContactToReplace = true
                    }
                }

                if isContactToReplace {
                    chatListObjects[index] = contact.getConversation() ?? contact
                    contactRowIndex = index
                    break
                }
            }
        }

        guard let indexToUpdate = contactRowIndex else {
            return
        }

        let indexPath = IndexPath(row: indexToUpdate, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func updateChatAndReload(object: ChatListCommonObject) {
        var chatRowIndex:Int? = nil
        
        guard let chat = object as? Chat else {
            return
        }

        for (index, o) in  chatListObjects.enumerated() {
            let chatObject = (o as? Chat) ?? o.getConversation()
            
            if let c = chatObject {
                if c.id == chat.id {
                    chatListObjects[index] = chat
                    chatRowIndex = index
                    break
                }
            }
        }

        guard let indexToUpdate = chatRowIndex else {
            return
        }

        let indexPath = IndexPath(row: indexToUpdate, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: .none)
    }
}

extension ChatListDataSource : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row < chatListObjects.count {
            return Constants.kChatListRowHeight
        } else {
            return 100.0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ChatListTableViewCell {
            let chatListObject = chatListObjects[indexPath.row]
            let isLastRow = indexPath.row == chatListObjects.count - 1
            
            if chatListObject.isConfirmed() {
                cell.configureChatListRow(object: chatListObject, isLastRow: isLastRow)
            } else if let contact = chatListObject as? UserContact {
                cell.configureInvitation(contact: contact, isLastRow: isLastRow)
            }
        } else if let cell = cell as? AddContactTableViewCell {
            cell.delegate = self
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) {
            cell.setSelected(false, animated: false)
        }
        
        if indexPath.row < chatListObjects.count {
            let chatListObject = chatListObjects[indexPath.row]
            delegate?.didTapChatRow(object: chatListObject)
        }
    }
}

extension ChatListDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatListObjects.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row < chatListObjects.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "ChatListTableViewCell", for: indexPath) as! ChatListTableViewCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "AddContactTableViewCell", for: indexPath) as! AddContactTableViewCell
            return cell
        }
    }
}

extension ChatListDataSource : AddFriendRowButtonDelegate {
    func didTouchAddFriend() {
        delegate?.didTapAddNewContact()
    }
    
    func didTouchCreateGroup() {
        delegate?.didTapCreateGroup()
    }
}
