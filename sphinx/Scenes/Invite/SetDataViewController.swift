//
//  SetDataViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 01/10/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class SetDataViewController : UIViewController {
    
    @IBOutlet weak var nextButton: UIButton!
    
    override func viewDidLoad() {
        nextButton.layer.cornerRadius = nextButton.frame.size.height / 2
        nextButton.clipsToBounds = true
        nextButton.addShadow(location: .bottom, opacity: 0.5, radius: 2.0)
    }
}
