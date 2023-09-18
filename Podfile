platform :ios, '13.0'
use_frameworks!
inhibit_all_warnings!

install! 'cocoapods'

target 'sphinx' do
    pod 'Alamofire', '~> 5.6.4'
    pod 'ReachabilitySwift'
    pod 'SwiftyJSON'
    pod 'SDWebImage', '~> 5.12'
    pod 'SDWebImageFLPlugin'
    pod 'SDWebImageSVGCoder', '~> 1.5.0'
    pod 'KYDrawerController'
    pod 'SwiftyRSA'
    pod 'RNCryptor', '~> 5.0'
    pod 'SwiftLinkPreview', '~> 3.4.0'
    pod 'JitsiMeetSDK', '~> 3.6.0'
    pod 'KeychainAccess'
    pod 'Giphy', '2.1.1'
    pod 'Starscream', '~> 3.1'
    pod 'lottie-ios'
    pod 'Tor', podspec: 'https://raw.githubusercontent.com/iCepa/Tor.framework/v405.8.1/Tor.podspec'
    pod "SwiftyXMLParser", :git => 'https://github.com/yahoojapan/SwiftyXMLParser.git'
    pod "youtube-ios-player-helper", "~> 1.0.3"
    pod 'MarqueeLabel'
    pod 'ObjectMapper'
    pod 'UIView-Shimmer', '~> 1.0'
    pod 'CocoaMQTT', :git => 'https://github.com/emqx/CocoaMQTT.git'
    pod 'MessagePack.swift', '~> 4.0'
    
    post_install do |installer|
      installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['ENABLE_BITCODE'] = 'NO'
          config.build_settings["SWIFT_OPTIMIZATION_LEVEL"] = "-Onone"
          config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
        end
      end
    end
end
