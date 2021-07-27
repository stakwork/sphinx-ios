//
// FeedFilterChipDataSource.swift
// sphinx


import UIKit

class FeedFilterChipDataSource: NSObject {
    weak var cellDelegate: FeedFilterChipCollectionViewCellDelegate?
    
    var collectionView: UICollectionView
    var mediaTypes: [String]
    
    
    let kCellHeight: CGFloat = 88.0
    let kCellWidth: CGFloat = 108.0
    
    
    init(
        collectionView: UICollectionView,
        mediaTypes: [String],
        cellDelegate: FeedFilterChipCollectionViewCellDelegate
    ) {
        self.cellDelegate = cellDelegate
        self.mediaTypes = mediaTypes
        self.collectionView = collectionView

        super.init()
        
        self.collectionView.contentInset = UIEdgeInsets(
            top: 0,
            left: 12,
            bottom: 0,
            right: 12
        )
    }
}


extension FeedFilterChipDataSource: UICollectionViewDelegate {
    
    func collectionView(
        _ collectionView: UICollectionView,
        willDisplay cell: UICollectionViewCell,
        forItemAt indexPath: IndexPath
    ) {
        if let cell = cell as? FeedFilterChipCollectionViewCell {
            let mediaType = mediaTypes[indexPath.row]
            
            cell.delegate = cellDelegate
            cell.configure(withMediaType: mediaType)
        }
    }
    
    
    func collectionView(
        _ collectionView: UICollectionView,
        didSelectItemAt indexPath: IndexPath
    ) {
        guard let cell = collectionView.cellForItem(at: indexPath) as? FeedFilterChipCollectionViewCell else { return }
        
        let mediaType = mediaTypes[indexPath.row]

        cellDelegate?.collectionViewCell(
            cell,
            didSelectMediaType: mediaType
        )
    }
}


extension FeedFilterChipDataSource: UICollectionViewDelegateFlowLayout {
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        CGSize(width: kCellWidth, height: kCellHeight)
    }
    
    
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        .zero
    }
}


extension FeedFilterChipDataSource: UICollectionViewDataSource {
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        collectionView.dequeueReusableCell(
            withReuseIdentifier: "FeedFilterChipCollectionViewCell",
            for: indexPath
        ) as! FeedFilterChipCollectionViewCell
    }
    

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }
    
    
    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        mediaTypes.count
    }
}
