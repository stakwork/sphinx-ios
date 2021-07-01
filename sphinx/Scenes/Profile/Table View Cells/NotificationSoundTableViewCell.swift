//
//  NotificationSoundTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 15/07/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class NotificationSoundTableViewCell: UITableViewCell {
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var selectedLabel: UILabel!
    
    var sound: NotificationSoundHelper.Sound? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    override func setHighlighted(_ highlighted: Bool, animated: Bool) {
        super.setHighlighted(highlighted, animated: animated)
        
        if (highlighted) {
            self.contentView.backgroundColor = UIColor.Sphinx.ChatListSelected
        } else {
            self.contentView.backgroundColor = UIColor.Sphinx.HeaderBG
        }
    }
    
    func configure(sound: NotificationSoundHelper.Sound) {
        self.sound = sound
        
        nameLabel.text = sound.name
        selectedLabel.isHidden = !sound.selected
    }
}
