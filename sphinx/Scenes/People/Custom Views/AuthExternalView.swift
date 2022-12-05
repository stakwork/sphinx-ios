//
//  AuthExternalView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 26/05/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import UIKit

class AuthExternalView: CommonModalView {
    
    @IBOutlet weak var hostLabel: UILabel!
    @IBOutlet weak var authorizeButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("AuthExternalView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.layer.cornerRadius = 15
        
        authorizeButton.layer.cornerRadius = authorizeButton.frame.height / 2
        authorizeButton.addShadow(location: .bottom, opacity: 0.3, radius: 5)
    }
    
    override func modalWillShowWith(query: String, delegate: ModalViewDelegate) {
        super.modalWillShowWith(query: query, delegate: delegate)
        
        processQuery()
        
        hostLabel.text = "\(authInfo?.host ?? "...")?"
    }
    
    override func modalDidShow() {
        super.modalDidShow()
    }
    
    @IBAction func authorizeButtonTouched() {
        buttonLoading = true
        verifyExternal()
    }
    
    func verifyExternal() {
        API.sharedInstance.verifyExternal(callback: { success, object in
            if let object = object, let token = object["token"] as? String, let info = object["info"] as? [String: AnyObject] {
                self.authInfo?.token = token
                self.authInfo?.info = info
                self.signBase64()
            }
        })
    }
    
    func signBase64() {
        API.sharedInstance.signBase64(b64: "U3BoaW54IFZlcmlmaWNhdGlvbg==", callback: { sig in
            if let sig = sig {
                self.authInfo?.verificationSignature = sig
                self.authorize()
            }
        })
    }
    
    func authorize() {
        if let host = authInfo?.host,
           let challenge = authInfo?.challenge,
           let verificationSignature = authInfo?.verificationSignature,
           let token = authInfo?.token,
           var info = authInfo?.info {
            
            info["url"] = UserData.sharedInstance.getNodeIP() as AnyObject
            info["verification_signature"] = verificationSignature as AnyObject
            
            API.sharedInstance.authorizeExternal(host: host, challenge: challenge, token: token, params: info, callback: { success in
                self.authorizationDone(success: success, host: host)
            })
        }
    }
    
    func authorizationDone(success: Bool, host: String) {
        if success {
            if let host = authInfo?.host, let challenge = authInfo?.challenge, let url = URL(string: "https://\(host)?challenge=\(challenge)") {
                UIApplication.shared.open(url)
            }
        } else {
            messageBubbleHelper.showGenericMessageView(text: "authorization.failed".localized, delay: 5, textColor: UIColor.white, backColor: UIColor.Sphinx.BadgeRed, backAlpha: 1.0)
        }
        delegate?.shouldDismissVC()
    }
}
