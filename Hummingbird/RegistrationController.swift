//
//  RegistrationController.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 30/08/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


enum LicenseCheck {
    case valid
    case invalid
    case error(Error)
}


protocol RegistrationControllerDelegate: class {
    func didSubmit(license: LicenseCheck)
}


class RegistrationController: NSWindowController {
    
    @IBOutlet weak var licenseKeyField: NSTextField!

    weak var delegate: RegistrationControllerDelegate?

    // TODO: enabled Submit button only if string is valid
    @IBAction func submit(_ sender: Any) {
        let firstLaunched = Date(forKey: .firstLaunched, defaults: defaults) ?? Current.date()
        let license = License(key: licenseKeyField.stringValue)
        let licenseInfo = LicenseInfo(firstLaunched: firstLaunched, license: license)
        validate(licenseInfo) { status in
            switch status {
            case .validLicenseKey:
                print("OK: valid license")
                self.delegate?.didSubmit(license: .valid)
            case .inTrial:
                print("In trial")
                self.delegate?.didSubmit(license: .invalid)
            case .noLicenseKey:
                print("⚠️ no license")
                self.delegate?.didSubmit(license: .invalid)
            case .invalidLicenseKey:
                print("⚠️ invalid license")
                self.delegate?.didSubmit(license: .invalid)
            case .error(let error):
                print("⚠️ \(error)")
                self.delegate?.didSubmit(license: .error(error))
            }
        }
    }

}
