//
//  NewContactViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import CoreData

@objc protocol NewContactVCDelegate: class {
    @objc optional func shouldReloadContacts(
        reload: Bool,
        dashboardTabIndex: Int
    )
    @objc optional func shouldReloadChat(chat: Chat)
    @objc optional func shouldDismissView()
    @objc optional func didDismissPresentedView()
    @objc optional func didCreateInvite()
}

class NewContactViewController: KeyboardEventsViewController {
    
    weak var delegate: NewContactVCDelegate?

    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var topViewContainer: UIView!
    @IBOutlet weak var contentScrollView: UIScrollView!
    @IBOutlet weak var nickNameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var routeHintTextField: UITextField!
    @IBOutlet weak var qrCodeImageView: UIImageView!
    @IBOutlet weak var saveToContactsContainer: UIView!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var subscribeButton: UIButton!
    @IBOutlet weak var saveButtonLabel: UILabel!
    @IBOutlet weak var saveLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var uploadingLabel: UILabel!
    @IBOutlet weak var contactImageView: UIImageView!
    @IBOutlet weak var contactInitials: UILabel!
    @IBOutlet weak var nameFieldRightConstraint: NSLayoutConstraint!
    @IBOutlet weak var groupPinContainer: GroupPinView!
    
    var contact : UserContact? = nil
    var pubkey : String? = nil
    
