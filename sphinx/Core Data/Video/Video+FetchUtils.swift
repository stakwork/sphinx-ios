//
//  Video+FetchUtils.swift
//  sphinx
//
//  Created by Tomas Timinskas on 02/11/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import Foundation
import CoreData

extension Video {
    static func getVideoWith(videoID: String) -> Video? {
        let predicate = NSPredicate(format: "videoID == %@", videoID)
        let video:Video? = CoreDataManager.sharedManager.getObjectOfTypeWith(predicate: predicate, sortDescriptors: [], entityName: "Video")
        return video
    }
}
