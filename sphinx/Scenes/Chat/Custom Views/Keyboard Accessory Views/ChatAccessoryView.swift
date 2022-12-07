//
//  Library
//
//  Created by Tomas Timinskas on 01/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

@objc protocol ChatAccessoryViewDelegate {
    func keyboardWillShow(_ notification: Notification)
    func keyboardWillHide(_ notification: Notification)
    func shouldSendMessage(text: String, type: Int, completion: @escaping (Bool) -> ())
    func didDetectPossibleMention(mentionText:String)
    
    @objc optional func didChangeAccessoryViewHeight(heightDiff: CGFloat, updatedText: String)
    @objc optional func didTapAttachmentsButton()
    @objc optional func shouldShowAlert(title: String, message: String)
    @objc optional func didTapSendBlueButton()
    @objc optional func shouldStartRecording()
    @objc optional func shouldStopAndSendAudio()
    @objc optional func shouldCancelRecording()
    @objc optional func didCloseReplyView()
}

class ChatAccessoryView: UIView {
    
    public static let kTableBottomPadding:CGFloat = 5
    public static let kAccessoryViewDefaultHeight:CGFloat = 58
    
    var kCharacterLimit = 500
    
    let kAccessoryViewMargins:CGFloat = 19
    let kCommentTextViewTopMargin:CGFloat = 10
    var kCommentTextViewLeftMargin:CGFloat = 60
    let kCommentTextViewRightMargin:CGFloat = 60
    let kCommentTextViewSidePadding:CGFloat = 18
    let kViewMaxLabelHeight:CGFloat = 75
    let kViewMinLabelHeight:CGFloat = 19
    
    var kFieldPlaceHolder = "message.placeholder".localized
    let kFieldPlaceHolderColor = UIColor.Sphinx.PlaceholderText
    let kFieldFont = UIFont(name: "Roboto-Regular", size: UIDevice.current.isIpad ? 20.0 : 16.0)!
    
    var delegate: ChatAccessoryViewDelegate?
    var autocompleteText:String? = nil
    
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var viewContainer: UIView!
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
    @IBOutlet weak var messageReplyView: MessageReplyView!
    @IBOutlet weak var podcastPlayerView: PodcastSmallPlayer!
    
    @IBOutlet weak var podcastPlayerBottom: NSLayoutConstraint!
    @IBOutlet weak var textViewHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewContainerHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var textViewContainerLeftConstraint: NSLayoutConstraint!
    
    var isAttachment = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    override var intrinsicContentSize: CGSize {
        return viewContentSize()
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        if isAttachment {
            return
        }
        
        if #available(iOS 11.0, *) {
            if let window = self.window {
                self.bottomAnchor.constraint(lessThanOrEqualTo: window.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
            }
        }
    }
    
