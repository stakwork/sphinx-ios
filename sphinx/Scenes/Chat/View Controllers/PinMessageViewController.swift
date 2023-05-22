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
    func didTapUnpinButton(message: TransactionMessage)
    func willDismissPresentedVC()
}

class PinMessageViewController: UIViewController {
    
    @IBOutlet weak var bottomViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bottomView: UIStackView!
    @IBOutlet weak var avatarView: ChatAvatarView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var messageBubbleView: UIView!
    @IBOutlet weak var messageBubbleArrowView: UIView!
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
}

//Setup logic
extension PinMessageViewController {
    func setupLayout() {
        drawArrow()
        
        unpinButtonContainer.layer.borderWidth = 1
        unpinButtonContainer.layer.borderColor = UIColor.Sphinx.SecondaryText.cgColor
        unpinButtonContainer.layer.cornerRadius = unpinButtonContainer.frame.height / 2
        
        popupView.layer.cornerRadius = 20.0
        
        messageBubbleView.layer.cornerRadius = 5.0
        
        pinIconView.makeCircular()
        
        setupMode()
    }
    
    func drawArrow() {
        let arrowBezierPath = UIBezierPath()
        
        arrowBezierPath.move(to: CGPoint(x: 0, y: 0))
        arrowBezierPath.addLine(to: CGPoint(x: messageBubbleArrowView.frame.width, y: 0))
        arrowBezierPath.addLine(to: CGPoint(x: messageBubbleArrowView.frame.width, y: messageBubbleArrowView.frame.height))
        arrowBezierPath.addLine(to: CGPoint(x: 4, y: messageBubbleArrowView.frame.height))
        arrowBezierPath.addLine(to: CGPoint(x: 0, y: 0))
        arrowBezierPath.close()
        
        let outgoingMessageLayer = CAShapeLayer()
        outgoingMessageLayer.path = arrowBezierPath.cgPath
        
        outgoingMessageLayer.frame = CGRect(
            x: 0, y: 0, width: messageBubbleArrowView.frame.width, height: messageBubbleArrowView.frame.height
        )

        outgoingMessageLayer.fillColor = UIColor.Sphinx.SentMsgBG.cgColor
        
        messageBubbleArrowView.layer.addSublayer(outgoingMessageLayer)
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
        if message.isOutgoing() {
            if let owner = UserContact.getOwner() {
                avatarView.configureForUserWith(
                    color: owner.getColor(),
                    alias: owner.nickname,
                    picture: owner.avatarUrl
                )
                
                usernameLabel.text = owner.nickname
            }
        } else {
            avatarView.configureForSenderWith(message: message)
            
            usernameLabel.text = message.senderAlias ?? "Unknown"
        }
        
        messageLabel.text = message.messageContent
        unpinButtonView.isHidden = message.chat?.isMyPublicGroup() == false
    }
}

//View animations
extension PinMessageViewController {
    func animateView() {
        bottomViewBottomConstraint.constant = -(bottomView.frame.height + 100)
        bottomView.superview?.layoutSubviews()
        
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
        
        self.animateBottomViewTo(constant: -(bottomView.frame.height + 100), completion: {
            self.animateAlphaAndDismiss()
        })
    }
    
    func animateAlphaAndDismiss() {
        UIView.animate(withDuration: 0.3, animations: {
            self.view.alpha = 0.0
        }, completion: { _ in
            if self.mode == .PinnedMessageInfo {
                self.dismiss(animated: true)
            } else {
                WindowsManager.sharedInstance.removeCoveringWindow()
            }
        })
    }
}


//Actions handling
extension PinMessageViewController {
    @IBAction func unpinButtonTapped() {
        delegate?.didTapUnpinButton(message: message)
        dismissBottomView()
    }
    
    @IBAction func dismissButtonTapped() {
        if mode == .PinnedMessageInfo {
            dismissBottomView()
        }
    }
}
