//
//  ChatMessageTextFieldView+UITextViewDelegate.swift
//  sphinx
//
//  Created by Tomas Timinskas on 11/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension ChatMessageTextFieldView : UITextViewDelegate {
    
    var placeHolderText : String {
        get {
            switch(mode) {
            case .Chat:
                return kFieldPlaceHolder
            case .Attachment:
                return kAttchmentFieldPlaceHolder
            }
        }
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        togglePlaceHolder(editing: true)
        textViewDidChange(textView)
    }

    func textViewDidEndEditing(_ textView: UITextView) {
        togglePlaceHolder(editing: false)
    }
    
    func togglePlaceHolder(editing: Bool) {
        if editing && (textView.text == placeHolderText) {
            textView.text = ""
            textView.textColor = UIColor.Sphinx.TextMessages
        } else if !editing && textView.text.isEmpty {
            textView.text = placeHolderText
            textView.textColor = kFieldPlaceHolderColor
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        let currentString = textView.text! as NSString
        let currentChangedString = currentString.replacingCharacters(in: range, with: text)
        return (currentChangedString.count <= kCharacterLimit)
    }
    
    func textViewDidChange(_ textView: UITextView) {
        animateElements(sendButtonVisible: !textView.text.isEmpty && textView.text != kFieldPlaceHolder)
        
        delegate?.didChangeText?(
            text: textView.text != kFieldPlaceHolder ? textView.text : ""
        )
        
        processMention(text: textView.text)
        processMacro(text: textView.text, cursorPosition: textView.text.length)
    }
    
    func animateElements(
        sendButtonVisible: Bool
    ) {
        let forceSendButtonVisible = sendButtonVisible || (mode == .Attachment)
        
        attachmentButton.backgroundColor = forceSendButtonVisible ? UIColor.Sphinx.ReceivedMsgBG : UIColor.Sphinx.PrimaryBlue
        attachmentButton.setTitleColor(forceSendButtonVisible ? UIColor.Sphinx.MainBottomIcons : UIColor.white, for: .normal)
        
        sendButtonContainer.isHidden = !forceSendButtonVisible
        audioButtonContainer.isHidden = forceSendButtonVisible
        
        attachmentButtonContainer.isHidden = (mode == .Attachment)
    }
}

///Mentions
extension ChatMessageTextFieldView {
    
    func getAtMention(
        text: String
    ) -> String? {
        
        if text.trim().isEmpty {
            return nil
        }
        
        let cursorPosition = textView.selectedRange.location
        
        let relevantText = text[0..<cursorPosition]
        
        if let lastLetter = relevantText.last, lastLetter == " " {
            return nil
        }
        
        if let lastLine = relevantText.split(separator: "\n").last,
           let lastWord = lastLine.split(separator: " ").last {
            
            if let firstLetter = lastWord.first, firstLetter == "@" && lastWord != "@" {
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
        } else {
            self.delegate?.didDetectPossibleMention(mentionText: "")
        }
    }
    
    func getMacro(
        text: String,
        cursorPosition: Int?
    ) -> String? {
        let relevantText = text[0..<(cursorPosition ?? text.count)]
        if let firstLetter = relevantText.first, firstLetter == "/" {
            return relevantText
        }

        return nil
    }
    
    func processMacro(
        text: String,
        cursorPosition: Int?
    ) {
        if let macroText = getMacro(text: text, cursorPosition: cursorPosition) {
            self.delegate?.didDetectPossibleMacro(macro: macroText)
        }
    }
}
