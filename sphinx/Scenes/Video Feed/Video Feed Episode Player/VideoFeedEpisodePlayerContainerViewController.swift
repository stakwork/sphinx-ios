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
        managedObjectContext: NSManagedObjectContext = CoreDataManager.sharedManager.persistentContainer.viewContext
    ) -> VideoFeedEpisodePlayerContainerViewController {
        let viewController = StoryboardScene
            .VideoFeed
            .videoFeedEpisodePlayerContainerViewController
            .instantiate()
        
        viewController.videoPlayerEpisode = videoPlayerEpisode
        viewController.dismissButtonStyle = dismissButtonStyle
        viewController.delegate = delegate
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
        
        updateEpisodesInBackground()
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
            let selectedEpisode = managedObjectContext.object(with: managedObjectID) as? Video
        else {
            preconditionFailure()
        }
        
        if selectedEpisode != videoPlayerEpisode {
            videoPlayerEpisode = selectedEpisode
            currentVideoPlayerViewController.videoPlayerEpisode = videoPlayerEpisode
            
            delegate?.viewController(
                self,
                didSelectVideoEpisodeWithID: managedObjectID
            )
        }
    }
    
    
    private func updateEpisodesInBackground() {
        DispatchQueue
            .global(qos: .utility)
            .async { [weak self] in
                guard
                    let self = self,
                    let videoFeed = self.videoPlayerEpisode.videoFeed,
                    let feedURL = videoFeed.feedURL
                else { return }

                let tribesServerURL = "\(API.kTestTribesServerBaseURL)/feed?url=\(feedURL.absoluteString)"

                API.sharedInstance.getContentFeed(
                    url: tribesServerURL,
                    callback: { contentFeed in
                        videoFeed.addToVideos(
                            Set(
                                contentFeed
                                    .items?
                                    .map(Video.convertedFrom(contentFeedItem:))
                                ?? []
                            )
                        )
                    },
                    errorCallback: {
                        print("Failed to fetch video entry data for feed.")
                    }
                )
        }
    }
}
