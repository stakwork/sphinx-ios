//
//  ActionsManager.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation
import CoreData

class ActionsManager {
    
    enum ActionType : Int {
        case Message = 0
        case FeedSearch = 1
        case ContentBoost = 2
        case PodcastClipComment = 3
        case ContentConsumed = 4
    }

    class var sharedInstance : ActionsManager {
        struct Static {
            static let instance = ActionsManager()
        }
        return Static.instance
    }
    
    func test() {
        let messageAction = MessageAction(keywords: ["bitcoin","lightning","sphinx"], currentTimestamp: Date())
        if let jsonString = messageAction.jsonString() {
            let _ = ActionTrack.createObject(type: ActionType.Message.rawValue, uploaded: false, metaData: jsonString)

            let actions = ActionTrack.getAll()

            for a in actions {
                if a.type == ActionType.Message.rawValue {
                    let messageAction = MessageAction.messageAction(jsonString: a.metaData)
                    print("test")
                }
            }
        }
    }
}
