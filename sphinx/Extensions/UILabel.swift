//
//  UILabel.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

extension UILabel {
    public static func getLabelSize(width: CGFloat? = nil, height: CGFloat? = nil, text: String, font: UIFont) -> CGSize {
        let label =  UILabel()
        label.numberOfLines = 0
        label.font = font
        label.text = text
        
        let constraintRect = CGSize(width: width ?? .greatestFiniteMagnitude, height: height ?? .greatestFiniteMagnitude)
        let boundingBox = text.boundingRect(with: constraintRect,
                                            options: .usesLineFragmentOrigin,
                                            attributes: [.font: label.font],
                                            context: nil)
        label.frame.size = CGSize(width: ceil(boundingBox.width),
                                  height: ceil(boundingBox.height))
        
        return label.frame.size
    }
    
    func addTextSpacing(value: Double) {
        if let textString = self.text {
            let attributedString = NSMutableAttributedString(string: textString)
            attributedString.addAttribute(.kern, value: value, range: NSRange(location: 0, length: attributedString.length - 1))
            self.attributedText = attributedString
        }
    }
    
    func addLinksOnLabel(linkColor: UIColor = UIColor.Sphinx.PrimaryBlue) -> [NSRange] {
        var URLRanges = [NSRange]()
        
        if let text = self.text {
            let linkMatches = text.stringLinks
            let pubKeyMatches = text.pubKeyMatches
            let mentionMatches = text.mentionMatches
            
            if (linkMatches.count + pubKeyMatches.count + mentionMatches.count) > 0 {
                let attributedString = NSMutableAttributedString(string: text)
                
                for match in linkMatches {
                    URLRanges.append(match.range)

                    attributedString.setAttributes([NSAttributedString.Key.foregroundColor: linkColor, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue], range: match.range)
                }
                
                for match in pubKeyMatches {
                    URLRanges.append(match.range)
                    
                    attributedString.setAttributes([NSAttributedString.Key.foregroundColor: linkColor, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue], range: match.range)
                }
                
                for match in mentionMatches {
                    URLRanges.append(match.range)
                    
                    attributedString.setAttributes([NSAttributedString.Key.foregroundColor: linkColor], range: match.range)
                }
                
                self.attributedText = attributedString
                self.isUserInteractionEnabled = true
            }
        }
        
        return URLRanges
    }
    
    func addLinkFor(link: String) {
        guard let text = self.text else {
            return
        }
        
        if let range = text.range(of: link) {
            let nsRange = NSRange(range, in: text)
            let attributedString = NSMutableAttributedString(string: text)
            
            attributedString.setAttributes([NSAttributedString.Key.foregroundColor: UIColor.Sphinx.PrimaryBlue, NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue], range: nsRange)
            
            self.attributedText = attributedString
            self.isUserInteractionEnabled = true
        }
    }
    
    func getRangeFor(link: String) -> NSRange? {
        guard let text = self.text else {
            return nil
        }
        
        if let range = text.range(of: link) {
            let nsRange = NSRange(range, in: text)
            return nsRange
        }
        
        return nil
    }
    
    var isTruncated: Bool {
            
        guard let labelText = text else {
            return false
        }
        
        let labelTextSize = (labelText as NSString).boundingRect(with: CGSize(width: frame.size.width, height: .greatestFiniteMagnitude),options: .usesLineFragmentOrigin,attributes: [NSAttributedString.Key.font: font],context: nil).size
        
        return labelTextSize.height > bounds.size.height
    }
    
    
    var numberOfLinesVisible : Int {
        
        if let text = text{
            // cast text to NSString so we can use sizeWithAttributes
            let myText = text as NSString
            
            //Set attributes
            let attributes = [NSAttributedString.Key.font : font!]
            
            //Calculate the size of your UILabel by using the systemfont and the paragraph we created before. Edit the font and replace it with yours if you use another
            let labelSize = myText.boundingRect(with: CGSize(width: bounds.width,height: CGFloat.greatestFiniteMagnitude), options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
            
            //Now we return the amount of lines using the ceil method
            let lines = ceil(CGFloat(labelSize.height) / font.lineHeight)
            return Int(lines)
        }
        
        return 0
    }
}
