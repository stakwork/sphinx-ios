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
    

    var buttonBackgroundColor: UIColor = .Sphinx.DashboardHeader
    var buttonTextColor: UIColor = .Sphinx.DashboardWashedOutText
    var activeTextColor: UIColor = .Sphinx.PrimaryText
    var buttonTitleFont = UIFont(
        name: "Roboto-Medium",
        size: UIDevice.current.isIpad ? 20.0 : 16.0
    )!
    
    var selectorViewColor: UIColor = .Sphinx.PrimaryBlue
    var selectorWidthRatio: CGFloat = 0.667
    

    weak var delegate: CustomSegmentedControlDelegate?
    
    private(set) var selectedIndex: Int = 0
    
    
    convenience init(
        frame: CGRect,
        buttonTitles: [String]
    ) {
        self.init(frame: frame)
        
        self.buttonTitles = buttonTitles
    }
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        backgroundColor = buttonBackgroundColor
        
        setupInitialViews()
    }
    
    
    public func configureFromOutlet(
        buttonTitles: [String],
        initialIndex: Int = 0,
        delegate: CustomSegmentedControlDelegate?
    ) {
        self.buttonTitles = buttonTitles
        self.selectedIndex = initialIndex
        self.delegate = delegate
        
        setupInitialViews()
        updateButtonsOnIndexChange()
    }
    
    
    private func updateButtonsOnIndexChange() {
        UIView.animate(withDuration: 0.3) {
            self.buttons[self.selectedIndex].setTitleColor(self.activeTextColor, for: .normal)
            self.selectorView.frame.origin.x = self.selectorPosition
        }
    }
    
    
    @objc func buttonAction(sender: UIButton) {
        for (buttonIndex, button) in buttons.enumerated() {
            button.setTitleColor(buttonTextColor, for: .normal)
            
            if button == sender {
                selectedIndex = buttonIndex

                delegate?.segmentedControlDidSwitch(self, to: selectedIndex)
                
                updateButtonsOnIndexChange()
            }
        }
    }
}

// MARK: -  View Configuration
extension CustomSegmentedControl {
    
    private func setupInitialViews() {
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
    
    
    private var selectorWidth: CGFloat {
        (
            frame.width / CGFloat(self.buttonTitles.count)
        ) * selectorWidthRatio
    }
    
    
    private var selectorPosition: CGFloat {
        let selectedTabStartX = (
            frame.width / CGFloat(buttonTitles.count)
        ) * CGFloat(selectedIndex)

        let offset = (
            frame.width / CGFloat(self.buttonTitles.count)
            - selectorWidth
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
        
        buttons[selectedIndex].setTitleColor(activeTextColor, for: .normal)
    }
}
