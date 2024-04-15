//
//  ProfileViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import MobileCoreServices

class ProfileViewController: NewKeyboardHandlerViewController {
    
    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var balanceLabel: UILabel!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var addressTextField: UITextField!
    @IBOutlet weak var routeHintTextField: UITextField!
    @IBOutlet weak var sharePhotoSwitch: UISwitch!
    @IBOutlet weak var trackRecommendationsSwitch: UISwitch!
    @IBOutlet weak var autoDownloadSubscribedPodsSwitch: UISwitch!
    @IBOutlet weak var notificationSoundButton: UIButton!
    @IBOutlet weak var inviteServerTextField: UITextField!
    @IBOutlet weak var memesServerTextField: UITextField!
    @IBOutlet weak var meetingServerTextField: UITextField!
    @IBOutlet weak var meetingAmountTextField: UITextField!
    @IBOutlet weak var relayUrlTextField: UITextField!
    @IBOutlet weak var appearanceView: AppAppearenceView!
    @IBOutlet weak var sizeView: AppSizeView!
    @IBOutlet weak var settingsTabView: SettingsTabsView!
    
    @IBOutlet weak var topContainerView: UIView!
    @IBOutlet weak var bottomContainerView: UIView!
    @IBOutlet weak var settingsContainerView: UIView!
    @IBOutlet weak var serversContainer: UIView!
    @IBOutlet weak var exportKeysContainer: UIView!
    @IBOutlet weak var exportKeyButton: UIButton!
    @IBOutlet weak var relayContainerView: UIView!
    @IBOutlet weak var changePINContainerView: UIView!
    @IBOutlet weak var setGithubPATContainerView: UIView!
    @IBOutlet weak var uploadingLabel: UILabel!
    @IBOutlet weak var uploadLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var contentScrollView: UIScrollView!
    @IBOutlet weak var advanceScrollView: UIScrollView!
    @IBOutlet weak var privacyPinLabel: UILabel!
    @IBOutlet weak var privacyPinGroupContainer: UIView!
    @IBOutlet weak var manageStorageChevronLabel: UILabel!
    @IBOutlet weak var manageStorageView: UIView!
    @IBOutlet weak var storageSumaryLabel: UILabel!
    @IBOutlet weak var storageSummaryBarView: StorageSummaryView!
    @IBOutlet weak var spinner: UIActivityIndicatorView!
    
    @IBOutlet var tabContainers: [UIScrollView]!
    
    @IBOutlet var keyboardAccessoryView: UIView!
    var currentField : UITextField?
    var previousFieldValue : String?
    
    var uploading = false {
        didSet {
            uploadLoadingWheel.color = UIColor.Sphinx.PrimaryText
            uploadLoadingWheel.alpha = uploading ? 1.0 : 0.0
            uploadingLabel.isHidden = !uploading
            view.isUserInteractionEnabled = !uploading
            
            if uploading {
                uploadLoadingWheel.startAnimating()
            } else {
                uploadLoadingWheel.stopAnimating()
            }
        }
    }
    
    let urlUpdateHelper = RelayURLUpdateHelper()
    let userData = UserData.sharedInstance
    
    var imagePickerManager = ImagePickerManager.sharedInstance
    var notificationSoundHelper = NotificationSoundHelper()
    let newMessageBubbleHelper = NewMessageBubbleHelper()
    var walletBalanceService = WalletBalanceService()
    
    public enum ProfileFields: Int {
        case Name
        case MeetingPmtAmt
        case VideoCallServer
        case InvitesServer
        case MemesServer
        case RelayUrl
    }
    
    static func instantiate() -> ProfileViewController {
        let viewController = StoryboardScene.Profile.profileViewController.instantiate()
        viewController.popOnSwipeEnabled = true
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        advanceScrollView.isScrollEnabled = true
        
        setStatusBarColor()
        viewTitle.addTextSpacing(value: 2)
        appearanceView.delegate = self
        settingsTabView.delegate = self
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height / 2
        profileImageView.clipsToBounds = true
        sharePhotoSwitch.onTintColor = UIColor.Sphinx.PrimaryBlue
        trackRecommendationsSwitch.onTintColor = UIColor.Sphinx.PrimaryBlue
        autoDownloadSubscribedPodsSwitch.onTintColor = UIColor.Sphinx.PrimaryBlue
        
        exportKeyButton.layer.cornerRadius = exportKeyButton.frame.height / 2
        privacyPinLabel.text = (GroupsPinManager.sharedInstance.isPrivacyPinSet() ? "change.privacy.pin" : "set.privacy.pin").localized
        
        setShadows()
        configureFields()
        configureProfile()
        configureServers()
        showStorageSpinner()
        configureBalanceTap()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setupMemoryManagement()
    }
    
