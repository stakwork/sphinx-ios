//
//  UserContact+FetchUtils.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/05/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//
import Foundation
import CoreData


// MARK: - Predicates
extension UserContact {

    public enum Predicates {
        
        public static func matching(searchQuery: String) -> NSPredicate {
            let keyword = "CONTAINS[cd]"
            let formatSpecifier = "%@"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                #keyPath(UserContact.nickname),
                searchQuery
            )
        }
        
        
        public static func matching(id: Int) -> NSPredicate {
            let keyword = "=="
            let formatSpecifier = "%i"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier)",
                "id",
                id
            )
        }
        
        public static func encryptedContactWith(id: Int) -> NSPredicate {
            let keyword = "=="
            let formatSpecifier = "%i"

            return NSPredicate(
                format: "%K \(keyword) \(formatSpecifier) AND contactKey != NULL",
                "id",
                id
            )
        }
        
        public static func chatList() -> NSPredicate {
            return NSPredicate(
                format: "fromGroup == %@",
                NSNumber(value: false)
            )
            
//            if GroupsPinManager.sharedInstance.isStandardPIN {
//                return NSPredicate(
//                    format: "isOwner == %@ AND fromGroup == %@ AND pin = nil",
//                    NSNumber(value: false),
//                    NSNumber(value: false)
//                )
//            } else {
//                return NSPredicate(
//                    format: "isOwner == %@ AND fromGroup == %@ AND pin = %@",
//                    NSNumber(value: false),
//                    NSNumber(value: false),
//                    GroupsPinManager.sharedInstance.currentPin
//                )
//            }
        }
        
        public static func owner() -> NSPredicate {
            return NSPredicate(
                format: "isOwner == %@",
                NSNumber(value: true)
            )
        }
    }
}

// MARK: - SortDescriptors
extension UserContact {

    // 💡 An instance of `NSFetchedResultsController`, or an `NSFetchRequestResult` created by
    // SwiftUI's `@FetchRequest` property wrapper, requires a fetch request with sort descriptors.

    public enum SortDescriptors {

        public static let nameAscending: NSSortDescriptor = NSSortDescriptor(
            key: #keyPath(UserContact.nickname),
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
extension UserContact {

    public enum FetchRequests {

        public static func baseFetchRequest<UserContact>() -> NSFetchRequest<UserContact> {
            NSFetchRequest<UserContact>(entityName: "UserContact")
        }


        public static func `default`() -> NSFetchRequest<UserContact> {
            let request: NSFetchRequest<UserContact> = baseFetchRequest()

            request.sortDescriptors = [UserContact.SortDescriptors.nameAscending]
            request.predicate = nil

            return request
        }
        
        public static func owner() -> NSFetchRequest<UserContact> {
            let request: NSFetchRequest<UserContact> = baseFetchRequest()

            request.sortDescriptors = [UserContact.SortDescriptors.nameAscending]
            request.predicate = Predicates.owner()
            request.fetchLimit = 1

            return request
        }
        
        public static func chatList() -> NSFetchRequest<UserContact> {
            let request: NSFetchRequest<UserContact> = baseFetchRequest()

            request.sortDescriptors = [UserContact.SortDescriptors.nameAscending]
            request.predicate = Predicates.chatList()

            return request
        }
        
        
        public static func matching(searchQuery: String) -> NSFetchRequest<UserContact> {
            let request: NSFetchRequest<UserContact> = baseFetchRequest()

            request.predicate = UserContact
                .Predicates
                .matching(searchQuery: searchQuery)

            request.sortDescriptors = [UserContact.SortDescriptors.nameAscending]

            return request
        }
     
        
        public static func matching(id: Int) -> NSFetchRequest<UserContact> {
            let request: NSFetchRequest<UserContact> = baseFetchRequest()
            
            request.predicate = Predicates.matching(id: id)
            request.sortDescriptors = []

            return request
        }
        
        public static func encryptedContactWith(id: Int) -> NSFetchRequest<UserContact> {
            let request: NSFetchRequest<UserContact> = baseFetchRequest()
            
            request.predicate = Predicates.encryptedContactWith(id: id)
            request.sortDescriptors = []

            return request
        }
    }
}

