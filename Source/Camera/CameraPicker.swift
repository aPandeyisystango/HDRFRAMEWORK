//
//  CameraPicker.swift
//  HDRKit
//
//  Created by Jean-François Duval on 2020-03-13.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import UIKit

class CameraPicker: NSObject, CameraPickerControllerDelegate, ImagePickerProtocol {

    // MARK: - Properties
    
    private weak var imagePickerDelegate: ImagePickerDelegate?
    private let cameraPickerController = CameraViewController()
    private var isBracketingEnabled  = false

    // MARK: - Init
    
    init(imagePickerDelegate: ImagePickerDelegate, isBracketingEnabled: Bool) {
        super.init()
        
        self.cameraPickerController.cameraPickerControllerDelegate = self
        self.imagePickerDelegate = imagePickerDelegate
        self.isBracketingEnabled = isBracketingEnabled
    }
    
    // MARK: - ImagePickerProtocol
    
    func present(from viewController: UIViewController) {
        let navigationController = UINavigationController(rootViewController: cameraPickerController)
        navigationController.modalPresentationStyle = .fullScreen
        navigationController.isNavigationBarHidden = true
        viewController.present(navigationController, animated: true)
    }
    
	func imageSelected(_ image: UIImage?, type: ImageType) {
		self.imagePickerDelegate?.imagePicker(self, didSelectImage: image, imageType: type, from: .camera)
    }

    func imageSequenceSelected(image: UIImage?, imageSequence: [UIImage]?, type: ImageType) {
		self.imagePickerDelegate?.imagePicker(self, didSelectImage: image, imageSequence: imageSequence, imageType: type, from: .camera)
    }
    
    func pickerController(_ pickerController: CameraViewController, didSelectImage image: UIImage?, imageType: ImageType) {
        imageSelected(image, type: imageType)
    }

    func pickerController(_ pickerController: CameraViewController, didSelectImages image: UIImage?, imageSequence: [UIImage]?, imageType: ImageType) {
		imageSequenceSelected(image: image, imageSequence: imageSequence, type: imageType)
    }
}
