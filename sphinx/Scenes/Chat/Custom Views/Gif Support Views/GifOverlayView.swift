//
//  GifOverlayView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 20/04/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol GifOverlayDelegate: class {
    func didTapButton()
}

class GifOverlayView: UIView {
    
    weak var delegate: GifOverlayDelegate?
    
    @IBOutlet private var contentView: UIView!
    @IBOutlet weak var gifIconContainer: UIView!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("GifOverlayView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        
        gifIconContainer.layer.cornerRadius = gifIconContainer.frame.size.height / 2
    }
    
    func configure(delegate: GifOverlayDelegate) {
        self.delegate = delegate
    }
    
    @IBAction func buttonTouched() {
        delegate?.didTapButton()
    }
}
