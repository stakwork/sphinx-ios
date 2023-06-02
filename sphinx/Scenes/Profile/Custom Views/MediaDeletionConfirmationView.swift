//
//  MediaDeletionConfirmationView.swift
//  sphinx
//
//  Created by James Carucci on 6/1/23.
//  Copyright © 2023 sphinx. All rights reserved.
//

import Foundation
import UIKit


protocol MediaDeletionConfirmationViewDelegate : NSObject{
    func cancelTapped()
    func deleteTapped()
}

class MediaDeletionConfirmationView: UIView {
    
    @IBOutlet weak var deletionSymbolContainerView: UIView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var deletionButton: UIButton!
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    
    var delegate : MediaDeletionConfirmationViewDelegate? = nil
    var type: StorageManagerMediaType? = nil {
        didSet{
            if let type = type{
                var typeString : String? = nil
                switch type {
                    case .audio:
                        typeString = NSLocalizedString("storage.management.audio.files", comment: "")
                    break
                    case .video:
                        typeString = NSLocalizedString("storage.management.video", comment: "")
                    break
                    case .photo:
                        typeString = NSLocalizedString("storage.management.images", comment: "")
                    break
                }
                
                let warningMessage = String(format: NSLocalizedString("deletion.warning.title", comment: ""), (typeString ?? "media files"))
                titleLabel.text = warningMessage
                
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("MediaDeletionConfirmationView", owner: self, options: nil)
        addSubview(contentView)
        self.backgroundColor = .clear
        deletionSymbolContainerView.makeCircular()
        deletionButton.layer.cornerRadius = deletionButton.frame.height/2.0
        cancelButton.layer.borderColor = UIColor.Sphinx.Divider.cgColor
        cancelButton.layer.borderWidth = 1.0
        cancelButton.layer.cornerRadius = cancelButton.frame.height/2.0
        contentView.layer.cornerRadius = 16.0
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        delegate?.deleteTapped()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        delegate?.cancelTapped()
    }
    
    
}