//
//  CommonModalView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 26/05/2021.
//  Copyright © 2021 Tomas Timinskas. All rights reserved.
//

import UIKit
import SwiftyJSON

class CommonModalView: UIView, ModalViewInterface {
    
    weak var delegate: ModalViewDelegate?
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var buttonLoadingWheel: UIActivityIndicatorView!
    
    var messageBubbleHelper = NewMessageBubbleHelper()
    
    struct AuthInfo {
        var host : String? = nil
        var challenge : String? = nil
        var token : String? = nil
        var pubkey : String? = nil
        var verificationSignature : String? = nil
        var ts : Int? = nil
        var info : [String: AnyObject] = [:]
        var jsonBody : JSON = JSON()
        
        var key : String? = nil
        var path : String? = nil
        var updateMethod : String? = nil
    }
    
    var authInfo: AuthInfo? = nil
    var query: String! = nil
    
    var buttonLoading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: buttonLoading, loadingWheel: buttonLoadingWheel, loadingWheelColor: UIColor.white, view: self)
        }
    }

    func modalWillShowWith(query: String, delegate: ModalViewDelegate) {
        self.query = query
        self.delegate = delegate
    }
    
    func modalDidShow() {
        
    }
    
    func processQuery() {
        if let query = query {
            authInfo = AuthInfo()
            
            for component in query.components(separatedBy: "&") {
                let elements = component.components(separatedBy: "=")
                if elements.count > 1 {
                    let key = elements[0]
                    let value = component.replacingOccurrences(of: "\(key)=", with: "")
                    
                    switch(key) {
                    case "host":
                        authInfo?.host = value
                        break
                    case "challenge":
                        authInfo?.challenge = value
                        break
                    case "pubkey":
                        authInfo?.pubkey = value
                    case "key":
                        authInfo?.key = value
                        break
                    default:
                        break
                    }
                }
            }
        }
    }
    
    @IBAction func closeButtonTouched() {
        delegate?.shouldDismissVC()
    }

}
