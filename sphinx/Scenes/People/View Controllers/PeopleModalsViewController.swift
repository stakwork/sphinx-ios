//
//  PeopleModalsViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 26/05/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import UIKit

protocol ModalViewDelegate: class {
    func shouldDismissVC()
}

protocol ModalViewInterface: class {
    var alpha: CGFloat { get set }
    
    func modalWillShowWith(query: String, delegate: ModalViewDelegate)
    func modalDidShow()
}

class PeopleModalsViewController: KeyboardEventsViewController {

    @IBOutlet weak var authExternalView: AuthExternalView!
    @IBOutlet weak var personModalView: PersonModalView!
    @IBOutlet weak var peopleTorActionsView: PeopleTorActionsView!
    
    @IBOutlet weak var personModalViewVerticalCenterConstraint: NSLayoutConstraint!
    
    var query: String! = nil
    
    static func instantiate(query: String) -> PeopleModalsViewController {
        let viewController = StoryboardScene.People.peopleModalsViewController.instantiate()
        viewController.query = query
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.alpha = 0.0
        
        authExternalView.layer.cornerRadius = 15
        personModalView.layer.cornerRadius = 15
        
        if let modal = getModal() {
            modal.alpha = 1.0
            modal.modalWillShowWith(query: query, delegate: self)
            
            UIView.animate(withDuration: 0.2, animations: {
                self.view.alpha = 1.0
            }, completion: { _ in
                modal.modalDidShow()
            })
        } else {
            shouldDismissVC()
        }
    }
    
    func getModal() -> ModalViewInterface? {
        if let query = query, let action = query.getLinkAction() {
            switch(action) {
            case "auth":
                return authExternalView
            case "person":
                return personModalView
            case "save":
                return peopleTorActionsView
            default:
                break
            }
        }
        return nil
    }
    
    @objc override func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            movePersonModalOnKeyboardToggle(value: -keyboardSize.height/2)
        }
    }
     
    @objc override func keyboardWillHide(_ notification: Notification) {
        movePersonModalOnKeyboardToggle(value: 0)
    }
    
    func movePersonModalOnKeyboardToggle(value: CGFloat) {
        if let _ = getModal() as? PersonModalView {
            personModalViewVerticalCenterConstraint.constant = value
            
            UIView.animate(withDuration: 0.3, animations: {
                self.view.layoutIfNeeded()
            })
        }
    }
}

extension PeopleModalsViewController : ModalViewDelegate {
    func shouldDismissVC() {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0.0
        }, completion: { _ in
            WindowsManager.sharedInstance.removeCoveringWindow()
        })
    }
}
