// Video+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation


extension Video {
    
    var titleForDisplay: String { title ?? "Untitled" }
    
    
    var publishDateText: String {
        guard let datePublished = datePublished else {
            return "Unknown Publish Date"
        }
        
        let calendar = Calendar.autoupdatingCurrent
        
        let dateComponents = calendar.dateComponents(
            [
                .year,
                .month,
                .day,
                .hour,
                .minute,
                .second,
            ],
            from: Date(),
            to: datePublished
        )
        

        return Self.publishDateFormatter.localizedString(
            from: dateComponents
        )
    }
}
