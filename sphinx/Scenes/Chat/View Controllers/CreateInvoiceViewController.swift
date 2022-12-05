//
//  Library
//
//  Created by Tomas Timinskas on 21/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftyJSON

class CreateInvoiceViewController: CommonPaymentViewController {
    
    enum bottomButtonState: Int {
        case next
        case confirm
    }
    
    enum paymentMode: Int {
        case receive
        case send
        case sendOnchain
    }
    
    var mode : paymentMode = paymentMode.receive

    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var keyPadView: NewKeyPadView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var fromLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var amountTextField: UITextField!
    @IBOutlet weak var unitLabel: UILabel!
    @IBOutlet weak var messageFieldContainer: UIView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var groupTotalLabel: UILabel!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    let kCharacterLimit = 200
    let kMaximumAmount = 9999999
    
    var textColor: UIColor = UIColor.Sphinx.Text {
        didSet {
            amountTextField.textColor = textColor
            keyPadView.textColor = textColor
        }
    }
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text, view: view)
        }
    }
    
    static func instantiate(
        contacts: [UserContact]? = nil,
        chat: Chat? = nil,
        messageUUID: String? = nil,
        viewModel: ChatViewModel,
        delegate: PaymentInvoiceDelegate? = nil,
        paymentMode: paymentMode = paymentMode.receive,
        rootViewController: RootViewController
    ) -> CreateInvoiceViewController {
        let viewController = StoryboardScene.Chat.createInvoiceViewController.instantiate()
        viewController.mode = paymentMode
        viewController.contacts = contacts
        viewController.chat = chat
        viewController.delegate = delegate
        viewController.rootViewController = rootViewController
        
        if let messageUUID = messageUUID {
            viewController.message = TransactionMessage.getMessageWith(uuid: messageUUID)
        }
        
        viewModel.resetCurrentPayment()
        viewController.chatViewModel = viewModel
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootViewController.setStatusBarColor(light: false)
        
        setupContact()
        setupKeyPad()
        setupView()
    }
    
    private func setupView() {
        let sending = mode == paymentMode.send
        let sendingOnchain = mode == paymentMode.sendOnchain
        
        nextButton.layer.cornerRadius = nextButton.frame.size.height / 2
        nextButton.clipsToBounds = true
        nextButton.isHidden = true
        backButton.isHidden = !(chat?.isGroup() ?? false) || sendingOnchain
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height / 2
        profileImageView.clipsToBounds = true
        
        messageTextField.delegate = self
        messageTextField.tintColor = messageTextField.textColor
        messageTextField.addTarget(self, action: #selector(updateMemo(sender:)), for: .editingChanged)
        
        fromLabel.text = sending ? "to".localized : "from".localized
        titleLabel.text = getViewTitle()
        messageFieldContainer.isHidden = sendingOnchain || (sending && contacts == nil)
        
        titleLabel.addTextSpacing(value: 2)
    }
    
    func getViewTitle() -> String {
        switch(mode) {
        case .send:
            return "send.payment.upper".localized
        case .sendOnchain:
            return "send.onchain.upper".localized
        default:
            return "request.amount.upper".localized
        }
    }
    
    @objc private func updateMemo(sender: UITextField) {
        let sending = mode == paymentMode.send
        
        if sending {
            chatViewModel.currentPayment.message = sender.text
        } else {
            chatViewModel.currentPayment.memo = sender.text
        }
    }
    
    private func setupContact() {
        if let contacts = contacts, contacts.count > 0 {
            let contact = contacts[0]
            
            if contacts.count > 1 {
                nameLabel.text = "\(contacts.count) \("users")"
            } else {
                nameLabel.text = contact.nickname
            }
            
            showUserImage(avatarUrl: contact.avatarUrl)
        } else if let message = message, let senderAlias = message.senderAlias {
            nameLabel.text = senderAlias
            showUserImage(avatarUrl: message.senderPic)
        } else {
            fromLabel.isHidden = true
            nameLabel.isHidden = true
            profileImageView.isHidden = true
        }
        
        let sending = mode == paymentMode.send
        let nextButtonTitle = sending ? "continue.upper".localized : "confirm.upper".localized
        nextButton.setTitle(nextButtonTitle, for: .normal)
    }
    
    private func showUserImage(avatarUrl: String?) {
        if let imageUrl = avatarUrl?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
            MediaLoader.asyncLoadImage(imageView: profileImageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"))
        } else {
            profileImageView.image = UIImage(named: "profile_avatar")
        }
    }
    
    private func setupKeyPad() {
        keyPadView.handler = { [weak self] in
            self?.updateKeyPadString(input: $0) ?? false
        }
    }
    
    private func updateKeyPadString(input: String) -> Bool {
        let amount = Int(input) ?? 0
        if amount >= 0 && amount <= kMaximumAmount {
            let contactsCount = (contacts?.count ?? 1).forcedNotZero
            let totalAmount = amount * contactsCount
            let walletBalance = WalletBalanceService().balance
            let sending = (mode == paymentMode.send || mode == paymentMode.sendOnchain)
            
            if totalAmount > walletBalance && sending {
                NewMessageBubbleHelper().showGenericMessageView(text: "balance.too.low".localized)
                return false
            }
            
            let amountString = amount.formattedWithSeparator
            nextButton.isHidden = amount == 0
            amountTextField.text = amount == 0 ? "" : amountString
            
            let totalAmountString = totalAmount.formattedWithSeparator
            groupTotalLabel.text = contactsCount > 1 ? "\("Total") \(totalAmountString)" : ""
            
            chatViewModel.currentPayment.amount = amount
            return true
        }
        NewMessageBubbleHelper().showGenericMessageView(text: "amount.too.high".localized)
        return false
    }
    
    @IBAction func amountButtonTapped() {
        keyPadView.isUserInteractionEnabled = true
        messageTextField.resignFirstResponder()
    }
    
    @IBAction func closeButtonTapped() {
        dismissView()
    }
    
    @IBAction func backButtonTouched() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func nextButtonSelected() {
        nextButton.backgroundColor = UIColor.Sphinx.PrimaryBlueBorder
    }
    
    @IBAction func nextButtonDeselected() {
        nextButton.backgroundColor = UIColor.Sphinx.PrimaryBlue
    }
    
    @IBAction func nextButtonTapped() {
        nextButtonDeselected()
        loading = true
        
        switch mode {
        case .send:
            shouldSendDirectPayment()
        case .sendOnchain:
            processOnchainPayment()
        default:
            //.receive
            createPaymentRequest()
        }
    }
    
    private func presentInvoiceDetailsVC(invoiceString: String) {
        let amount = chatViewModel.currentPayment.amount ?? 0
        let qrCodeDetailViewModel = QRCodeDetailViewModel(qrCodeString: invoiceString, amount: amount, viewTitle: "payment.request".localized)
        let viewController = QRCodeDetailViewController.instantiate(with: qrCodeDetailViewModel)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func processOnchainPayment() {
        if let amt = chatViewModel.currentPayment.amount, amt < 250000 {
            loading = false
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "onchain.amount.too.low".localized)
            return
        }
        goToScanner()
    }
    
    private func goToScanner() {
        loading = false
        let viewController = NewQRScannerViewController.instantiate()
        let scannerMode: NewQRScannerViewController.Mode = (mode == .sendOnchain) ? .OnchainPayment : .DirectPayment
        viewController.currentMode = scannerMode
        viewController.delegate = self
        self.present(viewController, animated: true)
    }
    
    private func shouldSendDirectPayment() {
        if let contacts = self.contacts, contacts.count > 0 {
            goToPaymentTemplate()
        } else if let _ = message {
            sendTribePayment()
        } else if let _ = self.chatViewModel.currentPayment.destinationKey {
            sendDirectPayment()
        } else {
            goToScanner()
        }
    }
    
    func sendTribePayment() {
        delegate?.shouldSendTribePayment?(
            amount: chatViewModel.currentPayment.amount ?? 0,
            message: chatViewModel.currentPayment.message ?? "",
            messageUUID: message?.uuid ?? ""
        ) {
            self.shouldDismissView()
        }
    }
    
    func goToPaymentTemplate() {
        guard let contacts = contacts else {
            return
        }
        loading = false
        
        let viewController = PaymentTemplateViewController.instantiate(contacts: contacts, chat: chat, chatViewModel: chatViewModel, delegate: delegate, rootViewController: rootViewController)
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func sendDirectPayment() {
        let parameters = chatViewModel.getParams(contacts: contacts, chat: chat)
        
        API.sharedInstance.sendDirectPayment(params: parameters, callback: { payment in
            if let payment = payment {
                self.createLocalMessages(message: payment)
            } else {
                AlertHelper.showAlert(title: "generic.success.title".localized, message: "payment.successfully.sent".localized, completion: {
                    self.shouldDismissView()
                })
            }
        }, errorCallback: {
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized, completion: {
                self.shouldDismissView()
            })
        })
    }
    
    private func createPaymentRequest() {
        if !chatViewModel.validateMemo(contacts: contacts) {
            loading = false
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "memo.too.large".localized)
            return
        }
            
        let parameters = chatViewModel.getParams(contacts: contacts, chat: chat)
        
        API.sharedInstance.createInvoice(parameters: parameters, callback: { message, invoice in
            if let message = message {
                self.createLocalMessages(message: message)
            } else if let invoice = invoice {
                self.presentInvoiceDetailsVC(invoiceString: invoice)
            }
        }, errorCallback: {
            self.createLocalMessages(message: nil)
        })
    }
}

extension CreateInvoiceViewController : UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let currentString = textField.text! as NSString
        let currentChangedString = currentString.replacingCharacters(in: range, with: string)
        
        if (currentChangedString.count <= kCharacterLimit) {
            return true
        } else {
            return false
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        keyPadView.isUserInteractionEnabled = true
        messageTextField.resignFirstResponder()
        return true
    }
}

extension CreateInvoiceViewController : QRCodeScannerDelegate {
    func didScanQRCode(string: String) {
        if mode == .sendOnchain {
            validateOnchainPmt(address: string)
            return
        }
        chatViewModel.currentPayment.destinationKey = string
        shouldSendDirectPayment()
    }
    
    func validateOnchainPmt(address: String) {
        loading = true
        
        if address.isValidBitcoinAddress {
            delegate?.shouldSendOnchain?(address: address.btcAddresWithoutPrefix, amount: chatViewModel.currentPayment.amount ?? 0)
            shouldDismissView()
            return
        }

        AlertHelper.showAlert(title: "generic.error.title".localized, message: "invalid.btc.address".localized, completion: {
            self.shouldDismissView()
        })
    }
}
