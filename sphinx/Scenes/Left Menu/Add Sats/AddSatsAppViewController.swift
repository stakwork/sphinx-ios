//
//  AddSatsAppViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 16/12/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class AddSatsAppViewController: UIViewController {
    
    var rootViewController : RootViewController!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    static func instantiate(rootViewController : RootViewController) -> AddSatsAppViewController {
        let viewController = StoryboardScene.LeftMenu.addSatsAppViewController.instantiate()
        viewController.rootViewController = rootViewController
        return viewController
    }
}
