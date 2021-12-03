//
//  NewsletterFeed+DisplayUtils.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit


extension NewsletterFeed {
    
    var avatarImagePlaceholder: UIImage? {
        UIImage(named: "profile_avatar")
    }
    
    
    var titleForDisplay: String { title ?? "Untitled" }
}
