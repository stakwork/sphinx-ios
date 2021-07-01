//
//  MainCoordinator.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import KYDrawerController

final class MainCoordinator: NSObject {

    var drawerController : KYDrawerController!
    var rootViewController : RootViewController!
    
    public init(rootViewController: RootViewController) {
        self.rootViewController = rootViewController
    }
    
    func presentSignUpScreen() {
        let currentStep = SignupHelper.step
        
        switch(currentStep) {
        case SignupHelper.SignupStep.Start.rawValue:
            UserData.sharedInstance.clearData()
            presentInviteCodeViewController()
            break
        case SignupHelper.SignupStep.IPAndTokenSet.rawValue:
            presentInviteWelcomeViewController()
            break
        case SignupHelper.SignupStep.InviterContactCreated.rawValue:
            presentSetPinViewController()
            break
        case SignupHelper.SignupStep.PINSet.rawValue:
            presentPersonalInfoViewController()
            break
        case SignupHelper.SignupStep.PersonalInfoSet.rawValue:
            presentSphinxReadyViewController()
            break
        case SignupHelper.SignupStep.SignupComplete.rawValue:
            presentInitialDrawer()
            break
        default:
            break
        }
    }
    
    func presentInviteCodeViewController() {
        let inviteCodeVC = InviteCodeViewController.instantiate(rootViewController: rootViewController, delegate: self)
        presentSignupInvialVC(vc: inviteCodeVC)
    }
    
    func presentInviteWelcomeViewController() {
        if let inviter = SignupHelper.getInviter() {
            let inviteWelcome = InviteWelcomeViewController.instantiate(rootViewController: rootViewController, inviter: inviter)
            presentSignupInvialVC(vc: inviteWelcome)
        }
    }
    
    func presentSetPinViewController() {
        let setPinVC = SetPinCodeViewController.instantiate(rootViewController: self.rootViewController)
        presentSignupInvialVC(vc: setPinVC)
    }
    
    func presentPersonalInfoViewController() {
        let nicknameVC = SetNickNameViewController.instantiate(rootViewController: rootViewController)
        presentSignupInvialVC(vc: nicknameVC)
    }
    
    func presentSphinxReadyViewController() {
        let sphinxReadyVC = SphinxReadyViewController.instantiate(rootViewController: rootViewController)
        presentSignupInvialVC(vc: sphinxReadyVC)
    }
    
    func presentSignupInvialVC(vc: UIViewController) {
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.isNavigationBarHidden = true
        rootViewController.setInitialViewController(navigationController)
    }
    
    func presentInitialDrawer() {
        let leftViewController = LeftMenuViewController.instantiate(rootViewController: rootViewController)
        let mainViewController = ChatListViewController.instantiate(rootViewController: rootViewController, delegate: leftViewController)
        let navigationController = UINavigationController(rootViewController: mainViewController)
        
        UserData.sharedInstance.saveNewNodeOnKeychain()
        runBackgroundProcesses()

        drawerController = KYDrawerController(drawerDirection: .left, drawerWidth: 270.0)
        drawerController.delegate = leftViewController
        drawerController.screenEdgePanGestureEnabled = false
        drawerController.mainViewController = navigationController
        drawerController.drawerViewController = leftViewController
        
        drawerController.setDrawerState(.opened, animated: false)
        drawerController.setDrawerState(.closed, animated: false)
        
        rootViewController.switchToViewController(drawerController)
    }
    
    func runBackgroundProcesses() {
        DispatchQueue.global().async {
            CoreDataManager.sharedManager.deleteExpiredInvites()
            
            let (_, _) = EncryptionManager.sharedInstance.getOrCreateKeys()
            AttachmentsManager.sharedInstance.runAuthentication()
        }
    }
}

extension MainCoordinator : MenuDelegate {
    func shouldOpenLeftMenu() {}
}
