//
//  KeychainRestoreViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol KeychainRestoreDelegate: class {
    func goToApp()
    func willDismiss()
    func shouldShowError()
}

class KeychainRestoreViewController: UIViewController {
    
    weak var delegate: KeychainRestoreDelegate?
    
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var nodesTableView: UITableView!
    
    let userData = UserData.sharedInstance
    var nodesArray = [String]()
    
    let messageBubbleHelper = NewMessageBubbleHelper()
    
    let deleteConfirmText = "confirm.delete.keychain".localized
    
    static func instantiate(delegate: KeychainRestoreDelegate) -> KeychainRestoreViewController {
        let viewController = StoryboardScene.Invite.keychainRestoreViewController.instantiate()
        viewController.delegate = delegate
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nodesArray = userData.getPubKeysForRestore()
        
        nodesTableView.registerCell(KeychainRestoreTableViewCell.self)
        nodesTableView.delegate = self
        nodesTableView.dataSource = self
        nodesTableView.reloadData()
    }
    
    func restoreNode(pubKey: String) {
        if let credentials = userData.getAllValuesFor(pubKey: pubKey) {
            messageBubbleHelper.showLoadingWheel()

            if EncryptionManager.sharedInstance.insertKeys(privateKey: credentials[3], publicKey: credentials[4]) {
                UserData.sharedInstance.save(ip: credentials[0], token: credentials[1], pin: credentials[2])

                userData.getAndSaveTransportKey(forceGet: true) { [weak self] _ in
                    guard let self = self else { return }
                    
                    self.userData.getOrCreateHMACKey(forceGet: true) { [weak self] in
                        guard let self = self else { return }
                        
                        self.delegate?.goToApp()
                        
                        self.dismiss(animated: true, completion: {
                            self.messageBubbleHelper.hideLoadingWheel()
                        })
                    }
                }
            } else {
                self.dismissAndShowError()
            }
        } else {
            self.dismissAndShowError()
        }
    }
    
    func dismissAndShowError() {
        dismiss(animated: true)
        delegate?.shouldShowError()
    }
    
    @IBAction func closeButtonTouched() {
        delegate?.willDismiss()
        self.dismiss(animated: true)
    }
}

extension KeychainRestoreViewController : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60.0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? KeychainRestoreTableViewCell {
            let pubKey = nodesArray[indexPath.row]
            cell.configureNode(with: pubKey, delegate: self)
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let pubKey = nodesArray[indexPath.row]
        restoreNode(pubKey: pubKey)
    }
}

extension KeychainRestoreViewController : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return nodesArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "KeychainRestoreTableViewCell", for: indexPath) as! KeychainRestoreTableViewCell
        return cell
    }
}

extension KeychainRestoreViewController : KeychainRestoreCellDelegate {
    func shouldDelete(cell: UITableViewCell) {
        if let indexPath = nodesTableView.indexPath(for: cell) {
            AlertHelper.showTwoOptionsAlert(title: "confirm".localized, message: deleteConfirmText, confirm: {
                let pubKey = self.nodesArray[indexPath.row]
                
                self.userData.resetAllFor(pubKey: pubKey)
                self.nodesArray.remove(at: indexPath.row)
                self.nodesTableView.deleteRows(at: [indexPath], with: .automatic)
            })
        }
    }
}
