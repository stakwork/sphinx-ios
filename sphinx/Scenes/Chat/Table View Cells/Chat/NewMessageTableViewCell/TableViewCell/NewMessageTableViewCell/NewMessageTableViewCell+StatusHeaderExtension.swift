//
//  NewMessageTableViewCell+StatusHeaderExtension.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/06/2023.
//  Copyright © 2023 sphinx. All rights reserved.
//

import UIKit

extension NewMessageTableViewCell {
    
    func configureWith(
        statusHeader: BubbleMessageLayoutState.StatusHeader?,
        uploadProgressData: MessageTableCellState.UploadProgressData?
    ) {
        if let statusHeader = statusHeader {
            statusHeaderView.configureWith(
                statusHeader: statusHeader,
                uploadProgressData: uploadProgressData
            )
        }
    }
}
