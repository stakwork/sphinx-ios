//
//  APIChatsExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 17/12/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation
import SwiftyJSON
import Alamofire

extension API {
    public func toggleChatSound(chatId: Int, muted: Bool, callback: @escaping MuteChatCallback, errorCallback: @escaping EmptyCallback) {
        let route = muted ? "mute" : "unmute"
        guard let request = getURLRequest(route: "/chats/\(chatId)/\(route)", method: "POST") else {
            errorCallback()
            return
        }
        
        sphinxRequest(request) { response in
            switch response.result {
            case .success(let data):
                if let json = data as? NSDictionary {
                    if let success = json["success"] as? Bool, let response = json["response"] as? NSDictionary, success {
                        callback(JSON(response))
                    } else {
                        errorCallback()
                    }
                }
            case .failure(_):
                errorCallback()
            }
        }
    }
}
