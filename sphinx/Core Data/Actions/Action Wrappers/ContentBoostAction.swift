//
//  ContentBoostAction.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

public class ContentBoostAction: Codable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.boost, forKey: .boost)
        try container.encode(self.feedId, forKey: .feedId)
        try container.encode(self.feedType, forKey: .feedType)
        try container.encode(self.feedUrl, forKey: .feedUrl)
        try container.encode(self.feedItemId, forKey: .feedItemId)
        try container.encode(self.feedItemUrl, forKey: .feedItemUrl)
        try container.encode(self.topics, forKey: .topics)
        try container.encode(self.currentTimestamp, forKey: .currentTimestamp)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let boost = try values.decode(Int.self, forKey: .boost)
        let feedId = try values.decode(String.self, forKey: .feedId)
        let feedType = try values.decode(Int.self, forKey: .feedType)
        let feedUrl = try values.decode(String.self, forKey: .feedUrl)
        let feedItemId = try values.decode(String.self, forKey: .feedItemId)
        let feedItemUrl = try values.decode(String.self, forKey: .feedItemUrl)
        let topics = try values.decode([String].self, forKey: .topics)
        let currentTimestamp = try values.decode(Date.self, forKey: .currentTimestamp)

        self.boost = boost
        self.feedId = feedId
        self.feedType = feedType
        self.feedUrl = feedUrl
        self.feedItemId = feedItemId
        self.feedItemUrl = feedItemUrl
        self.topics = topics
        self.currentTimestamp = currentTimestamp
    }
    
    
    public var boost: Int
    public var feedId: String
    public var feedType: Int
    public var feedUrl: String
    public var feedItemId: String
    public var feedItemUrl: String
    public var topics: [String] = []
    public var currentTimestamp: Date
    
    init(
        boost: Int,
        feedId: String,
        feedType: Int,
        feedUrl: String,
        feedItemId: String,
        feedItemUrl: String,
        topics: [String] = [],
        currentTimestamp: Date
    ) {
        self.boost = boost
        self.feedId = feedId
        self.feedType = feedType
        self.feedUrl = feedUrl
        self.feedItemId = feedItemId
        self.feedItemUrl = feedItemUrl
        self.topics = topics
        self.currentTimestamp = currentTimestamp
    }
    
    func getParamsDictionary() -> [String: Any] {
        let json: [String: Any] = [
            "type": ActionsManager.ActionType.ContentBoost.rawValue,
            "meta_data":
                [
                    "boost" : self.boost,
                    "feed_id" : self.feedId,
                    "feed_type" : self.feedType,
                    "feed_url" : self.feedUrl,
                    "feed_item_id" : self.feedItemId,
                    "feed_item_url" : self.feedItemUrl,
                    "topics" : self.topics,
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

    static func contentBoostAction(jsonString: String) -> ContentBoostAction? {
        let data = Data(jsonString.utf8)
        let jsonDecoder = JSONDecoder()
        var contentBoostAction: ContentBoostAction! = nil
        do {
            contentBoostAction = try jsonDecoder.decode(ContentBoostAction.self, from: data)
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
        return contentBoostAction
    }
}

extension ContentBoostAction {
    enum CodingKeys: String, CodingKey {
        case boost = "boost"
        case feedId = "feed_id"
        case feedType = "feed_type"
        case feedUrl = "feed_url"
        case feedItemId = "feed_item_id"
        case feedItemUrl = "feed_item_url"
        case topics = "topics"
        case currentTimestamp = "current_timestamp"
    }
}
