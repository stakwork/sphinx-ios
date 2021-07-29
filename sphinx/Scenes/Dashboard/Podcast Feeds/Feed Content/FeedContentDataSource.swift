////
//// FeedContentDataSource.swift
//// sphinx
////
//
//
//import UIKit
//
//class FeedContentDataSource: NSObject {
//    weak var cellDelegate: PodcastFeedCollectionViewCellDelegate?
//
//    var collectionView: UICollectionView
//    var newEpisodePodcastFeeds: [PodcastFeed]
//    var subscribedPodcastFeeds: [PodcastFeed]
//
//
//    let kCellWidth: CGFloat = 160.0
//    let kCellHeight: CGFloat = 240.0
//
//
//    init(
//        collectionView: UICollectionView,
//        newEpisodePodcastFeeds: [PodcastFeed],
//        subscribedPodcastFeeds: [PodcastFeed],
//        cellDelegate: PodcastFeedCollectionViewCellDelegate
//    ) {
//        self.cellDelegate = cellDelegate
//        self.newEpisodePodcastFeeds = newEpisodePodcastFeeds
//        self.subscribedPodcastFeeds = subscribedPodcastFeeds
//        self.collectionView = collectionView
//
//        super.init()
//
//        self.collectionView.contentInset = UIEdgeInsets(
//            top: 0,
//            left: 16,
//            bottom: 0,
//            right: 16
//        )
//    }
//}
//
//
//extension FeedContentDataSource: UICollectionViewDelegate {
//
//    func collectionView(
//        _ collectionView: UICollectionView,
//        willDisplay cell: UICollectionViewCell,
//        forItemAt indexPath: IndexPath
//    ) {
//        guard
//            let cell = cell as? PodcastFeedCollectionViewCell,
//            indexPath.section == 0 || indexPath.section == 1
//        else { return }
//
//        var podcastFeeds: [PodcastFeed]
//
//        switch indexPath.section {
//        case 0:
//            podcastFeeds = newEpisodePodcastFeeds
//        case 1:
//            podcastFeeds = subscribedPodcastFeeds
//        default:
//            preconditionFailure()
//        }
//
//        let podcastFeed = podcastFeeds[indexPath.row]
//
//        cell.delegate = cellDelegate
//        cell.configure(withPodcastFeed: podcastFeed)
//    }
//
//
//    func collectionView(
//        _ collectionView: UICollectionView,
//        didSelectItemAt indexPath: IndexPath
//    ) {
//        guard
//            let cell = collectionView.cellForItem(at: indexPath) as? PodcastFeedCollectionViewCell,
//            indexPath.section == 0 || indexPath.section == 1
//        else { return }
//
//        var podcastFeeds: [PodcastFeed]
//
//        switch indexPath.section {
//        case 0:
//            podcastFeeds = newEpisodePodcastFeeds
//        case 1:
//            podcastFeeds = subscribedPodcastFeeds
//        default:
//            preconditionFailure()
//        }
//
//        let podcastFeed = podcastFeeds[indexPath.row]
//
//        cellDelegate?.collectionViewCell(
//            cell,
//            didSelect: podcastFeed
//        )
//    }
//
//
//    func collectionView(
//        _ collectionView: UICollectionView,
//        viewForSupplementaryElementOfKind kind: String,
//        at indexPath: IndexPath
//    ) -> UICollectionReusableView {
//        if let sectionHeader = collectionView
//            .dequeueReusableSupplementaryView(
//                ofKind: kind,
//                withReuseIdentifier: "PodcastFeedCollectionViewSectionHeader",
//                for: indexPath
//            ) as? PodcastFeedCollectionViewSectionHeader {
//                sectionHeader.sectionTitleLabel.text = "Section \(indexPath.section)"
//
//                return sectionHeader
//        }
//
//        return UICollectionReusableView()
//    }
//
//
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
//        CGSize(width: collectionView.frame.size.width, height: 44)
//    }
//
//
//
//}
//
//
//extension FeedContentDataSource: UICollectionViewDelegateFlowLayout {
//
//    func collectionView(
//        _ collectionView: UICollectionView,
//        layout collectionViewLayout: UICollectionViewLayout,
//        sizeForItemAt indexPath: IndexPath
//    ) -> CGSize {
//        CGSize(width: kCellWidth, height: kCellHeight)
//    }
//
//
//    func collectionView(
//        _ collectionView: UICollectionView,
//        layout collectionViewLayout: UICollectionViewLayout,
//        minimumLineSpacingForSectionAt section: Int
//    ) -> CGFloat {
//        22.0
//    }
//}
//
//
//extension FeedContentDataSource: UICollectionViewDataSource {
//
//    func collectionView(
//        _ collectionView: UICollectionView,
//        cellForItemAt indexPath: IndexPath
//    ) -> UICollectionViewCell {
//        collectionView.dequeueReusableCell(
//            withReuseIdentifier: "PodcastFeedCollectionViewCell",
//            for: indexPath
//        ) as! PodcastFeedCollectionViewCell
//    }
//
//
//    func numberOfSections(in collectionView: UICollectionView) -> Int {
//        2
//    }
//
//
//    func collectionView(
//        _ collectionView: UICollectionView,
//        numberOfItemsInSection section: Int
//    ) -> Int {
//        switch section {
//        case 0:
//            return newEpisodePodcastFeeds.count
//        case 1:
//            return subscribedPodcastFeeds.count
//        default:
//            preconditionFailure()
//        }
//    }
//
//
//}