    func setShadows() {
        topContainerView.addShadow(location: VerticalLocation.center, color: UIColor.black, opacity: 0.2, radius: 2.0)
        bottomContainerView.addShadow(location: VerticalLocation.center, color: UIColor.black, opacity: 0.2, radius: 2.0)
        settingsContainerView.addShadow(location: VerticalLocation.center, color: UIColor.black, opacity: 0.2, radius: 2.0)
        serversContainer.addShadow(location: VerticalLocation.center, color: UIColor.black, opacity: 0.2, radius: 2.0)
        exportKeysContainer.addShadow(location: VerticalLocation.center, color: UIColor.black, opacity: 0.2, radius: 2.0)
        relayContainerView.addShadow(location: VerticalLocation.center, color: UIColor.black, opacity: 0.2, radius: 2.0)
        changePINContainerView.addShadow(location: VerticalLocation.center, color: UIColor.black, opacity: 0.2, radius: 2.0)
        privacyPinGroupContainer.addShadow(location: VerticalLocation.center, color: UIColor.black, opacity: 0.2, radius: 2.0)
        
        setStatusBarColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func keyboardWillShowHandler(_ notification: Notification) {
        if let keyboardSize = (notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
            contentScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
            advanceScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardSize.height, right: 0)
        }
    }
    
    override func keyboardWillHideHandler(_ notification: Notification) {
        contentScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        advanceScrollView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    
    func configureBalanceTap() {
        let balanceTap = UITapGestureRecognizer(target: self, action: #selector(self.balanceLabelTapped(gesture:)))
        self.balanceLabel.addGestureRecognizer(balanceTap)
        updateBalance()
    }
    
    func configureFields() {
        inviteServerTextField.delegate = self
        memesServerTextField.delegate = self
        meetingServerTextField.delegate = self
        meetingAmountTextField.delegate = self
        nameTextField.delegate = self
        relayUrlTextField.delegate = self
        
        inviteServerTextField.inputAccessoryView = keyboardAccessoryView
        memesServerTextField.inputAccessoryView = keyboardAccessoryView
        meetingServerTextField.inputAccessoryView = keyboardAccessoryView
        meetingAmountTextField.inputAccessoryView = keyboardAccessoryView
        nameTextField.inputAccessoryView = keyboardAccessoryView
        relayUrlTextField.inputAccessoryView = keyboardAccessoryView
    }
    
    func configureProfile() {
        uploading = false
        
        if let profile = UserContact.getOwner() {
            imagePickerManager.configurePicker(vc: self)
            
            if let imageUrl = profile.avatarUrl?.trim(), let nsUrl = URL(string: imageUrl), imageUrl != "" {
                MediaLoader.asyncLoadImage(imageView: profileImageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"))
            } else {
                profileImageView.image = UIImage(named: "profile_avatar")
            }
            
            sharePhotoSwitch.isOn = !profile.privatePhoto
            trackRecommendationsSwitch.isOn =  UserDefaults.Keys.shouldTrackActions.get(defaultValue: false)
            autoDownloadSubscribedPodsSwitch.isOn = UserDefaults.Keys.shouldAutoDownloadSubscribedPods.get(defaultValue: false)
            
            let nickname = profile.nickname ?? ""
            nameLabel.text = nickname.getNameStyleString()
            nameTextField.text = nickname.capitalized
            nameTextField.isUserInteractionEnabled = true
            
            let selectedSoundName = notificationSoundHelper.selectUserSound(file: profile.notificationSound)
            notificationSoundButton.setTitle(selectedSoundName, for: .normal)
            
            if let pubKey = profile.publicKey, pubKey != "" {
                addressTextField.text = pubKey
                addressTextField.isUserInteractionEnabled = false
            }
            
            if let routeHint = profile.routeHint, routeHint != "" {
                routeHintTextField.text = routeHint
                routeHintTextField.isUserInteractionEnabled = false
            }
        }
        
        relayUrlTextField.text = userData.getNodeIP()
    }
    
    func showStorageSpinner() {
        storageSumaryLabel.text = "Loading..."
        storageSumaryLabel.textColor = UIColor.Sphinx.SecondaryText
        
        spinner.isHidden = false
        spinner.tintColor = UIColor.Sphinx.Text
        spinner.startAnimating()
    }
    
    func hideStorageSpinner(){
        spinner.isHidden = true
        spinner.stopAnimating()
    }
    
    func setupMemoryManagement(){
        manageStorageView.isUserInteractionEnabled = true
        manageStorageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showManageStorageVC)))
        
        updateStorageSummaryLabel(completion: {
            self.storageSummaryBarView.summaryDict = StorageManager.sharedManager.getStorageItemSummaryByType()
            self.hideStorageSpinner()
        })
    }
    
