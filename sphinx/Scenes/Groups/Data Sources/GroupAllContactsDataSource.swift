//
//  GroupAllContactsDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol GroupAllContactsDataSourceDelegate: class {
    func didAddedContactWith(id: Int)
    func didRemoveContactWith(id: Int)
    func didToggleAll(selected: Bool)
}

class GroupAllContactsDataSource: NSObject {
    
    weak var delegate: GroupAllContactsDataSourceDelegate?
    var tableView: UITableView!
    var selectAllButton: UIButton!
    
    let kCellHeight: CGFloat = 63.0
    let kHeaderHeight: CGFloat = 30.0
    
    var searchTerm = ""
    var tableTitle = ""
    var contacts = [UserContact]()
    var pendingContacts = [UserContact]()
    var existingContactsCount = 0
    
    var groupContacts = [GroupContact]()
    var groupPendingContacts = [GroupContact]()
    
    let kGroupMembersMax = 20
    let kHeaderMargin: CGFloat = 16
    let kHeaderLabelFont = UIFont(name: "Roboto-Medium", size: 14.0)!
    let kHeaderButtonFont = UIFont(name: "Roboto-Bold", size: 11.0)!
    
    struct GroupContact {
        var id: Int! = nil
        var isOwner: Bool = false
        var nickname: String? = nil
        var avatarUrl: String? = nil
        var pubkey: String? = nil
        var selected: Bool = false
        var firstOnLetter: Bool = false
        
        public func getName() -> String {
            return getUserName()
        }
        
        func getUserName() -> String {
            if isOwner {
                return "name.you".localized
            }
            if let nn = nickname, nn != "" {
                return nn
            }
            return "name.unknown".localized
        }
        
        public func getColor() -> UIColor {
            let key = "\(self.id!)-color"
            return UIColor.getColorFor(key: key)
        }
    }
    
    let kSelectAllButtonWidht: CGFloat = 120
    let kTableHaderTag: Int = 100
    
    init(tableView: UITableView, delegate: GroupAllContactsDataSourceDelegate?, title: String) {
        super.init()
        self.tableView = tableView
        self.delegate = delegate
        self.tableTitle = title
    }
    
    func reloadContacts(contacts: [UserContact], existingContactsCount:Int = 0) {
        self.existingContactsCount = existingContactsCount
        self.contacts = contacts
        self.processContacts()
        self.tableView.reloadData()
    }
    
    func processContacts(searchTerm: String = "", selectedContactIds: [Int] = []) {
        self.groupContacts = []
        self.searchTerm = searchTerm
        
        var lastLetter = ""
        
        for contact in  contacts {
            let nickName = contact.getName()
            
            if searchTerm != "" && !nickName.lowercased().contains(searchTerm) {
                continue
            }
            
            if let initial = nickName.first {
                let initialString = String(initial)
            
                var groupContact = GroupContact()
                groupContact.id = contact.id
                groupContact.nickname = contact.nickname
                groupContact.isOwner = contact.isOwner
                groupContact.avatarUrl = contact.avatarUrl
                groupContact.selected = selectedContactIds.contains(contact.id)
                groupContact.firstOnLetter = (initialString != lastLetter)
                
                lastLetter = initialString
                
                groupContacts.append(groupContact)
            }
        }
    }
    
    func unselect(contact: UserContact) {
        let index = groupContacts.index(where: { (item) -> Bool in
            return item.id == contact.id
        })
        
        if let index = index {
            groupContacts[index].selected = false
            tableView.reloadRows(at: [IndexPath(row: index, section: 0)], with: .none)
        }
        updateTableHeader()
    }
    
    func getSelectedContactsCount() -> Int {
        return groupContacts.filter { $0.selected }.count + existingContactsCount
    }
}

