//
//  CameraViewController.swift
//  HDRKit
//
//  Created by Jean-François Duval on 2020-03-13.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import UIKit
import AVFoundation
import ImageIO
import CoreMotion

protocol CameraPickerControllerDelegate: class {
	func pickerController(_ pickerController: CameraViewController, didSelectImage image: UIImage?, imageType: ImageType)
    func pickerController(_ pickerController: CameraViewController, didSelectImages image: UIImage?, imageSequence: [UIImage]?, imageType: ImageType)
}

class CameraViewController: UIViewController {
    
    // MARK: - Properties
    
    let useTestImages = false
    let cameraManager = CameraManager()

    var imageSequence = [UIImage]()
    var imageExposure = [Double]()
    
    var cameraControlView: CameraControlView?
    
    var wideAngleActive = UserDefaults.standard.isWideAngleEnabled
    var photoGalleryActive = UserDefaults.standard.isLocallySaved
    var hdrActive = UserDefaults.standard.isHDREnabled
    var wideAngleImages = [UIImage]()
    weak var cameraPickerControllerDelegate: CameraPickerControllerDelegate?
    let manager = CMMotionManager()

    var frameNumber = 1
    var cameraView =  CameraControlView()

    // MARK: - UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        cameraControlView = CameraControlView(hdrActive: hdrActive, wideAngleActive: wideAngleActive, photoGalleryActive: photoGalleryActive, cameraManager: cameraManager, delegate: self)
        setCameraView()
        
        cameraManager.checkAuthorisation()
        cameraManager.configureSession()
    }
    
    override var shouldAutorotate: Bool {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return true
        }
        return false
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }
        return .portrait
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        cameraManager.sessionQueue.async {
            if self.cameraManager.setupResult == .success {
                self.cameraManager.captureSession.stopRunning()
            }
        }
        super.viewWillDisappear(animated)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageSequence.removeAll()
        imageExposure.removeAll()
        
        cameraManager.sessionQueue.async {
            if self.cameraManager.setupResult == .success {
                self.cameraManager.captureSession.startRunning()
            }
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Private functions
    
    private func setCameraView () {
        guard let cameraControlView = cameraControlView else {return}
        view.addSubview(cameraControlView)
        
        cameraControlView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            cameraControlView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraControlView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            cameraControlView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraControlView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
    }

    fileprivate func processHdrImages(_ images: [UIImage], times: [Double]) {
        let overlayViewC = OverlayViewController()
        overlayViewC.showActivityIndicator()
        overlayViewC.delegate = self
        
        navigationController?.pushViewController(overlayViewC, animated: true, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let proccessedImage = OpenCVWrapper.processHDR(withImageArray: images, andExposures: times) {
                    self.imageSequence.insert(proccessedImage, at: 0)
                    overlayViewC.setImage(processedImage: proccessedImage)
                } else {
					self.cameraPickerControllerDelegate?.pickerController(self, didSelectImages: nil, imageSequence: self.imageSequence, imageType: .hdr)
                }
            }
        })
    }

    private func reinitWideAngle() {
        wideAngleImages.removeAll()
        self.cameraControlView = nil
        cameraControlView = CameraControlView(hdrActive: hdrActive, wideAngleActive: wideAngleActive, photoGalleryActive: photoGalleryActive, cameraManager: cameraManager, delegate: self)
        setCameraView()
        cameraManager.checkAuthorisation()
    }
}

extension CameraViewController: AVCapturePhotoCaptureDelegate {

    func getEXIFFromImage(image: NSData) -> NSDictionary? {
        if
            let imageSourceRef = CGImageSourceCreateWithData(image, nil),
            let currentProperties = CGImageSourceCopyPropertiesAtIndex(imageSourceRef, 0, nil)
        {
            return NSMutableDictionary(dictionary: currentProperties)
        } else {
            return nil
        }
    }

    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let photoData = photo.fileDataRepresentation() else { return }
//        print(getEXIFFromImage(image: NSData(data: photoData)))
        
