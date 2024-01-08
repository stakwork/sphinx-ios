//
//  StakworkAuthorizeViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 22/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class StakworkAuthorizeViewController: UIViewController {

    @IBOutlet weak var authorizeWithLabel: UILabel!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var hostContainer: UIView!
    @IBOutlet weak var hostLabel: UILabel!
    @IBOutlet weak var authorizeButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    var query: String! = nil
    var authInfo: AuthInfo? = nil
    
    struct AuthInfo {
        var host : String? = nil
        var id : String? = nil
        var challenge : String? = nil
        var sig : String? = nil
        var pubkey : String? = nil
        var routeHint : String? = nil
        
        var name : String? = nil
        var token : String? = nil
        var amount : Int? = nil
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    static func instantiate(query: String) -> StakworkAuthorizeViewController {
        let viewController = StoryboardScene.Stakwork.stakworkAuthorizeViewController.instantiate()
        viewController.query = query
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.alpha = 0.0
        loading = false
        
        containerView.layer.cornerRadius = 15
        
        authorizeButton.layer.cornerRadius = authorizeButton.frame.height / 2
        authorizeButton.addShadow(location: .bottom, opacity: 0.3, radius: 5)
        
        getAuthInfo()
        configureView()
        
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 1.0
        })
    }
    
    func getAction() -> String? {
        if let query = query, let action = URL(string: "sphinx.chat://?\(query)")?.getLinkAction() {
            return action
        }
        return nil
    }
    
    func getAuthInfo() {
        authInfo = AuthInfo()

        let owner = UserContact.getOwner()
        
        authInfo?.pubkey = owner?.publicKey
        authInfo?.routeHint = owner?.routeHint
        
        if let query = query, let action = getAction() {
            let components = query.components(separatedBy: "&")
            
            switch(action) {
            case "challenge":
                configureForAuthorize(components: components)
                break
            case "redeem_sats":
                configureForSatsRedeem(components: components)
                break
            default:
                break
            }
        }
    }
    
    func configureForAuthorize(components: [String]) {
        for component in components {
            let elements = component.components(separatedBy: "=")
            if elements.count > 1 {
                let key = elements[0]
                let value = component.replacingOccurrences(of: "\(key)=", with: "")
                
                switch(key) {
                case "id":
                    authInfo?.id = value
                    break
                case "host":
                    authInfo?.host = value
                    break
                case "challenge":
                    authInfo?.challenge = value
                    break
                default:
                    break
                }
            }
        }
    }
    
    func configureForSatsRedeem(components: [String]) {
        for component in components {
            let elements = component.components(separatedBy: "=")
            if elements.count > 1 {
                let key = elements[0]
                let value = component.replacingOccurrences(of: "\(key)=", with: "")
                
                switch(key) {
                case "name":
                    authInfo?.name = value
                    break
                case "host":
                    authInfo?.host = value
                    break
                case "token":
                    authInfo?.token = value
                    break
                case "amount":
                    if let intValue = Int(value) {
                        authInfo?.amount = intValue
                    }
                    break
                default:
                    break
                }
            }
        }
    }
    
    func configureView() {
        guard let authInfo = authInfo else {
            showErrorAlert()
            return
        }
        
        let action = getAction() ?? ""
        switch(action) {
        case "challenge":
            hostLabel.text = authInfo.host ?? ""
            break
        case "redeem_sats":
            hostLabel.text = authInfo.name ?? "Name"
            authorizeWithLabel.text = String(format: "redeem.sats.from".localized, authInfo.amount ?? 0)
            authorizeButton.setTitle("confirm".localized.uppercased(), for: .normal)
            break
        default:
            break
        }
    }
    
    func showErrorAlert() {
        loading = false
        
        AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized, completion: {
            self.closeButtonTouched()
        })
    }
    
    func takeUserToAuth() {
        guard let authInfo = authInfo, let id = authInfo.id, let sig = authInfo.sig, let pubkey = authInfo.pubkey else {
            showErrorAlert()
            return
        }
        
        var urlString = "https://auth.sphinx.chat/oauth_verify?id=\(id)&sig=\(sig)&pubkey=\(pubkey)"
        
        if let routeHint = authInfo.routeHint, !routeHint.isEmpty {
            urlString = urlString + "&route_hint=\(routeHint)"
        }
        
        if let url = URL(string: urlString) {
            closeButtonTouched()
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func authorizeButtonTouched() {
        guard let _ = authInfo, let action = getAction() else {
            showErrorAlert()
            return
        }
        
        loading = true
        
        switch(action) {
        case "challenge":
            authorize()
            break
        case "redeem_sats":
            redeemSats()
            break
        default:
            break
        }
    }
    
    func authorize() {
        guard let authInfo = authInfo, let challenge = authInfo.challenge else {
            showErrorAlert()
            return
        }
        
       guard let sig = SphinxOnionManager.sharedInstance.signChallenge(challenge: challenge) else {
            showErrorAlert()
           return
        }
        
        self.authInfo?.sig = sig
        self.takeUserToAuth()
    }
    
    func redeemSats() {
        guard let authInfo = authInfo, let host = authInfo.host, let token = authInfo.token, let pubkey = authInfo.pubkey else {
            showErrorAlert()
            return
        }
        let params: [String: AnyObject] = ["token": token as AnyObject, "pubkey": pubkey as AnyObject]
        API.sharedInstance.redeemSats(url: host, params: params, callback: {
            NotificationCenter.default.post(name: .onBalanceDidChange, object: nil)
            self.closeButtonTouched()
        }, errorCallback: {
            self.showErrorAlert()
        })
    }
    
    @IBAction func closeButtonTouched() {
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 0.0
        }, completion: { _ in
            WindowsManager.sharedInstance.removeCoveringWindow()
        })
    }
}
