//
//  GroupAddedContactsDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class GroupAddedContactsDataSource: NSObject {
    
    weak var delegate: GroupContactCellDelegate?
    
    var collectionView : UICollectionView!
    
    let kCellHeight: CGFloat = 90.0
    let kCellWidth: CGFloat = 78.0
    
    var searchTerm = ""
    var contacts = [GroupContact]()
    var selectedContactIds = [Int]()
    
    struct GroupContact {
        var contact: UserContact!
        var existing = false
        
        init(contact: UserContact, existing: Bool) {
            self.contact = contact
            self.existing = existing
        }
    }
    
    init(collectionView: UICollectionView, delegate: GroupContactCellDelegate) {
        super.init()
        self.delegate = delegate
        self.collectionView = collectionView
        self.collectionView.contentInset = UIEdgeInsets(top: 0, left: 12, bottom: 0, right: 12)
    }
    
    func addExistingContacts(contacts: [UserContact]) {
        let groupContacts = contacts.map { GroupContact(contact: $0, existing: true) }
        self.contacts.append(contentsOf: groupContacts)
    }
    
    func addContact(contact: UserContact) {
        self.contacts.append(GroupContact(contact: contact, existing: false))
        
        let numberOfRow = self.collectionView.numberOfItems(inSection: 0)
        self.collectionView.insertItems(at: [IndexPath(row: numberOfRow, section: 0)])
        self.collectionView.scrollToItem(at: IndexPath(row: numberOfRow, section: 0), at: .left, animated: true)
    }
    
    func addAll(existingContacts: [UserContact?], contacts: [UserContact?]) {
        self.contacts = []
        
        for contact in existingContacts {
            addContact(contact: contact, existing: true)
        }
        
        for contact in contacts {
            addContact(contact: contact, existing: false)
        }
        
        self.collectionView.reloadData()
        self.collectionView.scrollToItem(at: IndexPath(row: 0, section: 0), at: .left, animated: true)
    }
    
    func removeContact(contact: UserContact) {
        let index = contacts.index(where: { (item) -> Bool in
            return item.contact.id == contact.id
        })
        
        if let index = index {
            self.contacts.remove(at: index)
            self.collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        }
    }
    
    func removeAll(existingContacts: [UserContact?]) {
        self.contacts = []
        
        for contact in existingContacts {
            addContact(contact: contact, existing: true)
        }
        
        self.collectionView.reloadData()
    }
    
    func addContact(contact: UserContact?, existing: Bool) {
        if let contact = contact {
            self.contacts.append(GroupContact(contact: contact, existing: existing))
        }
    }
}

extension GroupAddedContactsDataSource : UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let cell = cell as? GroupContactCollectionViewCell {
            let groupContact = contacts[indexPath.row]
            cell.delegate = delegate
            cell.configureFor(groupContact: groupContact)
        }
    }
}

extension GroupAddedContactsDataSource: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: kCellWidth, height: kCellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0.0
    }
}

extension GroupAddedContactsDataSource : UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "GroupContactCollectionViewCell", for: indexPath) as! GroupContactCollectionViewCell
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return contacts.count
    }
}
