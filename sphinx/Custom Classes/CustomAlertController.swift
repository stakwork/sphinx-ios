//
//  CustomAlertController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/09/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import UIKit

class CustomAlertController: UIAlertController {

    var willDisappearBlock: ((UIAlertController) -> Void)?
    var didDisappearBlock: ((UIAlertController) -> Void)?

    override func viewWillDisappear(_ animated: Bool) {
        willDisappearBlock?(self)
        super.viewWillDisappear(animated)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        didDisappearBlock?(self)
    }

}
