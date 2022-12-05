platform :ios, '11.0'
use_frameworks!
inhibit_all_warnings!

install! 'cocoapods'

target 'sphinx' do
    pod 'Alamofire', '~> 5.0.0-rc.3'
    pod 'ReachabilitySwift'
    pod 'SwiftyJSON'
    pod 'SDWebImage', '~> 5.11'
    pod 'SDWebImageFLPlugin'
    pod 'KYDrawerController'
    pod 'SwiftyRSA'
    pod 'RNCryptor', '~> 5.0'
    pod 'SwiftLinkPreview', '~> 3.1.0'
    pod 'JitsiMeetSDK', '~> 3.6.0'
    pod 'KeychainAccess'
    pod 'Giphy', '2.1.1'
    pod 'Starscream', '~> 3.1'
    pod 'lottie-ios'
    pod 'Tor', podspec: 'https://raw.githubusercontent.com/iCepa/Tor.framework/v405.8.1/Tor.podspec'
    pod "SwiftyXMLParser", :git => 'https://github.com/yahoojapan/SwiftyXMLParser.git'
    pod "youtube-ios-player-helper", "~> 1.0.3"
    pod 'MarqueeLabel'
    pod 'HDWalletKit'
    
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
