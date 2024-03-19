//
//  UIColor.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

public extension UIColor {
    
    func resolvedCGColor(with view: UIView) -> CGColor {
        if #available(iOS 13.0, *) {
            return self.resolvedColor(with: view.traitCollection).cgColor
        }
        return self.cgColor
    }
    
    static let colors = ["#7077FF","#DBD23C","#F57D25","#9F70FF","#9BC351","#FF3D3D","#C770FF","#62C784","#C99966","#FF70E9","#76D6CA","#ABDB50","#FF708B","#5AD7F7","#5FC455","#FF9270","#3FABFF","#56D978","#FFBA70","#5078F2","#618AFF"]
    
    enum Sphinx {
        public static let Body = color("Body")
        public static let BodyInverted = color("BodyInverted")
        public static let InputOutline1 = color("Input Outline 1")
        public static let HeaderBG = color("HeaderBG")
        public static let HeaderSemiTransparentBG = color("HeaderSemiTransparentBG")
        public static let ListBG = color("ListBG")
        public static let LightBG = color("LightBG")
        public static let ProfileBG = color("ProfileBG")
        
        public static let MainBottomIcons = color("MainBottomIcons")
        public static let ChatListSelected = color("ChatListSelected")
        
        public static let DashboardHeader = color("DashboardHeader")
        public static let DashboardFilterChipActiveText = color("DashboardFilterChipActiveText")
        public static let DashboardFilterChipBackground = color("DashboardFilterChipBackground")
        public static let DashboardSearch = color("DashboardSearch")
        public static let DashboardWashedOutText = color("DashboardWashedOutText")
        
        public static let PrimaryText = color("PrimaryText")
        public static let Text = color("Text")
        public static let TextInverted = color("TextInverted")
        public static let SecondaryText = color("SecondaryText")
        public static let SecondaryTextInverted = color("SecondaryTextInverted")
        public static let PlusMinusBackground = color("PlusMinusBackground")
        public static let SecondaryTextSent = color("SecondaryTextSent")
        public static let TextMessages = color("TextMessages")
        public static let PlaceholderText = color("PlaceholderText")
        
        public static let PrimaryBlue = color("PrimaryBlue")
        public static let PrimaryBlueBorder = color("PrimaryBlueBorder")
        public static let PrimaryBlueFontColor = color("PrimaryBlueFontColor")
        public static let BlueTextAccent = color("BlueTextAccent")
        
        public static let Shadow = color("Shadow")
        public static let BubbleShadow = color("BubbleShadow")
        public static let Divider = color("Divider")
        public static let Divider2 = color("Divider2")
        public static let LightDivider = color("LightDivider")
        public static let ExpiredInvoice = color("ExpiredInvoice")
        public static let AddressBookHeader = color("AddressBookHeader")
        public static let MessageOptionDivider = color("MessageOptionDivider")
        public static let ReplyDividerReceived = color("ReplyDividerReceived")
        public static let ReplyDividerSent = color("ReplyDividerSent")
        public static let ReceivedIcon = color("ReceivedIcon")
        public static let ReceivedMsgBG = color("ReceivedMsgBG")
        public static let SentMsgBG = color("SentMsgBG")
        public static let OldReceivedMsgBG = color("OldReceivedMsgBG")
        public static let OldSentMsgBG = color("OldSentMsgBG")
        
        public static let PrimaryGreen = color("PrimaryGreen")
        public static let GreenBorder = color("GreenBorder")
        
        public static let PrimaryRed = color("PrimaryRed")
        public static let SecondaryRed = color("SecondaryRed")

        public static let TransactionBG = color("TransactionBG")
        public static let TransactionBGBorder = color("TransactionBGBorder")
        
        public static let WashedOutGreen = color("WashedOutGreen")
        public static let WashedOutReceivedText = color("WashedOutReceivedText")
        public static let WashedOutSentText = color("WashedOutSentText")
        
        public static let SentBubbleBorder = color("SentBubbleBorder")
        public static let ReceivedBubbleBorder = color("ReceivedBubbleBorder")
        
        public static let SphinxOrange = color("sphinxOrange")
        public static let BadgeRed = color("BadgeRed")
        public static let AuthorizeModalBack = color("AuthorizeModalBack")
        public static let SemitransparentText = color("SemitransparentText")
        
        public static let LinkSentColor = color("LinkSentColor")
        public static let LinkReceivedColor = color("LinkReceivedColor")
        public static let LinkSentButtonColor = color("LinkSentButtonColor")
        public static let LinkReceivedButtonColor = color("LinkReceivedButtonColor")
        
        public static let OnboardingPlaceholderText = color("OnboardingPlaceholderText")
        
        public static let FeedItemDetailDivider = color("FeedItemDetailDivider")
        public static let RowViewsDivider = color("RowViewsDivider")
        
        public static let ThreadOriginalMsg = color("ThreadOriginalMsg")
        public static let ThreadLastReply = color("ThreadLastReply")
        public static let NewMessageIndicator = color("NewMessageIndicator")
        
        public static let HighlightedText = color("HighlightedText")
        public static let HighlightedTextBackground = color("HighlightedTextBackground")
        
        private static func color(_ name: String) -> UIColor {
            return UIColor(named: name, in: Bundle.main, compatibleWith: nil) ?? UIColor.magenta
            
        }
    }
    
    func toHexColorString() -> String {
        var r:CGFloat = 0
        var g:CGFloat = 0
        var b:CGFloat = 0
        var a:CGFloat = 0

        getRed(&r, green: &g, blue: &b, alpha: &a)

        let rgb:Int = (Int)(r*255)<<16 | (Int)(g*255)<<8 | (Int)(b*255)<<0

        return String(format:"#%06x", rgb)
    }
    
    private convenience init(red: Int, green: Int, blue: Int) {
        self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
    }
    
    convenience init(hex: Int) {
        self.init(red: (hex >> 16) & 0xff, green: (hex >> 8) & 0xff, blue: hex & 0xff)
    }
    
    convenience init(hex: String, alpha: CGFloat = 1) {
        var hexString = hex
        
        if hex[hex.startIndex] != "#" {
            hexString = "#\(hex)"
        }
        
        let scanner = Scanner(string: hexString)
        scanner.scanLocation = 1
        
        var rgb: UInt32 = 0
        scanner.scanHexInt32(&rgb)
        
        self.init(
            red:   CGFloat((rgb & 0xFF0000) >> 16)/255.0,
            green: CGFloat((rgb &   0xFF00) >>  8)/255.0,
            blue:  CGFloat((rgb &     0xFF)      )/255.0,
            alpha: alpha)
    }
    
    static func random() -> UIColor {
        if let colorCode = colors.randomElement() {
            return UIColor(hex: colorCode)
        }
        
        return UIColor(
           red:   .random(),
           green: .random(),
           blue:  .random(),
           alpha: 1.0
        )
    }
    
    static func getColorFor(key: String) -> UIColor {
        if let colorCode = UserDefaults.standard.string(forKey: key){
            return UIColor(hex: colorCode)
        } else {
            let newColor = UIColor.random()
            UserDefaults.standard.set(newColor.toHexString(), forKey: key)
            UserDefaults.standard.synchronize()
            return newColor
        }
    }
    
    static func removeColorFor(key: String) {
        UserDefaults.standard.removeObject(forKey: key)
        UserDefaults.standard.synchronize()
    }
}
