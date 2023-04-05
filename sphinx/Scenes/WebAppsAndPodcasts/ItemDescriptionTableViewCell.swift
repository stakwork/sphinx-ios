//
//  ItemDescriptionTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 4/4/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol ItemDescriptionTableViewCellDelegate{
    func didExpandCell()
}

class ItemDescriptionTableViewCell: UITableViewCell {
    @IBOutlet weak var showMoreButton: UIButton!
    @IBOutlet weak var podcastDescriptionLabel: UILabel!
    var delegate:ItemDescriptionTableViewCellDelegate?=nil
    
    static let reuseID = "ItemDescriptionTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureView(descriptionText:String,isExpanded:Bool){
        if(isExpanded){
            podcastDescriptionLabel.text = descriptionText
            podcastDescriptionLabel.numberOfLines = 0
            showMoreButton.isHidden = true
        }
        else{
            podcastDescriptionLabel.text = descriptionText
            podcastDescriptionLabel.numberOfLines = 5
            podcastDescriptionLabel.lineBreakMode = .byTruncatingTail
            showMoreButton.isHidden = false
        }
    }
    
    
    @IBAction func showMoreTapped(_ sender: Any) {
        delegate?.didExpandCell()
    }
    
}
