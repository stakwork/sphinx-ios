//
//  ShimmeringTableView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit
import UIView_Shimmer

class ShimmeringList: UIView, ShimmeringViewProtocol {

    @IBOutlet private var contentView: UIView!
    
    @IBOutlet var shimmeringSubviews: [UIButton]!
    
    var shimmeringAnimatedItems: [UIView] {
        get {
            shimmeringSubviews ?? []
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
        Bundle.main.loadNibNamed("ShimmeringList", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.setTemplateWithSubviews(
            true,
            color: UIColor.Sphinx.PlaceholderText,
            viewBackgroundColor: UIColor.Sphinx.Body
        )
    }

}
