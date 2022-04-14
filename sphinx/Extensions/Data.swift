//
//  Data.swift
//  sphinx
//
//  Created by Tomas Timinskas on 06/03/2020.
//  Copyright © 2020 Sphinx. All rights reserved.
//

import Foundation
import AVFoundation
import UIKit
import PDFKit

extension Data {
    var uint32: UInt32 {
        get {
            let value = UInt32(bigEndian: self.withUnsafeBytes { $0.pointee })
            return value
        }
    }
    
    var formattedSize : String {
        get {
            let bcf = ByteCountFormatter()
            bcf.allowedUnits = [.useAll]
            bcf.countStyle = .file
            return bcf.string(fromByteCount: Int64(self.count))
        }
    }
    
    func isAnimatedImage() -> Bool {
        if let source = CGImageSourceCreateWithData(self as CFData, nil) {
            let count = CGImageSourceGetCount(source)
            return count > 1
        }
        return false
    }
    
    func gifImageFromData() -> UIImage? {
            guard let source = CGImageSourceCreateWithData(self as CFData, nil) else {
                print("image doesn't exist")
                return nil
            }
            
            return Data.animatedImageWithSource(source)
        }
    
    func createGIFAnimation() -> CAKeyframeAnimation? {
        guard let src = CGImageSourceCreateWithData(self as CFData, nil) else { return nil }
        let frameCount = CGImageSourceGetCount(src)

        var time : Float = 0

        var framesArray = [AnyObject]()
        var tempTimesArray = [NSNumber]()

        for i in 0..<frameCount {
            var frameDuration : Float = 0.1;

            let cfFrameProperties = CGImageSourceCopyPropertiesAtIndex(src, i, nil)
            guard let framePrpoerties = cfFrameProperties as? [String:AnyObject] else {return nil}
            guard let gifProperties = framePrpoerties[kCGImagePropertyGIFDictionary as String] as? [String:AnyObject]
                else { return nil }

            if let delayTimeUnclampedProp = gifProperties[kCGImagePropertyGIFUnclampedDelayTime as String] as? NSNumber {
                frameDuration = delayTimeUnclampedProp.floatValue
            } else {
                if let delayTimeProp = gifProperties[kCGImagePropertyGIFDelayTime as String] as? NSNumber {
                    frameDuration = delayTimeProp.floatValue
                }
            }

            if frameDuration < 0.011 {
                frameDuration = 0.100;
            }

            if let frame = CGImageSourceCreateImageAtIndex(src, i, nil) {
                tempTimesArray.append(NSNumber(value: frameDuration))
                framesArray.append(frame)
            }

            time = time + frameDuration
        }

        var timesArray = [NSNumber]()
        var base : Float = 0
        for duration in tempTimesArray {
            timesArray.append(NSNumber(value: base))
            base += duration.floatValue / time
        }

        timesArray.append(NSNumber(value: 1.0))

        let animation = CAKeyframeAnimation(keyPath: "contents")

        animation.beginTime = AVCoreAnimationBeginTimeAtZero
        animation.duration = CFTimeInterval(time)
        animation.repeatCount = Float.greatestFiniteMagnitude;
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.values = framesArray
        animation.keyTimes = timesArray
        animation.calculationMode = CAAnimationCalculationMode.discrete

        return animation;
    }
    
    func getPDFPagesCount() -> Int? {
        guard let dataProvider = CGDataProvider(data: self as CFData), let document = CGPDFDocument(dataProvider) else {
            return nil
        }
        return document.numberOfPages
    }
    
    func getPDFThumbnail(ofPage pageIndex: Int = 0, size: CGSize = CGSize(width: 250, height: CGFloat.greatestFiniteMagnitude)) -> UIImage? {
        if let pdf = PDFDocument(data: self) {
            let pdfDocumentPage = pdf.page(at: pageIndex)
            if let image = pdfDocumentPage?.thumbnail(of: size, for: .cropBox) {
                return image
            }
        }
        return nil
    }
    
    static func delayForImageAtIndex(_ index: Int, source: CGImageSource!) -> Double {
        var delay = 0.1
        
        let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, index, nil)
        let gifProperties: CFDictionary = unsafeBitCast(
            CFDictionaryGetValue(cfProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDictionary).toOpaque()),
            to: CFDictionary.self)
        
        var delayObject: AnyObject = unsafeBitCast(
            CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFUnclampedDelayTime).toOpaque()),
            to: AnyObject.self)
        if delayObject.doubleValue == 0 {
            delayObject = unsafeBitCast(CFDictionaryGetValue(gifProperties,
                Unmanaged.passUnretained(kCGImagePropertyGIFDelayTime).toOpaque()), to: AnyObject.self)
        }
        
        delay = delayObject as! Double
        
        if delay < 0.1 {
            delay = 0.1
        }
        
        return delay
    }
    
    static func gcdForPair(_ a: Int?, _ b: Int?) -> Int {
        var a = a
        var b = b
        if b == nil || a == nil {
            if b != nil {
                return b!
            } else if a != nil {
                return a!
            } else {
                return 0
            }
        }
        
        if a ?? 0 < b ?? 0 {
            let c = a
            a = b
            b = c
        }
        
        var rest: Int
        while true {
            rest = a! % b!
            
            if rest == 0 {
                return b!
            } else {
                a = b
                b = rest
            }
        }
    }
    
    static func gcdForArray(_ array: Array<Int>) -> Int {
        if array.isEmpty {
            return 1
        }
        
        var gcd = array[0]
        
        for val in array {
            gcd = gcdForPair(val, gcd)
        }
        
        return gcd
    }
    
    static func animatedImageWithSource(_ source: CGImageSource) -> UIImage? {
            let count = CGImageSourceGetCount(source)
            var images = [CGImage]()
            var delays = [Int]()
            
            for i in 0..<count {
                if let image = CGImageSourceCreateImageAtIndex(source, i, nil) {
                    images.append(image)
                }
                
                let delaySeconds = delayForImageAtIndex(Int(i),
                    source: source)
                delays.append(Int(delaySeconds * 1000.0)) // Seconds to ms
            }
            
            let duration: Int = {
                var sum = 0
                
                for val: Int in delays {
                    sum += val
                }
                
                return sum
            }()
            
            let gcd = gcdForArray(delays)
            var frames = [UIImage]()
            
            var frame: UIImage
            var frameCount: Int
            for i in 0..<count {
                frame = UIImage(cgImage: images[Int(i)])
                frameCount = Int(delays[Int(i)] / gcd)
                
                for _ in 0..<frameCount {
                    frames.append(frame)
                }
            }
            
            let animation = UIImage.animatedImage(with: frames,
                duration: Double(duration) / 1000.0)
            
            return animation
        }
}
