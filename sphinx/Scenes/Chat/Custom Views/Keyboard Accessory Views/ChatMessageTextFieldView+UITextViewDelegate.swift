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
//        processMention(text: textView.text)
        animateElements(sendButtonVisible: !textView.text.isEmpty)
    }
    
    func getAtMention(text:String)->String?{
        if let lastWord = text.split(separator: " ").last, let firstLetter = lastWord.first, firstLetter == "@" {
            return String(lastWord)
        }
        return nil
    }
    
    @objc func populateMentionAutocomplete(notification:NSNotification){
        if let text = notification.object as? String,
           let typedMentionText = self.getAtMention(text: textView.text){
            self.textView.text = self.textView.text.replacingOccurrences(of: typedMentionText, with: "@\(text) ")
            
            NotificationCenter.default.removeObserver(
                self,
                name: NSNotification.Name.autocompleteMention,
                object: nil
            )
        }
    }
    
    func processMention(text:String){
        if let mention = getAtMention(text: text) {
            
            let mentionValue = String(mention).replacingOccurrences(of: "@", with: "").lowercased()
//            self.delegate?.didDetectPossibleMention(mentionText: mentionValue)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(populateMentionAutocomplete),
                name: NSNotification.Name.autocompleteMention,
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
    
    func animateElements(
        sendButtonVisible: Bool
    ) {
        attachmentButton.backgroundColor = sendButtonVisible ? UIColor.Sphinx.ReceivedMsgBG : UIColor.Sphinx.PrimaryBlue
        attachmentButton.setTitleColor(sendButtonVisible ? UIColor.Sphinx.MainBottomIcons : UIColor.white, for: .normal)
        
        sendButtonContainer.alpha = sendButtonVisible ? 1.0 : 0.0
        audioButtonContainer.alpha = sendButtonVisible ? 0.0 : 1.0
    }
}
