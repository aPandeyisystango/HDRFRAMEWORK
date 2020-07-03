//
//  ImagePickerProtocol.swift
//  HDRKit
//
//  Created by Jean-François Duval on 2020-03-11.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import UIKit

protocol ImagePickerProtocol: NSObject {
    func present(from viewController: UIViewController)
	func imageSelected(_ image: UIImage?, type: ImageType)
}

protocol ImagePickerDelegate: class {
	func imagePicker(_: ImagePickerProtocol, didSelectImage image: UIImage?, imageType: ImageType, from imageSourceType: ImageSourceType)
    func imagePicker(_: ImagePickerProtocol, didSelectImage image: UIImage?, imageSequence: [UIImage]?, imageType: ImageType, from imageSourceType: ImageSourceType)
}
