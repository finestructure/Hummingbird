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


enum ValidationError: Error {
    case postDataEncodingError
}


struct TrialData {
    static let length = DateComponents(day: 7)

    let firstLaunched: Date
    let currentDate: Date
    let licenseKey: String?

    var trialEnd: Date { return Calendar.current.date(byAdding: TrialData.length, to: firstLaunched)! }
    var inTrialPeriod: Bool { return currentDate <= trialEnd }
}


func validate(licenseKey: String, session: URLSession = URLSession.shared, completion: @escaping (Bool) -> ()) throws {
    let url = URL(string: "https://api.gumroad.com/v2/licenses/verify")!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let body = [
        "product_permalink": "hummingbirdapp",
        "license_key": licenseKey,
    ]

    if let postData = try? JSONEncoder().encode(body) {
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = postData
    } else {
        throw ValidationError.postDataEncodingError
    }

    let task = session.dataTask(with: request) { data, res, err in
        if
            let res = res,
            let httpRes = res as? HTTPURLResponse,
            httpRes.statusCode == 200 {
            completion(true)
        } else {
            completion(false)
        }
    }
    task.resume()
}


func validate(_ trialData: TrialData, completion: @escaping (Status) -> ()) throws {
    if let licenseKey = trialData.licenseKey {
        try validate(licenseKey: licenseKey) { valid in
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

