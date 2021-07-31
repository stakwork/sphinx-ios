//
// FeedFilterChipCollectionViewCell.swift
// sphinx
//

import UIKit


class FeedFilterChipCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var filterLabel: UILabel!
    
    
    var filterOption: FeedsListViewController.ContentFilterOption! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithItem()
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
  
        contentView.clipsToBounds = true
        contentView.layer.cornerCurve = .continuous
    }
    
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        
        contentView.layer.cornerRadius = max(
            contentView.frame.height,
            contentView.frame.width
        ) / 2.0
    }
    
    override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
        let modifiedAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)
        
        modifiedAttributes.frame.size = contentView
            .systemLayoutSizeFitting(
                targetSize, withHorizontalFittingPriority: .defaultLow,
                verticalFittingPriority: .required
            )
        
        return modifiedAttributes
    }
    
    
    private func updateViewsWithItem() {
        filterLabel.text = filterOption.titleForDisplay
        
        contentView.backgroundColor = filterOption.isActive ?
            .Sphinx.BodyInverted
            : .Sphinx.DashboardFilterChipBackground
        
        filterLabel.textColor = filterOption.isActive ?
            .Sphinx.DashboardFilterChipActiveText
            : .Sphinx.BodyInverted
    }
    
    
    private func updateViewsFromActiveState() {
        contentView.backgroundColor = filterOption.isActive ?
            .Sphinx.BodyInverted
            : .Sphinx.DashboardFilterChipBackground
        
        filterLabel.textColor = filterOption.isActive ?
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
