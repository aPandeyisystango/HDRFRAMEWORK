//
//  CameraControlButton.swift
//  HDRKit
//
//  Created by Jean-François Duval on 2020-05-26.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import UIKit

class CameraControlButton: UIButton {
    
    func setStatus(active: Bool) {
        if active {
            backgroundColor = .white
            imageView?.tintColor = .black
            layer.borderWidth = 0
        } else {
            backgroundColor = .clear
            imageView?.tintColor = .white
            layer.borderWidth = 1
        }
    }
}
