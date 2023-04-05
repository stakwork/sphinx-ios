// Video+Computeds.swift
//
// Created by CypherPoet.
// ✌️
//

import Foundation


extension Video {
    
    static let publishDateFormatter: RelativeDateTimeFormatter = {
        let formatter = RelativeDateTimeFormatter()
        
        return formatter
    }()
    
    var dateString : String?{
        let date = self.datePublished
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy"
        if let valid_date = date{
            let dateString = formatter.string(from: valid_date)
            return dateString
        }
        return nil
    }
}
