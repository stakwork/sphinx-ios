//
//  ChatMessageTextFieldView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

@objc protocol ChatMessageTextFieldViewDelegate {
    func didTapSendBlueButton()
    func didDetectPossibleMention(mentionText:String)
    func shouldSendMessage(text: String, type: Int, completion: @escaping (Bool) -> ())
    
    @objc optional func didTapAttachmentsButton(text: String?)
    @objc optional func shouldStartRecording()
    @objc optional func shouldStopAndSendAudio()
    @objc optional func shouldCancelRecording()
}

enum MessagesFieldMode: Int {
    case Chat
    case Attachment
}

class ChatMessageTextFieldView: UIView {
    
    var delegate: ChatMessageTextFieldViewDelegate?

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var textViewContainer: UIView!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var attachmentButtonContainer: UIView!
    @IBOutlet weak var attachmentButton: UIButton!
    
    @IBOutlet weak var sendButtonContainer: UIView!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var audioButtonContainer: UIView!
    @IBOutlet weak var audioButton: UIButton!
    
    @IBOutlet weak var recordingContainer: UIView!
    @IBOutlet weak var recordingTimeLabel: UILabel!
    @IBOutlet weak var recordingBlueCircle: UIView!
    @IBOutlet weak var animatedMicLabelView: IntermitentAlphaAnimatedView!
    
    let kCharacterLimit = 1000
    let kFieldPlaceHolder = "message.placeholder".localized
    let kAttchmentFieldPlaceHolder = ChatAttachmentViewController.kFieldPlaceHolder
    
    let kFieldPlaceHolderColor = UIColor.Sphinx.PlaceholderText
    let kFieldFont = UIFont(name: "Roboto-Regular", size: UIDevice.current.isIpad ? 20.0 : 16.0)!
    
    var mode = MessagesFieldMode.Chat
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("ChatMessageTextFieldView", owner: self, options: nil)
        addSubview(contentView)
        
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        setupViewLayouts()
    }
    
    func setupViewLayouts() {
        textViewContainer.layer.cornerRadius = textViewContainer.frame.size.height/2
        textViewContainer.clipsToBounds = true
        
        sendButton.layer.cornerRadius = sendButton.frame.size.height / 2
        sendButton.clipsToBounds = true
        
        textView.text = placeHolderText
        textView.font = kFieldFont
        textView.delegate = self
        
        attachmentButton.layer.cornerRadius = attachmentButton.frame.size.height / 2
        attachmentButton.clipsToBounds = true
        
        animatedMicLabelView.layer.cornerRadius = animatedMicLabelView.frame.size.height / 2
        recordingBlueCircle.layer.cornerRadius = recordingBlueCircle.frame.size.height / 2
        
        attachmentButton.tintColorDidChange()
    }
    
    func shouldExpandKeyboard() {
        textView.becomeFirstResponder()
    }
    
    func shouldDismissKeyboard() {
        textView.resignFirstResponder()
    }
    
    func setOngoingMessage(text: String) {
        if text.isEmpty {
            return
        }
        textView.text = text
        textView.textColor = UIColor.Sphinx.TextMessages
        textViewDidChange(textView)
    }
    
    func getMessage() -> String {
        if textView.text == placeHolderText {
            return ""
        }
        return textView.text
    }
    
    func createNewMessage(text: String) {
        clearMessage()
        
//        let messageType = TransactionMessage.TransactionMessageType.message.rawValue
//        delegate?.shouldSendMessage(text: text, type: messageType, completion: { success in
//            self.sendButton.isUserInteractionEnabled = true
//        })
    }
    
    func clearMessage() {
        textView.text = ""
        textViewDidChange(textView)
    }
    
    func updateFieldStateFrom(_ chat: Chat?) {
        setOngoingMessage(text: chat?.ongoingMessage ?? "")
        
        let pending = chat?.isStatusPending() ?? false
        let rejected = chat?.isStatusRejected() ?? false
        let active = !pending && !rejected
        
        self.isUserInteractionEnabled = active
        self.alpha = active ? 1.0 : 0.8
    }
}