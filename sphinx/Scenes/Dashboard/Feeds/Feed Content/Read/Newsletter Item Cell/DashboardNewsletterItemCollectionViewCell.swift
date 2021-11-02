//
//  DashboardNewsletterItemCollectionViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit

class DashboardNewsletterItemCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var shadowContainer: UIView!
    @IBOutlet weak var itemImageView: UIImageView!
    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var itemDescriptionLabel: UILabel!
    @IBOutlet weak var itemIcon: UIImageView!
    @IBOutlet weak var itemDateLabel: UILabel!
    
    var newsletterItem: NewsletterItem! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithNewsletterItem()
            }
        }
    }

}

// MARK: - Static Properties
extension DashboardNewsletterItemCollectionViewCell {
    static let reuseID = "DashboardNewsletterItemCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "DashboardNewsletterItemCollectionViewCell", bundle: nil)
    }()
}
    

// MARK: - Lifecycle
extension DashboardNewsletterItemCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupViews()
    }
}


// MARK: -  Public Methods
extension DashboardNewsletterItemCollectionViewCell {
    
    func configure(withNewsletterItem newsletterItem: NewsletterItem) {
        self.newsletterItem = newsletterItem
    }
}

// MARK: - Private Helpers
extension DashboardNewsletterItemCollectionViewCell {
    
    private func setupViews() {
        shadowContainer.addShadow(location: .center, opacity: 0.3, radius: 3)
        
        shadowContainer.layer.cornerRadius = 8.0
        shadowContainer.layer.masksToBounds = true
        shadowContainer.clipsToBounds = true

        itemIcon.makeCircular()
    }
    
    
    private func updateViewsWithNewsletterItem() {
        if let imageUrl = newsletterItem.newsletterFeed?.imageURL {
            
            itemImageView.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
            
            itemIcon.sd_setImage(
                with: imageUrl,
                placeholderImage: UIImage(named: "profile_avatar"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            itemImageView.image = UIImage(named: "podcastPlaceholder")
            itemIcon.image = UIImage(named: "profile_avatar")
        }

        itemTitleLabel.text = newsletterItem.title
        itemDescriptionLabel.text = newsletterItem.itemDescription
        itemDateLabel.text = newsletterItem.datePublished?.getStringFromDate(format: "MMM dd, yyyy")
    }
}
