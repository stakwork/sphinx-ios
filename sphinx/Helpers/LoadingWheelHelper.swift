//
//  LoadingWheelHelper.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class LoadingWheelHelper {
    
    public static func toggleLoadingWheel(
        loading: Bool,
        loadingWheel: UIActivityIndicatorView,
        loadingWheelColor: UIColor? = nil,
        view: UIView? = nil,
        views: [UIView] = []
    ) {
        
        view?.isUserInteractionEnabled = !loading
        
        for v in views {
            v.isUserInteractionEnabled = !loading
        }
        
        if let loadingWheelColor = loadingWheelColor {
            loadingWheel.color = loadingWheelColor
        }
        
        loadingWheel.alpha = loading ? 1.0 : 0.0
        
        if loading {
            loadingWheel.startAnimating()
        } else {
            loadingWheel.stopAnimating()
        }
    }
}
