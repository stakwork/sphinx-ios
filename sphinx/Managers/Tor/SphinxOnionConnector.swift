//
//  SphinxOnionConnector.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Tor
import Alamofire

protocol SphinxOnionConnectorDelegate : class {
    func onionConnecting()
    func onionConnectionFinished()
    func onionConnectionFailed()
}

class SphinxOnionConnector : NSObject {

    weak var delegate: SphinxOnionConnectorDelegate?

    static let sharedInstance = SphinxOnionConnector()

    let onionManager = OnionManager()

    var torSessionConfiguration: URLSessionConfiguration?
    var torSession : Alamofire.Session?

    func usingTor() -> Bool {
        return UserData.sharedInstance.getNodeIP().contains(".onion")
    }

    func isReady() -> Bool {
        return onionManager.state == .connected && torSession != nil
    }

    func isConnecting() -> Bool {
        return onionManager.state == .started
    }


    func startIfNeeded() {
        if let delegate = self.delegate, onionManager.state == .stopped {
            startTor(delegate: delegate)
        }
    }
    
    func getSessionConfiguration() -> URLSessionConfiguration {
        return torSessionConfiguration ?? .default
    }

    private func constructSession(configuration: URLSessionConfiguration) -> Alamofire.Session {
        if let session = self.torSession {
            return session
        }
        let rootQueue = DispatchQueue(label: "com.stakwork.torQueue")
        let queue = OperationQueue()
        queue.underlyingQueue = rootQueue

        configuration.timeoutIntervalForRequest = 180

        let delegate = SessionDelegate()
        let urlSession = URLSession(configuration: configuration,
                                    delegate: delegate,
                                    delegateQueue: queue)
        return Session(session: urlSession, delegate: delegate, rootQueue: rootQueue)
    }

    func startTor(delegate: SphinxOnionConnectorDelegate) {
        self.delegate = delegate

        onionManager.startTor(delegate: self)
    }
}

extension SphinxOnionConnector : OnionManagerDelegate {
    func torConnProgress(_: Int) {
        DispatchQueue.main.async {
            self.delegate?.onionConnecting()
        }
    }

    func torConnFinished(configuration: URLSessionConfiguration) {
        torSessionConfiguration = configuration
        torSession = constructSession(configuration: configuration)

        DispatchQueue.main.async {
            self.delegate?.onionConnectionFinished()
        }
    }

    func torConnError() {
        DispatchQueue.main.async {
            self.delegate?.onionConnectionFailed()
        }
    }
}
