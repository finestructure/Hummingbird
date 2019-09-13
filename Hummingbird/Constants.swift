//
//  Constants.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 13/09/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


enum Links: String {
    case accessibilityHelp = "https://finestructure.co/hummingbird-accessibility"
    case gumroadProductPage = "https://gum.co/hummingbirdapp"
    case gumroadLicenseVerification = "https://api.gumroad.com/v2/licenses/verify"
    case securitySystemPreferences = "/System/Library/PreferencePanes/Security.prefPane/"

    var url: URL {
        switch self {
        case .securitySystemPreferences:
            return URL(fileURLWithPath: self.rawValue)
        default:
            return URL(string: self.rawValue)!
        }
    }
}
