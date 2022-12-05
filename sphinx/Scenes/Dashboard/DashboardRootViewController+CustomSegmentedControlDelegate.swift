// DashboardRootViewController+CustomSegmentedControlDelegate.swift
//
// Created by CypherPoet.
// ✌️
//

import UIKit


extension DashboardRootViewController: CustomSegmentedControlDelegate {
    
    func segmentedControlDidSwitch(
        _ segmentedControl: CustomSegmentedControl,
        to index: Int
    ) {
        activeTab = DashboardTab(rawValue: index)!
    }
}
