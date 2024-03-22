//
// CustomSegmentedControl.swift
// sphinx
//


import UIKit


protocol CustomSegmentedControlDelegate: AnyObject {
    
    func segmentedControlDidSwitch(
        to index: Int
    )
}


class CustomSegmentedControl: UIView {
    private var buttonTitles: [String]!
    private var buttons: [UIButton]!
    private var buttonTitleBadges: [UIView]!
    private var selectorView: UIView!
    

    public var buttonBackgroundColor: UIColor = .Sphinx.DashboardHeader
    public var buttonTextColor: UIColor = .Sphinx.DashboardWashedOutText
    public var activeTextColor: UIColor = .Sphinx.PrimaryText
    public var buttonTitleFont = UIFont(
        name: "Roboto-Medium",
        size: UIDevice.current.isIpad ? 20.0 : 16.0
    )!
    
    public var selectorViewColor: UIColor = .Sphinx.PrimaryBlue
    public var selectorWidthRatio: CGFloat = 0.667
    
    
    /// Indices for tabs that should have a circular badge displayed next to their title.
    public var indicesOfTitlesWithBadge: [Int] = [] {
        didSet {
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                
                self.updateTitleBadges()
            }
        }
    }
    

    public weak var delegate: CustomSegmentedControlDelegate?
    
    private(set) var selectedIndex: Int = 0
    
    
    convenience init(
        frame: CGRect,
        buttonTitles: [String]
    ) {
        self.init(frame: frame)
        
        self.buttonTitles = buttonTitles
        
        setupInitialViews()
    }
}


// MARK: - Lifecycle
extension CustomSegmentedControl {
        
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        backgroundColor = buttonBackgroundColor
    }
}


// MARK: - Action Handling
extension CustomSegmentedControl {
    
    func selectTabWith(index: Int) {
        if index >= 0 && buttons.count > index {
            let button = buttons[index]
            buttonAction(sender: button)
        }
    }
    
    @objc func buttonAction(sender: UIButton) {
        for (buttonIndex, button) in buttons.enumerated() {
            button.setTitleColor(buttonTextColor, for: .normal)
            
            if button == sender {
                selectedIndex = buttonIndex

                delegate?.segmentedControlDidSwitch(to: selectedIndex)
                
                updateButtonsOnIndexChange()
            }
        }
    }
}


// MARK: - Public Methods
extension CustomSegmentedControl {

    public func configureFromOutlet(
        buttonTitles: [String],
        initialIndex: Int = 0,
        indicesOfTitlesWithBadge: [Int] = [],
        delegate: CustomSegmentedControlDelegate?
    ) {
        self.buttonTitles = buttonTitles
        self.selectedIndex = initialIndex
        self.delegate = delegate
        
        setupInitialViews()
        updateButtonsOnIndexChange()
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
            UIScreen.main.bounds.width / CGFloat(self.buttonTitles.count)
        ) * selectorWidthRatio
    }
    
    
    private var selectorPosition: CGFloat {
        let selectedTabStartX = (
            UIScreen.main.bounds.width / CGFloat(buttonTitles.count)
        ) * CGFloat(selectedIndex)

        let offset = (
            UIScreen.main.bounds.width / CGFloat(self.buttonTitles.count)
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
        
        createButtonTitleBadges()
    }
    
    
    func updateButtonsOnIndexChange() {
        UIView.animate(withDuration: 0.3) {
            self.buttons[self.selectedIndex].setTitleColor(self.activeTextColor, for: .normal)
            self.selectorView.frame.origin.x = self.selectorPosition
        }
    }
    
    
    private func updateTitleBadges() {
        buttonTitleBadges.enumerated().forEach { (index, badge) in
            badge.frame = .init(
                x: (buttons[index].titleLabel?.frame.maxX ?? 0) + 2.5,
                y: (buttons[index].titleLabel?.frame.minY ?? 0) - 2.5,
                width: 5.0,
                height: 5.0
            )
            badge.makeCircular()
            badge.isHidden = !indicesOfTitlesWithBadge.contains(index)
        }
    }
        
    
    private func createButtonTitleBadges() {
        buttonTitleBadges = buttons!.map { button in
            let badgeView = UIView()
            
            badgeView.isHidden = true
            badgeView.backgroundColor = .Sphinx.PrimaryBlue
                
            return badgeView
        }
        
        buttonTitleBadges.enumerated().forEach { (index, badge) in
            badge.isHidden = !indicesOfTitlesWithBadge.contains(index)
            buttons[index].insertSubview(badge, at: 0)
        }
    }
}
