//
//  AddFriendViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class AddFriendViewController: UIViewController {
    
    weak var delegate: NewContactVCDelegate?
    
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var buttonContainer: UIView!
    @IBOutlet weak var existingUserButton: UIButton!
    @IBOutlet weak var newUserButton: UIButton!
    
    static func instantiate() -> AddFriendViewController {
        let viewController = StoryboardScene.Invite.addFriendViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        viewTitle.addTextSpacing(value: 2)
        
        existingUserButton.layer.cornerRadius = existingUserButton.frame.size.height / 2
        existingUserButton.addShadow(location: VerticalLocation.bottom, color: UIColor.Sphinx.PrimaryBlueBorder, opacity: 1, radius: 0.5, bottomhHeight: 1.5)
        
        newUserButton.layer.cornerRadius = newUserButton.frame.size.height / 2
        newUserButton.addShadow(location: VerticalLocation.bottom, color: UIColor.Sphinx.GreenBorder, opacity: 1, radius: 0.5, bottomhHeight: 1.5)
        setAccessibilityIdentifiers()
    }
    
    func setAccessibilityIdentifiers(){
        existingUserButton.accessibilityIdentifier = "existingUserButton"
    }
    
    @IBAction func addContactButtonTouched() {
        goToAddContact()
    }
    
    @IBAction func inviteNewButtonTouched() {
        goToConfirmInvitation()
    }
    
    func goToAddContact() {
        let newContactVC = NewContactViewController.instantiate()
        newContactVC.delegate = self
        self.navigationController?.pushViewController(newContactVC, animated: true)
    }
    
    func goToConfirmInvitation() {
        UIView.animate(withDuration: 0.2, animations: {
            self.buttonContainer.alpha = 0.0
        }, completion: { _ in
            let confirmAddfriendVC = ConfirmAddFriendViewController.instantiate()
            confirmAddfriendVC.delegate = self
            self.navigationController?.pushViewController(confirmAddfriendVC, animated: false)
        })
    }
    
    @IBAction func closeButtonTouched() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension AddFriendViewController : NewContactVCDelegate {
    func shouldReloadContacts(reload: Bool, dashboardTabIndex: Int) {
        delegate?.shouldReloadContacts?(reload: reload, dashboardTabIndex: dashboardTabIndex)
    }
    
    func shouldDismissView() {
        delegate?.shouldReloadContacts?(reload: true, dashboardTabIndex: -1)
        self.dismiss(animated: true, completion: nil)
    }
    
    func didCreateInvite() {
        delegate?.shouldReloadContacts?(reload: true, dashboardTabIndex: 1)
        self.dismiss(animated: true, completion: nil)
    }
}