    func updateStorageSummaryLabel(completion:@escaping ()->()){
        let max = UserData.sharedInstance.getMaxMemoryGB()

        StorageManager.sharedManager.refreshAllStoredData(completion: {
            let usage = StorageManager.sharedManager.getItemGroupTotalSize(items: StorageManager.sharedManager.allItems)
            let maxInBytes = Int(Double(max) * 1e9)

            let usageText = formatBytes(Int(usage * 1e6))
            let remainingText = formatBytes(maxInBytes)

            let fullText = "\(usageText) of \(remainingText)"

            let attributedText = NSMutableAttributedString(string: fullText)
            let usageRange = (fullText as NSString).range(of: usageText)

            attributedText.addAttribute(.foregroundColor, value: UIColor.Sphinx.Text, range: usageRange)
            attributedText.addAttribute(.foregroundColor, value: UIColor.Sphinx.SecondaryText, range: NSRange(location: usageRange.length, length: fullText.count - usageRange.length))

            self.storageSumaryLabel.attributedText = attributedText
            
            completion()
        })
        
    }
    
    func configureServers() {
        inviteServerTextField.text = API.kHUBServerUrl
        memesServerTextField.text = API.kAttachmentsServerUrl
        meetingServerTextField.text = API.kVideoCallServer
        meetingAmountTextField.text = "\(UserContact.kTipAmount)"
    }
    
    //IBActions
    @IBAction func keyboardButtonTouched(_ sender: UIButton) {
        switch (sender.tag) {
        case KeyboardButtons.Done.rawValue:
            if let currentField = currentField {
                if currentField == nameTextField,
                   let name = nameTextField.text{
                    UserContact.updateOwnerAlias(newNickname: name)
                    nameLabel.text = name
                    let _ = textFieldShouldReturn(currentField)
                }
                else{
                    let _ = textFieldShouldReturn(currentField)
                }
            }
            break
        case KeyboardButtons.Cancel.rawValue:
            shouldRevertValue()
            break
        default:
            break
        }
        view.endEditing(true)
    }
    
    @IBAction func addressButtonTouched() {
        copyAddress()
    }
    
    @IBAction func routeHintButtonTouched() {
        copyAddress()
    }
    
    @IBAction func manageStorageButtonTapped(_ sender: Any) {
        showManageStorageVC()
    }
    
    @objc func showManageStorageVC(){
        let vc = ProfileManageStorageViewController.instantiate(storageStats: StorageManager.sharedManager.getStorageItemSummaryByType())
        self.navigationController?.pushViewController(vc, animated: true)

    }
    
    func getAddress() -> String? {
        if let address = addressTextField.text, !address.isEmpty {
            let routeHint = (routeHintTextField.text ?? "").isEmpty ? "" : "_\((routeHintTextField.text ?? ""))"
            return "\(address)\(routeHint)"
        }
        return nil
    }
    
    func copyAddress() {
        if let address = getAddress() {
            ClipboardHelper.copyToClipboard(text: address, message: "address.copied.clipboard".localized)
        }
    }
    
    @IBAction func sharePhotoSwitchChanged(_ sender: UISwitch) {
        updateProfile()
    }
    
    @IBAction func trackRecommendationsSwitchChanged(_ sender: Any) {
        UserDefaults.Keys.shouldTrackActions.set(trackRecommendationsSwitch.isOn)
    }
    
    @IBAction func autoDownloadSubscribedPodsChanged(_ sender: Any) {
        UserDefaults.Keys.shouldAutoDownloadSubscribedPods.set(autoDownloadSubscribedPodsSwitch.isOn)
    }
    
