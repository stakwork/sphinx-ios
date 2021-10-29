//
//  NewsletterItemsSectionCollectionReusableView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 28/10/2021.
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit

class NewsletterItemsSectionCollectionReusableView: UICollectionReusableView {

    @IBOutlet weak var countLabel: UILabel!
    @IBOutlet weak var articlesLabel: UILabel!
    
    var itemsCount: Int! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                self?.updateViewsWithItemsCount()
            }
        }
    }
}

// MARK: - Static Properties
extension NewsletterItemsSectionCollectionReusableView {
    static let reuseID = "NewsletterItemsSectionCollectionReusableView"

    static let nib: UINib = {
        UINib(nibName: "NewsletterItemsSectionCollectionReusableView", bundle: nil)
    }()
}


// MARK: - Lifecycle
extension NewsletterItemsSectionCollectionReusableView {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }
}


// MARK: - Public Methods
extension NewsletterItemsSectionCollectionReusableView {

    func configure(
        withItemsCount itemsCount: Int
    ) {
        self.itemsCount = itemsCount
    }
}


// MARK: - Private Helpers
extension NewsletterItemsSectionCollectionReusableView {
    
    private func updateViewsWithItemsCount() {
        countLabel.text = "\(itemsCount ?? 0)"

        articlesLabel.text = (
            itemsCount == 1 ?
                "article"
                : "articles"
        )
        .localized
        .capitalized
    }
}
