//
//  GroupTagCollectionViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class GroupTagCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var groupTagView: UIView!
    let tagView = AddedTagCell()
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        groupTagView.addSubview(tagView)
        tagView.anchor(top: groupTagView.topAnchor,
                       trailing: groupTagView.trailingAnchor,
                       bottom: groupTagView.bottomAnchor,
                       leading: groupTagView.leadingAnchor)
    }
    
    func configureWith(tag: GroupsManager.Tag) {
        tagView.configureWith(tag: tag.description)
    }

}
