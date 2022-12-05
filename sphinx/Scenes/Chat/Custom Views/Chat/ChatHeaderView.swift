//
//  ChatHeaderView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 29/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol ChatHeaderViewDelegate : class {
    func didTapHeaderButton()
    func didTapBackButton()
    func didTapWebAppButton()
    func didTapMuteButton()
    func didTapMoreOptionsButton(sender: UIButton)
}

class ChatHeaderView: UIView {
    
    weak var delegate: ChatHeaderViewDelegate?
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var backArrowButton: UIButton!
    @IBOutlet weak var imageContainer: UIView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var headerNameY: NSLayoutConstraint!
    @IBOutlet weak var contributedSatsLabel: UILabel!
    @IBOutlet weak var contributedSatsIcon: UILabel!
    @IBOutlet weak var lockSign: UILabel!
    @IBOutlet weak var boltSign: UILabel!
    @IBOutlet weak var keyLoadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var volumeButton: UIButton!
    @IBOutlet weak var webAppButton: UIButton!
    @IBOutlet weak var webAppButtonTrailing: NSLayoutConstraint!
    @IBOutlet weak var videoCallButton: UIButton!
    
    var keysLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: keysLoading, loadingWheel: keyLoadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    var chat: Chat? = nil
    var contact: UserContact? = nil
    var contactsService: ContactsService! = nil
    
    public enum RightButtons: Int {
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
    
    func configure(chat: Chat?, contact: UserContact?, contactsService: ContactsService, delegate: ChatHeaderViewDelegate) {
        self.chat = chat
        self.contact = contact
        self.contactsService = contactsService
        self.delegate = delegate
    }
    
    func setChatInfo() {
        nameLabel.text = getHeaderName()
        
        let isEncrypted = (chat?.isEncrypted() ?? contact?.hasEncryptionKey()) ?? false
        lockSign.text = isEncrypted ? "lock" : "lock_open"
        keysLoading = !isEncrypted
        
        configureWebAppButton()
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
            MediaLoader.asyncLoadImage(imageView: profileImageView, nsUrl: nsUrl, placeHolderImage: UIImage(named: "profile_avatar"), completion: { image in
                self.initialsLabel.isHidden = true
                self.profileImageView.isHidden = false
                self.profileImageView.image = image
            }, errorCompletion: { _ in })
        }
    }
    
    func showInitialsFor(contact: UserContact?, and chat: Chat?) {
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
            headerNameY.constant = -8
            contributedSatsIcon.isHidden = false
            contributedSatsLabel.text = String(format: label, sats)
        }
    }
    
    func configureWebAppButton() {
        let hasWebAppUrl = chat?.getAppUrl() != nil
        webAppButtonTrailing.constant = hasWebAppUrl ? 0 : -30
        webAppButton.isHidden = !hasWebAppUrl
        webAppButton.setTitle("apps", for: .normal)
    }
    
    func setVolumeState(muted: Bool) {
        volumeButton.setImage(UIImage(named: muted ? "muteOnIcon" : "muteOffIcon"), for: .normal)
    }
    
    func forceKeysExchange(contactId: Int) {
        contactsService.exchangeKeys(id: contactId)
    }
    
    func checkRoute() {
        API.sharedInstance.checkRoute(chat: self.chat, contact: self.contact, callback: { success in
            DispatchQueue.main.async {
                self.boltSign.textColor = success ? ChatListHeader.kConnectedColor : ChatListHeader.kNotConnectedColor
            }
        })
    }
    
    func toggleWebAppIcon(showChatIcon: Bool) {
        webAppButton.setTitle(showChatIcon ? "chat" : "apps", for: .normal)
    }

    @IBAction func backButtonTouched() {
        delegate?.didTapBackButton()
    }
    
    @IBAction func headerButtonTouched() {
        delegate?.didTapHeaderButton()
    }
    
    @IBAction func rightButtonTouched(_ sender: UIButton) {
        switch(sender.tag) {
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
}