extension GroupAllContactsDataSource : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kCellHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? GroupContactTableViewCell {
            let gc = groupContacts[indexPath.row]
            cell.configureFor(groupContact: gc)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if groupContacts.count > 0 {
            return kHeaderHeight
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let windowWidth = WindowsManager.getWindowWidth()
        let headerView = UIView(frame: CGRect(x: 0, y: 0, width: windowWidth, height: kHeaderHeight))
        headerView.backgroundColor = UIColor.Sphinx.AddressBookHeader
        
        let headerLabel = UILabel(frame: CGRect(x: kHeaderMargin, y: 0, width: windowWidth - (kHeaderMargin * 2), height: kHeaderHeight))
        headerLabel.font = kHeaderLabelFont
        headerLabel.textColor = UIColor.Sphinx.SecondaryText
        headerLabel.text = tableTitle.uppercased()
        
        let buttonTitle = areAllSelected() ? "unselect.all.upper".localized : "select.all.upper".localized
        let buttonWidth = getSelectButtonWidth()
        selectAllButton = UIButton(frame: CGRect(x: headerView.frame.size.width - buttonWidth - kHeaderMargin, y: 0, width: buttonWidth, height: kHeaderHeight))
        selectAllButton.titleLabel?.font = kHeaderButtonFont
        selectAllButton.contentHorizontalAlignment = .right
        selectAllButton.setTitleColor(UIColor.Sphinx.SecondaryText, for: .normal)
        selectAllButton.setTitle(buttonTitle, for: .normal)
        selectAllButton.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(selectAllButtonTouched)))
        selectAllButton.tag = kTableHaderTag
        
        headerView.addSubview(headerLabel)
        headerView.addSubview(selectAllButton)
        
        return headerView
    }
    
    @objc func selectAllButtonTouched() {
        let allSelected = areAllSelected()
        
        if groupContacts.count >= (kGroupMembersMax - 1) {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: String(format: "add.members.limit".localized, kGroupMembersMax))
            return
        }
        
        for i in 0..<groupContacts.count {
            groupContacts[i].selected = !allSelected
        }
        
        reloadRowsAndHeader()
        delegate?.didToggleAll(selected: !allSelected)
    }
    
    func getSelectButtonWidth() -> CGFloat {
        let selectAllWidth = kHeaderButtonFont.sizeOfString("unselect.all.upper".localized, height: Double(kHeaderHeight)).width
        let deselectAllWidth = kHeaderButtonFont.sizeOfString("select.all.upper".localized, height: Double(kHeaderHeight)).width
        return max(selectAllWidth, deselectAllWidth)
    }
    
    func updateTableHeader() {
        let buttonTitle = areAllSelected() ? "unselect.all.upper".localized : "select.all.upper".localized
        selectAllButton.setTitle(buttonTitle, for: .normal)
    }
    
    func reloadRowsAndHeader() {
        for cell in  tableView.visibleCells {
            if let cell = cell as? GroupContactTableViewCell, let indexPath = tableView.indexPath(for: cell) {
                let groupContact = groupContacts[indexPath.row]
                cell.configureFor(groupContact: groupContact)
            }
        }
        updateTableHeader()
    }
    
    func areAllSelected() -> Bool {
        let selectedCount = groupContacts.filter { $0.selected }.count
        return selectedCount == groupContacts.count
    }
}

extension GroupAllContactsDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return groupContacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "GroupContactTableViewCell", for: indexPath) as! GroupContactTableViewCell
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let cell = tableView.cellForRow(at: indexPath) as? GroupContactTableViewCell {
            var groupContact = groupContacts[indexPath.row]
            let contactId = groupContact.id!
            let selected = groupContact.selected
            
            if selected {
                groupContact.selected = false
                delegate?.didRemoveContactWith(id: contactId)
            } else {
                if getSelectedContactsCount() >= (kGroupMembersMax - 1) {
                    AlertHelper.showAlert(title: "warning".localized, message: "reach.members.limit".localized)
                    return
                }
                
                groupContact.selected = true
                delegate?.didAddedContactWith(id: contactId)
            }
            
            groupContacts[indexPath.row] = groupContact
            cell.configureFor(groupContact: groupContact)
            updateTableHeader()
        }
    }
}
