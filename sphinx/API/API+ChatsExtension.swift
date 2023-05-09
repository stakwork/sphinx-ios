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
        let level = muted ? Chat.NotificationLevel.MuteChat.rawValue : Chat.NotificationLevel.SeeAll.rawValue
        
        setNotificationLevel(chatId: chatId, level: level) { json in
            callback(json)
        } errorCallback: {
            errorCallback()
        }
    }
    
    public func setNotificationLevel(chatId: Int, level: Int, callback: @escaping NotificationLevelCallback, errorCallback: @escaping EmptyCallback) {
        guard let request = getURLRequest(route: "/notify/\(chatId)/\(level)", method: "PUT") else {
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
    

    public func askChatGPT(question: String,completion: @escaping (String?)->()) {
        let url = URL(string: "https://api.openai.com/v1/engines/text-davinci-001/completions")!
        let apiKey = "sk-ZUFAQWVunO2qSqZfVI0yT3BlbkFJHp89ALhP78itBHWc6p"
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let parameters = ["prompt": question, "temperature": 0.5, "max_tokens": 100] as [String : Any]
        request.httpBody = try! JSONSerialization.data(withJSONObject: parameters, options: [])
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Error: \(error!.localizedDescription)")
                return
            }
            
            if let httpRes = response as? HTTPURLResponse{
                print(httpRes.statusCode)
            }
            
            if let result = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let completions = result?["choices"] as? [[String: Any]],
               let text = completions.first?["text"] as? String {
                print(text)
                completion(text)
            } else {
                print("Error: Unable to parse response")
                completion(nil)
            }
        }
        
        task.resume()
    }

}
