//
//  PodcastClipAction.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

public class PodcastClipAction: Codable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.feedId, forKey: .feedId)
        try container.encode(self.feedType, forKey: .feedType)
        try container.encode(self.feedUrl, forKey: .feedUrl)
        try container.encode(self.feedItemId, forKey: .feedItemId)
        try container.encode(self.feedItemUrl, forKey: .feedItemUrl)
        try container.encode(self.topics, forKey: .topics)
        try container.encode(self.startTimestamp, forKey: .startTimestamp)
        try container.encode(self.endTimestamp, forKey: .endTimestamp)
        try container.encode(self.currentTimestamp, forKey: .currentTimestamp)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let feedId = try values.decode(String.self, forKey: .feedId)
        let feedType = try values.decode(Int.self, forKey: .feedType)
        let feedUrl = try values.decode(String.self, forKey: .feedUrl)
        let feedItemId = try values.decode(String.self, forKey: .feedItemId)
        let feedItemUrl = try values.decode(String.self, forKey: .feedItemUrl)
        let topics = try values.decode([String].self, forKey: .topics)
        let startTimestamp = try values.decode(Int.self, forKey: .startTimestamp)
        let endTimestamp = try values.decode(Int.self, forKey: .endTimestamp)
        let currentTimestamp = try values.decode(Date.self, forKey: .currentTimestamp)

        self.feedId = feedId
        self.feedType = feedType
        self.feedUrl = feedUrl
        self.feedItemId = feedItemId
        self.feedItemUrl = feedItemUrl
        self.topics = topics
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.currentTimestamp = currentTimestamp
    }
    
    
    public var feedId: String
    public var feedType: Int
    public var feedUrl: String
    public var feedItemId: String
    public var feedItemUrl: String
    public var topics: [String] = []
    public var startTimestamp: Int
    public var endTimestamp: Int
    public var currentTimestamp: Date
    
    init(
        feedId: String,
        feedType: Int,
        feedUrl: String,
        feedItemId: String,
        feedItemUrl: String,
        topics: [String] = [],
        startTimestamp: Int,
        endTimestamp: Int,
        currentTimestamp: Date
    ) {
        self.feedId = feedId
        self.feedType = feedType
        self.feedUrl = feedUrl
        self.feedItemId = feedItemId
        self.feedItemUrl = feedItemUrl
        self.topics = topics
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.currentTimestamp = currentTimestamp
    }
    
    func getParamsDictionary() -> [String: Any] {
        let json: [String: Any] = [
            "type": ActionsManager.ActionType.PodcastClipComment.rawValue,
            "meta_data":
                [
                    "feed_id" : self.feedId,
                    "feed_type" : self.feedType,
                    "feed_url" : self.feedUrl,
                    "feed_item_id" : self.feedItemId,
                    "feed_item_url" : self.feedItemUrl,
                    "topics" : self.topics,
                    "start_timestamp" : self.startTimestamp,
                    "end_timestamp" : self.endTimestamp,
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

    static func podcastClipAction(jsonString: String) -> PodcastClipAction? {
        let data = Data(jsonString.utf8)
        let jsonDecoder = JSONDecoder()
        var podcastClipAction: PodcastClipAction! = nil
        do {
            podcastClipAction = try jsonDecoder.decode(PodcastClipAction.self, from: data)
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
        return podcastClipAction
    }
}

extension PodcastClipAction {
    enum CodingKeys: String, CodingKey {
        case feedId = "feed_id"
        case feedType = "feed_type"
        case feedUrl = "feed_url"
        case feedItemId = "feed_item_id"
        case feedItemUrl = "feed_item_url"
        case topics = "topics"
        case startTimestamp = "start_timestamp"
        case endTimestamp = "end_timestamp"
        case currentTimestamp = "current_timestamp"
    }
}
