//
//  Trial.swift
//  Hummingbird
//
//  Created by Sven A. Schmidt on 04/08/2019.
//  Copyright © 2019 finestructure. All rights reserved.
//

import Foundation


enum Status {
    case inTrial
    case noLicenseKey
    case invalidLicenseKey
    case validLicenseKey
}


struct TrialData {
    static let length = DateComponents(day: 7)

    let firstLaunched: Date
    let currentDate: Date
    let licenseKey: String?

    var trialEnd: Date { return Calendar.current.date(byAdding: TrialData.length, to: firstLaunched)! }
    var inTrialPeriod: Bool { return currentDate <= trialEnd }
}


// FIXME: run against Gumroad API
func validate(licenseKey: String, completion: (Bool) -> ()) {
    if licenseKey == "good" {
        completion(true)
    } else {
        completion(false)
    }
}


func validate(_ trialData: TrialData, completion: (Status) -> ()) {
    if let licenseKey = trialData.licenseKey {
        validate(licenseKey: licenseKey) { valid in
            completion(valid ? .validLicenseKey : .invalidLicenseKey)
        }
    } else {
        if trialData.inTrialPeriod {
            completion(.inTrial)
        } else {
            completion(.noLicenseKey)
        }
    }
}

