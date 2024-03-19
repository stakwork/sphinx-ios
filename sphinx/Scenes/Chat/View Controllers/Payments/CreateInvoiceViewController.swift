//
//  Library
//
//  Created by Tomas Timinskas on 21/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SDWebImage
import SwiftyJSON

public enum CreateInvoiceVCPresentationContext{
    case Default
    case InChat
}

class CreateInvoiceViewController: CommonPaymentViewController {
    
    enum bottomButtonState: Int {
        case next
        case confirm
    }
    
    var mode = PaymentsViewModel.PaymentMode.receive
    var presentationContext : CreateInvoiceVCPresentationContext = .Default

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
    var preloadedPubkey : String? = nil
    
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
        contact: UserContact? = nil,
        chat: Chat? = nil,
        messageUUID: String? = nil,
        delegate: PaymentInvoiceDelegate? = nil,
        paymentMode: PaymentsViewModel.PaymentMode = PaymentsViewModel.PaymentMode.receive,
        preloadedPubkey: String? = nil,
        presentationContext: CreateInvoiceVCPresentationContext = .Default
    ) -> CreateInvoiceViewController {
        
        let viewController = StoryboardScene.Chat.createInvoiceViewController.instantiate()
        viewController.mode = paymentMode
        viewController.presentationContext = presentationContext
        viewController.contact = contact
        viewController.chat = chat
        viewController.delegate = delegate
        viewController.preloadedPubkey = preloadedPubkey
        
        if let messageUUID = messageUUID {
            viewController.message = TransactionMessage.getMessageWith(uuid: messageUUID)
        }
        
        viewController.paymentsViewModel = PaymentsViewModel()
        viewController.paymentsViewModel.setPreloadedPubKey(preloadedPubkey: preloadedPubkey)
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "CreateInvoiceViewController"
        setStatusBarColor()
        
        setupContact()
        setupKeyPad()
        setupView()
    }
    
    private func setupView() {
        let sending = mode == PaymentsViewModel.PaymentMode.send
        let sendingOnchain = mode == PaymentsViewModel.PaymentMode.sendOnchain
        
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
        messageFieldContainer.isHidden = sendingOnchain || (sending && contact == nil)
        
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
        let sending = mode == PaymentsViewModel.PaymentMode.send
        
        if sending {
            paymentsViewModel.payment.message = sender.text
        } else {
            paymentsViewModel.payment.memo = sender.text
        }
    }
    
    private func setupContact() {
        if let contact = contact {
            nameLabel.text = contact.nickname
            showUserImage(avatarUrl: contact.avatarUrl)
        } else if let message = message, let senderAlias = message.senderAlias {
            nameLabel.text = senderAlias
            showUserImage(avatarUrl: message.senderPic)
        } else {
            fromLabel.isHidden = true
            nameLabel.isHidden = true
            profileImageView.isHidden = true
        }
        
        let sending = mode == PaymentsViewModel.PaymentMode.send
        let chatPayment = contact != nil
        let nextButtonTitle = sending && chatPayment ? "continue.upper".localized : "confirm.upper".localized
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
            let contactsCount = 1
            let walletBalance = WalletBalanceService().balance
            let sending = (mode == PaymentsViewModel.PaymentMode.send || mode == PaymentsViewModel.PaymentMode.sendOnchain)
            
            if amount > walletBalance && sending && false {
                NewMessageBubbleHelper().showGenericMessageView(text: "balance.too.low".localized)
                return false
            }
            
            let amountString = amount.formattedWithSeparator
            nextButton.isHidden = amount == 0
            amountTextField.text = amount == 0 ? "" : amountString
            
            let totalAmountString = amount.formattedWithSeparator
            groupTotalLabel.text = contactsCount > 1 ? "\("Total") \(totalAmountString)" : ""
            
            paymentsViewModel.payment.amount = amount
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
        let amount = paymentsViewModel.payment.amount ?? 0
        
        let qrCodeDetailViewModel = QRCodeDetailViewModel(
            qrCodeString: invoiceString,
            amount: amount,
            viewTitle: "payment.request".localized
        )
        
        let viewController = QRCodeDetailViewController.instantiate(
            with: qrCodeDetailViewModel
        )
        
        SphinxSocketManager.sharedInstance.setDelegate(delegate: viewController)
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func processOnchainPayment() {
        if let amt = paymentsViewModel.payment.amount, amt < 250000 {
            loading = false
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "onchain.amount.too.low".localized)
            return
        }
        goToScanner()
    }
    
    private func goToScanner() {
        loading = false
        
        let viewController = NewQRScannerViewController.instantiate(
            currentMode: (mode == .sendOnchain) ? .OnchainPayment : .ScanAndProcessPayment
        )
        viewController.delegate = self
        self.present(viewController, animated: true)
    }
    
    private func shouldSendDirectPayment() {
        if let _ = self.contact {
            goToPaymentTemplate()
        } else if let _ = message {
            sendTribePayment()
        } else if let _ = paymentsViewModel.payment.destinationKey {
            sendDirectPayment()
        } else {
            goToScanner()
        }
    }
    
    func sendTribePayment() {
        delegate?.shouldSendTribePayment?(
            amount: paymentsViewModel.payment.amount ?? 0,
            message: paymentsViewModel.payment.message ?? "",
            messageUUID: message?.uuid ?? ""
        ) {
            self.shouldDismissView()
        }
    }
    
    func goToPaymentTemplate() {
        guard let contact = contact else {
            return
        }
        
        loading = false
        
        let viewController = PaymentTemplateViewController.instantiate(
            contact: contact,
            chat: chat,
            delegate: delegate,
            paymentsViewModel: paymentsViewModel
        )
        
        self.navigationController?.pushViewController(viewController, animated: true)
    }
    
    private func sendDirectPayment() {
        let fetchedChat = UserContact.getContactWith(pubkey: preloadedPubkey ?? "")?.getChat()
        guard let chat = chat ?? fetchedChat else{
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "contact.not.found".localized, completion: {
                self.shouldDismissView()
            })
            return
        }
        let parameters = TransactionMessage.getPaymentParamsFor(
            payment: paymentsViewModel.payment,
            contact: contact,
            chat: chat
        )
        
        let image =  #imageLiteral(resourceName: "appPinIcon")
        SphinxOnionManager.sharedInstance.sendDirectPaymentMessage(params: parameters, chat: chat, image: image, completion: { success, _ in
            if(success){
                self.shouldDismissView()
            }
            else{
                AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized, completion: {
                    self.shouldDismissView()
                })
            }
        })
    }
    
    private func createPaymentRequest() {
        if !paymentsViewModel.validateMemo(contact: contact) {
            loading = false
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "memo.too.large".localized)
            return
        }
        
        let parameters = TransactionMessage.getPaymentParamsFor(payment: paymentsViewModel.payment, contact: contact, chat: chat)
        print(parameters)
        if let paymentAmount = paymentsViewModel.payment.amount,
           let invoice = SphinxOnionManager.sharedInstance.createInvoice(amountMsat: paymentAmount * 1000, description: paymentsViewModel.payment.memo ?? "") {
            if presentationContext == .InChat,
               let contact = contact,
               let chat = chat{
                SphinxOnionManager.sharedInstance.sendInvoiceMessage(contact: contact, chat: chat, invoiceString: invoice)
                self.dismissView()
            }
            else{
                self.presentInvoiceDetailsVC(invoiceString: invoice)
            }
        }
        else{
            delegate?.didFailCreatingInvoice?()
        }
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
        paymentsViewModel.payment.destinationKey = string
        shouldSendDirectPayment()
    }
    
    func validateOnchainPmt(address: String) {
        loading = true
        
        if address.isValidBitcoinAddress {
            
            delegate?.shouldSendOnchain?(
                address: address.btcAddresWithoutPrefix,
                amount: paymentsViewModel.payment.amount ?? 0
            )
            
            shouldDismissView()
            return
        }

        AlertHelper.showAlert(title: "generic.error.title".localized, message: "invalid.btc.address".localized, completion: {
            self.shouldDismissView()
        })
    }
}
