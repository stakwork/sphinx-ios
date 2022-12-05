//
//  RelayURLUpdateHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 24/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

class RelayURLUpdateHelper : SphinxOnionConnectorDelegate {

    var newMessageBubbleHelper = NewMessageBubbleHelper()
    let userData = UserData.sharedInstance
    let onionConnector = SphinxOnionConnector.sharedInstance

    var newUrl: String? = nil
    var doneCompletion: (() -> ())? = nil

    func updateRelayURL(newValue: String, completion: @escaping (() -> ())) {
        self.doneCompletion = completion

        userData.save(ip: newValue)
        newUrl = newValue

        if connectTorIfNeeded() {
           return
        }

        verifyNewIP()
    }

    func connectTorIfNeeded() -> Bool {
        if onionConnector.usingTor() && !onionConnector.isReady() {
            onionConnector.startTor(delegate: self)
            return true
        }
        return false
    }

    func onionConnecting() {
        newMessageBubbleHelper.showLoadingWheel(text: "establishing.tor.circuit".localized)
    }

    func onionConnectionFinished() {
        verifyNewIP()
    }

    func onionConnectionFailed() {
        newURLConnectionFailed()
    }

    func verifyNewIP() {
        newMessageBubbleHelper.showLoadingWheel(text: "verifying.new.ip".localized)

        userData.getAndSaveTransportKey(completion: { [weak self] _ in
            guard let self = self else { return }
            
            API.sharedInstance.getWalletBalance(
                callback: { _ in
                    
                self.newURLConnected()
            }, errorCallback: {
                self.newURLConnectionFailed()
            })
        })
    }

    func newURLConnected() {
        UserDefaults.Keys.previousIP.removeValue()
        SphinxSocketManager.sharedInstance.reconnectSocketToNewIP()
        newMessageBubbleHelper.hideLoadingWheel()
        newMessageBubbleHelper.showGenericMessageView(text: "server.url.updated".localized)
        doneCompletion?()
    }

    func newURLConnectionFailed() {
        userData.revertIP()
        userData.getAndSaveTransportKey(completion: { [weak self] _ in
            guard let self = self else { return }
            
            self.newMessageBubbleHelper.hideLoadingWheel()
            self.newMessageBubbleHelper.showGenericMessageView(text: "reverting.ip".localized, delay: 4)
            self.doneCompletion?()
        })
    }
}
