//
//  KeychainRestoreTableViewCell.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/05/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol KeychainRestoreCellDelegate: class {
    func shouldDelete(cell: UITableViewCell)
}

class KeychainRestoreTableViewCell: UITableViewCell {
    
    weak var delegate: KeychainRestoreCellDelegate?

    @IBOutlet weak var pubKeyLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
//        numberOfButtons = .oneButton
//        button3 = button1
//        button1.tintColorDidChange()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureNode(with pubKey: String, delegate: KeychainRestoreCellDelegate) {
        self.delegate = delegate
        
        pubKeyLabel.text = pubKey
    }
    
    @IBAction func deleteButtonTouched() {
        delegate?.shouldDelete(cell: self)
    }
}
