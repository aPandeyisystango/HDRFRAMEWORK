//
//  OrientationManager.swift
//  HDRKit
//
//  Created by macmini41 on 20/03/20.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import UIKit
import CoreMotion
import AVFoundation

typealias OrientationHandler = (_ rotation: CGFloat) -> Void
typealias MotionHandler = (_ acceleration: CMAttitude?) -> Void

class OrientationManager: NSObject {

    // MARK: - Properties

    var accelerometerUpdateManager = CMMotionManager()
    var motionUpdateManager = CMMotionManager()
    var orientation: AVCaptureVideoOrientation = .portrait {
        didSet {
            if oldValue != orientation {
                NotificationCenter.default.post(name: .orientationChanged, object: nil)
            }
        }
    }
    var motionManager = CMMotionManager()
    var orientationAngle: CGFloat {
        if UIDevice.current.userInterfaceIdiom == .pad {
            switch self.orientation {
            case .portrait: return 0
            case .landscapeLeft: return CGFloat(Double.pi/2)
            case .portraitUpsideDown: return CGFloat(Double.pi)
            case .landscapeRight: return CGFloat(-Double.pi/2)
            @unknown default: return 0
            }
        } else {
            switch self.orientation {
            case .portrait: return 0
            case .landscapeLeft: return CGFloat(-Double.pi/2)
            case .portraitUpsideDown: return CGFloat(Double.pi)
            case .landscapeRight: return CGFloat(Double.pi/2)
            @unknown default: return 0
            }
        }
    }

    // MARK: - Internal functions
    
    func startOrientationUpdate() {
        if accelerometerUpdateManager.isDeviceMotionAvailable {
            accelerometerUpdateManager.deviceMotionUpdateInterval = 0.6
            let queue = OperationQueue()
            accelerometerUpdateManager.startAccelerometerUpdates( to: queue ) { accelerometerData, _ in
                if let accelerometerData = accelerometerData {
                    let accelerometerOrientation: AVCaptureVideoOrientation = abs(accelerometerData.acceleration.y ) < abs( accelerometerData.acceleration.x)
                        ? accelerometerData.acceleration.x > 0 ? .landscapeLeft : .landscapeRight
                        : accelerometerData.acceleration.y > 0 ? .portraitUpsideDown : .portrait
                    self.orientation = accelerometerOrientation
                }
            }
        } else {
            print("Accelerometer Not Available")
        }
    }
    func orientationUpdateWithRotation( handler: @escaping OrientationHandler) {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.01
            motionManager.startDeviceMotionUpdates(to: OperationQueue.main) { (data, _) in
                if let data = data {
                    let rotation = atan2(data.gravity.x, data.gravity.y) - .pi
                    handler(CGFloat(rotation))
                }
            }
        }
        handler(0)
    }
    
    func motionUpdates( active: Bool, handler: @escaping MotionHandler) {
        if active {
            if motionUpdateManager.isDeviceMotionAvailable {
                motionUpdateManager.startDeviceMotionUpdates(to: .main) { data, _ in
                    if let data = data {
                        handler(data.attitude)
                    }
                }
            }
        } else {
        }
    }
}
