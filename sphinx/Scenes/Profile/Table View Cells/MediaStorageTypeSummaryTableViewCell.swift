//
//  MediaStorageTypeSummaryTableViewCell.swift
//  sphinx
//
//  Created by James Carucci on 5/22/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

protocol MediaStorageTypeSummaryTableViewCellDelegate : NSObject{
    func didTapDelete(type:StorageManagerMediaType)
}

class MediaStorageTypeSummaryTableViewCell: UITableViewCell {
    
    @IBOutlet weak var dotView: UIView!
    @IBOutlet weak var storageAmountLabel: UILabel!
    @IBOutlet weak var mediaTypeLabel: UILabel!
    
    
    var delegate : MediaStorageTypeSummaryTableViewCellDelegate? = nil
    var type: StorageManagerMediaType? = nil
    
    static let reuseID = "MediaStorageTypeSummaryTableViewCell"
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        self.storageAmountLabel.text = "0 MB"
        self.mediaTypeLabel.text = ""
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func finishSetup(){
        dotView.makeCircular()
        self.selectionStyle = .none
        bringSubviewToFront(self.mediaTypeLabel)
    }
    
    func setupAsMediaType(type:StorageManagerMediaType){
        self.type = type
        switch(type){
        case .audio:
            dotView.backgroundColor = UIColor(hex: "#FAE676")
            mediaTypeLabel.text = "Audio"
            break
            
        case .video:
            dotView.backgroundColor = UIColor(hex: "#A76CF3")
            mediaTypeLabel.text = "Videos"
            break
        case .photo:
            dotView.backgroundColor = UIColor.Sphinx.PrimaryBlue
            mediaTypeLabel.text = "Images"
            break
        }
    }
    
    
    @IBAction func deleteButtonTap(_ sender: Any) {
        handleDelete()
    }
    
    
    @objc func handleDelete(){
        if let type = type,
           let delegate = delegate{
            delegate.didTapDelete(type: type)
        }
    }
    
}
