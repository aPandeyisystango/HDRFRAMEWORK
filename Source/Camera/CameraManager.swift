//
//  CameraManager.swift
//  HDRKit
//
//  Created by macmini41 on 19/03/20.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import UIKit
import Photos

public enum SessionSetupResult {
    case success
    case notAuthorized
    case configurationFailed
}

class CameraManager: NSObject {
    
    // MARK: - Properties

    var setupResult: SessionSetupResult = .success
    let sessionQueue = DispatchQueue(__label: "com.immosquare.hdr.sessionqueue", attr: nil)
    var captureSession: AVCaptureSession = AVCaptureSession()
    let stillImageOutput = AVCapturePhotoOutput()
    
    // MARK: - Private functions

    func configureSession() {
        sessionQueue.async {
            self.setConfigureSession()
        }
    }
    
    func checkAuthorisation() {
        self.captureSession.startRunning()
        
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            // The user has previously granted access to the camera.
            break
        case .notDetermined:
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
                if !granted {
                    self.setupResult = .notAuthorized
                }
                self.sessionQueue.resume()
            })
            
        default:
            // The user has previously denied access.
            setupResult = .notAuthorized
        }
    }
    
    // MARK: - Private functions
    
    private func setConfigureSession() {
        if setupResult != .success {
            return
        }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .photo
        // Add video input.
        do {
            var defaultVideoDevice: AVCaptureDevice?
            // Choose the back dual camera, if available, otherwise default to a wide angle camera.
            if let dualCameraDevice = AVCaptureDevice.default(.builtInDualCamera, for: .video, position: .back) {
                defaultVideoDevice = dualCameraDevice
            } else if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
                // If a rear dual camera is not available, default to the rear wide angle camera.
                defaultVideoDevice = backCameraDevice
            } else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                // If the rear wide angle camera isn't available, default to the front wide angle camera.
                defaultVideoDevice = frontCameraDevice
            }
            guard let videoDevice = defaultVideoDevice else {
                print("Default video device is unavailable.")
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                return
            }
            let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            
            if captureSession.canAddInput(videoDeviceInput) {
                captureSession.addInput(videoDeviceInput)
                //self.videoDeviceInput = videoDeviceInput
            } else {
                print("Couldn't add video device input to the session.")
                setupResult = .configurationFailed
                captureSession.commitConfiguration()
                return
            }
        } catch {
            print("Couldn't create video device input: \(error)")
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }
        
        // Add the photo output.
        if captureSession.canAddOutput(stillImageOutput) {
            captureSession.addOutput(stillImageOutput)
        } else {
            print("Could not add photo output to the session")
            setupResult = .configurationFailed
            captureSession.commitConfiguration()
            return
        }
        captureSession.commitConfiguration()
    }
    
    private func captureImageBrackets(cameraVC: CameraViewController, orientation: AVCaptureVideoOrientation) {
        let exposureValues: [Float] = Constants.exposureValues
        let makeAutoExposureSettings = AVCaptureAutoExposureBracketedStillImageSettings.autoExposureSettings(exposureTargetBias:)
        let exposureSettings = exposureValues.map(makeAutoExposureSettings)
        let photoSettings = AVCapturePhotoBracketSettings(rawPixelFormatType: 0,
                                                          processedFormat: [AVVideoCodecKey: AVVideoCodecType.jpeg],
                                                          bracketedSettings: exposureSettings)
        photoSettings.isLensStabilizationEnabled = AVCapturePhotoOutput().isLensStabilizationDuringBracketedCaptureSupported
        if let photoOutputConnection = stillImageOutput.connection(with: .video) {
            photoOutputConnection.videoOrientation = orientation
        }
        stillImageOutput.capturePhoto(with: photoSettings, delegate: cameraVC)
    }
    
    func captureImageFromCamera(cameraVC: CameraViewController, orientation: AVCaptureVideoOrientation, isHDREnabled: Bool) {
        sessionQueue.async {
            if isHDREnabled {
                self.captureImageBrackets(cameraVC: cameraVC, orientation: orientation)
            } else {
                if let photoOutputConnection = self.stillImageOutput.connection(with: .video) {
                    photoOutputConnection.videoOrientation = orientation
                }
                let photoSettings = AVCapturePhotoSettings()
                self.stillImageOutput.capturePhoto(with: photoSettings, delegate: cameraVC)
            }
        }
    }
    
    func savePhotoToLibrary(photoData: UIImage) {
        let data = photoData.pngData()
        // Check the authorization status.
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized {
                PHPhotoLibrary.shared().performChanges({
                    let options = PHAssetResourceCreationOptions()
                    let creationRequest = PHAssetCreationRequest.forAsset()
                    creationRequest.addResource(with: .photo, data: data ?? Data(), options: options)
                })
            }
        }
    }
}
