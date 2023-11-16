// Chat+FetchUtils.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation
import CoreData


// MARK: - Predicates
extension Chat {

    public enum Predicates {
        
        public static func matching(searchQuery: String) -> NSPredicate {
            let keyword = "CONTAINS[cd]"
            let formatSpecifier = "%@"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                #keyPath(Chat.name),
                searchQuery
            )
        }
        
        public static func matching(id: Chat.ID) -> NSPredicate {
            let keyword = "=="
            let formatSpecifier = "%i"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                "id",
                id
            )
        }
        
        public static func all() -> NSPredicate? {
            return nil
            
//            if GroupsPinManager.sharedInstance.isStandardPIN {
//                return NSPredicate(format: "pin = nil")
//            } else {
//                let currentPin = GroupsPinManager.sharedInstance.currentPin
//                return NSPredicate(format: "pin = %@", currentPin)
//            }
        }
    }
}


// MARK: - SortDescriptors
extension Chat {

    // 💡 An instance of `NSFetchedResultsController`, or an `NSFetchRequestResult` created by
    // SwiftUI's `@FetchRequest` property wrapper, requires a fetch request with sort descriptors.

    public enum SortDescriptors {

        public static let nameAscending: NSSortDescriptor = NSSortDescriptor(
            key: #keyPath(Chat.name),
            ascending: true,

            // 🔑 Any time you’re sorting user-facing strings,
            // Apple recommends that you pass in `NSString.localizedStandardCompare(_:)`
            // to sort according to the language rules of the current locale.
            // This means sort will “just work” and do the right thing for
            // languages with special character.
            selector: #selector(NSString.localizedStandardCompare(_:))
        )


        public static let nameDescending: NSSortDescriptor = {
            guard let descriptor = nameAscending.reversedSortDescriptor as? NSSortDescriptor else {
                preconditionFailure("Unable to make reversed sort descriptor")
            }

            return descriptor
        }()
    }
}


// MARK: - FetchRequests
extension Chat {

    public enum FetchRequests {

        public static func baseFetchRequest<Chat>() -> NSFetchRequest<Chat> {
            NSFetchRequest<Chat>(entityName: "Chat")
        }


        public static func `default`() -> NSFetchRequest<Chat> {
            let request: NSFetchRequest<Chat> = baseFetchRequest()

            request.sortDescriptors = [Chat.SortDescriptors.nameAscending]
            request.predicate = nil

            return request
        }
        
        public static func all() -> NSFetchRequest<Chat> {
            let request: NSFetchRequest<Chat> = baseFetchRequest()

            request.sortDescriptors = [Chat.SortDescriptors.nameAscending]
            request.predicate = Predicates.all()

            return request
        }
        
        public static func matching(searchQuery: String) -> NSFetchRequest<Chat> {
            let request: NSFetchRequest<Chat> = baseFetchRequest()

            request.predicate = Chat
                .Predicates
                .matching(searchQuery: searchQuery)

            request.sortDescriptors = [Chat.SortDescriptors.nameAscending]

            return request
        }
     
        
        public static func matching(id: Chat.ID) -> NSFetchRequest<Chat> {
            let request: NSFetchRequest<Chat> = baseFetchRequest()
            
            request.predicate = Predicates.matching(id: id)
            request.sortDescriptors = []

            return request
        }
    }
}
