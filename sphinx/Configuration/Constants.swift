//
//  Constants.swift
//  sphinx
//
//  Created by Tomas Timinskas on 31/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

public enum MessagesSize: Int {
    case Big
    case Medium
    case Small
}

class Constants {
    
    public static var kMargin: CGFloat = 16.0
    public static var kMarginForAllThreads: CGFloat = 48.0
    public static var kChatTableContentInset: CGFloat = 16.0
    
    //Fonts
    public static var kMessageFont = UIFont(name: "Roboto-Regular", size: UIDevice.current.isIpad ? 20.0 : 16.0)!
    public static var kMessageHighlightedFont = UIFont(name: "Roboto-Light", size: UIDevice.current.isIpad ? 20.0 : 16.0)!
    public static var kMessageBoldFont = UIFont(name: "Roboto-Regular", size: UIDevice.current.isIpad ? 20.0 : 16.0)!
    public static var kEmojisFont = UIFont(name: "Roboto-Regular", size: UIDevice.current.isIpad ? 40.0 : 30.0)!
    public static let kAmountFont = UIFont(name: "Roboto-Bold", size: UIDevice.current.isIpad ? 20.0 : 16.0)!
    public static let kBoldSmallMessageFont = UIFont(name: "Roboto-Bold", size: UIDevice.current.isIpad ? 20.0 : 16.0)!
    public static var kMessagePreviewFont = UIFont(name: "Roboto-Regular", size: 14.0)!
    public static var kNewMessagePreviewFont = UIFont(name: "Roboto-Bold", size: 14.0)!
    public static var kChatNameFont = UIFont(name: "Roboto-Regular", size: 17.0)!
    public static var kThreadHeaderFont = UIFont(name: "Roboto-Regular", size: 16.0)!
    public static var kThreadHeaderHighlightedFont = UIFont(name: "Roboto-Light", size: 16.0)!
    public static var kThreadListFont = UIFont(name: "Roboto-Regular", size: 17.0)!
    public static var kThreadListHighlightedFont = UIFont(name: "Roboto-Light", size: 17.0)!

    
    //Sizes
    public static var kChatListRowHeight: CGFloat = 90
    public static var kPictureBubbleHeight: CGFloat = 210.0
    public static var kBubbleCurveSize: CGFloat = 10
    public static var kLabelMargins: CGFloat = 20
    public static var kEmojisLabelMargins: CGFloat = 15
    public static var kPaidMessageTopPadding: CGFloat = 25
    
    public static let kBubbleMaxWidth:CGFloat = 600
    
    public static var kReactionsViewHeight: CGFloat = 39
    public static let kReactionsMinimumWidth:CGFloat = 220
    
    public static var kBubbleBottomMargin: CGFloat = 4
    public static var kBubbleReceivedArrowMargin: CGFloat = 4
    public static var kBubbleSentArrowMargin: CGFloat = 6
    
    public static let kLinkPreviewHeight: CGFloat = 100
    public static let kLinkBubbleMaxWidth:CGFloat = 400
    
    public static let kTribeLinkPreviewHeight: CGFloat = 112
    public static let kTribeLinkSeeButtonHeight: CGFloat = 56
    
    //Positions
    public static var kChatListNamePosition: CGFloat = -12
    public static var kChatListMessagePosition: CGFloat = 13
    
    
    public static func setSize() {
        let size = UserDefaults.Keys.messagesSize.get(defaultValue: MessagesSize.Big.rawValue)
        let isIpad = UIDevice.current.isIpad
        
        switch(size) {
        case MessagesSize.Small.rawValue:
            kMessageFont = UIFont(name: "Roboto-Regular", size: isIpad ? 17.0 : 13.0)!
            kMessageHighlightedFont = UIFont(name: "Roboto-Light", size: UIDevice.current.isIpad ? 17.0 : 13.0)!
            kEmojisFont = UIFont(name: "Roboto-Regular", size: 30.0)!
            kMessagePreviewFont = UIFont(name: "Roboto-Regular", size: 12.0)!
            kNewMessagePreviewFont = UIFont(name: "Roboto-Bold", size: 12.0)!
            kChatNameFont = UIFont(name: "Roboto-Regular", size: 16.0)!
            
            kChatListRowHeight = 70
            kPictureBubbleHeight = 170.0
            kBubbleCurveSize = 7
            kLabelMargins = 8
            kEmojisLabelMargins = 6
            kPaidMessageTopPadding = 30
            kReactionsViewHeight = 27
            
            kChatListNamePosition = -9.5
            kChatListMessagePosition = 10.5
            break
        case MessagesSize.Medium.rawValue:
            kMessageFont = UIFont(name: "Roboto-Regular", size: isIpad ? 18.0 : 15.0)!
            kMessageHighlightedFont = UIFont(name: "Roboto-Light", size: UIDevice.current.isIpad ? 18.0 : 15.0)!
            kEmojisFont = UIFont(name: "Roboto-Regular", size: isIpad ? 35.0 : 33.0)!
            kMessagePreviewFont = UIFont(name: "Roboto-Regular", size: 13.0)!
            kNewMessagePreviewFont = UIFont(name: "Roboto-Bold", size: 13.0)!
            kChatNameFont = UIFont(name: "Roboto-Regular", size: 16.0)!
            
            kChatListRowHeight = 80
            kPictureBubbleHeight = 190.0
            kBubbleCurveSize = 8
            kLabelMargins = 14
            kEmojisLabelMargins = 11.5
            kPaidMessageTopPadding = 25
            kReactionsViewHeight = 33
            
            kChatListNamePosition = -10.5
            kChatListMessagePosition = 11.5
            break
        case MessagesSize.Big.rawValue:
            kMessageFont = UIFont(name: "Roboto-Regular", size: isIpad ? 20.0 : 18.0)!
            kMessageHighlightedFont = UIFont(name: "Roboto-Light", size: UIDevice.current.isIpad ? 20.0 : 18.0)!
            kEmojisFont = UIFont(name: "Roboto-Regular", size: isIpad ? 40.0 : 36.0)!
            kMessagePreviewFont = UIFont(name: "Roboto-Regular", size: 14.0)!
            kNewMessagePreviewFont = UIFont(name: "Roboto-Bold", size: 14.0)!
            kChatNameFont = UIFont(name: "Roboto-Regular", size: 17.0)!
            
            kChatListRowHeight = 90
            kPictureBubbleHeight = 210.0
            kBubbleCurveSize = 10
            kLabelMargins = 20
            kEmojisLabelMargins = 15
            kPaidMessageTopPadding = 25
            kReactionsViewHeight = 39
            
            kChatListNamePosition = -12
            kChatListMessagePosition = 13
            break
        default:
            break
        }
    }
}

// MARK: -  Units
extension Constants {
    static let satoshisInBTC = 100_000_000
}
