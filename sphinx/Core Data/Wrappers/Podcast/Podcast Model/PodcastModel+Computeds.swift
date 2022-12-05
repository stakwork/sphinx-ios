import Foundation


extension PodcastModel {
    var suggestedSats: Int { Int(round(suggestedBTC * Double(Constants.satoshisInBTC))) }
}
