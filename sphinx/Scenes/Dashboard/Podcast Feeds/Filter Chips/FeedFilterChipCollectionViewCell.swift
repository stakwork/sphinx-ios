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
    
    var isFilterOptionActive: Bool = false {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsFromActiveState()
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
    
    
    private func updateViewsWithItem() {
        filterLabel.text = filterOption.titleForDisplay
    }
    
    
    private func updateViewsFromActiveState() {
        contentView.backgroundColor = isFilterOptionActive ?
            .Sphinx.BodyInverted
            : .Sphinx.DashboardFilterChipBackground
        
        filterLabel.textColor = isFilterOptionActive ?
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
