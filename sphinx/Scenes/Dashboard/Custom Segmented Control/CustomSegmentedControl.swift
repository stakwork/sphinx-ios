//
// CustomSegmentedControl.swift
// sphinx
//


import UIKit


protocol CustomSegmentedControlDelegate: AnyObject {
    
    func segmentedControlDidSwitch(
        _ segmentedControl: CustomSegmentedControl,
        to index: Int
    )
}


class CustomSegmentedControl: UIView {
    private var buttonTitles: [String]!
    private var buttons: [UIButton]!
    private var selectorView: UIView!
    

    var buttonBackgroundColor: UIColor = .clear
    var buttonTextColor: UIColor = .Sphinx.DashboardWashedOutText
    var activeTextColor: UIColor = .white
    var buttonTitleFont = UIFont(
        name: "Roboto-Medium",
        size: UIDevice.current.isIpad ? 20.0 : 16.0
    )!
    
    var selectorViewColor: UIColor = .Sphinx.PrimaryBlue
    var selectorWidthRatio: CGFloat = 0.8
    

    weak var delegate: CustomSegmentedControlDelegate?
    
    public private(set) var selectedIndex: Int = 0
    
    
    convenience init(
        frame: CGRect,
        buttonTitle: [String]
    ) {
        self.init(frame: frame)
        
        self.buttonTitles = buttonTitle
    }
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        backgroundColor = buttonBackgroundColor
        
        updateView()
    }
    
    
    public func setButtonTitles(_ newButtonTitles: [String]) {
        buttonTitles = newButtonTitles
        
        updateView()
    }
    
    
    public func setIndex(to newIndex: Int) {
        buttons.forEach({ $0.setTitleColor(buttonTextColor, for: .normal) })
        
        selectedIndex = newIndex

        let button = buttons[newIndex]
        button.setTitleColor(activeTextColor, for: .normal)

        UIView.animate(withDuration: 0.2) {
            self.selectorView.frame.origin.x = self.selectorPosition
        }
    }
    
    
    @objc func buttonAction(sender: UIButton) {
        for (buttonIndex, button) in buttons.enumerated() {
            button.setTitleColor(buttonTextColor, for: .normal)
            
            if button == sender {
                selectedIndex = buttonIndex
                
                delegate?.segmentedControlDidSwitch(self, to: selectedIndex)
                
                UIView.animate(withDuration: 0.3) {
                    self.selectorView.frame.origin.x = self.selectorPosition
                }
                
                button.setTitleColor(activeTextColor, for: .normal)
            }
        }
    }
}

// MARK: -  View Configuration
extension CustomSegmentedControl {
    
    private func updateView() {
        createButtons()
        configureSelectorView()
        configureStackView()
    }
    
    
    private func configureStackView() {
        let stackView = UIStackView(arrangedSubviews: buttons)
        
        stackView.axis = .horizontal
        stackView.alignment = .fill
        stackView.distribution = .fillEqually
        
        addSubview(stackView)
        
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        stackView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        stackView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        stackView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
    }
    
    
    var selectorWidth: CGFloat {
        (
            frame.width / CGFloat(self.buttonTitles.count)
        ) * selectorWidthRatio
    }
    
    
    var selectorPosition: CGFloat {
        let selectedTabStartX = (
            frame.width / CGFloat(buttonTitles.count)
        ) * CGFloat(selectedIndex)

        let offset = (
            selectorWidth * (1.0 - selectorWidthRatio)
        ) * 0.5
        
        return selectedTabStartX + offset
    }
    
    
    private func configureSelectorView() {
        selectorView = UIView(
            frame: CGRect(
                x: selectorPosition,
                y: self.frame.height,
                width: selectorWidth,
                height: 2
            )
        )
        
        selectorView.backgroundColor = selectorViewColor

        addSubview(selectorView)
    }
    
    
    private func createButtons() {
        buttons = [UIButton]()
        buttons.removeAll()
        
        subviews.forEach({ $0.removeFromSuperview() })
        
        for buttonTitle in buttonTitles {
            let button = UIButton(type: .system)
            
            button.setTitle(buttonTitle, for: .normal)
            button.setTitleColor(buttonTextColor, for: .normal)
            button.titleLabel?.font = buttonTitleFont
            
            button.addTarget(
                self,
                action: #selector(CustomSegmentedControl.buttonAction(sender:)),
                for: .touchUpInside
            )
            
            buttons.append(button)
        }
        
        buttons[0].setTitleColor(activeTextColor, for: .normal)
    }
}
