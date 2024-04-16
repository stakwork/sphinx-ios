//
//  ChatHeaderView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol ChatHeaderViewDelegate : class {
    ///Chat header
    func didTapHeaderButton()
    func didTapBackButton()
    func didTapWebAppButton()
    func didTapSecondBrainButton()
    func didTapMuteButton()
    func didTapMoreOptionsButton(sender: UIButton)
    func didTapShowThreadsButton()
    
    ///Chat search header
    func shouldSearchFor(term: String)
    func didTapSearchCancelButton()
}

class ChatHeaderView: UIView {
    
    weak var delegate: ChatHeaderViewDelegate?
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var backArrowButton: UIButton!
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var contributedSatsLabel: UILabel!
    @IBOutlet weak var contributedSatsIcon: UILabel!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var boltSign: UILabel!
    @IBOutlet weak var keyLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var volumeButton: UIButton!
    @IBOutlet weak var secondBrainButton: UIButton!
    @IBOutlet weak var webAppButton: UIButton!
    @IBOutlet weak var contributionsContainer: UIStackView!
    @IBOutlet weak var optionsButton: UIButton!
    @IBOutlet weak var showThreadsButton: UIButton!
    
    var keysLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: keysLoading, loadingWheel: keyLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    var chat: Chat? = nil
    var contact: UserContact? = nil
    
    public enum RightButtons: Int {
        case SecondBrain
        case WebApp
        case Mute
        case More
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
        Bundle.main.loadNibNamed("ChatHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        profileImageView.layer.cornerRadius = profileImageView.frame.size.height/2
        profileImageView.clipsToBounds = true
        
        initialsLabel.layer.cornerRadius = initialsLabel.frame.size.height/2
        initialsLabel.clipsToBounds = true
        
        NotificationCenter.default.addObserver(forName: .onBalanceDidChange, object: nil, queue: OperationQueue.main) { (n: Notification) in
            self.updateSatsEarned()
        }
    }
    
    func configureWith(
        chat: Chat?,
        contact: UserContact?,
        delegate: ChatHeaderViewDelegate
    ) {
        self.chat = chat
        self.contact = contact
        self.delegate = delegate
        
        setChatInfo()
    }
    
    func setChatInfo() {
        nameLabel.text = getHeaderName()
        
        let isEncrypted = (contact?.status == UserContact.Status.Confirmed.rawValue) || (chat?.status == Chat.ChatStatus.approved.rawValue)
        lockSign.text = isEncrypted ? "lock" : "lock_open"
        keysLoading = !isEncrypted
        
        configureWebAppButton()
        configureThreadsButton()
        configureSecondBrainButton()
        
        setVolumeState(muted: chat?.isMuted() ?? false)
        configureImageOrInitials()
        
        if let contact = contact, !contact.hasEncryptionKey() {
            forceKeysExchange(contactId: contact.id)
        }
    }
    
    func getHeaderName() -> String {
        if let chat = chat, chat.isGroup() {
            return chat.getName()
        } else if let contact = contact {
            return contact.getName()
        } else {
            return "name.unknown".localized
        }
    }
    
    func getInitialsColor() -> UIColor {
        if let chat = chat, chat.isGroup() {
            return chat.getColor()
        } else if let contact = contact {
            return contact.getColor()
        } else {
            return UIColor.random()
        }
    }
    
    func getImageUrl() -> String? {
        if let chat = chat, let url = chat.getPhotoUrl(), !url.isEmpty {
            return url.removeDuplicatedProtocol()
        } else if let contact = contact, let url = contact.getPhotoUrl(), !url.isEmpty {
            return url.removeDuplicatedProtocol()
        }
        return nil
    }
    
