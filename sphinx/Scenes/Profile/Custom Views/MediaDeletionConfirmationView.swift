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
    @IBOutlet weak var deletionSymbol: UIImageView!
    @IBOutlet weak var loadingCircularProgressView: CircularProgressView!
    
    @IBOutlet weak var viewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var subtitleToTitleConstraintSpacing: NSLayoutConstraint!
    
    
    
    var isLoading : Bool = false{
        didSet{
            isLoading ? moveToLoadingUI() : ()
        }
    }
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
    
    func moveToLoadingUI(){
        self.loadingCircularProgressView.backgroundColor = .clear
        self.deletionButton.isHidden = true
        self.cancelButton.isHidden = true
        self.deletionSymbol.image = #imageLiteral(resourceName: "deletion_loading")
        UIView.animate(withDuration: 0.05, delay: 0.0, animations: {
            self.loadingCircularProgressView.isHidden = false
            self.deletionSymbol.tintColor = UIColor.Sphinx.BodyInverted
            self.titleLabel.text = "storage.management.loading.deletion".localized
            self.subtitleLabel.text = "storage.management.loading.deletion.subtitle".localized
            self.viewBottomConstraint.constant -= 34
            self.subtitleToTitleConstraintSpacing.constant = -24.0
            self.layoutIfNeeded()
        },
        completion: { _ in
            self.startRotation()
            self.loadingCircularProgressView.isHidden = false
            self.loadingCircularProgressView.setProgressStrokeColor(color: UIColor.Sphinx.PrimaryRed)
            self.loadingCircularProgressView.progressAnimation(to: 0.9, active: true)
            self.loadingCircularProgressView.playPauseLabel.isHidden = true
        })
    }
    
    private func setup() {
        Bundle.main.loadNibNamed("MediaDeletionConfirmationView", owner: self, options: nil)
        addSubview(contentView)
        self.backgroundColor = .clear
        deletionSymbolContainerView.makeCircular()
        deletionButton.layer.cornerRadius = deletionButton.frame.height/2.0
        cancelButton.layer.borderColor = UIColor.Sphinx.InputOutline1.cgColor
        cancelButton.layer.borderWidth = 1.0
        cancelButton.layer.cornerRadius = cancelButton.frame.height/2.0
        contentView.layer.cornerRadius = 16.0
        loadingCircularProgressView.isHidden = true
    }
    
    func startRotation(){
        loadingCircularProgressView.startRotation()
    }
    
    @IBAction func deleteTapped(_ sender: Any) {
        delegate?.deleteTapped()
    }
    
    @IBAction func cancelTapped(_ sender: Any) {
        delegate?.cancelTapped()
    }
    
    
}
