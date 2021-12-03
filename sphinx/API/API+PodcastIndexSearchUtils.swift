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
import SwiftyJSON


extension API {
    
    public func searchForPodcasts(
        matching queryString: String,
        then completionHandler: @escaping PodcastSearchCompletionHandler
    ) {
        let urlPath = "\(API.kTestTribesServerBaseURL)/search_podcasts"
        
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
            method: "GET"
        ) else {
            completionHandler(.failure(.failedToCreateRequest(urlPath: urlPath)))
            return
        }

        podcastSearchRequest?.cancel()
        
        podcastSearchRequest = AF.request(request).responseJSON { response in
            switch response.result {
            case .success:
                guard let data = response.data else {
                    completionHandler(.failure(.missingResponseData))
                    return
                }

                do {
                    let decoder = ContentFeed.Decoders.default
                    
                    let searchResults = try decoder.decode([ContentFeed].self, from: data)
                    
                    searchResults.forEach { $0.feedKind = .Podcast }

                    completionHandler(.success(searchResults))
                } catch let error as DecodingError {
                    completionHandler(.failure(.decodingError(error)))
                } catch let error {
                    completionHandler(.failure(.unknownError(error)))
                }
            case .failure(let error):
                completionHandler(.failure(.networkError(error)))
            }
        }
    }
}
