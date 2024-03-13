//
//  WalletBalanceService.swift
//  sphinx
//
//  Created by Tomas Timinskas on 04/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import UIKit

public final class WalletBalanceService {
    
    var balance: Int {
        get {
            return UserDefaults.Keys.channelBalance.get() ?? 0 as Int
        }
        set {
            UserDefaults.Keys.channelBalance.set(newValue)
        }
    }
    
    var remoteBalance: Int {
        get {
            return UserDefaults.Keys.remoteBalance.get() ?? 0 as Int
        }
        set {
            UserDefaults.Keys.remoteBalance.set(newValue)
        }
    }
    
    func getBalance()->Int? {
        let balance = UserData.sharedInstance.getBalanceSats()
        return balance
    }
    
    func getBalanceAll(completion: @escaping (Int, Int) -> ()) -> (Int, Int) {
        API.sharedInstance.getWalletLocalAndRemote(callback: { local, remote in
            self.balance = local
            self.remoteBalance = remote
            completion(local, remote)
        }, errorCallback: {
            completion(self.balance, self.remoteBalance)
        })
        return (balance, remoteBalance)
    }
    
    func updateBalance(labels: [UILabel]) {
        DispatchQueue.global().async {
            if let storedBalance = self.getBalance(){
                self.updateLabels(labels: labels, balance: storedBalance.formattedWithSeparator)
            }
        }
    }
    
    private func updateLabels(labels: [UILabel], balance: String) {
        DispatchQueue.main.async {
            let hideBalances = UserDefaults.Keys.hideBalances.get(defaultValue: false)
            for label in labels {
                if (hideBalances) {
                    label.text = "＊＊＊＊"
                } else {
                    label.text = balance
                }
            }
        }
    }
}
