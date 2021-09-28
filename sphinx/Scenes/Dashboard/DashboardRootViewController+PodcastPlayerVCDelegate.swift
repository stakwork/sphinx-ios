import UIKit


extension DashboardRootViewController: PodcastPlayerVCDelegate {
    
    func shouldDismissPlayerView() {
        navigationController?.popViewController(animated: true)
    }
    
    
    func willDismissPlayer(playing: Bool) {
    }
    
    
    func shouldShareClip(comment: PodcastComment) {
        
    }
    
    
    func shouldGoToPlayer() {
        
    }
    

    func shouldSendBoost(message: String, amount: Int, animation: Bool) -> TransactionMessage? {
        nil
    }
}
