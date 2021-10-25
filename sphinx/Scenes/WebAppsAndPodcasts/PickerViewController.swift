//
//  PickerViewController.swift
//  sphinx
//
//  Created by Tomas Timinskas on 30/11/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import UIKit

protocol PickerViewDelegate: class {
    func didSelectValue(value: String)
}

class PickerViewController: UIViewController {
    
    weak var delegate: PickerViewDelegate?
    
    @IBOutlet weak var pickerTitleLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var bottomConstraint: NSLayoutConstraint!
    
    var pickerTitle: String = ""
    var values: [String] = []
    var selectedValue: String = ""
    
    public enum PickerButton: Int {
        case Cancel
        case Done
    }
    
    static func instantiate(
        values: [String],
        selectedValue: String,
        title: String = "",
        delegate: PickerViewDelegate) -> PickerViewController {
        
        let viewController = StoryboardScene.WebApps.pickerViewController.instantiate()
        viewController.pickerTitle = title
        viewController.values = values
        viewController.selectedValue = selectedValue
        viewController.delegate = delegate
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.alpha = 0.0
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        buildPicker()
        togglePicker(show: true)
    }
    
    func buildPicker() {
        pickerTitleLabel.text = pickerTitle
        
        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.reloadAllComponents()
        
        if let row = values.index(of: selectedValue) {
            pickerView.selectRow(row, inComponent: 0, animated: false)
        }
    }
    
    func togglePicker(show: Bool) {
        if show {
            UIView.animate(withDuration: 0.2, animations: {
                self.view.alpha = 1.0
            }, completion: { _ in
                self.togglePicker(show: true, completion: {})
            })
        } else {
            togglePicker(show: false, completion: {
                UIView.animate(withDuration: 0.2, animations: {
                    self.view.alpha = 0.0
                }, completion: { _ in
                    self.dismiss(animated: false, completion: nil)
                })
            })
        }
    }
    
    func togglePicker(show: Bool, completion: @escaping () -> ()) {
        self.bottomConstraint.constant = show ? 0 : -400
        
        UIView.animate(withDuration: 0.2, animations: {
            self.view.layoutIfNeeded()
        }, completion: { _ in
            completion()
        })
    }
    
    @IBAction func buttonTouched(_ sender: UIButton) {
        switch(sender.tag) {
        case PickerButton.Cancel.rawValue:
            break
        case PickerButton.Done.rawValue:
            let selectedRow = pickerView.selectedRow(inComponent: 0)
            let selectedValue = (values.count > selectedRow) ? values[selectedRow] : nil
            
            if let selectedValue = selectedValue {
                delegate?.didSelectValue(value: selectedValue)
            }
            break
        default:
            break
        }
        togglePicker(show: false)
    }
}

extension PickerViewController: UIPickerViewDelegate, UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return values.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        let value = values[row]
        return value
    }
}
