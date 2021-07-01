//
//  QRCodeDetailsViewModel.swift
//  sphinx
//
//  Created by Tomas Timinskas on 23/09/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import Foundation

class QRCodeDetailViewModel {
    
    var viewTitle: String?
    var qrCodeString: String?
    var amount: Int?
    
    init(qrCodeString: String, amount: Int?, viewTitle: String) {
        self.qrCodeString = qrCodeString
        self.amount = amount
        self.viewTitle = viewTitle
    }
}
