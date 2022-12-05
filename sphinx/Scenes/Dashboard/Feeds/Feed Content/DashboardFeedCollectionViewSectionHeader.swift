//
// DashboardFeedCollectionViewSectionHeader.swift
// sphinx


import UIKit


class DashboardFeedCollectionViewSectionHeader: UICollectionReusableView {
    @IBOutlet weak var sectionTitleLabel: UILabel!
}


// MARK: - Static Properties
extension DashboardFeedCollectionViewSectionHeader {
    static let reuseID = "DashboardFeedCollectionViewSectionHeader"

    static let nib: UINib = {
        UINib(nibName: "DashboardFeedCollectionViewSectionHeader", bundle: nil)
    }()
}


// MARK: - Lifecycle
extension DashboardFeedCollectionViewSectionHeader {

    override func awakeFromNib() {
        super.awakeFromNib()
    }
}


// MARK: - Public Methods
extension DashboardFeedCollectionViewSectionHeader {

    func render(withTitle title: String) {
        sectionTitleLabel.text = title
    }
}
