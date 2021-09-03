// PodcastEpisode+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//
    

import Foundation


extension PodcastEpisode {
    
    /// Converts the HTML-formatted ``episodeDescription`` string to a standard Swift String
    var formattedDescription: String {
        episodeDescription?.attributedStringFromHTML?.string ?? ""
    }
}
