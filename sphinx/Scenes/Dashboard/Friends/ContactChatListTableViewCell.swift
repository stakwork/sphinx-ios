import UIKit


class ContactChatListTableViewCell: UITableViewCell {

    var chat: Chat? {
        didSet {
            guard let chat = chat else { return }
            DispatchQueue.main.async { self.render(with: chat) }
        }
    }
}


// MARK: - Computeds
extension ContactChatListTableViewCell {
}


// MARK: - Static Properties
extension ContactChatListTableViewCell {
    static let reuseID = "ContactChatListTableViewCell"

    static let nib: UINib = {
        UINib(nibName: "ContactChatListTableViewCell", bundle: nil)
    }()
}


// MARK: - Lifecycle
extension ContactChatListTableViewCell {

    override func awakeFromNib() {
        super.awakeFromNib()

        setupView()
    }
}


// MARK: - Private Helpers
private extension ContactChatListTableViewCell {

    /// Set layout and styling for view elements
    func setupView() {

    }


    /// Feed view elements with data
    func render(with chat: Chat) {
//        someLabel.text = "some text"
    }
}
