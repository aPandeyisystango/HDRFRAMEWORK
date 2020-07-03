//
//  CameraControlView.swift
//  HDRKit
//
//  Created by macmini41 on 14/04/20.
//  Copyright © 2020 Immosquare. All rights reserved.
//
import Photos
import UIKit

protocol CameraControlViewDelegate: class {
    func cameraControlView(didActivateHdr active: Bool)
    func cameraControlView(didActivateWideAngle active: Bool)
    func cameraControlView(didActivatePhottoGallery active: Bool)
    func didTapCameraButton(numOfFramesCaptured: Int)
    func didTapDissmissButton()
}

class CameraControlView: UIView {
    
    // MARK: - Properties
    
    var hdrButton = CameraControlButton()
    var wideAngleButton = CameraControlButton()
    var photoGalleryButton = CameraControlButton()
    var cameraButton = UIButton()
    var crossButton = UIButton()
    let previewView = PreviewView()
    private let topView = UIView()
    private let bottomView = UIView()
    private var wideAngleActive: Bool
    private var photoGalleryActive: Bool
    private var hdrActive: Bool
    private var cameraManager: CameraManager
    
    var orientationManager = OrientationManager()
    
    weak  var delegate: CameraControlViewDelegate?
    private var rotationFlag: Bool
    
    // MARK: - Init
    
    init() {
        self.hdrActive = false
        self.wideAngleActive = false
        self.photoGalleryActive = false
        self.rotationFlag = false
        self.cameraManager = CameraManager()
        super.init(frame: CGRect.zero)
    }
    
    init(hdrActive: Bool, wideAngleActive: Bool, photoGalleryActive: Bool, cameraManager: CameraManager, delegate: CameraControlViewDelegate) {
        self.delegate = delegate
        self.hdrActive = hdrActive
        self.wideAngleActive = wideAngleActive
        self.rotationFlag = false
        self.photoGalleryActive = photoGalleryActive
        self.cameraManager = cameraManager

        super.init(frame: CGRect.zero)
        crossButton.addTarget(self, action: #selector(dismissButtonAction), for: .touchUpInside)
        cameraButton.addTarget(self, action: #selector(cameraButtonAction), for: .touchUpInside)
        previewView.videoPreviewLayer.session = cameraManager.captureSession
        previewView.videoPreviewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        previewView.videoPreviewLayer.frame = UIScreen.main.bounds
    }
    
    private var cameraHeight: CGFloat {
        var ratio: CGFloat
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            // On iPad change the ratio to support the various screen ratio
            ratio = 5
        } else {
            ratio = 4
        }
        
        if Constants.screenHeight > Constants.screenWidth {
            return Constants.screenHeight - ((Constants.screenWidth/3) * ratio)
        } else {
            return Constants.screenWidth - ((Constants.screenHeight/3) * ratio)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UIView
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        setUpUI()
        layoutIfNeeded()
        
        addCameraButton(on: bottomView, withButtonSize: bottomView.frame.height - 40)
        addHDRButton(on: bottomView, withButtonSize: 40)
        addWideAngleButton(on: bottomView, size: 40)
        addSaveButton(on: bottomView, size: 40)
    }

    // this methods sets the initial UI that is needed
    private func setUpUI() {
        //self.backgroundColor = .black
        self.addSubview(previewView)
        previewView.updatePreviewViewConstraints(cameraHeight: cameraHeight, parentView: self )
        previewView.didActivateWideAngle(active: wideAngleActive)
        previewView.delegate = self
        addTopView()
        addBottomView(cameraHeight: cameraHeight, parentView: self )
        if UIDevice.current.userInterfaceIdiom == .pad {
            topView.backgroundColor = .clear
            bottomView.backgroundColor = .clear
        } else {
            topView.backgroundColor = .black
            bottomView.backgroundColor = .black
        }
    }

    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        orientationManager.startOrientationUpdate()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: .orientationChanged, object: nil)
    }

