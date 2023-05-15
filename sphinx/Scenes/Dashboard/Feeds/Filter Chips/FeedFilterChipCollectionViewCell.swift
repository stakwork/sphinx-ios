//
// FeedFilterChipCollectionViewCell.swift
// sphinx
//

import UIKit


class FeedFilterChipCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var filterLabel: UILabel!
    
    
    var filterOption: DashboardFeedsContainerViewController.ContentFilterOption! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsFromItemState()
            }
        }
    }

    
    override func awakeFromNib() {
        super.awakeFromNib()

        contentView.layer.masksToBounds = true
        contentView.clipsToBounds = true
        contentView.layer.cornerCurve = .continuous
        
        setCornerRadius()
        filterLabel.text = ""
        contentView.backgroundColor = .Sphinx.DashboardFilterChipBackground
        filterLabel.textColor = .Sphinx.Text
    }
    

    override func preferredLayoutAttributesFitting(
        _ layoutAttributes: UICollectionViewLayoutAttributes
    ) -> UICollectionViewLayoutAttributes {
        let targetSize = CGSize(width: layoutAttributes.frame.width, height: 0)
        let modifiedAttributes = super.preferredLayoutAttributesFitting(layoutAttributes)

        modifiedAttributes.frame.size = contentView
            .systemLayoutSizeFitting(
                targetSize, withHorizontalFittingPriority: .defaultLow,
                verticalFittingPriority: .required
            )

        return modifiedAttributes
    }

    
    private func updateViewsFromItemState() {
        setCornerRadius()
        
        filterLabel.text = filterOption.titleForDisplay
        
        contentView.backgroundColor = filterOption.isActive ?
            .Sphinx.Text
            : .Sphinx.DashboardFilterChipBackground
        
        filterLabel.textColor = filterOption.isActive ?
            .Sphinx.TextInverted
            : .Sphinx.Text
    }
    
    private func setCornerRadius() {
        let cornerRadius =  min(
            contentView.frame.height,
            contentView.frame.width
        ) / 2.0
        
        contentView.layer.cornerRadius = cornerRadius
    }
}


// MARK: - Static Properties
extension FeedFilterChipCollectionViewCell {
    static let reuseID = "FeedFilterChipCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "FeedFilterChipCollectionViewCell", bundle: nil)
    }()
}
