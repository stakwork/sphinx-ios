//
//  EpisodesHeaderView.swift
//  sphinx
//
//  Created by Tomas Timinskas on 27/10/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

class EpisodesHeaderView: UIView {
    
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var episodesLabel: UILabel!
    @IBOutlet weak var episodesCountLabel: UILabel!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    private func setup() {
        Bundle.main.loadNibNamed("EpisodesHeaderView", owner: self, options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
    }
    
    func configureWith(count: Int) {
        episodesLabel.text = "episodes".localized.uppercased()
        episodesCountLabel.text = "\(count)"
    }
}
