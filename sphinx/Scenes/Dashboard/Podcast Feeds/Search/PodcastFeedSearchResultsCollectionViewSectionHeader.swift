// PodcastFeedSearchResultsCollectionViewSectionHeader.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit


class PodcastFeedSearchResultsCollectionViewSectionHeader: UICollectionReusableView {
    @IBOutlet weak var sectionTitleLabel: UILabel!
}


// MARK: - Static Properties
extension PodcastFeedSearchResultsCollectionViewSectionHeader {
    static let reuseID = "PodcastFeedSearchResultsCollectionViewSectionHeader"

    static let nib: UINib = {
        UINib(nibName: "PodcastFeedSearchResultsCollectionViewSectionHeader", bundle: nil)
    }()
}


// MARK: - Lifecycle
extension PodcastFeedSearchResultsCollectionViewSectionHeader {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}


// MARK: - Public Methods
extension PodcastFeedSearchResultsCollectionViewSectionHeader {

    func render(withTitle title: String) {
        sectionTitleLabel.text = title
    }
}


// MARK: - Event Handling
private extension PodcastFeedSearchResultsCollectionViewSectionHeader {

    @IBAction func trailingButtonTapped() {
    }
}
