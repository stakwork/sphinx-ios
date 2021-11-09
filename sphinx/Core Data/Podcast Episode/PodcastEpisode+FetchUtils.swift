//
//  PodcastEpisode+FetchUtils.swift
//  sphinx
//
//  Created by Tomas Timinskas on 08/11/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import CoreData

extension PodcastEpisode {
    static func getPodcastEpisodeWith(id: Int64) -> PodcastEpisode? {
        let predicate = NSPredicate(format: "id == %@", NSNumber(value: id))
        let episode:PodcastEpisode? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "PodcastEpisode")
        return episode
    }
}
