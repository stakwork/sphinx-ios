//
//  PaymentTemplateCollectionViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 12/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class PaymentTemplateCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var circularImageBack: UIView!
    @IBOutlet weak var circularImageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        circularImageBack.layer.cornerRadius = circularImageBack.frame.size.width / 2
        circularImageView.layer.cornerRadius = circularImageView.frame.size.width / 2
    }
    
    func configure(rowIndex: Int, imageTemplate: ImageTemplate?) {
        circularImageView.image = nil
        addShadow()
        
        guard let imageTemplate = imageTemplate else {
            return
        }
        
        if let muid = imageTemplate.muid {
            MediaLoader.loadTemplate(row: rowIndex, muid: muid, completion: { (row, _, image) in
                if rowIndex != row {
                    return
                }
                self.circularImageView.image = image
            })
        }
    }
    
    func addShadow() {
        circularImageBack.addShadow(location: .center, opacity: 0.4, radius: 8)
        circularImageBack.clipsToBounds = false
        circularImageView.backgroundColor = UIColor.Sphinx.HeaderBG
    }
}
