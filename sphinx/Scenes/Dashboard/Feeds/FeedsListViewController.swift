//
//  FeedsListViewController.swift
//  FeedsListViewController
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit

class FeedsListViewController: UIViewController {
    @IBOutlet weak var feedFilterChipCollectionView: UICollectionView!
    @IBOutlet weak var feedContentChipCollectionView: UICollectionView!
    
    
    var feedFilterChipDataSource: FeedFilterChipDataSource!
    
    // TODO: These should probably be strongly-typed and dynamically generated in some way.
    var mediaTypes: [String] = []


    static func instantiate() -> FeedsListViewController {
        let viewController = StoryboardScene.Dashboard.feedsListViewController.instantiate()
        
        return viewController
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        loadData()
        configureCollectionView()
    }
}


// MARK: -  Private Helpers

extension FeedsListViewController {
    
    private func loadData() {
        mediaTypes = getFeedMediaTypes()
    }

    
    // TODO: These should probably be strongly-typed and dynamically generated in some way.
    private func getFeedMediaTypes() -> [String] {
        [
            "All",
            "Listen",
            "Watch",
            "Read",
            "Play",
        ]
    }
    
    
    private func configureCollectionView() {
        feedFilterChipCollectionView.registerCell(FeedFilterChipCollectionViewCell.self)
        
        feedFilterChipDataSource = FeedFilterChipDataSource(
            collectionView: feedFilterChipCollectionView,
            mediaTypes: mediaTypes,
            cellDelegate: self
        )
        
        feedFilterChipCollectionView.delegate = feedFilterChipDataSource
        feedFilterChipCollectionView.dataSource = feedFilterChipDataSource
        feedFilterChipCollectionView.reloadData()
    }
}


extension FeedsListViewController: FeedFilterChipCollectionViewCellDelegate {
    
    func collectionViewCell(
        _ cell: FeedFilterChipCollectionViewCell,
        didSelectMediaType mediaType: String
    ) {
        AlertHelper.showAlert(title: "Selected Media Type", message: mediaType)
    }
}
