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
            case .success(let data):
                var podcasts = [PodcastFeed]()
                
                if let itemsArray = data as? NSArray {
                    itemsArray.forEach {
                        podcasts.append(
                            PodcastFeed.convertFrom(searchResult: JSON($0))
                        )
                    }
                }
                
                completionHandler(.success(podcasts))
            case .failure(let error):
                completionHandler(.failure(.networkError(error)))
            }
        }
    }
}
