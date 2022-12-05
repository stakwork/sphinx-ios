//
//  ChatListHeader.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol ChatListHeaderDelegate: class {
    func leftMenuButtonTouched()
}

class ChatListHeader: UIView {
    
    weak var delegate: ChatListHeaderDelegate?
    
    @IBOutlet var contentView: UIView!
    
    @IBOutlet weak var smallBalanceLabel: UILabel!
    @IBOutlet weak var smallUnitLabel: UILabel!
    @IBOutlet weak var healthCheckButton: UIButton!
    @IBOutlet weak var upgradeAppButton: UIButton!
    
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    let walletBalanceService = WalletBalanceService()
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    public static let kConnectedColor = UIColor.Sphinx.PrimaryGreen
    public static let kNotConnectedColor = UIColor.Sphinx.SphinxOrange

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("ChatListHeader", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        upgradeAppButton.layer.cornerRadius = upgradeAppButton.frame.size.height / 2
    }
    
    func listenForEvents() {
        NotificationCenter.default.addObserver(forName: .onBalanceDidChange, object: nil, queue: OperationQueue.main) { (n: Notification) in
            self.updateBalance()
        }
        
        NotificationCenter.default.addObserver(forName: .onConnectionStatusChanged, object: nil, queue: OperationQueue.main) { (n: Notification) in
            self.updateConnectionSign()
        }
    }
    
    func shouldCheckAppVersions() {
        API.sharedInstance.getAppVersions(callback: { v in
            let version = Int(v) ?? 0
            let appVersion = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0") ?? 0
            self.upgradeAppButton.isHidden = version <= appVersion
        })
    }
    
    func updateConnectionSign() {
        let socketManager = SphinxSocketManager.sharedInstance
        let status = API.sharedInstance.connectionStatus
        let nodeConnected = status == API.ConnectionStatus.Connected
        let socketConnected = socketManager.isConnected() || socketManager.isConnecting()
        let connected = nodeConnected && socketConnected
        healthCheckButton.setTitleColor(connected ? ChatListHeader.kConnectedColor : ChatListHeader.kNotConnectedColor, for: .normal)
    }
    
    func showBalance() {
        smallUnitLabel.text = "chat-header.balance.unit".localized
        smallBalanceLabel.text = walletBalanceService.balance.formattedWithSeparator
        
        shouldCheckAppVersions()
    }
    
    func updateBalance() {
        smallUnitLabel.text = "chat-header.balance.unit".localized
        walletBalanceService.updateBalance(labels: [smallBalanceLabel])
    }
    
    func takeUserToSupport() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        appDelegate.goToSupport()
    }
    
    @IBAction func healthCheckButtonTouched() {
        let status = API.sharedInstance.connectionStatus
        let socketConnected = SphinxSocketManager.sharedInstance.isConnected()
        var message: String? = nil
        
        switch(status) {
        case API.ConnectionStatus.Connecting:
            break
        case API.ConnectionStatus.Connected:
            if socketConnected {
                message = "connected.to.node".localized
            } else {
                message = "socket.disconnected".localized
            }
            break
        case API.ConnectionStatus.NotConnected:
            takeUserToSupport()
            message = "unable.to.connect".localized
            break
        case API.ConnectionStatus.Unauthorize:
            takeUserToSupport()
            message = "unauthorized.error.message".localized
            break
        default:
            message = "network.connection.lost".localized
            break
        }
        
        if let message = message {
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.messageBubbleHelper.showGenericMessageView(text:message, delay: 3)
            })
        }
    }
    
    @IBAction func upgradeAppButtonTouched() {
        let urlStr = "https://testflight.apple.com/join/QoaCkJn6"
        UIApplication.shared.open(URL(string: urlStr)!, options: [:], completionHandler: nil)
    }
    
    @IBAction func leftMenuButtonTouched() {
        delegate?.leftMenuButtonTouched()
    }
    
}