    deinit {
        removeKeyboardObservers()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("ChatAccessoryView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        self.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        setupViewLayouts()
    }
    
    func setupViewLayouts() {
        backgroundColor = UIColor.clear
        
        textViewContainer.layer.cornerRadius = textViewContainer.frame.size.height/2
        textViewContainer.clipsToBounds = true
        
        sendButton.layer.cornerRadius = sendButton.frame.size.height / 2
        sendButton.clipsToBounds = true
        
        textView.text = kFieldPlaceHolder
        textView.delegate = self
        textView.textContainer.lineFragmentPadding = 0
        textView.textContainerInset = .zero
        textView.contentInset = .zero
        textView.clipsToBounds = true
        textView.font = kFieldFont
        
        viewContainer.addShadow(location: .top, color: UIColor.black, opacity: 0.1)
        
        attachmentButton.layer.cornerRadius = attachmentButton.frame.size.height / 2
        attachmentButton.clipsToBounds = true
        
        animatedMicLabelView.layer.cornerRadius = animatedMicLabelView.frame.size.height / 2
        recordingBlueCircle.layer.cornerRadius = recordingBlueCircle.frame.size.height / 2
        
        attachmentButton.tintColorDidChange()
        
        addKeyboardObservers()
        animateView(commentString: "")
    }
    
    func addKeyboardObservers() {
        removeKeyboardObservers()
        NotificationCenter.default.addObserver(self, selector: #selector(ChatAccessoryView.keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(ChatAccessoryView.keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func removeKeyboardObservers() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    func rebuildSize() {
        invalidateIntrinsicContentSize()
        setNeedsLayout()
        layoutIfNeeded()
    }
    
    @objc func keyboardWillShow(_ notification: Notification) {
        if let delegate = delegate as? ChatAttachmentViewController {
            if textView.isFirstResponder {
                delegate.keyboardWillShow(notification)
            }
        } else {
            delegate?.keyboardWillShow(notification)
        }
    }
    
    @objc func keyboardWillHide(_ notification: Notification) {
        delegate?.keyboardWillHide(notification)
    }
    
    func viewContentSize() -> CGSize {
        let messageString = textView.text ?? ""
        let labelHeight = getLabelHeight(text: messageString)
        let viewHeight = labelHeight + (kCommentTextViewTopMargin * 2) + kAccessoryViewMargins + messageReplyView.getViewHeight() + podcastPlayerView.getViewHeight()
        return CGSize(width: WindowsManager.getWindowWidth(), height: viewHeight)
    }
    
    func getLabelHeight(text: String) -> CGFloat {
        let labelWidth = Double(WindowsManager.getWindowWidth() - (kCommentTextViewLeftMargin + kCommentTextViewRightMargin) - (kCommentTextViewSidePadding * 2))
        var labelHeight = kFieldFont.sizeOfString(text, constrainedToWidth: labelWidth).height
        labelHeight = limitLabelToMaxAndMinHeight(labelHeight: labelHeight)
        return labelHeight
    }
    
    func setupForAttachments(with text: String? = nil) {
        isAttachment = true
        
        kFieldPlaceHolder = ChatAttachmentViewController.kFieldPlaceHolder
        
        if let text = text, !text.isEmpty {
            textView.text = text
            textView.textColor = UIColor.Sphinx.TextMessages
        } else {
            textView.text = kFieldPlaceHolder
        }
        
        kCommentTextViewLeftMargin = 8
        textViewContainerLeftConstraint.constant = kCommentTextViewLeftMargin
        
        textViewContainer.superview?.layoutIfNeeded()
        textViewDidChange(textView)
    }
    
    func show(animated: Bool = true) {
        if animated {
            toggleElements(show: false)
            
            UIView.animate(withDuration: 0.3, animations: {
                self.alpha = 1.0
            }, completion: { _ in
                UIView.animate(withDuration: 0.2, animations: {
                    self.toggleElements(show: true)
                })
            })
        } else {
            self.alpha = 1.0
        }
    }
    
    func toggleElements(show: Bool) {
        attachmentButton.alpha = show ? 1.0 : 0.0
        textViewContainer.alpha = show ? 1.0 : 0.0
        audioButtonContainer.alpha = show ? 1.0 : 0.0
        messageReplyView.alpha = show ? 1.0 : 0.0
        podcastPlayerView.alpha = show ? 1.0 : 0.0
    }
    
    func hide() {
        self.alpha = 0.0
    }
    
    func shouldExpandKeyboard() {
        textView.becomeFirstResponder()
    }
    
    func shouldDismissKeyboard() {
        textView.resignFirstResponder()
    }
    
    func setTextBackAndDismissKeyboard(text: String) {
        setTextBack(text: text)
        shouldDismissKeyboard()
    }
    
    func setTextBack(text: String) {
        let updatedText = (text.trim().isEmpty && !textView.isFirstResponder) ? kFieldPlaceHolder : text
        setOngoingMessage(text: updatedText)
        sendButton.isUserInteractionEnabled = true
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
        
        let messageType = TransactionMessage.TransactionMessageType.message.rawValue
        delegate?.shouldSendMessage(text: text, type: messageType, completion: { success in
            self.sendButton.isUserInteractionEnabled = true
        })
    }
    
    func clearMessage() {
        textView.text = ""
        textViewDidChange(textView)
    }
    
    func configurePlayerViewWith(
        podcast: PodcastFeed,
        delegate: PodcastPlayerVCDelegate,
        completion: @escaping () -> ()
    ) {
        podcastPlayerView.configureWith(
            podcast: podcast,
            and: delegate,
            completion: {
                self.rebuildSize()
                
                self.podcastPlayerView.addShadow(location: .top, color: UIColor.black, opacity: 0.1)
                self.viewContainer.removeShadow()
                completion()
            })
    }
    
    func hideReplyView() {
        messageReplyView.isHidden = true
        podcastPlayerBottom.constant = 0
        toggleShadow(showingReplayView: false)
        rebuildSize()
    }
    
    func configureReplyFor(message: TransactionMessage? = nil, podcastComment: PodcastComment? = nil) {
        toggleShadow(showingReplayView: true)
        
        if let message = message {
            messageReplyView.configureForKeyboard(with: message, delegate: self)
        } else if let podcastComment = podcastComment {
            messageReplyView.configureForKeyboard(with: podcastComment, and: self)
        }
        podcastPlayerBottom.constant = 50
        rebuildSize()
    }
    
    func toggleShadow(showingReplayView: Bool) {
        let isPlayerVisible = !podcastPlayerView.isHidden
        if isPlayerVisible {
            return
        }
        
        if showingReplayView {
            viewContainer.removeShadow()
            messageReplyView.addShadow(location: .top, color: UIColor.black, opacity: 0.1)
        } else {
            viewContainer.addShadow(location: .top, color: UIColor.black, opacity: 0.1)
        }
    }
    
    func getReplyingMessage() -> TransactionMessage? {
        return messageReplyView.getReplyingMessage()
    }
    
    func getReplyingPodcast() -> PodcastComment? {
        return messageReplyView.getReplyingPodcast()
    }
    
    func updateFromChat(_ chat: Chat?) {
        setOngoingMessage(text: chat?.ongoingMessage ?? "")
        
        let pending = chat?.isStatusPending() ?? false
        let rejected = chat?.isStatusRejected() ?? false
        let active = !pending && !rejected
        
        self.isUserInteractionEnabled = active
        self.alpha = active ? 1.0 : 0.8
    }
    
    @IBAction func attachmentButtonTouched() {
        if textView.isFirstResponder {
            textView.resignFirstResponder()
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.3) {
                self.delegate?.didTapAttachmentsButton?()
            }
        } else {
            delegate?.didTapAttachmentsButton?()
        }
    }
    
    @IBAction func sendButtonTouched() {
        sendButton.isUserInteractionEnabled = false
        
        let currentString = (textView.text ?? "").trim()
        
        if currentString == "" || currentString == kFieldPlaceHolder {
            if let didTapSendButton = delegate?.didTapSendBlueButton {
                didTapSendButton()
            } else {
                sendButton.isUserInteractionEnabled = true
            }
            return
        }
        
        createNewMessage(text: currentString as String)
    }
    
    @IBAction func audioButtonTouchDown(_ sender: Any) {
        delegate?.shouldStartRecording?()
    }
    
    @IBAction func audioButtonTouchUpInside() {
        toggleAudioRecording(show: false)
        delegate?.shouldStopAndSendAudio?()
    }
    
    @IBAction func audioButtonDragOutside() {
        NewMessageBubbleHelper().showGenericMessageView(text: "audio.message.cancelled".localized)
        toggleAudioRecording(show: false)
        delegate?.shouldCancelRecording?()
    }
    
}
