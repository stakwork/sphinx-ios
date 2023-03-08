//
//  KnownBadgeCell.swift
//  sphinx
//
//  Created by James Carucci on 2/2/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

class KnownBadgeCell: UITableViewCell {

    @IBOutlet weak var knownBadgeImageView: UIImageView!
    @IBOutlet weak var knownBadgeNameLabel: UILabel!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell(badge:Badge){
        let bitmapSize = CGSize(width: 500, height: 500)
        let defaultImage = #imageLiteral(resourceName: "appPinIcon")
        
        knownBadgeImageView.sd_setImage(
            with: URL(string: badge.icon_url ?? ""),
            placeholderImage: defaultImage,
            options: [],
            context: [.imageThumbnailPixelSize : bitmapSize]
        )
        
        knownBadgeImageView.makeCircular()
        
        knownBadgeNameLabel.text = badge.name
    }
    
}


// MARK: - Static Properties
extension KnownBadgeCell {
    static let reuseID = "KnownBadgeCell"
    
    static let nib: UINib = {
        UINib(nibName: "KnownBadgeCell", bundle: nil)
    }()
    
}
