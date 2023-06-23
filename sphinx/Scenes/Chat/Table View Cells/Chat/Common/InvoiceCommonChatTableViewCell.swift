//
//  Library
//
//  Created by Tomas Timinskas on 08/03/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit
import SDWebImage

class InvoiceContainerView : UIView {
    
}

//class InvoiceCommonChatTableViewCell: CommonChatTableViewCell {
//
//    static let kBubbleWidth: CGFloat = 210
//    static let kLabelWidth: CGFloat = 170
//    static let kLabelTopMargin: CGFloat = 57
//    static let kLabelBottomMargin: CGFloat = 77
//    static let kLabelBottomMarginWithoutButton: CGFloat = 20
//
//    @IBOutlet weak var expireLabel: UILabel!
//
//    var timer : Timer!
//
//    override func awakeFromNib() {
//        super.awakeFromNib()
//    }
//
//    override func setSelected(_ selected: Bool, animated: Bool) {
//        super.setSelected(selected, animated: animated)
//    }
//
//    func configureExpiry() {
//        stopTimer()
//        configureTimer()
//    }
//
//    func stopTimer() {
//        timer?.invalidate()
//        timer = nil
//    }
//
//    func configureTimer() {
//        updateTimer()
//        timer = Timer(timeInterval: 1.0, target: self, selector: #selector(InvoiceReceivedTableViewCell.updateTimer), userInfo: nil, repeats: true)
//        RunLoop.current.add(timer, forMode: RunLoop.Mode.common)
//    }
//
//    @objc func updateTimer() {
//        if let expiryDate = messageRow?.transactionMessage.expirationDate, Date().timeIntervalSince1970 < expiryDate.timeIntervalSince1970 {
//            let diff = expiryDate.timeIntervalSince1970 - Date().timeIntervalSince1970
//            let minutes = secondsToMinutes(seconds: Int(diff))
//            let expirationString = String(format: "expires.in".localized, minutes)
//            expireLabel.text = expirationString.uppercased()
//        } else {
//            expireLabel.text = "expired".localized
//        }
//    }
//
//    func secondsToMinutes(seconds : Int) -> String {
//        let minutes: Int = (seconds % 3600) / 60
//        return minutes.timeString
//    }
//}
