//
//  HistoryDataSource.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/01/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol HistoryDataSourceDelegate: class {
    func shouldLoadMoreTransactions()
}

class HistoryDataSource : NSObject {
    
    weak var delegate: HistoryDataSourceDelegate?
    
    var tableView : UITableView!
    
    var transactions = [PaymentTransaction]()
    
    var insertingRows = false
    
    var shouldShowLoadingWheel = true
    
    init(tableView: UITableView, delegate: HistoryDataSourceDelegate) {
        self.tableView = tableView
        self.delegate = delegate
    }
    
    func loadTransactions(transactions: [PaymentTransaction]) {
        self.shouldShowLoadingWheel = (transactions.count > 0 && transactions.count % 50 == 0)
        self.transactions = transactions
        self.tableView.reloadData()
    }
    
    func addMoreTransactions(transactions: [PaymentTransaction]) {
        shouldShowLoadingWheel = (transactions.count > 0 && transactions.count % 50 == 0)
        insertObjectsToModel(transactions: transactions)
        tableView.reloadData()
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
            self.insertingRows = false
        }
    }
    
    func insertObjectsToModel(transactions: [PaymentTransaction]) {
        self.transactions.append(contentsOf: transactions)
    }
}

extension HistoryDataSource : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let transaction = transactions.count > indexPath.row ? transactions[indexPath.row] : nil
        
        if !transaction!.isFailed() {
            return
        }
        
        transaction?.expanded = !(transaction?.expanded ?? false)

        tableView.reloadRows(at: [indexPath], with: .none)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? LoadingMoreTableViewCell {
            cell.configureCell(text: "loading.more.transactions".localized)
        }
    }
}

extension HistoryDataSource : UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shouldShowLoadingWheel ? transactions.count + 1 : transactions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == transactions.count {
            let cell = tableView.dequeueReusableCell(withIdentifier: "LoadingMoreTableViewCell", for: indexPath) as! LoadingMoreTableViewCell
            return cell
        }
        
        let transaction = transactions[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionTableViewCell", for: indexPath) as! TransactionTableViewCell
        cell.configureCell(transaction: transaction)
        return cell
    }
}

extension HistoryDataSource : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (
            scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height - LoadingMoreTableViewCell.kLoadingHeight) &&
            !insertingRows
        ) {
            insertingRows = true

            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.delegate?.shouldLoadMoreTransactions()
            })
        }
    }
}
