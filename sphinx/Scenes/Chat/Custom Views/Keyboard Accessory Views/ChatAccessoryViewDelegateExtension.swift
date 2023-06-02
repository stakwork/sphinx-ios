//
//  ChatAccessoryViewDelegateExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

extension ChatAccessoryView {
    func didStartRecording() {
        toggleAudioRecording(show: true)
    }
    
    func toggleAudioRecording(show: Bool) {
        recordingTimeLabel.text = "0:00"
        recordingBlueCircle.alpha = show ? 1.0 : 0.0
        audioButton.titleLabel?.font = UIFont(name: "MaterialIcons-Regular", size: show ? 50 : 27)!
        animatedMicLabelView.toggleAnimation(animate: show)
        
        UIView.animate(withDuration: 0.2, animations: {
            self.recordingContainer.alpha = show ? 1.0 : 0.0
        })
    }
    
    func updateRecordingAudio(minutes: String, seconds: String) {
        recordingTimeLabel.text = "\(minutes):\(seconds)"
    }
}

extension ChatAccessoryView : UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        animateElements(active: true)
        togglePlaceHolder(editing: true)
        textViewDidChange(textView)
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        animateElements(active: false)
        togglePlaceHolder(editing: false)
    }
    
    func togglePlaceHolder(editing: Bool) {
        if editing && textView.text == kFieldPlaceHolder {
            textView.text = ""
            textView.textColor = UIColor.Sphinx.TextMessages
        } else if !editing && textView.text.isEmpty {
            textView.text = kFieldPlaceHolder
            textView.textColor = kFieldPlaceHolderColor
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentString = textView.text! as NSString
        let currentChangedString = currentString.replacingCharacters(in: range, with: text)
        return (currentChangedString.count <= kCharacterLimit)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        processMention(text: textView.text)
        animateView(commentString: textView.text)
        rebuildSize()
    }
    
    func getAtMention(
        text: String
    ) -> String? {
        let cursorPosition = textView.selectedRange.location
        let relevantText = text[0..<cursorPosition]
        if let lastLetter = relevantText.last, lastLetter == " " {
            return nil
        }
        if let lastWord = relevantText.split(separator: " ").last {
            if let firstLetter = lastWord.first, firstLetter == "@" {
                return String(lastWord)
            }
        }
        return nil
    }
    
    @objc func populateMentionAutocomplete(
        notification: NSNotification
    ){
        if let mention = notification.object as? String, let text = textView.text {
            let initialPosition = textView.selectedRange.location
            
            if let typedMentionText = getAtMention(text: text) {
                
                let startIndex = text.index(text.startIndex, offsetBy: initialPosition - typedMentionText.count)
                let endIndex = text.index(text.startIndex, offsetBy: initialPosition)
                
                textView.text = textView.text.replacingOccurrences(
                    of: typedMentionText,
                    with: "@\(mention) ",
                    options: [],
                    range: startIndex..<endIndex
                )
                

                let position = initialPosition + (("@\(mention) ".count - typedMentionText.count))
                textView.selectedRange = NSRange(location: position, length: 0)
                
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.autocompleteMention, object: nil)
                
                textViewDidChange(textView)
            }
        }
    }
    
    func processMention(text: String ) {
        if let mention = getAtMention(text: text) {
            let mentionValue = String(mention).replacingOccurrences(of: "@", with: "").lowercased()
            self.delegate?.didDetectPossibleMention(mentionText: mentionValue)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(populateMentionAutocomplete),
                name:NSNotification.Name.autocompleteMention,
                object: nil
            )
        } else {
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.autocompleteMention,
                object: nil
            )
        }
    }
    
    func animateElements(active: Bool) {
        attachmentButton.backgroundColor = active ? UIColor.Sphinx.ReceivedMsgBG : UIColor.Sphinx.PrimaryBlue
        attachmentButton.setTitleColor(active ? UIColor.Sphinx.MainBottomIcons : UIColor.white, for: .normal)
        sendButtonContainer.alpha = (active || isAttachment) ? 1.0 : 0.0
        
        UIView.animate(withDuration: 0.2, animations: {
            self.textViewContainer.superview?.layoutIfNeeded()
            self.audioButtonContainer.alpha = (active || self.isAttachment) ? 0.0 : 1.0
        })
    }
    
    func animateView(commentString: String) {
        let previousViewHeight = self.frame.size.height
        
        let labelHeight = getLabelHeight(text: commentString)
        let labelHeightWithMargins = labelHeight + (kCommentTextViewTopMargin * 2)
        let accessoryViewHeight = labelHeightWithMargins + kAccessoryViewMargins + messageReplyView.getViewHeight() + podcastPlayerView.getViewHeight()
        
        textViewHeightConstraint.constant = labelHeight
        textViewContainerHeightConstraint.constant = labelHeightWithMargins
        
        let heightDifference = accessoryViewHeight - previousViewHeight
        shouldUpdateTableView(heightDiff: heightDifference, updatedText: commentString)
    }
    
    func shouldUpdateTableView(heightDiff: CGFloat, updatedText: String) {
        self.delegate?.didChangeAccessoryViewHeight?(heightDiff: heightDiff, updatedText: updatedText)
    }
    
    func limitLabelToMaxAndMinHeight(labelHeight: CGFloat) -> CGFloat {
        textView.isScrollEnabled = labelHeight > kViewMaxLabelHeight
        
        if labelHeight > kViewMaxLabelHeight {
            return kViewMaxLabelHeight
        } else if labelHeight < kViewMinLabelHeight {
            return kViewMinLabelHeight
        }
        return labelHeight
    }
}

extension ChatAccessoryView : MessageReplyViewDelegate {
    func didCloseView() {
        podcastPlayerBottom.constant = 0
        delegate?.didCloseReplyView?()
        rebuildSize()
    }
}
