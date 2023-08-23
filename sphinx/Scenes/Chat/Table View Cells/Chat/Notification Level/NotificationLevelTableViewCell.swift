//
//  NotificationLevelTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 05/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class NotificationLevelTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell(notificationLevel: NotificationsLevelViewController.NotificationLevel) {
        titleLabel.text = notificationLevel.title
        
        contentView.backgroundColor = notificationLevel.selected ? UIColor.Sphinx.PrimaryBlue : UIColor.Sphinx.HeaderBG
    }

}
