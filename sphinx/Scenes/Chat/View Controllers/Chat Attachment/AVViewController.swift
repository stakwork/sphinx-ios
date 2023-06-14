//
//  AVViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 13/02/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

protocol PresentedViewDelegate: class {
    func didDismissPresentedView()
}

class AVViewController: AVPlayerViewController {
    
    weak var viewDelegate: PresentedViewDelegate?
    
    var data: Data!
    
    static func instantiate(
        data: Data,
        delegate: PresentedViewDelegate? = nil
    ) -> AVViewController {
        
        let viewController = StoryboardScene.Chat.avViewController.instantiate()
        viewController.data = data
        viewController.viewDelegate = delegate
        
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let playerItem = CachingPlayerItem(data: data, mimeType: "video/mp4", fileExtension: "mp4")
        self.player = AVPlayer(playerItem: playerItem)
        self.player?.automaticallyWaitsToMinimizeStalling = false
        self.player?.play()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        viewDelegate?.didDismissPresentedView()
    }
}
