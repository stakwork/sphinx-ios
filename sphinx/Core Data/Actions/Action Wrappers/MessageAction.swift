//
//  MessageAction.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

public class MessageAction: Codable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.keywords, forKey: .keywords)
        try container.encode(self.currentTimestamp, forKey: .currentTimestamp)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let keywords = try values.decode([String].self, forKey: .keywords)
        let currentTimestamp = try values.decode(Date.self, forKey: .currentTimestamp)

        self.keywords = keywords
        self.currentTimestamp = currentTimestamp
    }
    
    
    public var keywords: [String]
    public var currentTimestamp: Date
    
    init(
        keywords: [String],
        currentTimestamp: Date
    ) {
        self.keywords = keywords
        self.currentTimestamp = currentTimestamp
    }
    
    func getParamsDictionary() -> [String: Any] {
        let json: [String: Any] = [
            "type": ActionsManager.ActionType.Message.rawValue,
            "meta_data":
                [
                    "keywords" : self.keywords,
                    "current_timestamp" : round(self.currentTimestamp.timeIntervalSince1970 * 1000),
                ]
        ]
        return json
    }
    
    func jsonString() -> String? {
        let jsonEncoder = JSONEncoder()
        var jsonData: Data! = nil
        do {
            jsonData = try jsonEncoder.encode(self)
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
        return String(data: jsonData, encoding: String.Encoding.utf8)
    }

    static func messageAction(jsonString: String) -> MessageAction? {
        let data = Data(jsonString.utf8)
        let jsonDecoder = JSONDecoder()
        var messageAction: MessageAction! = nil
        do {
            messageAction = try jsonDecoder.decode(MessageAction.self, from: data)
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
        return messageAction
    }
}

extension MessageAction {
    enum CodingKeys: String, CodingKey {
        case keywords = "keywords"
        case currentTimestamp = "current_timestamp"
    }
}
