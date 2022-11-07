//
//  Action+FetchUtils.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import CoreData

extension ActionTrack {

    public enum Predicates {
        
        public static func matching(type: Int) -> NSPredicate {
            let keyword = "=="
            let formatSpecifier = "%i"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                "type",
                type
            )
        }
        
        public static func matching(uploaded: Bool) -> NSPredicate {
            let keyword = "=="
            let formatSpecifier = "%i"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                "uploaded",
                uploaded
            )
        }
        
        public static func contains(searchTerm: String) -> NSPredicate {
            let keyword = "CONTAINS[cd]"
            let formatSpecifier = "%@"
            let typeFormatSpecifier = "%d"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier) AND type == \(typeFormatSpecifier)",
                "metaData",
                searchTerm,
                ActionsManager.ActionType.FeedSearch.rawValue
            )
        }
    }
}


// MARK: - SortDescriptors
extension ActionTrack {

    public enum SortDescriptors {

        public static let typeAscending: NSSortDescriptor = NSSortDescriptor(
            key: #keyPath(ActionTrack.type),
            ascending: true,
            selector: #selector(NSString.localizedStandardCompare(_:))
        )


        public static let typeDescending: NSSortDescriptor = {
            guard let descriptor = typeAscending.reversedSortDescriptor as? NSSortDescriptor else {
                preconditionFailure("Unable to make reversed sort descriptor")
            }

            return descriptor
        }()
    }
}


// MARK: - FetchRequests
extension ActionTrack {

    public enum FetchRequests {

        public static func baseFetchRequest<ActionTrack>() -> NSFetchRequest<ActionTrack> {
            NSFetchRequest<ActionTrack>(entityName: "ActionTrack")
        }

        public static func `default`() -> NSFetchRequest<ActionTrack> {
            let request: NSFetchRequest<ActionTrack> = baseFetchRequest()

            request.sortDescriptors = [ActionTrack.SortDescriptors.typeAscending]
            request.predicate = nil

            return request
        }
        
        public static func matching(type: Int) -> NSFetchRequest<ActionTrack> {
            let request: NSFetchRequest<ActionTrack> = baseFetchRequest()
            
            request.predicate = Predicates.matching(type: type)
            request.sortDescriptors = []

            return request
        }
        
        public static func contains(searchTerm: String) -> NSFetchRequest<ActionTrack> {
            let request: NSFetchRequest<ActionTrack> = baseFetchRequest()
            
            request.predicate = Predicates.contains(searchTerm: searchTerm.uppercased())
            request.sortDescriptors = []

            return request
        }
    }
}