    @IBAction func qrCodeButtonTouched() {
        if let profile = UserContact.getOwner(), let qrCodeString = profile.getAddress(), !qrCodeString.isEmpty {
            goToQRDetails(qrCodeString: qrCodeString, title: "public.key".localized)
        }
    }
    
    func goToQRDetails(qrCodeString: String, title: String) {
        let qrCodeDetailViewModel = QRCodeDetailViewModel(qrCodeString: qrCodeString, amount: 0, viewTitle: title)
        let viewController = QRCodeDetailViewController.instantiate(with: qrCodeDetailViewModel)
        self.present(viewController, animated: true, completion: nil)
    }
    
    @IBAction func backbuttonTouched() {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func profilePictureButtonTouched() {
        imagePickerManager.showAlert(
            title: "profile.image".localized,
            message: "select.option".localized,
            sourceView: profileImageView,
            mediaTypes: [kUTTypeImage as String]
        )
    }
    
    @IBAction func exportKeysButtonTouched() {
        let subtitle = "pin.keys.encryption".localized
        let setPinVC = PinCodeViewController.instantiate(subtitle: subtitle)
        setPinVC.doneCompletion = { pin in
            setPinVC.dismiss(animated: true, completion: {
                if let mnemonic = UserData.sharedInstance.getMnemonic() {
                    SphinxOnionManager.sharedInstance.vc = self
                    SphinxOnionManager.sharedInstance.showMnemonicToUser(mnemonic: mnemonic, callback: {})
                    SphinxOnionManager.sharedInstance.vc = nil
                } else {
                    AlertHelper.showAlert(title: "generic.error.title".localized, message: "generic.error.message".localized)
                }
            })
        }
        self.present(setPinVC, animated: true)
    }
    
    @IBAction func setGithubPATButtonTouched() {
        AlertHelper.showPromptAlert(
            title: "profile.github-pat-title".localized,
            message: "profile.github-pat-message".localized,
            on: self,
            confirm: { value in
                if let value = value {
                    self.sendGithubPAT(pat: value)
                }
            },
            cancel: {}
        )
    }
    
    func sendGithubPAT(
        pat: String
    ) {
        var parameters = [String : AnyObject]()
        
        if let transportK = userData.getTransportKey(),
           let transportEncryptionKey = EncryptionManager.sharedInstance.getPublicKeyFromBase64String(base64String: transportK) {
            
            if let encryptedPat = EncryptionManager.sharedInstance.encryptToken(token: pat, key: transportEncryptionKey) {
                parameters["encrypted_pat"] = encryptedPat as AnyObject?
            }
        }
        
        if (parameters.keys.isEmpty) {
            AlertHelper.showAlert(
                title: "generic.error.title".localized,
                message: "profile.github-pat.error".localized
            )
            return
        }
        
        API.sharedInstance.addGitPAT(
            params: parameters,
            callback: { _ in
                self.newMessageBubbleHelper.showGenericMessageView(
                    text: "profile.github-pat.success".localized,
                    textColor: UIColor.white,
                    backColor: UIColor.Sphinx.PrimaryGreen,
                    backAlpha: 1.0
                )
            },
            errorCallback: {
                AlertHelper.showAlert(
                    title: "generic.error.title".localized,
                    message: "profile.github-pat.error".localized
                )
            }
        )
    }
    
    @IBAction func changePinButtonTouched() {
        shouldChangePIN()
    }
    
    @IBAction func privacyPinButtonTouched() {
        shouldChangePrivacyPIN()
    }
    
    @IBAction func notificationButtonTouched() {
        let _ = notificationSoundHelper.selectUserSound(file: UserContact.getOwner()?.notificationSound)
        let notificationSoundVC = NotificationSoundViewController.instantiate(helper: notificationSoundHelper, delegate: self)
        self.navigationController?.pushViewController(notificationSoundVC, animated: true)
    }
    
    private func updateBalance() {
        walletBalanceService.updateBalance(labels: [balanceLabel])
    }
    
    @objc private func balanceLabelTapped(gesture: UIGestureRecognizer) {
        let hideBalances = UserDefaults.Keys.hideBalances.get(defaultValue: false)
        UserDefaults.Keys.hideBalances.set(!hideBalances)
        updateBalance()
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if self.traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
                setShadows()
            }
        }
    }
}
