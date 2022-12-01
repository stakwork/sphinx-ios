//
// DashboardFeedCollectionViewSectionHeader.swift
// sphinx


import UIKit

protocol DashboardFeedHeaderDelegate: class {
    func didTapOnRefresh()
}


class DashboardFeedCollectionViewSectionHeader: UICollectionReusableView {
    
    @IBOutlet weak var sectionTitleLabel: UILabel!
    @IBOutlet weak var refreshButtonContainer: UIView!
    
    weak var delegate: DashboardFeedHeaderDelegate?
    
    @IBAction func refreshButtonTapped() {
        delegate?.didTapOnRefresh()
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
        delegate: DashboardFeedHeaderDelegate? = nil,
        refreshButton: Bool = false
    ) {
        self.delegate = delegate
        
        sectionTitleLabel.text = title
        
        refreshButtonContainer.alpha = refreshButton ? 1.0 : 0.0
    }
}
