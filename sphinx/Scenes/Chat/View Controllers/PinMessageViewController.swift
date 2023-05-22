//
//  PinMessageViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 22/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import CoreData

protocol PinMessageDelegate: class {
    func willDismissPresentedVC()
}

class PinMessageViewController: UIViewController {
    
    @IBOutlet weak var bottomViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bottomView: UIStackView!
    @IBOutlet weak var avatarView: ChatAvatarView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var unpinButtonView: UIView!
    @IBOutlet weak var unpinButtonContainer: UIStackView!
    
    @IBOutlet weak var popupView: UIView!
    @IBOutlet weak var pinIconView: UIView!
    @IBOutlet weak var popupLabel: UILabel!
    
    weak var delegate: PinMessageDelegate?
    
    var message: TransactionMessage! = nil
    
    var mode = ViewMode.PinnedMessageInfo
    
    public enum ViewMode {
        case MessagePinned
        case MessageUnpinned
        case PinnedMessageInfo
    }
    
    static func instantiate(
        messageObjectId: NSManagedObjectID,
        delegate: PinMessageDelegate,
        mode: ViewMode
    ) -> PinMessageViewController {
        let viewController = StoryboardScene.Chat.pinMessageViewController.instantiate()
        
        viewController.message = CoreDataManager.sharedManager.getObjectWith(objectId: messageObjectId)
        viewController.delegate = delegate
        viewController.mode = mode
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupLayout()
        setupMessageData()
        
        animateView()
        setupDismiss()
    }
    
    func setupLayout() {
//        bottomView.roundCorners(corners: [.topLeft, .topRight], radius: 10.0)
        
        unpinButtonContainer.layer.borderWidth = 1
        unpinButtonContainer.layer.borderColor = UIColor.Sphinx.SecondaryText.cgColor
        unpinButtonContainer.layer.cornerRadius = unpinButtonContainer.frame.height / 2
        
        popupView.layer.cornerRadius = 20.0
        
        pinIconView.makeCircular()
        
        setupMode()
    }
    
    func setupMode() {
        switch(self.mode) {
        case .PinnedMessageInfo:
            popupView.isHidden = true
            bottomView.isHidden = false
            break
        case .MessagePinned:
            popupView.isHidden = false
            bottomView.isHidden = true
            popupLabel.text = "Message Pinned"
            break
        case .MessageUnpinned:
            popupView.isHidden = false
            bottomView.isHidden = true
            popupLabel.text = "Message Unpinned"
            break
        }
    }
    
    func setupDismiss() {
        if mode == .MessagePinned || mode == .MessageUnpinned {
            DelayPerformedHelper.performAfterDelay(seconds: 2.0, completion: {
                self.animateAlphaAndDismiss()
            })
        }
    }
    
    func setupMessageData() {
        avatarView.configureForSenderWith(message: message)
        
        usernameLabel.text = message.senderAlias ?? "Unknown"
        messageLabel.text = message.messageContent
        
        unpinButtonView.isHidden = message.chat?.isMyPublicGroup() == false
    }
    
    func animateView() {
        view.alpha = 0.0
        
        UIView.animate(withDuration: 0.2, animations: {
            self.view.alpha = 1.0
            self.animatePopup()
        }, completion: { _ in
            self.animateBottomViewTo(constant: 0.0)
        })
    }
    
    func animatePopup() {
        if mode == .MessagePinned || mode == .MessageUnpinned {
            self.popupView.alpha = 1.0
        }
    }
    
    func animateBottomViewTo(
        constant: CGFloat,
        completion: (() -> ())? = nil
    ) {
        if mode != .PinnedMessageInfo {
            return
        }
        
        self.bottomViewBottomConstraint.constant = constant
        
        UIView.animate(withDuration: 0.3, animations: {
            self.bottomView.superview?.layoutSubviews()
        }, completion: { _ in
            completion?()
        })
    }
    
    func dismissBottomView() {
        self.delegate?.willDismissPresentedVC()
        
        self.animateBottomViewTo(constant: -300, completion: {
            self.animateAlphaAndDismiss()
        })
    }
    
    func animateAlphaAndDismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0.0
        }, completion: { _ in
            self.dismiss(animated: true)
        })
    }
    
    @IBAction func unpinButtonTapped() {
        //Handle Unpin
        dismissBottomView()
    }
}
