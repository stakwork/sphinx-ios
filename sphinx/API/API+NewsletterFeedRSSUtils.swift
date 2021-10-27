//
//  API+NewsletterFeedRSSUtils.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import Alamofire

extension API {
    
    public func fetchNewsletterRSSFeed(
        from feedURLPath: String,
        then completionHandler: @escaping RSSFeedFetchCompletionHandler
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
    
    
    public func fetchNewsletterItems(
        for newsletterFeed: NewsletterFeed,
        then completionHandler: @escaping ((Result<[NewsletterItem], Error>) -> Void)
    ) {
        guard let urlPath = newsletterFeed.feedURL?.absoluteString else {
            preconditionFailure()
        }
        
        fetchYouTubeRSSFeed(
            from: urlPath,
            then: { result in
                switch result {
                case .success(let data):
                    let parsingResult = NewsletterFeedXMLParser.parseNewsletterFeedItems(from: data)
                    
                    switch parsingResult {
                    case .success(let newsletterItems):
                        completionHandler(.success(newsletterItems))
                    case .failure(let error):
                        completionHandler(.failure(error))
                    }
                case .failure(let error):
                    completionHandler(.failure(error))
                }
            }
        )
    }
}
