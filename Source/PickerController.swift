//
//  ImagePicker.swift
//  HDRKit
//
//  Created by Jean-François Duval on 2020-03-11.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import UIKit

protocol PickerControllerDelegate: class {
    func pickerController(_ pickerController: PickerController, didSelectImage image: UIImage?, imageSequence: [UIImage]?, imageType: ImageType, from imageSourceType: ImageSourceType)
}

class PickerController: NSObject, ImagePickerDelegate {
    
    // MARK: - Properties
    
    private var imagePicker: ImagePickerProtocol?
    private weak var pickerControllerDelegate: PickerControllerDelegate?
    private var isBracketingEnabled = false
    
    // MARK: - Init
    init(pickerControllerDelegate: PickerControllerDelegate) {
        super.init()
        
        self.pickerControllerDelegate = pickerControllerDelegate
    }
    
    // MARK: - Internal functions
    
    func showImagePickerOptions(from viewController: UIViewController, isBracketingEnabled: Bool, sourceView: UIView?, barButtonItem: UIBarButtonItem?) {
        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        if let libraryPickerAction = libraryPickerAction(title: "pick_picture".localized, viewController: viewController) {
            alertController.addAction(libraryPickerAction)
        }
        
        if let cameraPickerAction = cameraPickerAction(title: "take_picture".localized, viewController: viewController, isBracketingEnabled: isBracketingEnabled) {
            alertController.addAction(cameraPickerAction)
        }
        
        alertController.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler: nil))
        
        if let sourceView = sourceView {
			alertController.popoverPresentationController?.sourceView = sourceView
			alertController.popoverPresentationController?.sourceRect = sourceView.frame
        } else if let barButtonItem = barButtonItem {
            alertController.popoverPresentationController?.barButtonItem = barButtonItem
        }

        DispatchQueue.main.async {
            viewController.present(alertController, animated: true)
        }
    }
    
    // MARK: - Private functions
    
    private func libraryPickerAction(title: String, viewController: UIViewController) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else { return nil }
        
        let alertAction = UIAlertAction(title: title, style: .default) { [weak self] _ in
            guard let self = self else { return }
            self.isBracketingEnabled = false
            
            self.imagePicker = LibraryPicker(imagePickerDelegate: self)
            self.imagePicker?.present(from: viewController)
        }
        
        return alertAction
    }
    
    private func cameraPickerAction(title: String, viewController: UIViewController, isBracketingEnabled: Bool) -> UIAlertAction? {
        guard UIImagePickerController.isSourceTypeAvailable(.camera) else { return nil }
        
        let alertAction = UIAlertAction(title: title, style: .default) { [weak self] _ in
            guard let self = self else { return }
            let cameraPicker = CameraPicker(imagePickerDelegate: self, isBracketingEnabled: isBracketingEnabled)
            self.isBracketingEnabled = isBracketingEnabled
            
            self.imagePicker = cameraPicker
            self.imagePicker?.present(from: viewController)
        }
        
        return alertAction
    }
    
    // MARK: - PickerControllerDelegate
	
	func imagePicker(_: ImagePickerProtocol, didSelectImage image: UIImage?, imageType: ImageType, from imageSourceType: ImageSourceType) {
		pickerControllerDelegate?.pickerController(self, didSelectImage: image, imageSequence: nil, imageType: imageType, from: imageSourceType)
    }
	
    func imagePicker(_: ImagePickerProtocol, didSelectImage image: UIImage?, imageSequence: [UIImage]?, imageType: ImageType, from imageSourceType: ImageSourceType) {
		pickerControllerDelegate?.pickerController(self, didSelectImage: image, imageSequence: imageSequence, imageType: imageType, from: imageSourceType)
    }
}
