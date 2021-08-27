// PodcastFeedViewModel.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation


final class PodcastFeedViewModel: NSObject {

    private var contactsService: ContactsService
    private var podcastFeedService: PodcastFeedService
    
    
    init(
        contactsService: ContactsService = .init(),
        podcastFeedService: PodcastFeedService = .init()
    ) {
        self.contactsService = contactsService
        self.podcastFeedService = podcastFeedService
    }
    
    
    var allFeeds: [PodcastFeed] {
        contactsService
            .getChatListObjects()
            .filter { $0.isPublicGroup() } // "Is Tribe"
            .compactMap { $0 as? Chat }
            .compactMap(\.podcastPlayer?.podcast)
    }
    
    
    var latestEpisodes: [PodcastEpisode] {
        allFeeds
            .compactMap(\.episodes?.first)
    }
    
    
    func performSearch(
        withQuery query: String,
        then completionHandler: @escaping () -> Void
    ) {
        podcastFeedService.fetchFeedSearchResults(
            fromQuery: query
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let feeds):
                break
            case .failure(let error):
                break
            }
            
            DispatchQueue.main.async(execute: completionHandler)
        }
    }
}
