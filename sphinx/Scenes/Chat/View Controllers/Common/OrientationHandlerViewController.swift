//
//  OrientationHandlerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/06/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class OrientationHandlerViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewWidth = view.frame.width
    }
    
    var initialOrientation = true
    var isInPortrait = false
    var orientationDidChange = false
    var viewWidth: CGFloat = 0

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        if initialOrientation {
            initialOrientation = false
            if view.frame.width > view.frame.height {
                isInPortrait = false
            } else {
                isInPortrait = true
            }
            orientationWillChange()
        } else {
            if view.orientationHasChanged(&isInPortrait) {
                orientationWillChange()
            }
        }
    }
    func orientationWillChange() {
        orientationDidChange = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if orientationDidChange {
            orientationDidChange = false
            orientationDidChanged()
        } else if viewWidth != view.frame.width {
            viewWidth = view.frame.width
            orientationDidChanged()
        }
    }
    
    func orientationDidChanged() {}
}
