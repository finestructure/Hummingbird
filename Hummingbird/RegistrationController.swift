//
//  RegistrationController.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 30/08/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


enum LicenseCheck {
    case valid(License)
    case invalid
    case error(Error)
}


protocol RegistrationControllerDelegate: class {
    func didSubmit(license: LicenseCheck)
}


class RegistrationController: NSWindowController {
    
    @IBOutlet weak var licenseKeyField: NSTextField!
    @IBOutlet weak var errorLabel: NSTextField!
    @IBOutlet weak var submitButton: NSButton!
    @IBOutlet weak var spinner: NSProgressIndicator!

    weak var delegate: RegistrationControllerDelegate?


    lazy var successAlert: NSAlert = {
        let alert = NSAlert()
        alert.alertStyle = .informational
        alert.messageText = "Registration successful"
        alert.informativeText = """
        Your copy of Hummingbird has been registered.

        Thank you for your support!
        """
        return alert
    }()


    var error: String? {
        didSet {
            if let error = error {
                errorLabel.stringValue = error
                errorLabel.isHidden = false
            } else {
                errorLabel.stringValue = ""
                errorLabel.isHidden = true
            }
        }
    }


    var requestInProgress: Bool = false {
        didSet {
            licenseKeyField.isEnabled = !requestInProgress
            submitButton.isHidden = requestInProgress
            spinner.isHidden = !requestInProgress
            requestInProgress ? spinner.startAnimation(self) : spinner.stopAnimation(self)
        }
    }


    override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        error = nil
        requestInProgress = false
    }


    // TODO: enabled Submit button only if string is valid
    @IBAction func submit(_ sender: Any) {
        guard !licenseKeyField.stringValue.isEmpty else {
            error = "Please enter a license key."
            return
        }

        let firstLaunched = Date(forKey: .firstLaunched, defaults: defaults) ?? Current.date()
        let license = License(key: licenseKeyField.stringValue)
        let licenseInfo = LicenseInfo(firstLaunched: firstLaunched, license: license)

        error = nil
        requestInProgress = true
        validate(licenseInfo) { status in
            DispatchQueue.main.async {
                switch status {
                case .validLicenseKey:
                    self.window?.close()
                    self.successAlert.runModal()
                    self.delegate?.didSubmit(license: .valid(license))
                case .inTrial, .invalidLicenseKey, .noLicenseKey:
                    self.delegate?.didSubmit(license: .invalid)
                    self.error = "⚠️ License key invalid."
                case .error(let error):
                    print("⚠️ \(error)")
                    self.delegate?.didSubmit(license: .error(error))
                    self.error = "⚠️ \(error.localizedDescription)"
                }
                self.requestInProgress = false
            }
        }
    }


    @IBAction func purchaseLinkClicked(_ sender: Any) {
        presentPurchaseView()
    }


    @IBAction func retrieveLicenseKeyClicked(_ sender: Any) {
        NSWorkspace.shared.open(Links.retrieveLicenseKey)
    }

}
