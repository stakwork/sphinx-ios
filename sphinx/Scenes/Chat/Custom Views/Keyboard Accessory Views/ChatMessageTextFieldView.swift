//
//  ChatMessageTextFieldView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ChatMessageTextFieldViewDelegate {
    func shouldSendMessage(text: String, type: Int, completion: @escaping (Bool) -> ())
    
    func didTapAttachmentsButton(text: String?)
    func didTapSendBlueButton()
    
    func shouldStartRecording()
    func shouldStopAndSendAudio()
    func shouldCancelRecording()
    
    func didDetectPossibleMention(mentionText:String)
}

class ChatMessageTextFieldView: UIView {
    
    var delegate: ChatMessageTextFieldViewDelegate?

    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var textViewContainer: UIView!
    @IBOutlet weak var textView: UITextView!
    
    @IBOutlet weak var attachmentButton: UIButton!
    
    @IBOutlet weak var sendButtonContainer: UIView!
    @IBOutlet weak var sendButton: UIButton!
    
    @IBOutlet weak var audioButtonContainer: UIView!
    @IBOutlet weak var audioButton: UIButton!
    
    @IBOutlet weak var recordingContainer: UIView!
    @IBOutlet weak var recordingTimeLabel: UILabel!
    @IBOutlet weak var recordingBlueCircle: UIView!
    @IBOutlet weak var animatedMicLabelView: IntermitentAlphaAnimatedView!
    
    let kCharacterLimit = 500
    let kFieldPlaceHolder = "message.placeholder".localized
    
    let kFieldPlaceHolderColor = UIColor.Sphinx.PlaceholderText
    let kFieldFont = UIFont(name: "Roboto-Regular", size: UIDevice.current.isIpad ? 20.0 : 16.0)!
    
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
        
        textView.text = kFieldPlaceHolder
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
        if textView.text == kFieldPlaceHolder {
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
}
