//
// FeedFilterChipCollectionViewCell.swift
// sphinx
//

import UIKit


class FeedFilterChipCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var filterLabel: UILabel!
    
    
    var mediaType: String! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithItem()
            }
        }
    }
    
    var isMediaTypeActive: Bool = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsFromActiveState()
            }
        }
    }
    

    override func awakeFromNib() {
        super.awakeFromNib()
  
        contentView.clipsToBounds = true

        contentView.layer.cornerRadius = max(
            contentView.frame.height,
            contentView.frame.width
        ) / 2.0
        
        contentView.layer.cornerCurve = .continuous
    }
    
    
    func configure(withMediaType mediaType: String) {
        self.mediaType = mediaType
    }
    
    
    private func updateViewsWithItem() {
        filterLabel.text = mediaType
    }
    
    
    private func updateViewsFromActiveState() {
        contentView.backgroundColor = isMediaTypeActive ?
            .Sphinx.BodyInverted
            : .Sphinx.DashboardFilterChipBackground
        
        filterLabel.textColor = isMediaTypeActive ?
            .Sphinx.DashboardFilterChipActiveText
            : .Sphinx.BodyInverted
    }
}


// MARK: - Static Properties
extension FeedFilterChipCollectionViewCell {
    static let reuseID = "FeedFilterChipCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "FeedFilterChipCollectionViewCell", bundle: nil)
    }()
}
