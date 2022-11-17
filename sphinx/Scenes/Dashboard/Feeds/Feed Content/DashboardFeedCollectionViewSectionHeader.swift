//
// DashboardFeedCollectionViewSectionHeader.swift
// sphinx


import UIKit


class DashboardFeedCollectionViewSectionHeader: UICollectionReusableView {
    @IBOutlet weak var sectionTitleLabel: UILabel!
    @IBOutlet weak var refreshButtonContainer: UIView!
    
    @IBAction func refreshButtonTapped() {
    }
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

    func render(
        withTitle title: String,
        refreshButton: Bool = false
    ) {
        sectionTitleLabel.text = title
        
        refreshButtonContainer.alpha = refreshButton ? 1.0 : 0.0
    }
}
