//
//  APIPodcastExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import Alamofire
import CryptoKit


extension API {
    
    enum PodcastIndexSearchError: Swift.Error {
        case failedToCreateRequestURL
        case failedToCreateRequest(urlPath: String)
        case missingResponseData
        case decodingError(DecodingError)
        case unknownError(Swift.Error)
        case unexpectedResponseData
        case networkError(AFError)
        case nodeInvoiceGenerationFailure(message: String)
        case karmaReceiptValidationFailure(message: String)
    }
}


extension API {
    
    public func searchPodcastIndex(
        matching queryString: String,
        apiKey: String,
        apiSecret: String,
        then completionHandler: @escaping PodcastIndexSearchCompletionHandler
    ) {
        let urlPath = "\(API.kPodcastIndexURL)/api/1.0/search/byterm"
        
        let authDate = "\(Int(Date().timeIntervalSince1970))"
        let userAgent = "SphinxChat/1.0"

        let rawAuthorizationDataString = [
            apiKey,
            apiSecret,
            authDate,
        ]
        .joined()
        .utf8

        let authorizationInputData = Data(rawAuthorizationDataString)
        let authorizationHeaderHash = Insecure.SHA1.hash(data: authorizationInputData)

        let authorizationHeaderString = authorizationHeaderHash
            .compactMap { String(format: "%02x", $0) }
            .joined()
        
        let requestHeaders: [String: String] = [
            "x-auth-key": apiKey,
            "x-auth-date": authDate,
            "user-agent": userAgent,
            "authorization": authorizationHeaderString,
        ]
                                  
        var urlComponents = URLComponents(string: urlPath)!
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: queryString)
        ]
        
        guard let urlString = urlComponents.url?.absoluteString else {
            completionHandler(.failure(.failedToCreateRequestURL))
            return
        }
        
        guard let request = createRequest(
            urlString,
            bodyParams: nil,
            headers: requestHeaders,
            method: "GET"
        ) else {
            completionHandler(.failure(.failedToCreateRequest(urlPath: urlPath)))
            return
        }
        
        AF.request(request).responseJSON { [weak self] response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    completionHandler(.failure(.missingResponseData))
                    return
                }
                
                do {
                    let searchResults = try self?.decodePodcastFeeds(from: data) ?? []
                    
                    completionHandler(.success(searchResults))
                } catch let error as DecodingError {
                    completionHandler(.failure(.decodingError(error)))
                } catch let error {
                    completionHandler(.failure(.unknownError(error)))
                }
            case .failure(let error):
                completionHandler(.failure(.networkError(error)))
                return
            }
        }
    }
    
    
    func decodePodcastFeeds(from searchResults: Data) throws -> [PodcastFeedSearchResult] {
        let decoder = JSONDecoder()
        
        let resultsContainer = try decoder.decode(
            PodcastFeedSearchResult.ResultsContainer.self,
            from: searchResults
        )
        
        return resultsContainer.feeds
    }
}
    


extension PodcastFeedSearchResult {
    
    fileprivate struct ResultsContainer: Decodable {
        var feeds: [PodcastFeedSearchResult]
        
        enum CodingKeys: String, CodingKey {
            case feeds = "feeds"
        }
    }
}
