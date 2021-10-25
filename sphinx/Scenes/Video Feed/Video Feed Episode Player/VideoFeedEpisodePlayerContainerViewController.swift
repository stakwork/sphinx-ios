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
    

    internal lazy var playerViewController: VideoFeedEpisodePlayerViewController = {
        VideoFeedEpisodePlayerViewController.instantiate(
            videoPlayerEpisode: videoPlayerEpisode,
            dismissButtonStyle: dismissButtonStyle,
            onDismiss: { self.delegate?.viewControllerShouldDismiss(self) }
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
}


// MARK: -  Private Helpers
extension VideoFeedEpisodePlayerContainerViewController {
    
    private func configurePlayerView() {
        addChildVC(
            child: playerViewController,
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
            playerViewController.videoPlayerEpisode = videoPlayerEpisode
            
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
                    let videoFeed = self.videoPlayerEpisode.videoFeed
                else { return }
                
                API.sharedInstance.fetchYouTubeEpisodes(
                    for: videoFeed,
                    then: { result in
                        switch result {
                        case .success(let videoEpisodes):
                            videoFeed.videos = Set(videoEpisodes)

                            let updatedEpisode = videoFeed
                                .videos?
                                .first(where: { $0.id == self.videoPlayerEpisode.id })
                            
                            self.videoPlayerEpisode = updatedEpisode
                        case .failure(let error):
                            print("Failed to fetch video entry data for feed. Error: \(error)")
                        }
                    }
                )
        }
    }
}
