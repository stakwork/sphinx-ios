// FeedSearchResultsCollectionViewSectionHeader.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class FeedSearchResultsCollectionViewSectionHeader: UICollectionReusableView {
    @IBOutlet weak var sectionTitleLabel: UILabel!
}


// MARK: - Static Properties
extension FeedSearchResultsCollectionViewSectionHeader {
    static let reuseID = "FeedSearchResultsCollectionViewSectionHeader"

    static let nib: UINib = {
        UINib(nibName: "FeedSearchResultsCollectionViewSectionHeader", bundle: nil)
    }()
}


// MARK: - Lifecycle
extension FeedSearchResultsCollectionViewSectionHeader {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}


// MARK: - Public Methods
extension FeedSearchResultsCollectionViewSectionHeader {

    func render(withTitle title: String) {
        sectionTitleLabel.text = title.uppercased()
    }
}


// MARK: - Event Handling
private extension FeedSearchResultsCollectionViewSectionHeader {
}
