//
//  String+Extensions.swift
//  HDRKit
//
//  Created by Jean-François Duval on 2020-03-11.
//  Copyright © 2020 Immosquare. All rights reserved.
//

import Foundation

extension String {
    
    var localized: String {
        let bundle = Bundle(for: HDRKit.self)
        
        return bundle.localizedString(forKey: self, value: "", table: nil)
    }
}
