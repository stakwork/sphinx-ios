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
        animateView(commentString: textView.text)
        rebuildSize()
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
