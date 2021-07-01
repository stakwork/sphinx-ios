//
//  LinkPreviewImageView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 24/09/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class LinkPreviewUIImage : UIImage {
    var imageName : String? = nil
    
    convenience init?(named name: String) {
        guard let image = UIImage(named: name),
            let cgImage = image.cgImage else {
                return nil
        }
        self.init(cgImage: cgImage)
        self.imageName = name
    }
}
