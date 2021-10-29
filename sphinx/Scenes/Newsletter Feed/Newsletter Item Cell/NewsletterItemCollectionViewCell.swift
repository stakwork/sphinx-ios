//
//  NewsletterItemCollectionViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit

class NewsletterItemCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var itemTitleLabel: UILabel!
    @IBOutlet weak var itemDescriptionLabel: UILabel!
    @IBOutlet weak var itemDateLabel: UILabel!
    @IBOutlet weak var itemImageView: UIImageView!
    
    var newsletterItem: NewsletterItem! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithNewsletterItem()
            }
        }
    }
}

// MARK: - Static Properties
extension NewsletterItemCollectionViewCell {
    
    static let reuseID = "NewsletterItemCollectionViewCell"
    
    static let nib: UINib = {
        UINib(nibName: "NewsletterItemCollectionViewCell", bundle: nil)
    }()
}


// MARK: - Computeds
extension NewsletterItemCollectionViewCell {
    
    var imageViewURL: URL? {
        if let url = newsletterItem.newsletterFeed?.imageURL {
            return url
        } else if let chatUrl = newsletterItem.newsletterFeed?.chat?.photoUrl, let url = URL(string: chatUrl) {
            return url
        }
        return nil
    }
}


// MARK: - Lifecycle
extension NewsletterItemCollectionViewCell {
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}
 

// MARK: - Public Methods
extension NewsletterItemCollectionViewCell {
    
    func configure(withNewsletterItem newsletterItem: NewsletterItem) {
        self.newsletterItem = newsletterItem
    }
}


// MARK: - Private Helpers
extension NewsletterItemCollectionViewCell {
    
    private func updateViewsWithNewsletterItem() {
        if let imageURL = imageViewURL {
            itemImageView.sd_setImage(
                with: imageURL,
                placeholderImage: UIImage(named: "podcastPlaceholder"),
                options: [.highPriority],
                progress: nil
            )
        } else {
            // 📝 TODO:  Use a newsletter placeholder here
            itemImageView.image = UIImage(named: "podcastPlaceholder")
        }


        itemTitleLabel.text = newsletterItem.titleForDisplay
        itemDescriptionLabel.text = newsletterItem.itemDescription
        itemDateLabel.text = newsletterItem.publishDateText
    }
}
