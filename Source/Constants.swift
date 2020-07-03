//
//  Constants.swift
//  HDRKit
//
//  Created by macmini41 on 26/03/20.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import UIKit

class Constants: NSObject {
    static let exposureValues: [Float] = [-3.0, 0.0, 3.0]
    static let screenWidth: CGFloat = UIScreen.main.bounds.width
    static let screenHeight: CGFloat = UIScreen.main.bounds.height
}

extension UserDefaults {

    private var locallySaved: String {
        return (Bundle.main.bundleIdentifier ?? "") + ".locallySaved"
    }
    
    private var wideAngleEnabled: String {
        return (Bundle.main.bundleIdentifier ?? "") + ".wideAngleEnabled"
    }
    
    private var hdrEnabledKey: String {
        return (Bundle.main.bundleIdentifier ?? "") + ".HDREnabled"
    }

    var isWideAngleEnabled: Bool {
        set {
            set(newValue, forKey: wideAngleEnabled)
            synchronize()
        }
        get {
            if value(forKey: wideAngleEnabled) == nil {
                return true
            }
            return bool(forKey: wideAngleEnabled)
        }
    }

    var isLocallySaved: Bool {
        set {
            set(newValue, forKey: locallySaved)
            synchronize()
        }
        get {
            if value(forKey: locallySaved) == nil {
                return true
            }
            return bool(forKey: locallySaved)
        }
    }
    
    var isHDREnabled: Bool {
        set {
            set(newValue, forKey: hdrEnabledKey)
            synchronize()
        }
        get {
            if value(forKey: hdrEnabledKey) == nil {
                return true
            }
            return bool(forKey: hdrEnabledKey)
        }
    }
}

extension NSNotification.Name {
    static let orientationChanged = NSNotification.Name((Bundle.main.bundleIdentifier ?? "") + ".orientationChanged")
}
