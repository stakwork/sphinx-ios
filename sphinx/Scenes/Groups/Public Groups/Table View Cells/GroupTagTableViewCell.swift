//
//  GroupTagTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class GroupTagTableViewCell: UITableViewCell {

    @IBOutlet weak var groupTagView: GroupTagView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureWith(tag: GroupsManager.Tag) {
        groupTagView.configureWith(tag: tag)
    }
    
}
