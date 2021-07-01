//
//  Library
//
//  Created by Tomas Timinskas on 26/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class DayHeaderTableViewCell: UITableViewCell {
    
    public static let kHeaderHeight: CGFloat = 40.0

    @IBOutlet weak var dateLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    func configureCell(messageRow: TransactionMessageRow) {
        let date = messageRow.headerDate ?? Date()
        let (shouldShowMonth, shouldShowYear) = date.shouldShowMonthAndYear()
        
        if date.isToday() {
            dateLabel.text = "today".localized
        } else if shouldShowMonth && shouldShowYear {
            dateLabel.text = date.getStringDate(format: "EEEE MMMM dd, yyyy")
        } else if shouldShowMonth {
            dateLabel.text = date.getStringDate(format: "EEEE MMMM dd")
        } else {
            dateLabel.text = date.getStringDate(format: "EEEE dd")
        }
    }
}
