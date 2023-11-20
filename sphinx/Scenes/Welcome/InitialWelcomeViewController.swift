import UIKit

class InitialWelcomeViewController: UIViewController {
    
    @IBOutlet weak var welcomeTitle: UILabel!
    @IBOutlet weak var newUserButton: UIButton!
    @IBOutlet weak var existingUserButton: UIButton!
    
    @IBOutlet weak var newUserButtonContainer: UIView!
    @IBOutlet weak var existingUserButtonContainer: UIView!
    
    static func instantiate() -> InitialWelcomeViewController {
        let viewController = StoryboardScene.Welcome.initialWelcomeViewController.instantiate()
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserData.sharedInstance.clearData()
        
        welcomeTitle.text = "welcome.initial.title".localized.uppercased()
        
        setupButton(
            newUserButton,
            in: newUserButtonContainer,
            withTitle: "new.user".localized,
            withAccessibilityString: "new.user"
        )
        
        setupButton(
            existingUserButton,
            in: existingUserButtonContainer,
            withTitle: "existing.user".localized,
            withAccessibilityString: "existing.user"
        )
    }
    
    
    @IBAction func newUserButtonTapped(_ sender: UIButton) {
        let nextVC = NewUserSignupOptionsViewController.instantiate()
        
        navigationController?
            .pushViewController(nextVC, animated: true)
    }
    
    
    @IBAction func existingUserButtonTapped(_ sender: UIButton) {
        let restoreExistingUserDescriptionVC = RestoreUserDescriptionViewController.instantiate()
        
        navigationController?
            .pushViewController(restoreExistingUserDescriptionVC, animated: true)
    }
    
}


extension InitialWelcomeViewController {
    
    private func setupButton(
        _ button: UIButton,
        in container: UIView,
        withTitle title: String,
        withAccessibilityString string: String
    ) {
        container.layer.cornerRadius = container.frame.size.height / 2
        container.clipsToBounds = true
        container.addShadow(location: .bottom, opacity: 0.5, radius: 2.0)
        
        button.setTitle(title, for: .normal)
        button.accessibilityIdentifier = string
    }
}
