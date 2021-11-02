//
//  GroupPinView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class GroupPinView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var privacySwitch: UISwitch!
    
    var contact: UserContact? = nil
    var chat: Chat? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("GroupPinView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        privacySwitch.onTintColor = UIColor.Sphinx.PrimaryBlue
        
        let privacyPinSet = GroupsPinManager.sharedInstance.isPrivacyPinSet()
        privacySwitch.isEnabled = privacyPinSet
        self.alpha = privacyPinSet ? 1.0 : 0.7
    }
    
    func configureWith(contact: UserContact? = nil, chat: Chat? = nil) {
        self.contact = contact
        self.chat = chat
        
        if let contact = contact {
            privacySwitch.isOn = !(contact.pin ?? "").isEmpty
        } else if let chat = chat {
            privacySwitch.isOn = !(chat.pin ?? "").isEmpty
        }
    }
    
    @IBAction func helpTooltipButtonTouched() {
        NewMessageBubbleHelper().showGenericMessageView(text: "privacy.pin.tooltip".localized, delay: 5, backAlpha: 1.0)
    }
    
    @IBAction func privacySwitchChanged(_ sender: UISwitch) {
        if let privacyPin = UserData.sharedInstance.getPrivacyPin(), !privacyPin.isEmpty {
            let privateObject = sender.isOn
            setObjectPrivate(pin: privateObject ? privacyPin : nil)
        }
    }
    
    func setObjectPrivate(pin: String? = nil) {
        self.contact?.pin = pin
        self.contact?.getChat()?.pin = pin
        self.chat?.pin = pin
    }
    
    func getPin() -> String? {
        if let privacyPin = UserData.sharedInstance.getPrivacyPin(), !privacyPin.isEmpty, privacySwitch.isOn {
            return privacyPin
        }
        return nil
    }
}
