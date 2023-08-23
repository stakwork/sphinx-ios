//
//  AddressBookDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

protocol AddressBookDataSourceDelegate: class {
    func didTapOnContact(contact: UserContact)
    func shouldShowAlert(title: String, text: String)
    func shouldToggleInteraction(enable: Bool)
}

class AddressBookDataSource: NSObject {
    
    weak var delegate: AddressBookDataSourceDelegate?
    var tableView : UITableView!
    
    let kCellHeight: CGFloat = 85.0
    let kHeaderHeight: CGFloat = 38.0
    
    var searchTerm: String? = nil
    var contacts = [UserContact]()
    var sections = [String]()
    var sectionWithContacts = [String: [UserContact]]()
    
    init(tableView: UITableView, delegate: AddressBookDataSourceDelegate) {
        super.init()
        self.tableView = tableView
        self.delegate = delegate
        
        reloadContacts()
    }
    
    func reloadContacts(searchTerm: String? = nil) {
        contacts = UserContact.getAll().filter { !$0.isOwner && !$0.shouldBeExcluded() }
        processContacts(searchTerm: searchTerm)
    }
    
    func processContacts(searchTerm: String? = nil) {
        self.searchTerm = searchTerm
        
        sections = [String]()
        sectionWithContacts = [String: [UserContact]]()
        
        for contact in  contacts {
            let nickName = contact.getName()
            let initial = ((nickName.first != nil) ? nickName.first : Character("u"))?.lowercased()
            
            if let initial = initial {
                if let searchTerm = searchTerm, searchTerm.isNotEmpty && !nickName.lowercased().contains(searchTerm) {
                    continue
                }
                
                let initialString = String(initial)
                if sectionWithContacts[initialString] != nil {
                   sectionWithContacts[initialString]?.append(contact)
                } else {
                   sectionWithContacts[initialString] = [contact]
                   sections.append(initialString)
                }
            }
        }
        
        sections = sections.sorted(by: { $0 < $1 })
        
        for section in sectionWithContacts {
            let orderedSection = section.value.sorted(by: { $0.getName().lowercased() < $1.getName().lowercased() })
            sectionWithContacts[section.key] = orderedSection
        }
    }
}

extension AddressBookDataSource : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return kCellHeight
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ContactTableViewCell {
            let lastOnSection = indexPath.row == tableView.numberOfRows(inSection: indexPath.section) - 1
            let s = sections[indexPath.section]
            if let contact = sectionWithContacts[s]?[indexPath.row] {
                cell.configure(contact: contact, delegate: self, lastOnSection: lastOnSection)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return kHeaderHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let s = sections[section].uppercased()
        let screenWidth = WindowsManager.getWindowWidth()
        let headerView = AddressBookHeaderView(frame: CGRect(x: 0.0, y: 0.0, width: screenWidth, height: kHeaderHeight))
        headerView.configureView(letter: s)
        return headerView
    }
}

extension AddressBookDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return sectionWithContacts.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let s = sections[section]
        return sectionWithContacts[s]?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ContactTableViewCell", for: indexPath) as! ContactTableViewCell
        return cell
    }
}

extension AddressBookDataSource : ContactCellDelegate {
    func shouldGoToContact(contact: UserContact?, cell: UITableViewCell) {
        guard let contact = contact else {
            return
        }
        
        if contact.isBlocked() {
            AlertHelper.showTwoOptionsAlert(
                title: "address-boox.contact-unblock.alert-title".localized,
                message: "address-boox.contact-unblock.alert-message".localized,
                confirm: {
                    self.shouldUnBlockContact(contact: contact, cell: cell)
                }
            )
        } else {
            delegate?.didTapOnContact(contact: contact)
        }
    }
    
    func shouldDeleteContact(contact: UserContact?, cell: UITableViewCell) {
        guard let contact = contact else {
            return
        }
        
        delegate?.shouldToggleInteraction(enable: false)
        
        API.sharedInstance.deleteContact(id: contact.id, callback: { success in
            if success {
                self.deleteContactAndRow(contact: contact, cell: cell)
            } else {
                self.delegate?.shouldToggleInteraction(enable: true)
                self.delegate?.shouldShowAlert(title: "generic.error.title".localized, text: "generic.error.message".localized)
            }
        })
    }
    
    func shouldBlockContact(contact: UserContact?, cell: UITableViewCell) {
        shouldToggleBlockContact(contact: contact, route: .Block, cell: cell)
    }
    
    func shouldUnBlockContact(contact: UserContact?, cell: UITableViewCell) {
        shouldToggleBlockContact(contact: contact, route: .Unblock, cell: cell)
    }
    
    func shouldToggleBlockContact(contact: UserContact?, route: API.ToggleBlockRoute, cell: UITableViewCell) {
        guard let contact = contact else {
            return
        }
        
        delegate?.shouldToggleInteraction(enable: false)
        
        API.sharedInstance.toggleBlockContact(
            id: contact.id,
            route: route,
            callback: { contactJson in
                
                if let _ = UserContact.insertContact(contact: contactJson) {
                    self.updateContactsAndReloadRow(cell: cell)
                    self.delegate?.shouldToggleInteraction(enable: true)
                }
                
            }, errorCallback: {
                
                self.delegate?.shouldToggleInteraction(enable: true)
                self.delegate?.shouldShowAlert(title: "generic.error.title".localized, text: "generic.error.message".localized)
                
            }
        )
    }
    
    func updateContactsAndReloadRow(cell: UITableViewCell) {
        reloadContacts()
        
        if let indexPath = tableView.indexPath(for: cell) {
            tableView.reloadRows(at: [indexPath], with: .fade)
        } else {
            tableView.reloadData()
        }
    }
    
    func deleteContactAndRow(contact: UserContact, cell: UITableViewCell) {
        let contactsCount = contacts.count
        
        deleteObjects(contact: contact)
        contacts = UserContact.getAll().filter { !$0.isOwner && !$0.shouldBeExcluded() }
        processContacts(searchTerm: self.searchTerm)
        
        if contacts.count == contactsCount - 1 {
            deleteCell(cell: cell)
            return
        }
        
        delegate?.shouldToggleInteraction(enable: true)
        delegate?.shouldShowAlert(title: "generic.error.title".localized, text: "generic.error.message".localized)
    }
    
    func deleteObjects(contact: UserContact) {
        CoreDataManager.sharedManager.deleteContactObjectsFor(contact)
    }
    
    func deleteCell(cell: UITableViewCell) {
        if let indexPath = tableView.indexPath(for: cell) {
            if tableView.numberOfRows(inSection: indexPath.section) == 1 {
                tableView.beginUpdates()
                tableView.deleteSections([indexPath.section], with: .automatic)
                tableView.endUpdates()
            } else {
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: .automatic)
                tableView.endUpdates()
            }
        }
        delegate?.shouldToggleInteraction(enable: true)
    }
}
