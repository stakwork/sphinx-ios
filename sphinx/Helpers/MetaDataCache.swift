//
//  MetaDataCache.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import LinkPresentation

class MetaDataCache {
    
    @available(iOS 13.0, *)
    static func cache(metadata: LPLinkMetadata, link: String) {
        do {
            guard retrieve(urlString: link) == nil else {
                return
            }

            let data = try NSKeyedArchiver.archivedData(withRootObject: metadata, requiringSecureCoding: true)
            UserDefaults.standard.setValue(data, forKey: link)
        } catch let error {
            print("Error when caching: \(error.localizedDescription)")
        }
    }

    @available(iOS 13.0, *)
    static func retrieve(urlString: String) -> LPLinkMetadata? {
        do {
            guard let data = UserDefaults.standard.object(forKey: urlString) as? Data,
                  let metadata = try NSKeyedUnarchiver.unarchivedObject(ofClass: LPLinkMetadata.self, from: data) else { return nil }
        
            return metadata
            
        } catch let error {
            print("Error when caching: \(error.localizedDescription)")
            return nil
        }
    }
}
