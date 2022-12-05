//
//  RestoreUserConnectingViewController.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import SDWebImage

class RestoreUserConnectingViewController: UIViewController {
    @IBOutlet weak var connectingGIFImageView: UIImageView!
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var connectingLabel: UILabel!
    
    
    private var rootViewController: RootViewController!

    
    static func instantiate(
        rootViewController: RootViewController
    ) -> RestoreUserConnectingViewController {
        let viewController = StoryboardScene.RestoreUser.restoreUserConnectingViewController.instantiate()
        
        viewController.rootViewController = rootViewController
        
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectingLabel.text = "welcome.connecting".localized.uppercased()
        
        let imageView = SDAnimatedImageView()
        
        guard
            let imageURL = Bundle
                .main
                .url(forResource: "connecting", withExtension: "gif"),
            let data = try? Data(contentsOf: imageURL)
        else {
            // Show the static image as a backup
            connectingGIFImageView.isHidden = false
            return
        }
        
        let animateGIFImage = SDAnimatedImage(data: data)
        
        imageView.image = animateGIFImage
        imageView.frame = .init(
            origin: connectingGIFImageView.frame.origin,
            size: connectingGIFImageView.frame.size
        )

        contentContainer.insertSubview(imageView, at: 0)
    }
}
