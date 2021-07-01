//
//  ProfileViewControllerRelayExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 21/08/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation

extension ProfileViewController {
    func updateRelayURL() {
        view.endEditing(true)
        
        if let relayURL = relayUrlTextField.text {
            urlUpdateHelper.updateRelayURL(newValue: relayURL, completion: relayUpdateFinished)
        } else {
            relayUpdateFinished()
        }
    }
    
    func relayUpdateFinished() {
        configureProfile()
    }
}