        if hdrActive {
            let exposureValues = Constants.exposureValues
            guard
                let photoData = photo.fileDataRepresentation(),
                let exifMetadata = getEXIFFromImage(image: NSData(data: photoData))?["{Exif}"] as? NSDictionary,
                let exposureTime = exifMetadata["ExposureTime"] as? Double
                else {
                    return
            }
            
            if let image = UIImage(data: photoData) {
                imageSequence.append(image)
                imageExposure.append(exposureTime)
                
                if #available(iOS 9.0, *) {
                    AudioServicesPlaySystemSoundWithCompletion(SystemSoundID(1108), nil)
                } else {
                    AudioServicesPlaySystemSound(1108)
                }
                
                if exposureValues.count == photo.sequenceCount {
                    imageSequence.append(image)
                    imageExposure.append(exposureTime)
                        
                    processHdrImages(imageSequence, times: imageExposure)
                }
            }
        } else if wideAngleActive {
            if let image = UIImage(data: photoData) {
                wideAngleImages.append(image)
            }
            if self.wideAngleImages.count == 3 {
                processWideAngleImage(self.wideAngleImages)
            }
            return
        } else {
            if let image = UIImage(data: photoData) {
                passImage(image)
            }
        }
    }

    private func passImage(_ image: UIImage) {
        let overlayViewC = OverlayViewController()
        overlayViewC.showActivityIndicator()
        overlayViewC.delegate = self
        overlayViewC.setImage(processedImage: image)
        navigationController?.pushViewController(overlayViewC, animated: true)
    }

    private func processWideAngleImage(_ images: [UIImage]) {
        let overlayViewC = OverlayViewController()
        overlayViewC.showActivityIndicator()
        overlayViewC.delegate = self

        navigationController?.pushViewController(overlayViewC, animated: true, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if let proccessedImage = OpenCVWrapper.processStich(with: images) {
                    self.imageSequence.insert(proccessedImage, at: 0)
                    overlayViewC.setImage(processedImage: proccessedImage)
                } else {
					self.cameraPickerControllerDelegate?.pickerController(self, didSelectImage: nil, imageType: .wideAngle)
                    self.reinitWideAngle()
                    self.navigationController?.popViewController(animated: true)
                }
            }
        })
    }
}

extension CameraViewController: CameraControlViewDelegate {
    
    func cameraControlView(didActivateHdr active: Bool) {
        UserDefaults.standard.isHDREnabled = active
        hdrActive = active
    }
    
    func cameraControlView(didActivateWideAngle active: Bool) {
        UserDefaults.standard.isWideAngleEnabled = active
        wideAngleActive = active
        
        if !active {
            wideAngleImages.removeAll()
        }
    }
    
    func cameraControlView(didActivatePhottoGallery active: Bool) {
        UserDefaults.standard.isLocallySaved = active
        photoGalleryActive = active
    }

    func didTapCameraButton(numOfFramesCaptured: Int) {
        if wideAngleActive {
            //for now keeping HDR off while Stiching
            if wideAngleImages.count == numOfFramesCaptured - 1 {
                self.cameraManager.captureImageFromCamera(cameraVC: self, orientation: (cameraControlView?.orientationManager.orientation)!, isHDREnabled: false)
            }
        } else {
            if useTestImages {
                // swiftlint:disable:next force_unwrapping
                imageSequence = (0...15).map { return UIImage(named: "memorial\($0).png")! }

                imageExposure = [
                    0.03125,
                    0.0625,
                    0.125,
                    0.25,
                    0.5,
                    1.0,
                    2.0,
                    4.0,
                    8.0,
                    16.0,
                    32.0,
                    64.0,
                    128.0,
                    256.0,
                    512.0,
                    1024.0
                ]

                processHdrImages(imageSequence, times: imageExposure)
            } else {
                cameraManager.captureImageFromCamera(cameraVC: self, orientation: (cameraControlView?.orientationManager.orientation)!, isHDREnabled: hdrActive)
            }
        }
    }
    
    func didTapDissmissButton() {
        self.dismiss(animated: true, completion: nil)
    }
}

extension CameraViewController: OverlayViewControllerDelegate {

    func resetWideAngle() {
        if wideAngleActive {
            self.reinitWideAngle()
        }
    }

    func useTheImageClicked(proccessedImage: UIImage?) {
        if hdrActive {
			self.cameraPickerControllerDelegate?.pickerController(self, didSelectImages: proccessedImage, imageSequence: self.imageSequence, imageType: .hdr)
            if self.photoGalleryActive {
                if let image = proccessedImage {
                    self.cameraManager.savePhotoToLibrary(photoData: image)
                }
            }
        } else if wideAngleActive {
			self.cameraPickerControllerDelegate?.pickerController(self, didSelectImage: proccessedImage, imageType: .wideAngle)

            if self.photoGalleryActive {
                if let image = proccessedImage {
                    self.cameraManager.savePhotoToLibrary(photoData: image)
                }
            }
        } else {
			self.cameraPickerControllerDelegate?.pickerController(self, didSelectImage: proccessedImage, imageType: .normal)
            if self.photoGalleryActive {
                if let image = proccessedImage {
                    if let image = image.updateImageOrientionUpSide() {
                        self.cameraManager.savePhotoToLibrary(photoData: image)
                    }
                }
            }
        }
    }
}

extension UINavigationController {
    
    override open var shouldAutorotate: Bool {
        if visibleViewController is CameraViewController {
            if UIDevice.current.userInterfaceIdiom == .pad {
                return true
            } else {
                return false
            }
        }

        return true
    }
    
    override open var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .all
        }
        return .portrait
    }
    
    func pushViewController(_ viewController: UIViewController, animated: Bool, completion: @escaping () -> Void) {
        pushViewController(viewController, animated: animated)
        
        if animated, let coordinator = transitionCoordinator {
            coordinator.animate(alongsideTransition: nil) { _ in
                completion()
            }
        } else {
            completion()
        }
    }
}
