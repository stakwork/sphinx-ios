//
//  GroupTagCollectionViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/05/2020.
//  Copyright © 2020 Tomas Timinskas. All rights reserved.
//

import UIKit

class GroupTagCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var groupTagView: GroupTagView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func configureWith(tag: GroupsManager.Tag) {
        groupTagView.configureWith(tag: tag)
    }

}
