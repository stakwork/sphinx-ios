//
//  ConfirmAddFriendViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class ConfirmAddFriendViewController: UIViewController {
    
    weak var delegate: NewContactVCDelegate?
    
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var includeMessageLabel: UILabel!
    @IBOutlet weak var messageFieldContainer: UIView!
    @IBOutlet weak var messageFieldView: UIView!
    @IBOutlet weak var messageTextView: UITextView!
    @IBOutlet weak var bottomContainer: UIView!
    @IBOutlet weak var bottomLeftContainer: UIView!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var createInvitationButton: UIButton!
    @IBOutlet weak var nickNameLabel: UILabel!
    @IBOutlet weak var nickNameView: UIView!
    @IBOutlet weak var nickNameField: UITextField!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    let kCharacterLimit = 100
    let kTextViewNewUserPlaceHolder = "Welcome to Sphinx!"
    let kTextViewExistingUserPlaceHolder = "Join me on Sphinx!"
    let kPlaceHolderColor = UIColor.Sphinx.PlaceholderText
    let kTextViewColor = UIColor.Sphinx.Text
    
    private var lowestPrice : Int?
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    let walletBalanceService = WalletBalanceService()
    
    static func instantiate() -> ConfirmAddFriendViewController {
        let viewController = StoryboardScene.Invite.confirmAddFriendViewController.instantiate()
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loading = false
        configureView()
    }
    
    func isNewUserInvite() -> Bool {
        return true
    }
    
    func configureView() {
        viewTitle.addTextSpacing(value: 2)
        includeMessageLabel.addTextSpacing(value: 2)
        nickNameLabel.addTextSpacing(value: 2)
        
        messageFieldContainer.alpha = 0.0
        bottomContainer.alpha = 0.0
        
        messageFieldView.layer.cornerRadius = 5
        messageFieldView.layer.borderWidth = 1
        messageFieldView.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self.view)
        
        nickNameView.layer.cornerRadius = 5
        nickNameView.layer.borderWidth = 1
        nickNameView.layer.borderColor = UIColor.Sphinx.LightDivider.resolvedCGColor(with: self.view)
        
        messageTextView.text = kTextViewNewUserPlaceHolder
        createInvitationButton.layer.cornerRadius = createInvitationButton.frame.size.height / 2
        createInvitationButton.backgroundColor = UIColor.Sphinx.PrimaryGreen
        createInvitationButton.addShadow(location: VerticalLocation.bottom, color: UIColor.Sphinx.GreenBorder, opacity: 1, radius: 0.5, bottomhHeight: 1.5)
        
        messageTextView.delegate = self
        
        nickNameField.textColor = kTextViewColor
        nickNameField.delegate = self
        
        getLowestPrice()
        
        messageTextView.isHidden = true
        messageFieldContainer.isHidden = true
        nickNameLabel.text = "Amount for Invitee (sats)"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIView.animate(withDuration: 0.2, animations: {
            self.messageFieldContainer.alpha = 1.0
            self.bottomContainer.alpha = 1.0
        })
    }
    
    @IBAction func createInvitationButtonTouched() {
        if let lowestPrice = lowestPrice, walletBalanceService.balance <= lowestPrice {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "invite.more.sats".localized)
            return
        }
        createInvite()
    }
    
    func getLowestPrice() {
        bottomLeftContainer.alpha = 0.0
        createInvitationButton.isUserInteractionEnabled = false
        
        API.sharedInstance.getLowestPrice(callback: { price in
            self.createInvitationButton.isUserInteractionEnabled = true
            self.lowestPrice = Int(price)
            self.configurePriceContainer(lowestPrice: Int(price))
        }, errorCallback: {
            self.bottomLeftContainer.alpha = 0.0
            self.createInvitationButton.isUserInteractionEnabled = true
        })
    }
    
    func configurePriceContainer(lowestPrice: Int) {
        let localBalance = walletBalanceService.balance
        if localBalance > lowestPrice && lowestPrice > 0 {
            amountLabel.text = lowestPrice.formattedWithSeparator
            UIView.animate(withDuration: 0.3, animations: {
                self.bottomLeftContainer.alpha = 1.0
            })
        } else {
            bottomLeftContainer.alpha = 0.0
        }
    }
    
    func createInvite() {
        view.endEditing(true)
        
        if let amount = nickNameField.text,
            let amountSats = Int(amount)
            //let message = messageTextView.text
            //nickname != "" && message != ""
        {
            loading = true
            if let code = SphinxOnionManager.sharedInstance.issueInvite(amountMsat: amountSats * 1000){
                loading = false
                self.delegate?.shouldDismissView?()
                self.closeButtonTouched()
                ClipboardHelper.copyToClipboard(text: code)
            }
            else{
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
            }
        } else {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "nickname.cannot.empty".localized)
        }
    }
    
    func goToInviteCodeString(inviteCode: String) {
        let confirmAddfriendVC = ShareInviteCodeViewController.instantiate()
        confirmAddfriendVC.qrCodeString = inviteCode
        self.navigationController?.pushViewController(confirmAddfriendVC, animated: true)
    }
    
    @IBAction func closeButtonTouched() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension ConfirmAddFriendViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        messageTextView.becomeFirstResponder()
        return true
    }
}

extension ConfirmAddFriendViewController : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        let currentString = textView.text! as NSString
        let currentTrimmedString = (currentString as String).trim()
        if currentTrimmedString == kTextViewNewUserPlaceHolder || currentTrimmedString == kTextViewExistingUserPlaceHolder {
            textView.text = ""
            textView.textColor = kTextViewColor
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        let currentString = textView.text! as NSString
        if (currentString as String).trim() == "" {
            textView.text = isNewUserInvite() ? kTextViewNewUserPlaceHolder : kTextViewExistingUserPlaceHolder
            textView.textColor = kPlaceHolderColor
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentString = textView.text! as NSString
        let currentChangedString = currentString.replacingCharacters(in: range, with: text)
        
        if (currentChangedString.count <= kCharacterLimit) {
            if text == "\n" {
                textView.resignFirstResponder()
                return false
            }
            return true
        } else {
            return false
        }
    }
}
