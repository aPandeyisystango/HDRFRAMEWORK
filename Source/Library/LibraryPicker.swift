//
//  LibraryPicker.swift
//  HDRKit
//
//  Created by Jean-François Duval on 2020-03-11.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import UIKit

class LibraryPicker: NSObject, ImagePickerProtocol, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // MARK: - Properties
    
    private let imagePickerController = UIImagePickerController()
    private weak var imagePickerDelegate: ImagePickerDelegate?
    
    // MARK: - Init
    
    init(imagePickerDelegate: ImagePickerDelegate) {
        super.init()
        
        self.imagePickerDelegate = imagePickerDelegate
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = true
        imagePickerController.mediaTypes = ["public.image"]
    }
    
    // MARK: - Internal functions
    
    func present(from viewController: UIViewController) {
        viewController.present(imagePickerController, animated: true)
    }
    
	func imageSelected(_ image: UIImage?, type: ImageType) {
        imagePickerController.dismiss(animated: true, completion: { [weak self] in
            guard let self = self else { return }
			self.imagePickerDelegate?.imagePicker(self, didSelectImage: image, imageType: .normal, from: .library)
        })
    }
    
    // MARK: - UIImagePickerControllerDelegate
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		imageSelected(nil, type: .normal)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
		imageSelected(info[.editedImage] as? UIImage, type: .normal)
    }
    
}
