//
//  CallManager.swift
//  Alamofire
//
//  Created by James Carucci on 2/20/23.
//

import Foundation
import CallKit
import UIKit

@available(iOS 14.0, *)
final class JitsiIncomingCallManager: NSObject, CXProviderDelegate {
    
    class var sharedInstance : JitsiIncomingCallManager {
        struct Static {
            static let instance = JitsiIncomingCallManager()
        }
        return Static.instance
    }
    
    let provider = CXProvider(configuration: CXProviderConfiguration())
    let callController = CXCallController()
    var chatID: Int? = nil
    var currentJitsiURL: String? = nil
    
    override init(){
        super.init()
        
        provider.setDelegate(self, queue: nil)
    }
    
    
    public func reportIncomingCall(id: UUID, handle: String){
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: handle)
        provider.reportNewIncomingCall(with: id, update: update, completion: { error in
            if let error = error{
                print(String(describing: error))
            }
        })
    }
    
    public func startCall(id:UUID,handle:String){
        let action = CXStartCallAction(call: id, handle: CXHandle(type: .generic, value: handle))
        let transaction = CXTransaction(action: action)
        callController.request(transaction, completion: { error in
            if let error = error {
                print(String(describing: error))
            }
        })
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction){
        let hangUpAction = CXEndCallAction(call: action.callUUID)
        hangUpAction.fulfill()
        
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let callURL = currentJitsiURL {
            appDelegate.handleAcceptedCall(callLink: callURL)
        }
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction){
        action.fulfill()
    }
    
    
    func providerDidReset(_ provider: CXProvider) {
        print("Provider reset.")
    }
    
    
}
