//
// PodcastFeedCollectionViewSectionHeader.swift
// sphinx


import UIKit


class PodcastFeedCollectionViewSectionHeader: UICollectionReusableView {
    @IBOutlet weak var sectionTitleLabel: UILabel!
}


// MARK: - Static Properties
extension PodcastFeedCollectionViewSectionHeader {
    static let reuseID = "PodcastFeedCollectionViewSectionHeader"

    static let nib: UINib = {
        UINib(nibName: "PodcastFeedCollectionViewSectionHeader", bundle: nil)
    }()
}


// MARK: - Lifecycle
extension PodcastFeedCollectionViewSectionHeader {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}


// MARK: - Public Methods
extension PodcastFeedCollectionViewSectionHeader {

    func render(withTitle title: String) {
        sectionTitleLabel.text = title
    }
}
