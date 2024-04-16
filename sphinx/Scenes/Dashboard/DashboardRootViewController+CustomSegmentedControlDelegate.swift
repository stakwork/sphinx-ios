// DashboardRootViewController+CustomSegmentedControlDelegate.swift
//
// Created by CypherPoet.
// ✌️
//

import UIKit


extension DashboardRootViewController: CustomSegmentedControlDelegate {
    
    func segmentedControlDidSwitch(
        to index: Int
    ) {
        activeTab = DashboardTab(rawValue: index)!
    }
}
