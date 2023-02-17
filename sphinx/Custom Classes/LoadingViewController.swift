// LoadingViewController.swift
//
// Created by CypherPoet.
// ✌️
//
    
import UIKit


class LoadingViewController: UIViewController {
    private let backgroundColor: UIColor
    private lazy var spinner: UIActivityIndicatorView = makeSpinner()
    
    
    init(backgroundColor: UIColor = UIColor.systemFill.withAlphaComponent(0.4)) {
        self.backgroundColor = backgroundColor

        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError()
    }
}
    

extension LoadingViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupSpinner()
        view.backgroundColor = backgroundColor
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // add a small delay so the spinner doesn't flicker when showing for negligable periods
        let deadline = DispatchTime.now() + 0.3
        
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            self.spinner.startAnimating()
        }
    }
}


private extension LoadingViewController {
    
    func setupSpinner() {
        spinner.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(spinner)

        NSLayoutConstraint.activate([
            spinner.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
        
        spinner.startAnimating()
    }
    
    
    func makeSpinner() -> UIActivityIndicatorView {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.color = UIColor.white

        spinner.sizeToFit()
        spinner.translatesAutoresizingMaskIntoConstraints = false
        
        return spinner
    }
}
