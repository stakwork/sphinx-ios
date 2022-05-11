//
//  TribeMemberPopupView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 09/05/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

protocol TribeMemberPopupViewDelegate: class {
    func shouldGoToSendPayment(message: TransactionMessage)
}

class TribeMemberPopupView: UIView {
    
    weak var delegate: TribeMemberPopupViewDelegate?
    
    var message: TransactionMessage!

    @IBOutlet var contentView: UIView!
    @IBOutlet weak var memberPicture: ChatAvatarView!
    @IBOutlet weak var memberAliasLabel: UILabel!
    @IBOutlet weak var sendSatsButton: UIButton!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("TribeMemberPopupView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        contentView.layer.cornerRadius = 15
        
        sendSatsButton.layer.cornerRadius = sendSatsButton.frame.height / 2
        sendSatsButton.layer.borderColor = UIColor.Sphinx.PlaceholderText.cgColor
        sendSatsButton.layer.borderWidth = 1
        
        memberPicture.setInitialLabelSize(size: 30)
    }
    
    func configureFor(
        message: TransactionMessage,
        with delegate: TribeMemberPopupViewDelegate
    ) {
        self.message = message
        self.delegate = delegate
        
        memberAliasLabel.text = message.senderAlias ?? "Unknown"

        memberPicture.configureFor(
            alias: message.senderAlias ?? "Unknown",
            picture: message.senderPic
        )
    }
    
    @IBAction func sendSatsButtonTouched() {
        delegate?.shouldGoToSendPayment(message: message)
        WindowsManager.sharedInstance.removeCoveringWindow()
    }
    
    @IBAction func closeButtonTouched() {
        WindowsManager.sharedInstance.removeCoveringWindow()
    }
}
