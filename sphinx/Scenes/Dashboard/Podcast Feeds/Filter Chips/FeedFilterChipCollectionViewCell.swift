//
// FeedFilterChipCollectionViewCell.swift
// sphinx
//

import UIKit

protocol FeedFilterChipCollectionViewCellDelegate: class {

    func collectionViewCell(
        _ cell: FeedFilterChipCollectionViewCell,
        didSelectMediaType mediaType: String
    )
}


class FeedFilterChipCollectionViewCell: UICollectionViewCell {
    
    weak var delegate: FeedFilterChipCollectionViewCellDelegate?
    
    @IBOutlet weak var filterLabel: UILabel!
    
    
    var mediaType: String! {
        didSet {
            filterLabel.text = mediaType
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        contentView.layer.cornerRadius = contentView.frame.size.height / 2
    }
    
  
    func configure(withMediaType mediaType: String) {
        self.mediaType = mediaType
    }
}
