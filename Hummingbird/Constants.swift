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
    // To: Hummingbird Help <sas+hb-help@finestructure.co, Subject: Lost license, Body: I've lost my license key 😞. Could you please send it again?
    case retrieveLicenseKey = "mailto:%22Hummingbird%20Help%22%3csas+hb-help@finestructure.co%3e?subject=Lost%20license%20key&body=I've%20lost%20my%20license%20key%20%F0%9F%98%9E.%20Could%20you%20please%20send%20it%20again%3F"
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
