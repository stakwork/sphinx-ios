import Foundation


extension PodcastModel {
    var suggestedSats: Int { Int(round(suggestedBTC * Constants.satoshisInBTC)) }
}