    func configureImageOrInitials() {
        profileImageView.isHidden = true
        initialsLabel.isHidden = true
        profileImageView.layer.borderWidth = 0
        
        showInitialsFor(contact: contact, and: chat)
        
        if let imageUrl = getImageUrl()?.trim(), let nsUrl = URL(string: imageUrl) {
            profileImageView.sd_setImage(
                with: nsUrl,
                placeholderImage: UIImage(named: "profile_avatar"),
                options: [.scaleDownLargeImages, .decodeFirstFrameOnly, .lowPriority],
                progress: nil,
                completed: { (image, error, _, _) in
                    if (error == nil) {
                        self.initialsLabel.isHidden = true
                        self.profileImageView.isHidden = false
                        self.profileImageView.image = image
                    }
                }
            )
        }
    }
    
    func showInitialsFor(
        contact: UserContact?,
        and chat: Chat?
    ) {
        let name = getHeaderName()
        let color = getInitialsColor()
        
        initialsLabel.isHidden = false
        initialsLabel.backgroundColor = color
        initialsLabel.textColor = UIColor.white
        initialsLabel.text = name.getInitialsFromName()
    }
    
    func updateSatsEarned() {
        if let feedID = chat?.contentFeed?.feedID {
            let isMyTribe = (chat?.isMyPublicGroup() ?? false)
            let label = isMyTribe ? "earned.sats".localized : "contributed.sats".localized
            let sats = PodcastPaymentsHelper.getSatsEarnedFor(feedID)
            contributedSatsLabel.text = String(format: label, sats)
            contributionsContainer.isHidden = false
        }
    }
    
    func configureWebAppButton() {
        let hasWebAppUrl = chat?.getAppUrl() != nil
        webAppButton.isHidden = !hasWebAppUrl
        webAppButton.setTitle("apps", for: .normal)
    }
    
    func configureSecondBrainButton() {
        let hasSecondBrain = chat?.getSecondBrainAppUrl() != nil
        secondBrainButton.isHidden = !hasSecondBrain
    }
    
    func configureThreadsButton() {
        let isTribe = chat?.isPublicGroup() == true
        showThreadsButton.isHidden = !isTribe
    }
    
    func setVolumeState(muted: Bool) {
        volumeButton.setImage(UIImage(named: muted ? "muteOnIcon" : "muteOffIcon"), for: .normal)
    }
    
    func forceKeysExchange(contactId: Int) {
        UserContactsHelper.exchangeKeys(id: contactId)
    }
    
    func checkRoute() {
        let success = (contact?.status == UserContact.Status.Confirmed.rawValue) || (chat?.status == Chat.ChatStatus.approved.rawValue)
        self.boltSign.textColor = success ? ChatListHeader.kConnectedColor : ChatListHeader.kNotConnectedColor
        keysLoading = !success
    }
    
    func toggleWebAppIcon(showChatIcon: Bool) {
        webAppButton.setTitle(showChatIcon ? "chat" : "apps", for: .normal)
    }
    
    func toggleSBIcon(showChatIcon: Bool) {
        secondBrainButton.setTitle(showChatIcon ? "chat" : "", for: .normal)
        secondBrainButton.setImage(showChatIcon ? nil : UIImage(named: "secondBrainIcon"), for: .normal)
    }

    @IBAction func backButtonTouched() {
        delegate?.didTapBackButton()
    }
    
    @IBAction func headerButtonTouched() {
        delegate?.didTapHeaderButton()
    }
    
    @IBAction func rightButtonTouched(_ sender: UIButton) {
        switch(sender.tag) {
        case RightButtons.SecondBrain.rawValue:
            delegate?.didTapSecondBrainButton()
            break
        case RightButtons.WebApp.rawValue:
            delegate?.didTapWebAppButton()
            break
        case RightButtons.Mute.rawValue:
            delegate?.didTapMuteButton()
            break
        case RightButtons.More.rawValue:
            delegate?.didTapMoreOptionsButton(sender: sender)
            break
        default:
            break
        }
    }
    
    @IBAction func showThreadsButtonTapped(_ sender: Any) {
        delegate?.didTapShowThreadsButton()
    }
    
}
