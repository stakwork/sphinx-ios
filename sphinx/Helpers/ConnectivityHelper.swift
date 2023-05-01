//
//  ReachabilityHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import SystemConfiguration
import Alamofire

struct ConnectivityHelper {
    
    static let sharedInstance = NetworkReachabilityManager()!

    static var isConnectedToInternet: Bool {
        return self.sharedInstance.isReachable
    }
}
