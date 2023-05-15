//
//  RestoreUserConnectingViewController.swift
//  sphinx
//
//  Copyright © 2021 sphinx. All rights reserved.
//

import UIKit
import SDWebImage

class RestoreUserConnectingViewController: UIViewController {
    
    @IBOutlet weak var connectingImageView: UIImageView!
    @IBOutlet weak var contentContainer: UIView!
    @IBOutlet weak var connectingLabel: UILabel!
    
    static func instantiate() -> RestoreUserConnectingViewController {
        let viewController = StoryboardScene.RestoreUser.restoreUserConnectingViewController.instantiate()
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectingLabel.text = "welcome.connecting".localized.uppercased()
        
        let imageData = try? Data(contentsOf: Bundle.main.url(forResource: "connecting", withExtension: "gif")!)
        let advTimeGif = UIImage.sd_image(withGIFData: imageData)
        connectingImageView.image = advTimeGif
    }
}
