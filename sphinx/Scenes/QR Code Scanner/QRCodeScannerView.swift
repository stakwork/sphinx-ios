//
//  Sphinx
//
//  Created by Tomas Timinskas on 09.02.18.
//  Copyright © 2018 Otto Suess. All rights reserved.
//

import AVFoundation
import UIKit

final class QRCodeScannerView: UIView {
    private weak var overlayView: UIView?
    private weak var scanRectView: UIView?
    private weak var captureDevice: AVCaptureDevice?
    
    private var captureSession = AVCaptureSession()
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var oldCode: String?
    
    var handler: ((String) -> Void)?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        DispatchQueue.main.async {
            self.setup()
        }
    }
    
    private func setup() {
        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInTrueDepthCamera, .builtInTelephotoCamera, .builtInDualCamera], mediaType: AVMediaType.video, position: .back)
        
        guard
            let captureDevice = deviceDiscoverySession.devices.first,
            let input = try? AVCaptureDeviceInput(device: captureDevice)
            else { return }
        self.captureDevice = captureDevice
        
        captureSession.addInput(input)
        let captureMetadataOutput = AVCaptureMetadataOutput()
        captureSession.addOutput(captureMetadataOutput)
        captureMetadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
        captureMetadataOutput.metadataObjectTypes = [AVMetadataObject.ObjectType.qr]
        
        let videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer.frame = layer.bounds
        layer.addSublayer(videoPreviewLayer)
        
        self.start()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        videoPreviewLayer?.frame = layer.bounds
    }
    
    func start() {
        DispatchQueue.global().async {
            self.captureSession.startRunning()
        }
    }
    
    func stop() {
        DispatchQueue.global().async {
            self.captureSession.stopRunning()
        }
        oldCode = nil
    }
}

extension QRCodeScannerView: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard
            let metadataObj = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
            let code = metadataObj.stringValue,
            code != oldCode
            else { return }
        
        oldCode = code
        handler?(code)
    }
}
