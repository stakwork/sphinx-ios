//
//  PersonModalView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 26/05/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import UIKit
import SwiftyJSON

class PersonModalView: CommonModalView {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var nicknameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var initialMessageField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: nil)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("PersonModalView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.layer.cornerRadius = 15
        
        initialMessageField.delegate = self
        imageView.layer.cornerRadius = imageView.frame.height / 2
        
        connectButton.layer.cornerRadius = connectButton.frame.height / 2
        connectButton.addShadow(location: .bottom, opacity: 0.3, radius: 5)
    }
    
    override func modalWillShowWith(query: String, delegate: ModalViewDelegate) {
        super.modalWillShowWith(query: query, delegate: delegate)
        
        loading = true
        processQuery()
        getPersonInfo()
    }
    
    func getPersonInfo() {
        if let host = authInfo?.host, let pubkey = authInfo?.pubkey {
            API.sharedInstance.getPersonInfo(host: host, pubkey: pubkey, callback: { success, person in
                if let person = person {
                    self.showPersonInfo(person: person)
                } else {
                    self.delegate?.shouldDismissVC()
                }
            })
        }
    }
    
    func showPersonInfo(person: JSON) {
        authInfo?.jsonBody = person
        
        if let imageUrl = person["img"].string, let nsUrl = URL(string: imageUrl), imageUrl != "" {
            MediaLoader.asyncLoadImage(imageView: imageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"))
        } else {
            imageView.image = UIImage(named: "profile_avatar")
        }
        
        nicknameLabel.text = person["owner_alias"].string ?? "Unknown"
        messageLabel.text = person["description"].string ?? "No description"
        priceLabel.text = "\("price.to.meet".localized)\((person["price_to_meet"].int ?? 0)) sat"
        initialMessageField.placeholder = "\("people.message.placeholder".localized) \(person["owner_alias"].string ?? "Unknown")"
        
        loading = false
    }
    
    override func modalDidShow() {
        super.modalDidShow()
    }
    
    @IBAction func connectButtonTouched() {
        buttonLoading = true
        
        if let pubkey = authInfo?.pubkey {
            if let _ = UserContact.getContactWith(pubkey: pubkey) {
                showMessage(message: "already.connected".localized, color: UIColor.Sphinx.PrimaryGreen)
                return
            }
            
            guard let text = initialMessageField.text, !text.isEmpty else {
                showMessage(message: "message.required".localized, color: UIColor.Sphinx.BadgeRed)
                return
            }
            
            let nickname = authInfo?.jsonBody["owner_alias"].string ?? "Unknown"
            let pubkey = authInfo?.jsonBody["owner_pubkey"].string ?? ""
            let routeHint = authInfo?.jsonBody["owner_route_hint"].string ?? ""
            let contactKey = authInfo?.jsonBody["owner_contact_key"].string ?? ""
            
            let contactsService = ContactsService()
            contactsService.createContact(nickname: nickname,pubKey: pubkey, routeHint: routeHint, contactKey: contactKey, callback: { (success, _) in
                if success {
                    self.sendInitialMessage()
                    return
                }
                self.showErrorMessage()
            })
        }
    }
    
    func sendInitialMessage() {
        if let pubkey = authInfo?.jsonBody["owner_pubkey"].string, let contact = UserContact.getContactWith(pubkey: pubkey) {
            let text = initialMessageField.text
            let price = authInfo?.jsonBody["price_to_meet"].int ?? 0
            
            guard let params = TransactionMessage.getMessageParams(contact: contact, type: TransactionMessage.TransactionMessageType.message, text: text, priceToMeet: price) else {
                showErrorMessage()
                return
            }
            
            API.sharedInstance.sendMessage(params: params, callback: { m in
                if let _ = TransactionMessage.insertMessage(m: m).0 {
                    self.delegate?.shouldDismissVC()
                }
            }, errorCallback: {
                self.showErrorMessage()
            })
        } else {
            showErrorMessage()
        }
    }
    
    func showErrorMessage() {
        showMessage(message: "generic.error".localized, color: UIColor.Sphinx.BadgeRed)
    }
    
    func showMessage(message: String, color: UIColor) {
        buttonLoading = false
        messageBubbleHelper.showGenericMessageView(text: message, delay: 3, textColor: UIColor.white, backColor: color, backAlpha: 1.0)
    }
}

extension PersonModalView : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        self.endEditing(true)
    }
}
