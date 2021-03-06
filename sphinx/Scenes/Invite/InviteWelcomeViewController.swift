//
//  InviteWelcomeViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class InviteWelcomeViewController: UIViewController {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactNameLabel: UILabel!
    @IBOutlet weak var welcomeMessageLabel: UILabel!
    @IBOutlet weak var nextButtonContainer: UIView!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    private var rootViewController : RootViewController!
    private var contactsService : ContactsService!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    var currentInviter : SignupHelper.Inviter?
    
    static func instantiate(rootViewController : RootViewController, inviter: SignupHelper.Inviter) -> InviteWelcomeViewController {
        let viewController = StoryboardScene.Invite.inviteWelcomeViewController.instantiate()
        viewController.rootViewController = rootViewController
        viewController.contactsService = rootViewController.contactsService
        viewController.currentInviter = inviter
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootViewController.setStatusBarColor(light: false)
        
        nextButtonContainer.layer.cornerRadius = nextButtonContainer.frame.size.height / 2
        nextButtonContainer.clipsToBounds = true
        nextButtonContainer.addShadow(location: .bottom, opacity: 0.5, radius: 2.0)
        
        contactImageView.layer.cornerRadius = contactImageView.frame.size.height / 2
        contactImageView.clipsToBounds = true
        
        if let profile = UserContact.getOwner() {
            if let imageUrl = profile.avatarUrl?.trim(), let nsUrl = URL(string: imageUrl) {
                MediaLoader.asyncLoadImage(imageView: contactImageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"))
            }
        }
        
        if let inviter = currentInviter {
            contactNameLabel.text = inviter.nickname
            welcomeMessageLabel.text = inviter.welcomeMessage
        }
        
        setTitle()
    }
    
    func setTitle() {
        titleLabel.text = "message.from.friend".localized
    }
    
    @IBAction func nextButtonTouched() {
        loading = true
        
        if let inviter = currentInviter {
            let contactsService = ContactsService()
            contactsService.createContact(nickname: inviter.nickname, pubKey: inviter.pubkey, routeHint: inviter.routeHint, callback: { success in
                if success {
                    SignupHelper.step = SignupHelper.SignupStep.InviterContactCreated.rawValue
                    
                    let setPinVC = SetPinCodeViewController.instantiate(rootViewController: self.rootViewController)
                    self.navigationController?.pushViewController(setPinVC, animated: true)
                } else {
                    self.didFailCreatingContact()
                }
            })
        }
    }
    
    func didFailCreatingContact() {
        loading = false
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
    }
}
