//
//  Server+CoreDataClass.swift
//  sphinx
//
//  Created by James Carucci on 11/10/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import CoreData
import SwiftyJSON


@objc(Server)
public class Server: NSManagedObject {
    
    public static func getAllServers(context: NSManagedObjectContext) -> [Server] {
        let fetchRequest = NSFetchRequest<Server>(entityName: "Server")
        
        do {
            let servers = try context.fetch(fetchRequest)
            return servers
        } catch let error as NSError {
            print("Error fetching servers: \(error.localizedDescription)")
            return []
        }
    }
    
}
