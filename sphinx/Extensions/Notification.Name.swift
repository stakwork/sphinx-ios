//
//  Notification.Name.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

extension Notification.Name {
    static let onKeyboardShown = Notification.Name("onKeyboardShown")
    static let onMessageLongPressed = Notification.Name("onMessageLongPressed")
    static let onBalanceDidChange = Notification.Name("onBalanceDidChange")
    static let onGroupDeleted = Notification.Name("onGroupDeleted")
    static let onMessageMenuShow = Notification.Name("onMessageMenuShow")
    static let onMessageMenuHide = Notification.Name("onMessageMenuHide")
    static let onConnectionStatusChanged = Notification.Name("onConnectionStatusChanged")
    static let autocompleteMention = Notification.Name("autocompleteMention")
}
