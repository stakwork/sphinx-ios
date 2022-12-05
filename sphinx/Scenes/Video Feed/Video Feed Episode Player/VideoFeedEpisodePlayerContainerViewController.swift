// VideoFeedEpisodePlayerContainerViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    

import UIKit
import CoreData


protocol VideoFeedEpisodePlayerViewControllerDelegate: AnyObject {
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoFeedWithID videoFeedID: NSManagedObjectID
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoEpisodeWithID videoEpisodeID: NSManagedObjectID
    )
    
    func viewControllerShouldDismiss(
        _ viewController: UIViewController
    )
}


protocol VideoFeedEpisodePlayerViewController: UIViewController {
    var videoPlayerEpisode: Video! { get set }
}


class VideoFeedEpisodePlayerContainerViewController: UIViewController {
    
    @IBOutlet weak var playerViewContainer: UIView!
    @IBOutlet weak var collectionViewContainer: UIView!
    
    internal var managedObjectContext: NSManagedObjectContext!
    
    var videoPlayerEpisode: Video! {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard
                    let self = self,
                    let videoPlayerEpisode = self.videoPlayerEpisode
                else { return }
                
                self.collectionViewController
                    .updateWithNew(
                        videoPlayerEpisode: videoPlayerEpisode,
                        shouldAnimate: true
                    )
            }
        }
    }
    
    
    var dismissButtonStyle: ModalDismissButtonStyle!

    weak var delegate: VideoFeedEpisodePlayerViewControllerDelegate?
    weak var boostDelegate: CustomBoostDelegate?

    internal lazy var youtubeVideoPlayerViewController: YouTubeVideoFeedEpisodePlayerViewController = {
        YouTubeVideoFeedEpisodePlayerViewController.instantiate(
            videoPlayerEpisode: videoPlayerEpisode,
            dismissButtonStyle: dismissButtonStyle,
            onDismiss: { self.delegate?.viewControllerShouldDismiss(self) }
        )
    }()
    
    
    internal lazy var generalVideoPlayerViewController: GeneralVideoFeedEpisodePlayerViewController = {
        GeneralVideoFeedEpisodePlayerViewController.instantiate(
            videoPlayerEpisode: videoPlayerEpisode
        )
    }()
    
    
    internal lazy var collectionViewController: VideoFeedEpisodePlayerCollectionViewController = {
        VideoFeedEpisodePlayerCollectionViewController.instantiate(
            videoPlayerEpisode: videoPlayerEpisode,
            videoFeedEpisodes: videoFeedEpisodes,
            boostDelegate: boostDelegate,
            onVideoEpisodeCellSelected: handleVideoEpisodeCellSelection(_:)
        )
    }()
}


// MARK: -  Static Methods
extension VideoFeedEpisodePlayerContainerViewController {
    
    static func instantiate(
        videoPlayerEpisode: Video,
        dismissButtonStyle: ModalDismissButtonStyle,
        delegate: VideoFeedEpisodePlayerViewControllerDelegate,
        boostDelegate: CustomBoostDelegate,
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> VideoFeedEpisodePlayerContainerViewController {
        let viewController = StoryboardScene
            .VideoFeed
            .videoFeedEpisodePlayerContainerViewController
            .instantiate()
        
        viewController.videoPlayerEpisode = videoPlayerEpisode
        viewController.dismissButtonStyle = dismissButtonStyle
        viewController.delegate = delegate
        viewController.boostDelegate = boostDelegate
        viewController.managedObjectContext = managedObjectContext
        
        return viewController
    }
}


// MARK: -  Lifecycle
extension VideoFeedEpisodePlayerContainerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePlayerView()
        configureCollectionView()
        
        updateEpisodes()
    }
}


// MARK: -  Computeds
extension VideoFeedEpisodePlayerContainerViewController {
    
    
    private var videoFeedEpisodes: [Video] {
        videoPlayerEpisode.videoFeed?.videosArray ?? []
    }
    
    private var isVideoFromYouTubeFeed: Bool {
        guard let videoFeed = videoPlayerEpisode.videoFeed else { return false }
        
        return videoFeed.isYouTubeFeed
    }
    
    private var currentVideoPlayerViewController: VideoFeedEpisodePlayerViewController {
        isVideoFromYouTubeFeed ?
            youtubeVideoPlayerViewController
            : generalVideoPlayerViewController
    }
}


// MARK: -  Private Helpers
extension VideoFeedEpisodePlayerContainerViewController {
    
    private func configurePlayerView() {
        addChildVC(
            child: currentVideoPlayerViewController,
            container: playerViewContainer
        )
    }

    private func configureCollectionView() {
        addChildVC(
            child: collectionViewController,
            container: collectionViewContainer
        )
    }
}


// MARK: -  Action Handling
extension VideoFeedEpisodePlayerContainerViewController {
    
    private func handleVideoEpisodeCellSelection(
        _ managedObjectID: NSManagedObjectID
    ) {
        guard
            let selectedFeedItem = managedObjectContext.object(with: managedObjectID) as? ContentFeedItem
        else {
            preconditionFailure()
        }
        
        if let contentFeed = selectedFeedItem.contentFeed {
            
            let videoFeed = VideoFeed.convertFrom(contentFeed:  contentFeed)
            let selectedEpisode = Video.convertFrom(contentFeedItem: selectedFeedItem, videoFeed: videoFeed)
            
            if selectedEpisode != videoPlayerEpisode {
                videoPlayerEpisode = selectedEpisode
                currentVideoPlayerViewController.videoPlayerEpisode = videoPlayerEpisode
                
                delegate?.viewController(
                    self,
                    didSelectVideoEpisodeWithID: managedObjectID
                )
            }
        }
    }
    
    
    private func updateEpisodes() {
        if  let videoFeed = self.videoPlayerEpisode?.videoFeed,
            let feedUrl = videoFeed.feedURL?.absoluteString {
            
            ContentFeed.fetchFeedItemsInBackground(feedUrl: feedUrl, contentFeedObjectID: videoFeed.objectID, completion: {})
        }
    }
}
