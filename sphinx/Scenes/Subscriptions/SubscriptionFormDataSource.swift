//
//  SubscriptionFormDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 07/11/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

protocol SubscriptionFormDataSourceDelegate: class {
    func shouldShowAlert(title: String, text: String)
    func didTapSubscribeButton()
}

struct TableSection {
    var title : String = ""
    var rowsCount : Int = 0
    var headerHeight : CGFloat = 36.0
    var rowsHeight = [CGFloat]()
    
    init(title: String, rowsCount: Int, rowsHeight: [CGFloat]) {
        self.title = title
        self.rowsCount = rowsCount
        self.rowsHeight = rowsHeight
    }
}

class SubscriptionFormDataSource : NSObject {
    
    var delegate: SubscriptionFormDataSourceDelegate!
    
    let firstSection = TableSection(title: "amount.upper".localized, rowsCount: 1, rowsHeight: [250.0])
    var secondSection = TableSection(title: "time.interval.upper".localized, rowsCount: 1, rowsHeight: [200.0])
    var thirdSection = TableSection(title: "end.rule.upper".localized, rowsCount: 2, rowsHeight: [160.0, 112.0])
    var tableSections = [TableSection]()
    
    static let maxHeaderHeight: CGFloat = 150
    static let minHeaderHeight: CGFloat = 60
    
    static let maxImageWidth: CGFloat = 88
    static let minImageWidth: CGFloat = 40
    static let maxImageTop: CGFloat = 32
    static let minImageTop: CGFloat = 10
    static let maxLabelLeft: CGFloat = 30
    static let minLabelLeft: CGFloat = 15
    
    var amountView : SubscriptionAmountView!
    var timeIntervalView : SubscriptionTimeIntervalView!
    var endRuleView : SubscriptionEndRuleView!
    
    var subscription : Subscription?
    
    var tableView : UITableView!
    
    init(delegate: SubscriptionFormDataSourceDelegate, tableView: UITableView, subscription: Subscription?) {
        super.init()
        
        self.tableView = tableView
        self.delegate = delegate
        self.subscription = subscription
        self.tableSections = [firstSection, secondSection, thirdSection]
    }
    
    func isSubscriptionActive() -> Bool {
        if let _ = subscription {
            return true
        }
        return false
    }
    
    func reloadSubscribeButtonRow() {
        let lastSection = tableView.numberOfSections - 1
        let lastRow = tableView.numberOfRows(inSection: lastSection) - 1
        let subscribeButtonIndexPath = IndexPath(row: lastRow, section: lastSection)
        reloadRowAt(indexPath: subscribeButtonIndexPath)
    }
    
    func reloadRowAt(indexPath: IndexPath) {
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}

extension SubscriptionFormDataSource : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return tableSections[indexPath.section].rowsHeight[indexPath.row]
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return tableSections[section].headerHeight
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = SubscriptionFormTableHeaderView(frame: CGRect(x: 0, y: 0, width: WindowsManager.getWindowWidth(), height: 36))
        let title = tableSections[section].title
        headerView.configureLabel(text: title)
        return headerView
    }
}

extension SubscriptionFormDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return tableSections.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableSections[section].rowsCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if isLastCell(indexPath: indexPath, numberOfSections: tableSections.count) {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriptionFormButtonTableViewCell", for: indexPath) as! SubscriptionFormButtonTableViewCell
            cell.delegate = self
            cell.configureButton(editing: isSubscriptionActive())
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SubscriptionFormTableViewCell", for: indexPath) as! SubscriptionFormTableViewCell
            if let view = getViewForRow(indexPath: indexPath) {
                removeSubview(view: cell.contentView)
                cell.contentView.addSubview(view)
            }
            return cell
        }
    }
    
    func removeSubview(view: UIView) {
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
    }
    
    func getViewForRow(indexPath: IndexPath) -> UIView? {
        let width = WindowsManager.getWindowWidth()
        let height = tableSections[indexPath.section].rowsHeight[indexPath.row]
        
        switch (indexPath.section) {
        case 0:
            amountView = SubscriptionAmountView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            amountView.delegate = self
            return amountView
        case 1:
            timeIntervalView = SubscriptionTimeIntervalView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            timeIntervalView.delegate = self
            return timeIntervalView
        case 2:
            endRuleView = SubscriptionEndRuleView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            endRuleView.delegate = self
            return endRuleView
        default:
            return nil
        }
    }
    
    func isLastCell(indexPath: IndexPath, numberOfSections: Int) -> Bool {
        return indexPath.section == numberOfSections - 1 && indexPath.row == tableSections[indexPath.section].rowsCount - 1
    }
}

extension SubscriptionFormDataSource : SubscriptionFormViewDelegate {    
    func shouldShowAlert(title: String, text: String) {
        delegate?.shouldShowAlert(title: title, text: text)
    }
    
    func shouldScrollToBottom() {
        DelayPerformedHelper.performAfterDelay(seconds: 0.3) {
            self.tableView.scrollToBottom(animated: true)
        }
    }
}

extension SubscriptionFormDataSource : SubscriptionFormRowDelegate {
    func didTapSubscribeButton() {
        delegate?.didTapSubscribeButton()
    }
}
