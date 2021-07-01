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
        appendCells()
        
        DelayPerformedHelper.performAfterDelay(seconds: 0.5) {
            self.insertingRows = false
        }
    }
    
    func insertObjectsToModel(transactions: [PaymentTransaction]) {
        self.transactions.append(contentsOf: transactions)
    }
    
    func appendCells() {
        let oldContentHeight = tableView.contentSize.height
        let oldOffsetY = tableView.contentOffset.y
        tableView.reloadData()
        let newContentHeight: CGFloat = tableView.contentSize.height
        tableView.contentOffset.y = oldOffsetY + (newContentHeight - oldContentHeight)
    }
}

extension HistoryDataSource : UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85.0
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let transaction = transactions.count > indexPath.row ? transactions[indexPath.row] : nil
        
        if let cell = cell as? LoadingMoreTableViewCell {
            cell.configureCell(text: "loading.more.transactions".localized)
        } else if let cell = cell as? TransactionPaymentReceivedTableViewCell {
            cell.configureCell(transaction: transaction)
        } else if let cell = cell as? TransactionPaymentSentTableViewCell {
            cell.configureCell(transaction: transaction)
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
        
        if transaction.isIncoming() {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionPaymentReceivedTableViewCell", for: indexPath) as! TransactionPaymentReceivedTableViewCell
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TransactionPaymentSentTableViewCell", for: indexPath) as! TransactionPaymentSentTableViewCell
            return cell
        }
    }
}

extension HistoryDataSource : UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y >= (scrollView.contentSize.height - scrollView.frame.size.height - LoadingMoreTableViewCell.kLoadingHeight) && !insertingRows) {
            insertingRows = true
            
            DelayPerformedHelper.performAfterDelay(seconds: 0.5, completion: {
                self.delegate?.shouldLoadMoreTransactions()
            })
        }
    }
}
