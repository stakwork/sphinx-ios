//
//  BiometricAuthenticationHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import LocalAuthentication

class BiometricAuthenticationHelper {
    func canUseBiometricAuthentication() -> Bool {
        return LAContext().biometricType != .none
    }
    
    func authenticationAction(policy: LAPolicy = .deviceOwnerAuthenticationWithBiometrics, completion: @escaping (Bool) -> ()) {
        let myContext = LAContext()
        let myLocalizedReasonString = "log.into.your.account".localized
        
        var authError: NSError?
        if myContext.canEvaluatePolicy(policy, error: &authError) {
            myContext.evaluatePolicy(policy, localizedReason: myLocalizedReasonString) { success, evaluateError in
                DispatchQueue.main.async {
                    if let evaluateError = evaluateError {
                        completion(evaluateError._code == LAError.Code.passcodeNotSet.rawValue)
                    } else {
                        completion(success)
                    }
                }
            }
            return
        }
        completion(false)
    }
}
