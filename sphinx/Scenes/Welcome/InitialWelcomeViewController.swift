import UIKit

class InitialWelcomeViewController: UIViewController {
    
    @IBOutlet weak var welcomeTitle: UILabel!
    @IBOutlet weak var newUserButton: UIButton!
    @IBOutlet weak var existingUserButton: UIButton!
    
    @IBOutlet weak var newUserButtonContainer: UIView!
    @IBOutlet weak var existingUserButtonContainer: UIView!
    
    private var rootViewController: RootViewController!

    
    static func instantiate(
        rootViewController: RootViewController
    ) -> InitialWelcomeViewController {
        let viewController = StoryboardScene.Welcome.initialWelcomeViewController.instantiate()
        
        viewController.rootViewController = rootViewController
        
        return viewController
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UserData.sharedInstance.clearData()
        
        welcomeTitle.text = "welcome.initial.title".localized.uppercased()
        
        setupButton(
            newUserButton,
            in: newUserButtonContainer,
            withTitle: "new.user".localized
        )
        
        setupButton(
            existingUserButton,
            in: existingUserButtonContainer,
            withTitle: "existing.user".localized
        )
    }
    
    
    @IBAction func newUserButtonTapped(_ sender: UIButton) {
        let nextVC = NewUserSignupOptionsViewController
            .instantiate(rootViewController: rootViewController)
        
        navigationController?
            .pushViewController(nextVC, animated: true)
    }
    
    
    @IBAction func existingUserButtonTapped(_ sender: UIButton) {
        let restoreExistingUserDescriptionVC = RestoreUserDescriptionViewController
            .instantiate(rootViewController: rootViewController)
        
        navigationController?
            .pushViewController(restoreExistingUserDescriptionVC, animated: true)
    }
}


extension InitialWelcomeViewController {
    
    private func setupButton(
        _ button: UIButton,
        in container: UIView,
        withTitle title: String
    ) {
        container.layer.cornerRadius = container.frame.size.height / 2
        container.clipsToBounds = true
        container.addShadow(location: .bottom, opacity: 0.5, radius: 2.0)
        
        button.setTitle(title, for: .normal)
    }
}
