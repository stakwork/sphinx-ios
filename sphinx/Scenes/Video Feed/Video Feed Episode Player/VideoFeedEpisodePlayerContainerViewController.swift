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
        didSelectVideoFeedWithID videoFeedID: String
    )
    
    func viewController(
        _ viewController: UIViewController,
        didSelectVideoEpisodeWithID videoEpisodeID: String
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
    
    var deeplinkedTimestamp : Int? = nil
    
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

    lazy var youtubeVideoPlayerViewController: YouTubeVideoFeedEpisodePlayerViewController = {
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
        let vc = VideoFeedEpisodePlayerCollectionViewController.instantiate(
            videoPlayerEpisode: videoPlayerEpisode,
            videoFeedEpisodes: videoFeedEpisodes,
            boostDelegate: boostDelegate,
            onVideoEpisodeCellSelected: handleVideoEpisodeCellSelection(_:)
        )
        vc.delegate = self
        return vc
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
        
        updateFeed()
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5, execute: {
            if let timestamp = self.deeplinkedTimestamp{
                self.youtubeVideoPlayerViewController.startPlay()
            }
        })
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0, execute: {
            if let timestamp = self.deeplinkedTimestamp{
                self.youtubeVideoPlayerViewController.seekTo(time: timestamp)
            }
        })
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
        _ feeditemId: String
    ) {
        guard
            let selectedFeedItem = ContentFeedItem.getItemWith(itemID: feeditemId)
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
                    didSelectVideoEpisodeWithID: feeditemId
                )
            }
        }
    }
    
    
    private func updateFeed() {
        if  let videoFeed = self.videoPlayerEpisode?.videoFeed,
            let feedUrl = videoFeed.feedURL?.absoluteString {
            
            FeedsManager.sharedInstance.fetchItemsFor(feedUrl: feedUrl, feedId: videoFeed.id)
        }
    }
}

extension VideoFeedEpisodePlayerContainerViewController:VideoFeedEpisodePlayerCollectionViewControllerDelegate{
    func requestPlay() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.25, execute: {
            self.youtubeVideoPlayerViewController.startPlay()
        })
    }
}
