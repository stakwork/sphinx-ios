//
//  ChatMessageTextFieldView+UITextViewDelegate.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension ChatMessageTextFieldView : UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        togglePlaceHolder(editing: true)
        textViewDidChange(textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
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
        animateElements(sendButtonVisible: !textView.text.isEmpty)
        processMention(text: textView.text)
    }
    
    func animateElements(
        sendButtonVisible: Bool
    ) {
        attachmentButton.backgroundColor = sendButtonVisible ? UIColor.Sphinx.ReceivedMsgBG : UIColor.Sphinx.PrimaryBlue
        attachmentButton.setTitleColor(sendButtonVisible ? UIColor.Sphinx.MainBottomIcons : UIColor.white, for: .normal)
        
        sendButtonContainer.alpha = sendButtonVisible ? 1.0 : 0.0
        audioButtonContainer.alpha = sendButtonVisible ? 0.0 : 1.0
    }
}

///Mentions
extension ChatMessageTextFieldView {
    
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
    
    func populateMentionAutocomplete(
        mention: String
    ) {
        if let text = textView.text {
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
                
//                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.autocompleteMention, object: nil)
                
                textViewDidChange(textView)
            }
        }
    }
    
    func processMention(
        text: String
    ) {
        if let mention = getAtMention(text: text) {
            let mentionValue = String(mention).replacingOccurrences(of: "@", with: "").lowercased()
            self.delegate?.didDetectPossibleMention(mentionText: mentionValue)
            
//            NotificationCenter.default.addObserver(
//                self,
//                selector: #selector(populateMentionAutocomplete),
//                name: NSNotification.Name.autocompleteMention,
//                object: nil
//            )
        } else {
//            NotificationCenter.default.removeObserver(
//                self,
//                name: NSNotification.Name.autocompleteMention,
//                object: nil
//            )
        }
    }
}
