//
//  FeedSearchAction.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

public class FeedSearchAction: Codable {
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(self.frequency, forKey: .frequency)
        try container.encode(self.searchTerm, forKey: .searchTerm)
        try container.encode(self.currentTimestamp, forKey: .currentTimestamp)
    }
    
    public required init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)

        let frequency = try values.decode(Int.self, forKey: .frequency)
        let searchTerm = try values.decode(String.self, forKey: .searchTerm)
        let currentTimestamp = try values.decode(Date.self, forKey: .currentTimestamp)

        self.frequency = frequency
        self.searchTerm = searchTerm
        self.currentTimestamp = currentTimestamp
    }
    
    
    public var frequency: Int = 0
    public var searchTerm: String
    public var currentTimestamp: Date
    
    init(
        frequency: Int = 0,
        searchTerm: String,
        currentTimestamp: Date
    ) {
        self.frequency = frequency
        self.searchTerm = searchTerm
        self.currentTimestamp = currentTimestamp
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

    static func messageAction(jsonString: String) -> FeedSearchAction? {
        let data = Data(jsonString.utf8)
        let jsonDecoder = JSONDecoder()
        var feedSearchAction: FeedSearchAction! = nil
        do {
            feedSearchAction = try jsonDecoder.decode(FeedSearchAction.self, from: data)
        } catch let error {
            print(error.localizedDescription)
            return nil
        }
        return feedSearchAction
    }
}

extension FeedSearchAction {
    enum CodingKeys: String, CodingKey {
        case frequency = "frequency"
        case searchTerm = "search_term"
        case currentTimestamp = "current_timestamp"
    }
}
