//
//  Constants.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 13/09/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


enum TipSize: String {
    case small
    case medium
    case large
}


struct Links {
    static let gumroadLicenseVerification = URL(string: "https://api.gumroad.com/v2/licenses/verify")!
    static let gumroadProductPage = URL(string: "https://gum.co/hummingbirdapp?wanted=true")!
    // To: Hummingbird Help <sas+hb-help@finestructure.co, Subject: Lost license, Body: I've lost my license key 😞. Could you please send it again?

    static let hummingbirdAccessibility = URL(string: "https://finestructure.co/hummingbird-accessibility")!
    static let hummingbirdHelp = URL(string: "https://finestructure.co/hummingbird-help")!

    static let retrieveLicenseKey = URL(string: "mailto:%22Hummingbird%20Help%22%3csas+hb-help@finestructure.co%3e?subject=Lost%20license%20key&body=I've%20lost%20my%20license%20key%20%F0%9F%98%9E.%20Could%20you%20please%20send%20it%20again%3F"
    )!

    static let securitySystemPreferences = URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane/")

    static func gumroadTip(size: TipSize) -> URL {
        URL(string: "https://gum.co/hb-tip-\(size.rawValue)?wanted=true")!
    }
}
