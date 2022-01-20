//
//  DashboardRootViewController+RestoreProgressViewDelegate.swift
//  sphinx
//
//  Created by Tomas Timinskas on 19/01/2022.
//  Copyright © 2022 sphinx. All rights reserved.
//

import Foundation

extension DashboardRootViewController : RestoreProgressViewDelegate {
    func shouldFinishRestoring() {
        chatsListViewModel.finishRestoring()
        finishLoading()
    }
}
