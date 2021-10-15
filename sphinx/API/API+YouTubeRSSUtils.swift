// API+YouTubeRSSUtils.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import Alamofire


extension API {
    
    public func fetchYouTubeRSSFeed(
        from feedURLPath: String,
        then completionHandler: @escaping YouTubeRSSFeedFetchCompletionHandler
    ) {
        guard let request = createRequest(
            feedURLPath,
            bodyParams: nil,
            method: "GET"
        ) else {
            completionHandler(.failure(.failedToCreateRequest(urlPath: feedURLPath)))
            return
        }
        
        
        AF.request(request).responseData { response in
            guard let data = response.data else {
                completionHandler(.failure(.unexpectedResponseData))
                return
            }
            
            completionHandler(.success(data))
        }
    }
}
