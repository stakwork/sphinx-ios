//
//  TribeMemberPopupViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 09/05/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class TribeMemberPopupViewController: UIViewController {
    
    @IBOutlet weak var tribeMemberPopupView: TribeMemberPopupView!
    
    weak var delegate: TribeMemberViewDelegate!
    
    var message: TransactionMessage!
    
    static func instantiate(
        message : TransactionMessage,
        delegate: TribeMemberViewDelegate
    ) -> TribeMemberPopupViewController {
        let viewController = StoryboardScene.Chat.tribeMemberPopupViewController.instantiate()
        viewController.message = message
        viewController.delegate = delegate
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tribeMemberPopupView.configureFor(message: message, with: delegate)
    }

}
