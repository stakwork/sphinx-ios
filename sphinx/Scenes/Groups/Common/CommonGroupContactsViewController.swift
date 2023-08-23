//
//  CommonGroupContactsViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 26/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class CommonGroupContactsViewController: KeyboardEventsViewController {
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
     
    @IBOutlet weak var searchFieldContainer: UIView!
    @IBOutlet weak var searchField: UITextField!

    @IBOutlet weak var addedContactsCollectionView: UICollectionView!
    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!

    var tableDataSource : GroupAllContactsDataSource!
    var collectionDataSource : GroupAddedContactsDataSource!

    var allContacts = [UserContact]()
    var selectedContactIds = [Int]()
    var chat: Chat!

    var groupsManager = GroupsManager.sharedInstance
     
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        groupsManager.resetData()

        searchFieldContainer.layer.cornerRadius = searchFieldContainer.frame.size.height / 2
        searchFieldContainer.clipsToBounds = true
        searchFieldContainer.layer.borderWidth = 1
        searchFieldContainer.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self.view)

        nextButton.layer.cornerRadius = nextButton.frame.size.height / 2
        nextButton.clipsToBounds = true
        nextButton.addShadow(location: .bottom, opacity: 0.3, radius: 2.0)
        nextButton.isHidden = true

        searchField.delegate = self
        
        loadData()
    }
    
    func loadData() {
        allContacts = getContactsToShow()
        configureTableView()
        configureCollectionView()
    }
     
    func getContactsToShow() -> [UserContact] {
        return []
    }
    
    func getExistingContacts() -> [UserContact] {
        return []
    }
    
    func getTableTitle() -> String {
        return ""
    }
     
    func configureTableView() {
        contactsTableView.registerCell(GroupContactTableViewCell.self)

        tableDataSource = GroupAllContactsDataSource(tableView: contactsTableView, delegate: self, title: getTableTitle())
        contactsTableView.backgroundColor = UIColor.Sphinx.Body
        contactsTableView.delegate = tableDataSource
        contactsTableView.dataSource = tableDataSource

        let existingContacts = chat?.getContacts().filter { !$0.isOwner } ?? []
        tableDataSource.reloadContacts(contacts: allContacts, existingContactsCount: existingContacts.count)
    }
     
    func configureCollectionView() {
        addedContactsCollectionView.registerCell(GroupContactCollectionViewCell.self)

        collectionDataSource = GroupAddedContactsDataSource(collectionView: addedContactsCollectionView, delegate: self)

        let contacts = getExistingContacts()
        collectionDataSource.addExistingContacts(contacts: contacts)
        toggleCollectionView(show: contacts.count > 0, animated: false)

        addedContactsCollectionView.delegate = collectionDataSource
        addedContactsCollectionView.dataSource = collectionDataSource
        addedContactsCollectionView.reloadData()
    }
     
    @objc override func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            contactsTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }
     
    @objc override func keyboardWillHide(_ notification: Notification) {
        contactsTableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
}

extension CommonGroupContactsViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var currentString = textField.text! as NSString
        currentString = currentString.replacingCharacters(in: range, with: string) as NSString
        let searchTerm = (currentString as String).lowercased()
        
        tableDataSource.processContacts(searchTerm: searchTerm, selectedContactIds: selectedContactIds)
        contactsTableView.reloadData()
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        tableDataSource.processContacts(selectedContactIds: selectedContactIds)
        contactsTableView.reloadData()
        
        return true
    }
}

extension CommonGroupContactsViewController : GroupAllContactsDataSourceDelegate {
    func didToggleAll(selected: Bool) {
        selectedContactIds = selected ? allContacts.map { $0.id } : []
        updateLayouts(added: selected, ids: selectedContactIds)
    }
    
    func didAddedContactWith(id: Int) {
        selectedContactIds.append(id)
        updateLayouts(added: true, ids: [id])
    }
    
    func didRemoveContactWith(id: Int) {
        if let index = selectedContactIds.index(of: id) {
            selectedContactIds.remove(at: index)
        }
        updateLayouts(added: false, ids: [id])
    }
    
    func updateLayouts(added: Bool, ids: [Int]) {
        let shouldShow = selectedContactIds.count + getExistingContacts().count > 0
        if added {
            toggleCollectionView(show: shouldShow, completion: {
                self.reloadCollectionView(added: added, contactIds: ids)
            })
        } else {
            reloadCollectionView(added: false, contactIds: ids)
            toggleCollectionView(show: shouldShow)
        }
        toggleNextButton()
    }
    
    func reloadCollectionView(added: Bool, contactIds: [Int]) {
        let contactId = (contactIds.count == 1) ? contactIds[0] : nil
        if let contactId = contactId, let contact = UserContact.getContactWith(id: contactId) {
            if added {
                collectionDataSource.addContact(contact: contact)
            } else {
                collectionDataSource.removeContact(contact: contact)
            }
        } else {
            if added {
                let contacts = contactIds.map { UserContact.getContactWith(id: $0) }
                collectionDataSource.addAll(existingContacts: getExistingContacts(), contacts: contacts)
            } else {
                collectionDataSource.removeAll(existingContacts: getExistingContacts())
            }
        }
    }
    
    func toggleNextButton() {
        let shouldShow = selectedContactIds.count > 0
        nextButton.isHidden = !shouldShow
    }
    
    func toggleCollectionView(show: Bool, completion: (() -> ())? = nil, animated: Bool = true) {
        let expectedHeight:CGFloat = show ? 90 : 0
        
        if collectionViewHeightConstraint.constant == expectedHeight {
            completion?()
            return
        }
        collectionViewHeightConstraint.constant = expectedHeight
        
        if !animated {
            self.addedContactsCollectionView.superview?.layoutIfNeeded()
            return
        }
        
        UIView.animate(withDuration: 0.2, animations: {
            self.addedContactsCollectionView.superview?.layoutIfNeeded()
        }, completion: {_ in
            completion?()
        })
    }
}

extension CommonGroupContactsViewController : GroupContactCellDelegate {
    func didDeleteContact(contact: UserContact, cell: UICollectionViewCell) {
        tableDataSource.unselect(contact: contact)
        didRemoveContactWith(id: contact.id)
    }
}
