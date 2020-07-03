//
//  HDRKit.swift
//  HDRKit
//
//  Created by Jean-François Duval on 2020-03-11.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import Foundation
import UIKit
 
@objc public enum ImageSourceType: Int {
	case library
	case camera
}

@objc public enum ImageType: Int {
	case normal
	case hdr
	case wideAngle
}

@objc public protocol HDRKitDelegate: class {
	func hdrKit(_: HDRKit, didSelectImages image: UIImage?, imageSequence: [UIImage]?, imageType: ImageType, from imageSourceType: ImageSourceType)
}

@objc public class HDRKit: NSObject, PickerControllerDelegate {
    
    // MARK: - Properties
    
    private lazy var pickerController = PickerController(pickerControllerDelegate: self)
    private weak var delegate: HDRKitDelegate?
    private var isBracketingEnabled  = false
    
    // MARK: - Init
    
    @objc public init(delegate: HDRKitDelegate) {
        super.init()
        
        self.delegate = delegate
    }
   
    // MARK: - Public functions
    
    @objc public func presentAddPictureOptions(from viewController: UIViewController, sourceView: UIView) {
        pickerController.showImagePickerOptions(from: viewController, isBracketingEnabled: isBracketingEnabled, sourceView: sourceView, barButtonItem: nil)
    }
    
    @objc public func presentAddPictureOptions(from viewController: UIViewController, barButtonItem: UIBarButtonItem?) {
        pickerController.showImagePickerOptions(from: viewController, isBracketingEnabled: isBracketingEnabled, sourceView: nil, barButtonItem: barButtonItem)
    }
    
    // MARK: - PickerControllerDelegate

    func pickerController(_ pickerController: PickerController, didSelectImage image: UIImage?, imageSequence: [UIImage]?, imageType: ImageType, from imageSourceType: ImageSourceType) {
        delegate?.hdrKit(self, didSelectImages: image, imageSequence: imageSequence, imageType: imageType, from: imageSourceType)
    }
}