    var shouldRealodChat = false
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: saveLoadingWheel, loadingWheelColor: UIColor.white, view: view)
        }
    }
    
    enum TextFields: Int {
        case NickName
        case Address
        case GroupPIN
    }
    
    enum GroupPINButtons: Int {
        case Change
        case Remove
    }
    
    var saveEnabled = false {
        didSet {
            saveToContactsContainer.isUserInteractionEnabled = saveEnabled
            saveToContactsContainer.alpha = saveEnabled ? 1.0 : 0.5
        }
    }
    
    static func instantiate(
        contactId: Int? = nil,
        pubkey: String? = nil
    ) -> NewContactViewController {
        let viewController = StoryboardScene.Contacts.newContactViewController.instantiate()
        
        if let contactId = contactId {
            viewController.contact = UserContact.getContactWith(id: contactId)
        }
        
        viewController.pubkey = pubkey
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loading = false
        
        topViewContainer.addShadow(location: VerticalLocation.bottom, opacity: 0.2, radius: 2.0)
        saveToContactsContainer.layer.cornerRadius = saveToContactsContainer.frame.size.height / 2
        subscribeButton.layer.cornerRadius = subscribeButton.frame.size.height / 2
        
        contactImageView.layer.cornerRadius = contactImageView.frame.height / 2
        contactImageView.clipsToBounds = true
        
        contactInitials.layer.cornerRadius = contactInitials.frame.height / 2
        contactInitials.clipsToBounds = true
        
        groupPinContainer.configureWith()
        
        qrCodeImageView.image = UIImage(named: "scannerIcon")
        
        configureTextField()
        setAccessibilityIdentifiers()
    }
    
    func setContactInfo(contact: UserContact) {
        viewTitle.text = "edit.contact.upper".localized
        saveButtonLabel.text = "save.upper".localized
        
        closeButton.isHidden = true
        subscribeButton.isHidden = false
        backButton.isHidden = false
        contactImageView.isHidden = false
        contactInitials.isHidden = false
        
        groupPinContainer.configureWith(contact: contact)
        
        nickNameTextField.text = contact.nickname ?? ""
        addressTextField.text = contact.publicKey ?? ""
        routeHintTextField.text = contact.routeHint ?? ""
        addressTextField.isUserInteractionEnabled = false
        
        nameFieldRightConstraint.constant = 60
        nickNameTextField.superview?.layoutIfNeeded()
        
        qrCodeImageView.image = UIImage(named: "qr_code")
        setSubscriptionInfo(subscribed: contact.getCurrentSubscription() != nil)
        
        showInitials(contact: contact)
        viewTitle.addTextSpacing(value: 2)
        
        if let imageUrl = contact.avatarUrl?.trim().removeDuplicatedProtocol(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
            MediaLoader.asyncLoadImage(imageView: contactImageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"), completion: { image in
                self.contactImageView.contentMode = .scaleAspectFill
                self.contactInitials.isHidden = true
                self.contactImageView.isHidden = false
                self.contactImageView.image = image
            }, errorCompletion: { _ in })
        }
        
    }
    
    func setAccessibilityIdentifiers(){
        nickNameTextField.accessibilityIdentifier = "nickNameTextField"
        addressTextField.accessibilityIdentifier = "addressTextField"
        routeHintTextField.accessibilityIdentifier = "routeHintTextField"
        saveToContactsContainer.accessibilityIdentifier = "saveToContactsContainer"
        self.view.accessibilityIdentifier = "parentView"
    }
    
    func showInitials(contact: UserContact) {
        let senderNickname = contact.nickname ?? "name.unknown".localized
        let senderColor = contact.getColor()
        
        contactInitials.isHidden = false
        contactImageView.isHidden = true
        contactInitials.backgroundColor = senderColor
        contactInitials.textColor = UIColor.white
        contactInitials.text = senderNickname.getInitialsFromName()
    }
    
    func setSubscriptionInfo(subscribed: Bool) {
        subscribeButton.setTitle((subscribed ? "subscribed.upper" : "subscribe.upper").localized, for: .normal)
        subscribeButton.setBackgroundColor(color: subscribed ? UIColor.Sphinx.WashedOutReceivedText : UIColor.Sphinx.PrimaryBlue, forUIControlState: .normal)
        subscribeButton.layer.cornerRadius = subscribeButton.frame.size.height / 2
        subscribeButton.clipsToBounds = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let contact = contact {
            setContactInfo(contact: contact)
            
            UserContactsHelper.reloadSubscriptions(contact: contact, callback: { _ in
                self.setContactInfo(contact: contact)
            })
        } else if let pubkey = pubkey {
            let (pk, rh) = (pubkey.isV2Pubkey) ? pubkey.v2PubkeyComponents : pubkey.pubkeyComponents
            backButton.isHidden = true
            addressTextField.text = pk
            routeHintTextField.text = rh
        }
    }

    @objc override func keyboardWillShow(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            contentScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }

    @objc override func keyboardWillHide(_ notification: Notification) {
        contentScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func configureTextField() {
        nickNameTextField.delegate = self
        addressTextField.delegate = self
        routeHintTextField.delegate = self
    }
    
    func reloadChatIfNeeded() {
        if self.shouldRealodChat {
            self.shouldRealodChat = false
            self.delegate?.shouldReloadContacts?(reload: true, dashboardTabIndex: -1)
        }
    }
    
    @IBAction func addressButtonTouched() {
        if let contact = contact {
            guard let qrCodeString = contact.getAddress() else { return }
            presentQRCodeDetails(qrCode: qrCodeString)
        } else {
            presentScanner()
        }
    }
    
    func presentQRCodeDetails(qrCode: String) {
        let qrCodeDetailViewModel = QRCodeDetailViewModel(qrCodeString: qrCode, amount: 0, viewTitle: "public.key".localized)
        let viewController = QRCodeDetailViewController.instantiate(with: qrCodeDetailViewModel)
        self.present(viewController, animated: true, completion: nil)
    }
    
    func presentScanner() {
        let viewController = NewQRScannerViewController.instantiate(
            currentMode: NewQRScannerViewController.Mode.ScanAndDismiss
        )
        viewController.delegate = self
        self.present(viewController, animated: true)
    }
    
    @IBAction func saveToContactsButtonTouched() {
        loading = true
        
        if let _ = contact {
            updateProfile()
        }
        else if routeHintTextField.text?.isV2RouteHint ?? false{
            createV2Contact()
        }
        else {
            createContact()
        }
    }
    
    @IBAction func subscribeButtonTouched() {
        SubscriptionManager.sharedInstance.resetValues()
        SubscriptionManager.sharedInstance.contact = contact
        
        let viewController = SubscriptionFormViewController.instantiate()
        viewController.delegate = self
        navigationController?.pushViewController(viewController, animated: true)
    }
    
    @IBAction func closeButtonTouched() {
        dismiss(animated: true, completion: {
            self.delegate?.didDismissPresentedView?()
        })
    }
    
    @IBAction func backButtonTouched() {
        reloadChatIfNeeded()
        navigationController?.popViewController(animated: true)
    }
    
    
}

