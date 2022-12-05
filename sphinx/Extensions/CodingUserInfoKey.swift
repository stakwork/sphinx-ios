// CodingUserInfoKey.swift
//
// Created by CypherPoet.
// ✌️
//
    
import Foundation


extension CodingUserInfoKey {
    
    /// Use for retrieving a Core Data managed object context from the `userInfo` dictionary
    /// of a decoder instance.
    public static let managedObjectContext = CodingUserInfoKey(rawValue: "Managed Object Context")!
}
