//
//  Library
//
//  Created by Tomas Timinskas on 19/04/2019.
//  Copyright © 2019 Sphinx. All rights reserved.
//

import UIKit

class HistoryViewController: UIViewController {
    
    private var rootViewController : RootViewController!

    @IBOutlet weak var viewTitle: UILabel!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var historyTableView: UITableView!
    @IBOutlet weak var noResultsLabel: UILabel!
    @IBOutlet weak var loadingWheel: UIActivityIndicatorView!
    
    var historyDataSource : HistoryDataSource!
    
    var loading = false {
        didSet {
            LoadingWheelHelper.toggleLoadingWheel(loading: loading, loadingWheel: loadingWheel, loadingWheelColor: UIColor.Sphinx.Text)
        }
    }
    
    var page = 1
    var didReachLimit = false
    let itemsPerPage = 50
    
    static func instantiate(rootViewController: RootViewController) -> HistoryViewController {
        let viewController = StoryboardScene.History.historyViewController.instantiate()
        viewController.rootViewController = rootViewController
        
        return viewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        rootViewController.setStatusBarColor(light: false)
        
        viewTitle.addTextSpacing(value: 2)
        headerView.addShadow(location: VerticalLocation.bottom, opacity: 0.2, radius: 2.0)
        configureTableView()
    }
    
    func configureTableView() {
        historyTableView.backgroundColor = UIColor.Sphinx.Body
        historyTableView.registerCell(TransactionPaymentSentTableViewCell.self)
        historyTableView.registerCell(TransactionPaymentReceivedTableViewCell.self)
        historyTableView.registerCell(LoadingMoreTableViewCell.self)
        
        historyDataSource = HistoryDataSource(tableView: historyTableView, delegate: self)
        historyTableView.delegate = historyDataSource
        historyTableView.dataSource = historyDataSource
        
        loading = true

        API.sharedInstance.getTransactionsList(page: page, itemsPerPage: itemsPerPage, callback: { transactions in
            self.setNoResultsLabel(count: transactions.count)
            self.checkResultsLimit(count: transactions.count)
            self.historyDataSource.loadTransactions(transactions: transactions)
            self.loading = false
        }, errorCallback: {
            self.checkResultsLimit(count: 0)
            self.historyTableView.alpha = 0.0
            self.loading = false
            AlertHelper.showAlert(title: "generic.error.title".localized, message: "error.loading.transactions".localized)
        })
    }
    
    func setNoResultsLabel(count: Int) {
        noResultsLabel.alpha = count > 0 ? 0.0 : 1.0
    }
    
    func checkResultsLimit(count: Int) {
        didReachLimit = count < itemsPerPage
    }
    
    @IBAction func closeButtonTouched() {
        rootViewController.setStatusBarColor(light: true)
        dismiss(animated: true, completion: nil)
    }
}

extension HistoryViewController : HistoryDataSourceDelegate {
    func shouldLoadMoreTransactions() {
        if didReachLimit {
            return
        }
        
        page = page + 1
        
        API.sharedInstance.getTransactionsList(page: page, itemsPerPage: itemsPerPage, callback: { transactions in
            self.checkResultsLimit(count: transactions.count)
            self.historyDataSource.addMoreTransactions(transactions: transactions)
        }, errorCallback: { })
    }
}
