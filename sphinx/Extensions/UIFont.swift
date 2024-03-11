//
//  UIFont.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

public extension UIFont {
    func sizeOfString(_ string: String, constrainedToWidth width: Double? = nil, height: Double? = nil) -> CGSize {
        let constraintRect = CGSize(width: width ?? .greatestFiniteMagnitude, height: height ?? .greatestFiniteMagnitude)
        
        let boundingBox = string.boundingRect(with: constraintRect,
                                              options: .usesLineFragmentOrigin,
                                              attributes: [.font: self],
                                              context: nil)
        
        return CGSize(width: ceil(boundingBox.width),
                      height: ceil(boundingBox.height))
    }
    
    func withTraits(traits: UIFontDescriptor.SymbolicTraits) -> UIFont {
        if fontDescriptor.symbolicTraits.contains(traits) {
            let descriptor = fontDescriptor.withSymbolicTraits(traits)
            return UIFont(descriptor: descriptor!, size: 0)
        }
        return self
    }

    func bold() -> UIFont {
        return withTraits(traits: .traitBold)
    }

    func italic() -> UIFont {
        return withTraits(traits: .traitItalic)
    }
    
    static func getMessageFont() -> UIFont {
        return Constants.kMessageFont
    }

    static func getHighlightedMessageFont() -> UIFont {
        return Constants.kMessageHighlightedFont
    }
    
    static func getThreadHeaderFont() -> UIFont {
        return Constants.kThreadHeaderFont
    }
    
    static func getThreadHeaderHightlightedFont() -> UIFont {
        return Constants.kThreadHeaderHighlightedFont
    }
    
    static func getThreadListFont() -> UIFont {
        return Constants.kThreadListFont
    }
    
    static func getThreadListHightlightedFont() -> UIFont {
        return Constants.kThreadListHighlightedFont
    }
    
    static func getEmojisFont() -> UIFont {
        return Constants.kEmojisFont
    }
    
    static func getAmountFont() -> UIFont {
        let size: CGFloat = UIDevice.current.isIpad ? 20 : 16
        return UIFont(name: "Roboto-Bold", size: size)!
    }
    
    static func getEncryptionErrorFont() -> UIFont {
        return Constants.kBoldSmallMessageFont
    }
}
