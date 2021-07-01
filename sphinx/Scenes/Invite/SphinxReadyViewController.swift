//
//  SphinxReadyViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SwiftyJSON

class SphinxReadyViewController: UIViewController {
    
    private var rootViewController : RootViewController!
    
    @IBOutlet weak var centerLabel: UILabel!
    @IBOutlet weak var centerSubtitle: UILabel!
    @IBOutlet weak var nextButtonContainer: UIView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    let walletBalanceService = WalletBalanceService()
    let inviteActionsHelper = InviteActionsHelper()
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    static func instantiate(rootViewController : RootViewController) -> SphinxReadyViewController {
        let viewController = StoryboardScene.Invite.sphinxReadyViewController.instantiate()
        viewController.rootViewController = rootViewController
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootViewController.setStatusBarColor(light: true)
        
        nextButtonContainer.layer.cornerRadius = nextButtonContainer.frame.size.height / 2
        nextButtonContainer.clipsToBounds = true
        nextButtonContainer.addShadow(location: .bottom, color: UIColor.Sphinx.PrimaryBlueBorder, opacity: 0.5, radius: 2.0)
        
        setAttributedTitles(local: 1000, remote: 10000)
        loadBalances()
    }
    
    func loadBalances() {
        loading = true
        
        let (_, _) = walletBalanceService.getBalanceAll(completion: { local, remote in
            self.loading = false
            self.setAttributedTitles(local: local, remote: remote)
        })
    }
    
    func setAttributedTitles(local: Int, remote: Int) {
        let formattedLocal = local.formattedWithSeparator
        let formattedRemote = remote.formattedWithSeparator
        
        var normalFont = UIFont(name: "Roboto-Light", size: 30.0)!
        var boldFont = UIFont(name: "Roboto-Bold", size: 30.0)!
        
        centerLabel.attributedText = String.getAttributedText(string: "ready.use.sphinx".localized, boldStrings: ["ready".localized], font: normalFont, boldFont: boldFont)
        
        normalFont = UIFont(name: "Roboto-Light", size: 17.0)!
        boldFont = UIFont(name: "Roboto-Bold", size: 17.0)!
        
        let completeMessage = String(format: "ready.sphinx.text".localized, formattedLocal, formattedRemote)
        let firstSatsMsg = String(format: "x.sats,".localized, formattedLocal)
        let secondSatsMsg = String(format: "x.sats.".localized, formattedRemote)
        
        centerSubtitle.attributedText = String.getAttributedText(string: completeMessage, boldStrings: [firstSatsMsg, secondSatsMsg], font: normalFont, boldFont: boldFont)
    }
    
    @IBAction func nextButtonTouched() {
        loading = true
        
        if let inviteString: String = UserDefaults.Keys.inviteString.get() {
            API.sharedInstance.finishInvite(inviteString: inviteString, callback: { success in
                if success {
                    self.joinDefaultTribe()
                } else {
                    self.nextButtonTouched()
                }
            })
        } else {
            self.joinDefaultTribe()
        }
    }
    
    func resetSignupData() {
        UserDefaults.Keys.inviteString.removeValue()
        UserDefaults.Keys.inviterNickname.removeValue()
        UserDefaults.Keys.inviterPubkey.removeValue()
        UserDefaults.Keys.welcomeMessage.removeValue()
    }
    
    func joinDefaultTribe() {
        let (_, _) = EncryptionManager.sharedInstance.getOrCreateKeys() {
            GroupsManager.sharedInstance.getAndJoinDefaultTribe {
                self.handleInviteActions()
            }
        }
    }
    
    func handleInviteActions() {
        inviteActionsHelper.handleInviteActions {
            self.goToApp()
        }
    }
    
    func goToApp() {
        SignupHelper.completeSignup()
        resetSignupData()
        UserDefaults.Keys.lastPinDate.set(Date())
        
        DelayPerformedHelper.performAfterDelay(seconds: 1.0, completion: {
            let mainCoordinator = MainCoordinator(rootViewController: self.rootViewController)
            mainCoordinator.presentInitialDrawer()
        })
    }
}
