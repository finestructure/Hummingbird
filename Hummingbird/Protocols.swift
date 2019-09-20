//
//  Protocols.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 19/09/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Cocoa


protocol ShowTipJarControllerDelegate: class {
    func showTipJarController()
}


protocol ShowRegistrationControllerDelegate: class {
    func showRegistrationController()
}


protocol ShowTrialExpiredAlertDelegate: class {
    func showTrialExpiredAlert(completion: (NSApplication.ModalResponse) -> ())
}
