//
//  LoadingMoreTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class LoadingMoreTableViewCell: UITableViewCell {
    
    public static let kLoadingHeight: CGFloat = 50.0
    
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    @IBOutlet weak var loadingMoreLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell(text: String) {
        loadingMoreLabel.text = text
        loadingWheel.color = UIColor.Sphinx.Text
        loadingWheel.startAnimating()
    }
    
}
