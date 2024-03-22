//
//  AddressBookViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 25/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class AddressBookViewController: PopHandlerViewController {
    
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var searchFieldContainer: UIView!
    @IBOutlet weak var searchTextField: UITextField!
    @IBOutlet weak var contactsTableView: UITableView!
    @IBOutlet weak var addFriendView: AddFriendRowButton!
    
    var tableDataSource : AddressBookDataSource!
    
    static func instantiate() -> AddressBookViewController {
        let viewController = StoryboardScene.Contacts.addressBookViewController.instantiate()
        viewController.popOnSwipeEnabled = true
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setStatusBarColor()
        viewTitle.addTextSpacing(value: 2)
        
        addFriendView.configureForAddFriend()
        addFriendView.delegate = self
        
        searchFieldContainer.layer.cornerRadius = searchFieldContainer.frame.height / 2
        searchFieldContainer.layer.borderWidth = 1
        searchFieldContainer.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self.view)
        
        searchTextField.delegate = self
        
        configureTableView()
    }
    
    func configureTableView() {
        contactsTableView.registerCell(ContactTableViewCell.self)
        
        tableDataSource = AddressBookDataSource(tableView: contactsTableView, delegate: self)
        contactsTableView.delegate = tableDataSource
        contactsTableView.dataSource = tableDataSource
        contactsTableView.reloadData()
    }
    
    @IBAction func backButtonTouched() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func searchButtonTouched() {}
}

extension AddressBookViewController : AddressBookDataSourceDelegate {
    func didTapOnContact(contact: UserContact) {
        let newContactVC = NewContactViewController.instantiate(contactId: contact.id)
        newContactVC.delegate = self
        self.navigationController?.pushViewController(newContactVC, animated: true)
    }
    
    func shouldShowAlert(title: String, text: String) {
        AlertHelper.showAlert(title: title, message: text)
    }
    
    func shouldToggleInteraction(enable: Bool) {
        view.isUserInteractionEnabled = enable
    }
}

extension AddressBookViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        view.endEditing(true)
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        var currentString = textField.text! as NSString
        currentString = currentString.replacingCharacters(in: range, with: string) as NSString
        let searchTerm = (currentString as String).lowercased()
        
        tableDataSource.processContacts(searchTerm: searchTerm)
        contactsTableView.reloadData()
        
        return true
    }
    
    func textFieldShouldClear(_ textField: UITextField) -> Bool {
        tableDataSource.processContacts()
        contactsTableView.reloadData()
        
        return true
    }
}

extension AddressBookViewController : NewContactVCDelegate {
    func shouldReloadContacts(reload: Bool, dashboardTabIndex: Int) {
        if !reload {
            return
        }
        
        DispatchQueue.main.async {
            self.tableDataSource.reloadContacts(
                searchTerm: self.searchTextField.text
            )
            self.contactsTableView.reloadData()
        }
    }
    
    func shouldDismissView() {}
}

extension AddressBookViewController : AddFriendRowButtonDelegate {
    func didTouchAddFriend() {
        let addfriendVC = AddFriendViewController.instantiate()
        addfriendVC.delegate = self
        presentNavConWith(vc: addfriendVC)
    }
    
    func presentNavConWith(vc: UIViewController) {
        let newNC = UINavigationController(rootViewController: vc)
        newNC.isNavigationBarHidden = true
        navigationController?.present(newNC, animated: true, completion: nil)
    }
}