    override func removeFromSuperview() {
        super.removeFromSuperview()
        NotificationCenter.default.removeObserver(self, name: .orientationChanged, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    // MARK: - Actions
    
    @objc func cameraButtonAction() {
        if wideAngleActive {
        previewView.cameraCaptureClicked(active: wideAngleActive)
            return
        }
        delegate?.didTapCameraButton(numOfFramesCaptured: 1)
     }
     
     @objc func dismissButtonAction() {
        delegate?.didTapDissmissButton()
     }
    
    // MARK: - Internal function
    
    func setTransparentBackground() {
        
    }
    
    // MARK: - private functions
    private func addTopView() {
        topView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(topView)
        
        NSLayoutConstraint.activate([
            topView.topAnchor.constraint(equalTo: self.topAnchor),
            topView.widthAnchor.constraint(equalTo: self.widthAnchor)
        ])
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            NSLayoutConstraint.activate([
                topView.heightAnchor.constraint(equalToConstant: 100)
            ])
        } else {
            NSLayoutConstraint.activate([
                topView.heightAnchor.constraint(equalToConstant: cameraHeight/3)
            ])
        }
        
        addCrossButton(on: topView)
    }
    
    private func addBottomView(cameraHeight: CGFloat, parentView: UIView) {
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        parentView.addSubview(bottomView)
        
        NSLayoutConstraint.activate([
            bottomView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor),
            bottomView.widthAnchor.constraint(equalTo: parentView.widthAnchor)
        ])
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            NSLayoutConstraint.activate([
                bottomView.heightAnchor.constraint(equalToConstant: 120)
            ])
        } else {
            NSLayoutConstraint.activate([
                bottomView.topAnchor.constraint(equalTo: parentView.bottomAnchor, constant: -(cameraHeight/3) * 2),
                bottomView.heightAnchor.constraint(equalToConstant: (cameraHeight/3) * 2)
            ])
        }
    }
    
    private func addHDRButton(on parentView: UIView, withButtonSize size: CGFloat) {
        parentView.addSubview(hdrButton)
        
        hdrButton.translatesAutoresizingMaskIntoConstraints = false
        hdrButton.setImage(UIImage(named: "Icon-HDR", in: Bundle(for: HDRKit.self), compatibleWith: nil), for: .normal)
        hdrButton.setStatus(active: hdrActive)
        hdrButton.layer.cornerRadius =  6
        hdrButton.layer.masksToBounds = true
        hdrButton.layer.borderColor = UIColor.white.cgColor
        
        var buttonBottomConstant: CGFloat = -10
        if UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.safeAreaInsets.bottom != 0 {
            buttonBottomConstant = -26
        }
        NSLayoutConstraint.activate([
            hdrButton.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -15),
            hdrButton.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: buttonBottomConstant),
            hdrButton.widthAnchor.constraint(equalToConstant: size),
            hdrButton.heightAnchor.constraint(equalToConstant: size)
        ])
        hdrButton.addTarget(self, action: #selector(hdrButtonPressend), for: .touchUpInside)
    }
    
    private func addCameraButton(on parentView: UIView, withButtonSize size: CGFloat) {
        parentView.addSubview(cameraButton)
        
        cameraButton.translatesAutoresizingMaskIntoConstraints = false
        cameraButton.setImage(UIImage(named: "Icon-Camera-Capture", in: Bundle(for: HDRKit.self), compatibleWith: nil), for: .normal)
        
        NSLayoutConstraint.activate([
            cameraButton.centerXAnchor.constraint(equalTo: parentView.centerXAnchor),
            cameraButton.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            cameraButton.widthAnchor.constraint(equalToConstant: size),
            cameraButton.heightAnchor.constraint(equalToConstant: size)
        ])
    }
    
    private func addCrossButton(on parentView: UIView) {
        crossButton.translatesAutoresizingMaskIntoConstraints = false
        crossButton.setImage(UIImage(named: "Icon-Dismiss", in: Bundle(for: HDRKit.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        crossButton.tintColor = .white
        parentView.addSubview(crossButton)

        NSLayoutConstraint.activate([
            crossButton.centerYAnchor.constraint(equalTo: parentView.centerYAnchor),
            crossButton.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -15),
            crossButton.widthAnchor.constraint(equalToConstant: 30),
            crossButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    private func addWideAngleButton(on parentView: UIView, size: CGFloat ) {
        parentView.addSubview(wideAngleButton)
        
        wideAngleButton.translatesAutoresizingMaskIntoConstraints = false
        wideAngleButton.layer.borderColor = UIColor.white.cgColor
        wideAngleButton.layer.cornerRadius = 6
        wideAngleButton.layer.masksToBounds = true
        wideAngleButton.setImage(UIImage(named: "Icon-Wide-Angle", in: Bundle(for: HDRKit.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate), for: .normal)
        wideAngleButton.setStatus(active: wideAngleActive)
        
        NSLayoutConstraint.activate([
            wideAngleButton.topAnchor.constraint(equalTo: parentView.topAnchor, constant: 10),
            wideAngleButton.trailingAnchor.constraint(equalTo: parentView.trailingAnchor, constant: -15),
            wideAngleButton.widthAnchor.constraint(equalToConstant: size),
            wideAngleButton.heightAnchor.constraint(equalToConstant: size)
        ])
        
        wideAngleButton.addTarget(self, action: #selector(wideAngleButtonPressend(sender:)), for: .touchUpInside)
    }
    
    private func addSaveButton(on parentView: UIView, size: CGFloat ) {
        parentView.addSubview(photoGalleryButton)
        photoGalleryButton.translatesAutoresizingMaskIntoConstraints = false
        
        let saveImg = UIImage(named: "Icon-Gallery", in: Bundle(for: HDRKit.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        photoGalleryButton.setImage(saveImg, for: .normal)
        photoGalleryButton.setStatus(active: photoGalleryActive)
        photoGalleryButton.layer.borderColor = UIColor.white.cgColor
        photoGalleryButton.layer.cornerRadius =  6
        photoGalleryButton.layer.masksToBounds = true
        
        var buttonBottomConstant: CGFloat = -10
        if UIApplication.shared.windows.filter({$0.isKeyWindow}).first?.safeAreaInsets.bottom != 0 {
            buttonBottomConstant = -26
        }
        NSLayoutConstraint.activate([
            photoGalleryButton.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: buttonBottomConstant),
            photoGalleryButton.leadingAnchor.constraint(equalTo: parentView.leadingAnchor, constant: 15),
            photoGalleryButton.widthAnchor.constraint(equalToConstant: size),
            photoGalleryButton.heightAnchor.constraint(equalToConstant: size)
        ])
        
        photoGalleryButton.addTarget(self, action: #selector(photoGalleryButtonPressend), for: .touchUpInside)
    }

    @objc private func orientationChanged() {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.5) {
                if UIDevice.current.userInterfaceIdiom == .pad {
                    if UIDevice.current.orientation.isPortrait {
                        self.rotationFlag = true
                    }
                    if self.rotationFlag {
                        NotificationCenter.default.addObserver(self, selector: #selector(self.cameraRotation), name: UIDevice.orientationDidChangeNotification, object: nil)
                    } else {
                        self.cameraRotation()
                        self.rotationFlag = true
                    }
                } else {
                    self.hdrButton.transform = CGAffineTransform(rotationAngle: self.orientationManager.orientationAngle)
                    self.photoGalleryButton.transform = CGAffineTransform(rotationAngle: self.orientationManager.orientationAngle)
                    self.wideAngleButton.transform = CGAffineTransform(rotationAngle: self.orientationManager.orientationAngle)
                }
            }
        }
    }

    @objc func cameraRotation() {
        self.previewView.transform = CGAffineTransform(rotationAngle: self.orientationManager.orientationAngle)
        self.previewView.levelStaticView.transform = CGAffineTransform(rotationAngle: self.orientationManager.orientationAngle)
    }
}

extension  CameraControlView {
    
    // MARK: - Actions
    
    @objc func hdrButtonPressend(sender: CameraControlButton) {
        hdrButton.backgroundColor = .white
        hdrActive.toggle()
        delegate?.cameraControlView(didActivateHdr: hdrActive)
        sender.setStatus(active: hdrActive)
    }
    
    @objc func wideAngleButtonPressend(sender: CameraControlButton) {
        wideAngleActive.toggle()
        delegate?.cameraControlView(didActivateWideAngle: wideAngleActive)

        //this code resets wide angle UI
        previewView.didActivateWideAngle(active: wideAngleActive)
        sender.setStatus(active: wideAngleActive)

        if wideAngleActive {
            sender.layer.borderWidth = 0
            sender.tintColor = .black
            sender.backgroundColor = .white
        } else {
            sender.layer.borderWidth = 1
            sender.tintColor = .white
            sender.backgroundColor = .black
        }
    }
    
    @objc func photoGalleryButtonPressend(sender: CameraControlButton) {
        photoGalleryActive.toggle()
        delegate?.cameraControlView(didActivatePhottoGallery: photoGalleryActive)
        
        let saveImg = UIImage(named: "Icon-Gallery", in: Bundle(for: HDRKit.self), compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        sender.setImage(saveImg, for: .normal)
        sender.setStatus(active: photoGalleryActive)
    }
    
}

extension CameraControlView: PreviewViewDelegate {
    func captureWideAngle(numOfFramesCaptured: Int) {
        delegate?.didTapCameraButton(numOfFramesCaptured: numOfFramesCaptured)
    }
    
}
